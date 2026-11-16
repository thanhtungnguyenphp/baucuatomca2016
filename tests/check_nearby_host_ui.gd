extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/NearbyPartyMode.tscn") as PackedScene
	var ui = scene.instantiate()
	root.add_child(ui)
	await process_frame
	ui.room.mode = "host"
	ui.room.room_id = "123456"
	assert(ui.room._match.add_player("p1", "An"))
	ui.room._sync_public_state()
	ui._refresh()
	var start := ui._lobby.get_node("StartButton") as Button
	assert(ui._role_label.text == "CHỦ PHÒNG · NGƯỜI LẮC")
	assert(ui.room.players == ["An"])
	assert(not start.disabled)
	assert(ui.room.start_match())
	ui._refresh()
	for card: MascotCard in ui._cards.values():
		assert(card.disabled)
	assert(ui._action.disabled)
	assert(ui.room._match.place_bet("p1", "bau", 10_000))
	assert(ui.room._match.confirm_bets("p1"))
	ui.room._publish_state()
	ui._refresh()
	assert(ui.room.state["phase"] == "locked")
	assert(ui._action.text == "LẮC TÔ" and not ui._action.disabled)
	assert("An" in ui._cards["bau"].stake.text)
	print("Nearby dealer host UI passed")
	quit(0)
