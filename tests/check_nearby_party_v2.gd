extends SceneTree

const AdapterScript := preload("res://scripts/core/party_nearby_adapter_v2.gd")
const MatchScript := preload("res://scripts/core/dealer_party_match.gd")

class FakeNearby extends NearbyService:
	var sent: Array[Dictionary] = []
	var disconnected: Array[String] = []
	func is_supported() -> bool:
		return true
	func get_missing_permissions() -> PackedStringArray:
		return PackedStringArray()
	func start_advertising(_service_id: String, _name: String, _topology: String = "STAR") -> void:
		pass
	func start_discovery(_service_id: String, _topology: String = "STAR") -> void:
		pass
	func stop_discovery() -> void:
		pass
	func stop_all() -> void:
		pass
	func disconnect_endpoint(endpoint_id: String) -> void:
		disconnected.append(endpoint_id)
	func send_bytes(endpoint_id: String, bytes: PackedByteArray) -> void:
		sent.append({"id": endpoint_id, "bytes": bytes})

var host
var guests: Array = []
var host_wire: FakeNearby
var guest_wires: Array[FakeNearby] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	host = AdapterScript.new()
	host_wire = FakeNearby.new()
	host.nearby = host_wire
	root.add_child(host)
	host.create_room("Chủ bàn")
	assert(host.local_seat == -1 and host.players.is_empty())

	for index in AdapterScript.MAX_CLIENTS:
		var guest = AdapterScript.new()
		var wire := FakeNearby.new()
		guest.nearby = wire
		root.add_child(guest)
		guests.append(guest)
		guest_wires.append(wire)
		guest.find_rooms("Khách %d" % (index + 1))
		guest.rooms["host"] = "Chủ bàn"
		guest.join_room("host")
		host._on_connection_result("guest%d" % (index + 1), true, 0)
		guest._on_connection_result("host", true, 0)
		_drain_guest(index)
		_drain_host()

	assert(host.players.size() == 5) # Host is dealer, not a sixth player.
	for guest in guests:
		assert(guest.players.size() == 5)
		assert(guest.host_name == "Chủ bàn")
		assert(guest.local_seat >= 1 and not guest.local_player_id.is_empty())
	# A sixth client is outside the product limit and is disconnected before the match.
	host._on_connection_result("guest6", true, 0)
	host._on_payload("guest6", JSON.stringify({
		"v": AdapterScript.PROTOCOL_VERSION,
		"room": "",
		"seq": 1,
		"type": "HELLO",
		"payload": {"name": "Khách 6"},
	}).to_utf8_buffer())
	assert(host_wire.disconnected.has("guest6"))
	assert(host.start_match())
	_drain_host()
	assert(host.state["phase"] == "betting")
	assert(not host.place_bet("bau", 10_000))

	for index in guests.size():
		assert(guests[index].place_bet(GameConstants.SYMBOLS[index], 10_000))
		_drain_guest(index)
		_drain_host()
		assert(guests[index].confirm_bets())
		_drain_guest(index)
		_drain_host()

	assert(host.state["phase"] == "locked")
	for guest in guests:
		assert(guest.state["phase"] == "locked")
	# Replaying an accepted action_id with a newer transport seq cannot double the bet.
	var duplicate := {
		"v": AdapterScript.PROTOCOL_VERSION,
		"room": host.room_id,
		"seq": 100,
		"type": "PLACE_BET",
		"payload": {"round": 1, "symbol": "bau", "amount": 10_000, "action_id": "1-1"},
	}
	var first_id: String = host._endpoint_players["guest1"]
	var first_bets_before: Dictionary = host._match.get_player(first_id)["bets"].duplicate(true)
	host._on_payload("guest1", JSON.stringify(duplicate).to_utf8_buffer())
	assert(host._match.get_player(first_id)["bets"] == first_bets_before)
	assert(host.roll())
	_drain_host()
	assert(host.state["phase"] == "settled")
	for guest in guests:
		assert(guest.state["results"] == host.state["results"])
		assert(guest.state["leaderboard"] == host.state["leaderboard"])
	assert(JSON.stringify(host.state).to_utf8_buffer().size() < AdapterScript.MAX_MESSAGE_BYTES)

	# An unsupported client message cannot forge host-owned state.
	var before: Dictionary = host.state.duplicate(true)
	var forged := {
		"v": AdapterScript.PROTOCOL_VERSION,
		"room": host.room_id,
		"seq": 999,
		"type": "STATE",
		"payload": {"action_id": "forge", "balance": 99_000_000, "results": ["bau", "bau", "bau"]},
	}
	host._on_payload("guest1", JSON.stringify(forged).to_utf8_buffer())
	assert(host.state == before)

	assert(host.advance())
	_drain_host()
	assert(host.state["round_number"] == 2 and host.state["phase"] == "betting")
	# A validly shaped action from an older round is rejected.
	var stale := {
		"v": AdapterScript.PROTOCOL_VERSION,
		"room": host.room_id,
		"seq": 100,
		"type": "PLACE_BET",
		"payload": {"round": 1, "symbol": "ca", "amount": 10_000, "action_id": "stale-round"},
	}
	var third_id: String = host._endpoint_players["guest3"]
	var third_bets_before: Dictionary = host._match.get_player(third_id)["bets"].duplicate(true)
	host._on_payload("guest3", JSON.stringify(stale).to_utf8_buffer())
	assert(host._match.get_player(third_id)["bets"] == third_bets_before)
	# Reward claims change balance but never total_net, and the same reward cannot be reused.
	var rewarded_id: String = host._endpoint_players["guest2"]
	var rewarded_player: Dictionary = host._match.get_player(rewarded_id)
	rewarded_player["balance"] = 0
	rewarded_player["spectator"] = true
	var rewarded_net_before := int(rewarded_player["total_net"])
	host._publish_state()
	_drain_host()
	assert(guests[1].request_reward("reward-1"))
	_drain_guest(1)
	_drain_host()
	assert(host._match.get_player(rewarded_id)["balance"] == MatchScript.REWARD_AMOUNT)
	assert(host._match.get_player(rewarded_id)["total_net"] == rewarded_net_before)
	assert(guests[1].request_reward("reward-1"))
	_drain_guest(1)
	_drain_host()
	assert(host._match.get_player(rewarded_id)["balance"] == MatchScript.REWARD_AMOUNT)
	# Guest leaving before settle cancels the round and refunds confirmed stakes.
	assert(guests[1].place_bet("ga", 50_000))
	_drain_guest(1)
	_drain_host()
	assert(guests[1].confirm_bets())
	_drain_guest(1)
	_drain_host()
	var remaining_id: String = host._endpoint_players["guest2"]
	var locked_balance := int(host._match.get_player(remaining_id)["balance"])
	host._on_endpoint_disconnected("guest3")
	_drain_host()
	assert(host._match.get_player(remaining_id)["balance"] == locked_balance + 50_000)
	assert(host.state["phase"] == "betting")

	# A previous v3 peer is explicitly rejected instead of joining a room without the countdown contract.
	var old_message := {"v": 3, "room": host.room_id, "seq": 1000, "type": "CHOICE", "payload": {}}
	host._on_payload("guest1", JSON.stringify(old_message).to_utf8_buffer())
	assert(host_wire.disconnected.has("guest1"))

	print("Nearby party protocol v4 six-device flow passed")
	quit(0)

func _drain_guest(index: int) -> void:
	var wire := guest_wires[index]
	while not wire.sent.is_empty():
		var item: Dictionary = wire.sent.pop_front()
		host._on_payload("guest%d" % (index + 1), item["bytes"])

func _drain_host() -> void:
	while not host_wire.sent.is_empty():
		var item: Dictionary = host_wire.sent.pop_front()
		var endpoint := str(item["id"])
		var index := int(endpoint.trim_prefix("guest")) - 1
		if index >= 0 and index < guests.size():
			guests[index]._on_payload("host", item["bytes"])
