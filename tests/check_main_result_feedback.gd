extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1080, 1920)
	root.get_node("GameSettings").onboarding_seen = true
	var ui = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	root.add_child(ui)
	await process_frame
	await process_frame
	var summary := {
		"results": ["bau", "bau", "ca"],
		"payout": 30_000,
		"net": 20_000,
	}
	ui._on_round_resolved(summary)
	await process_frame
	assert(ui.result_overlay.visible)
	assert("BẦU" in ui.result_overlay_label.text)
	assert("CÁ" in ui.result_overlay_label.text)
	assert("CHẠM TÔ ĐỂ ĐẬY LẠI" in ui.results_label.text.to_upper())
	assert((ui.mascot_buttons["bau"] as MascotCard).result_state == MascotCard.RESULT_HIT)
	assert((ui.mascot_buttons["ca"] as MascotCard).result_state == MascotCard.RESULT_HIT)
	assert((ui.mascot_buttons["cua"] as MascotCard).result_state == MascotCard.RESULT_MISS)
	ui._hide_round_result_feedback()
	assert(not ui.result_overlay.visible)
	for card: MascotCard in ui.mascot_buttons.values():
		assert(card.result_state == MascotCard.RESULT_NONE)
	ui.queue_free()
	await process_frame
	print("Main three-second result feedback state passed")
	quit(0)
