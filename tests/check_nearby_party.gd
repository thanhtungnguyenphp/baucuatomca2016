extends SceneTree

class FakeNearby extends NearbyService:
	var sent: Array[Dictionary] = []
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
	func send_bytes(endpoint_id: String, bytes: PackedByteArray) -> void:
		sent.append({"id": endpoint_id, "bytes": bytes})

var host: PartyNearbyAdapter
var guests: Array[PartyNearbyAdapter] = []
var host_wire: FakeNearby
var guest_wires: Array[FakeNearby] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	host = PartyNearbyAdapter.new()
	host_wire = FakeNearby.new()
	host.nearby = host_wire
	root.add_child(host)
	host.create_room("Chủ phòng")
	assert(host.local_seat == 0)
	assert(not host.start_match())
	for seat in range(1, 4):
		var guest := PartyNearbyAdapter.new()
		var wire := FakeNearby.new()
		guest.nearby = wire
		root.add_child(guest)
		guests.append(guest)
		guest_wires.append(wire)
		guest.find_rooms("Khách %d" % seat)
		guest.rooms["host"] = "Chủ phòng"
		guest.join_room("host")
		host._on_connection_result("guest%d" % seat, true, 0)
		guest._on_connection_result("host", true, 0)
		_drain_guest_messages(seat - 1)
		_drain_host_messages()
		assert(guest.local_seat == seat)
	assert(host.players.size() == 4)
	assert(host.room_id == guests[0].room_id)
	assert(host.start_match())
	_drain_host_messages()
	for turn in range(1, 6):
		assert(host.state["turn_number"] == turn)
		assert(host.choose("bau"))
		assert(not host.choose("cua")) # one choice per seat
		for index in guests.size():
			assert(guests[index].choose(GameConstants.SYMBOLS[index + 1]))
			_drain_guest_messages(index)
		_drain_host_messages()
		assert(host.state["choices"].size() == 4)
		assert(not guests[0].roll()) # host alone may shake
		assert(host.roll())
		_drain_host_messages()
		for guest in guests:
			assert(guest.state["last_results"] == host.state["last_results"])
			assert(guest.state["scores"] == host.state["scores"])
		assert(host.advance())
		_drain_host_messages()
	assert(host.state["phase"] == "finished")
	assert(guests[2].state["phase"] == "finished")
	assert(host.start_match()) # rematch
	_drain_host_messages()
	assert(host.state["turn_number"] == 1)
	# An old choice for the prior turn cannot be counted twice.
	var stale := {"v": 1, "room": host.room_id, "seq": 9999, "type": "CHOICE", "payload": {"turn": 5, "symbol": "ga"}}
	host._on_payload("guest1", JSON.stringify(stale).to_utf8_buffer())
	assert(host.state["choices"][1] == "")
	# Unknown endpoint cannot submit a choice or a result.
	var forged := {"v": 1, "room": host.room_id, "seq": 1, "type": "CHOICE", "payload": {"turn": 1, "symbol": "ga"}}
	host._on_payload("outsider", JSON.stringify(forged).to_utf8_buffer())
	assert(host.state["choices"][1] == "")
	# An active guest leaving ends the round and returns everyone to lobby.
	host._on_endpoint_disconnected("guest3")
	_drain_host_messages()
	assert(host.state.is_empty() and host.players.size() == 3)
	assert(guests[0].state.is_empty())
	assert(not guests[0].rooms.is_empty())
	host.leave()
	_drain_host_messages()
	assert(guests[0].mode == "idle")
	assert(guests[0].room_id.is_empty())
	assert(guests[0].rooms.is_empty())
	print("Nearby party 4-player flow passed")
	quit(0)

func _drain_guest_messages(index: int) -> void:
	var wire := guest_wires[index]
	while not wire.sent.is_empty():
		var item: Dictionary = wire.sent.pop_front()
		host._on_payload("guest%d" % (index + 1), item["bytes"])

func _drain_host_messages() -> void:
	while not host_wire.sent.is_empty():
		var item: Dictionary = host_wire.sent.pop_front()
		var seat := int(str(item["id"]).trim_prefix("guest"))
		if seat >= 1 and seat <= guests.size():
			guests[seat - 1]._on_payload("host", item["bytes"])
