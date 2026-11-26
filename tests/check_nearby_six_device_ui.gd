extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1080, 1920)
	var ui = (load("res://scenes/NearbyPartyMode.tscn") as PackedScene).instantiate()
	root.add_child(ui)
	await process_frame
	ui.room.mode = "host"
	ui.room.room_id = "654321"
	ui.room.local_name = "Chủ bàn"
	var names := ["An", "Bình", "Chi", "Dũng", "Giang"]
	for index in names.size():
		assert(ui.room._match.add_player("p%d" % (index + 1), names[index]))
	ui.room._sync_public_state()
	ui._refresh()
	assert(ui._start_button.text == "ĐỦ PHÒNG · BẮT ĐẦU 5 LƯỢT")
	assert(ui.room.start_match())
	for index in names.size():
		var player_id := "p%d" % (index + 1)
		assert(ui.room._match.place_bet(player_id, "bau", 10_000))
		assert(ui.room._match.confirm_bets(player_id))
	ui.room._publish_state()
	ui._refresh()
	await process_frame
	assert(ui.room.state["phase"] == "locked")
	assert(ui._scores_label.text.split("\n").size() == 5)
	assert("5 NGƯỜI" in ui._cards["bau"].stake.text)
	assert(ui._action.text == "LẮC TÔ" and not ui._action.disabled)
	var logical_height := ui.get_viewport().get_visible_rect().size.y
	assert(ui._board.get_global_rect().end.y <= logical_height - 100)
	print("Nearby six-device board UI passed")
	quit(0)
