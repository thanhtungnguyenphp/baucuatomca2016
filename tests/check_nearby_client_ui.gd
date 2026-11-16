extends SceneTree

const MatchScript := preload("res://scripts/core/dealer_party_match.gd")

class FakeNearby extends NearbyService:
	var sent: Array[Dictionary] = []
	func send_bytes(endpoint_id: String, bytes: PackedByteArray) -> void:
		sent.append({"id": endpoint_id, "bytes": bytes})
	func stop_all() -> void:
		pass

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/NearbyPartyMode.tscn") as PackedScene
	var ui = scene.instantiate()
	root.add_child(ui)
	await process_frame
	assert(ui._content_margin.get_theme_constant("margin_bottom") == 120)
	ui._on_banner_visibility_changed(true)
	assert(ui._content_margin.get_theme_constant("margin_bottom") == 270)
	ui._on_banner_visibility_changed(false)
	assert(ui._content_margin.get_theme_constant("margin_bottom") == 120)
	var wire := FakeNearby.new()
	ui.room.nearby = wire
	ui.room.mode = "guest"
	ui.room.host_endpoint = "host"
	var match = MatchScript.new()
	assert(match.add_player("p1", "An"))
	assert(match.add_player("p2", "Bình"))
	assert(match.start_match())
	_apply_snapshot(ui, match.snapshot())
	assert(ui._role_label.text == "MÁY CON · NGƯỜI ĐẶT")
	assert(ui._client_controls.visible and not ui._action.visible)
	assert(not ui._cards["bau"].disabled)
	ui._select_chip(50_000)
	ui._choose("bau")
	assert(not wire.sent.is_empty())
	var message: Dictionary = JSON.parse_string(wire.sent.back()["bytes"].get_string_from_utf8())
	assert(message["type"] == "PLACE_BET")
	assert(message["payload"]["symbol"] == "bau" and message["payload"]["amount"] == 50_000)

	assert(match.place_bet("p1", "bau", 50_000))
	assert(match.confirm_bets("p1"))
	_apply_snapshot(ui, match.snapshot())
	assert(ui._cards["bau"].disabled)
	assert(ui._clear_bets_button.disabled and ui._confirm_bets_button.disabled)
	assert("Đã chốt cược" in ui._instruction.text)

	var player := match.get_player("p1")
	player["balance"] = 0
	player["spectator"] = true
	player["ready"] = false
	player["bets"] = GameConstants.empty_bets()
	_apply_snapshot(ui, match.snapshot())
	assert(ui._cards["bau"].disabled)
	assert("khán giả" in ui._instruction.text)
	assert(ui._reward_button.visible and ui._reward_button.disabled) # Desktop has no loaded ad.
	var ad_placement = root.get_node("AdPlacement")
	ad_placement._fullscreen_ad_active = true
	ui._notification(NOTIFICATION_APPLICATION_PAUSED)
	assert(ui.room.mode == "guest") # Full-screen ad pause must not close the room.
	ad_placement._fullscreen_ad_active = false
	print("Nearby client betting UI passed")
	quit(0)

func _apply_snapshot(ui: Control, snapshot: Dictionary) -> void:
	var payload := {
		"room": "123456",
		"seat": 1,
		"player_id": "p1",
		"players": ["An", "Bình"],
		"match": snapshot,
	}
	assert(ui.room._accept_state(payload))
	ui._refresh()
