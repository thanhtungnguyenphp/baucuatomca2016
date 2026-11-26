extends SceneTree

const AdapterScript := preload("res://scripts/core/party_nearby_adapter_v2.gd")
const MatchScript := preload("res://scripts/core/dealer_party_match.gd")

class FakeNearby extends NearbyService:
	func is_supported() -> bool:
		return true
	func get_missing_permissions() -> PackedStringArray:
		return PackedStringArray()
	func stop_all() -> void:
		pass
	func send_bytes(_endpoint_id: String, _bytes: PackedByteArray) -> void:
		pass

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var host = AdapterScript.new()
	host.nearby = FakeNearby.new()
	root.add_child(host)
	await process_frame
	host.mode = "host"
	host.room_id = "123456"
	host.local_name = "Chủ bàn"
	assert(host._match.add_player("p1", "Đã đặt"))
	assert(host._match.add_player("p2", "Chưa đặt"))
	assert(host.start_match())
	assert(host.state["phase"] == MatchScript.PHASE_BETTING)
	assert(int(host.state["betting_seconds_left"]) >= 29)
	assert(int(host.state["betting_seconds_left"]) <= AdapterScript.BETTING_DURATION_SECONDS)
	assert(host._match.place_bet("p1", "bau", 50_000))
	host._betting_deadline_msec = Time.get_ticks_msec() - 1
	host._tick_betting_countdown()
	assert(host.state["phase"] == MatchScript.PHASE_LOCKED)
	assert(host.state["betting_seconds_left"] == 0)
	assert(host._match.get_player("p1")["round_stake"] == 50_000)
	assert(host._match.get_player("p1")["ready"])
	assert(host._match.get_player("p2")["round_stake"] == 0)
	assert(host._match.get_player("p2")["ready"])
	assert(not host.place_bet("bau", 10_000))
	print("Nearby authoritative 30-second countdown passed")
	quit(0)
