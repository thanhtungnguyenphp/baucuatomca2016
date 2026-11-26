extends SceneTree

const MatchScript := preload("res://scripts/core/dealer_party_match.gd")
const VIEWPORTS := [Vector2i(720, 1650), Vector2i(1080, 1920), Vector2i(1080, 2400)]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for viewport_size in VIEWPORTS:
		root.size = viewport_size
		var ui = (load("res://scenes/NearbyPartyMode.tscn") as PackedScene).instantiate()
		root.add_child(ui)
		await process_frame
		ui.room.mode = "guest"
		ui.room.host_endpoint = "host"
		var match = MatchScript.new()
		for index in 5:
			assert(match.add_player("p%d" % (index + 1), "Người %d" % (index + 1)))
		assert(match.start_match())
		var names: Array[String] = []
		for player: Dictionary in match.players:
			names.append(player["name"])
		var network_snapshot := match.snapshot()
		network_snapshot["betting_seconds_left"] = 30
		assert(ui.room._accept_state({
			"room": "123456",
			"host_name": "Chủ bàn",
			"seat": 1,
			"player_id": "p1",
			"players": names,
			"match": network_snapshot,
		}))
		ui._on_banner_visibility_changed(true)
		ui._refresh()
		await process_frame
		var logical_size: Vector2 = ui.get_viewport().get_visible_rect().size
		var panel_rect: Rect2 = ui._client_panel.get_global_rect()
		assert(ui._chip_selector_button.size.y >= 96)
		assert(ui._clear_bets_button.size.y >= 112)
		assert(ui._confirm_bets_button.size.y >= 112)
		if panel_rect.end.y > logical_size.y - 260:
			printerr("Bet controls overlap the native banner safe area at ", viewport_size, ": ", panel_rect)
			quit(1)
		ui._open_chip_picker()
		await process_frame
		var sheet_rect: Rect2 = ui._chip_picker_sheet.get_global_rect()
		if sheet_rect.position.y < 20 or sheet_rect.end.y > logical_size.y - 260:
			printerr("Chip picker is outside the safe area at ", viewport_size, ": ", sheet_rect)
			quit(1)
		ui.queue_free()
		await process_frame
	print("Nearby betting controls and chip picker layout passed")
	quit(0)
