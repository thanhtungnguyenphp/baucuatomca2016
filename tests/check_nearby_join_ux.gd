extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1080, 1920)
	var ui = (load("res://scenes/NearbyPartyMode.tscn") as PackedScene).instantiate()
	root.add_child(ui)
	await process_frame
	assert(ui._setup_panel.visible)
	assert(not ui._waiting_panel.visible)
	ui.room.mode = "guest"
	ui.room.local_name = "An"
	ui.room.rooms["host-a"] = "Bàn của Bình"
	ui._refresh()
	await process_frame
	assert(not ui._setup_panel.visible)
	assert(ui._rooms_caption.visible and ui._rooms_box.visible)
	assert(not ui._waiting_panel.visible)
	assert(ui._join_buttons.size() == 1)
	var join: Button = ui._join_buttons[0]
	assert(join.text == "THAM GIA")
	assert(join.custom_minimum_size.y >= 104 and join.custom_minimum_size.x >= 240)
	ui._join_room("host-a", join)
	assert(join.disabled and "ĐANG KẾT NỐI" in join.text)
	assert("so mã" in ui._status.text)
	print("Nearby join and verification touch UX passed")
	quit(0)
