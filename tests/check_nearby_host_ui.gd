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
	ui.room.local_name = "Chủ bàn"
	assert(ui.room._match.add_player("p1", "An"))
	ui.room._sync_public_state()
	ui._refresh()
	var start := ui._lobby.get_node("StartButton") as Button
	assert(ui._role_label.text == "BẠN LÀ CHỦ PHÒNG")
	assert("CHỦ BÀN" in ui._host_identity.text)
	assert(ui.room.players == ["An"])
	assert(not start.disabled)
	assert(start.text == "BẮT ĐẦU VỚI 1 BẠN")
	assert(ui._lobby_slots.size() == 5)
	assert("An" in ui._lobby_slots[0].text)
	assert("ĐANG CHỜ" in ui._lobby_slots[1].text)
	ui._on_verification_needed("guest-a", "Bình", "1234")
	ui._on_verification_needed("guest-b", "Chi", "5678")
	await process_frame
	assert(ui._pending_endpoint == "guest-a")
	assert(ui._pairing_queue.size() == 1)
	assert("1   2   3   4" in ui._verify_dialog.dialog_text)
	assert(ui._verify_dialog.get_ok_button().size.y >= 104)
	assert(ui._verify_dialog.get_cancel_button().size.y >= 104)
	assert(ui._verify_dialog.get_ok_button().size.x >= 330)
	assert(ui._verify_dialog.get_cancel_button().size.x >= 330)
	ui._accept_pairing()
	await process_frame
	assert(ui._pending_endpoint == "guest-b")
	ui._reject_pairing()
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
