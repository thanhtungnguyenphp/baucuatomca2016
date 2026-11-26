extends SceneTree

const VIEWPORTS := [Vector2i(720, 1650), Vector2i(1080, 1920), Vector2i(1080, 2400)]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for viewport_size in VIEWPORTS:
		root.size = viewport_size
		var ui = (load("res://scenes/NearbyPartyMode.tscn") as PackedScene).instantiate()
		root.add_child(ui)
		await process_frame
		await process_frame
		ui.room.mode = "host"
		ui.room.room_id = "123456"
		ui.room.local_name = "Chủ bàn"
		assert(ui.room._match.add_player("p1", "An"))
		assert(ui.room._match.add_player("p2", "Bình"))
		assert(ui.room._match.add_player("p3", "Chi"))
		assert(ui.room._match.add_player("p4", "Dũng"))
		assert(ui.room._match.add_player("p5", "Giang"))
		ui.room._sync_public_state()
		ui._refresh()
		await process_frame
		assert(not ui._setup_panel.visible)
		assert(ui._waiting_panel.visible)
		var logical_size: Vector2 = ui.get_viewport().get_visible_rect().size
		var lobby_rect: Rect2 = ui._lobby.get_global_rect()
		var start_rect: Rect2 = ui._start_button.get_global_rect()
		assert(ui._lobby_slots.size() == 5)
		assert(ui._start_button.text == "ĐỦ PHÒNG · BẮT ĐẦU 5 LƯỢT")
		print(viewport_size, " logical=", logical_size, " lobby=", lobby_rect, " start=", start_rect)
		if lobby_rect.end.y > logical_size.y - 100:
			printerr("Nearby lobby exceeds the safe bottom at ", viewport_size)
			quit(1)
		if start_rect.size.y < 80 or start_rect.end.x > logical_size.x - 20:
			printerr("Nearby start action is not safely tappable at ", viewport_size)
			quit(1)
		ui.queue_free()
		await process_frame
	print("Nearby lobby layout passed on phone and tablet viewports")
	quit(0)
