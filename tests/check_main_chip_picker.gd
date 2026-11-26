extends SceneTree

const VIEWPORTS := [Vector2i(720, 1650), Vector2i(1080, 1920), Vector2i(1080, 2400)]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for viewport_size in VIEWPORTS:
		root.size = viewport_size
		var ui = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
		root.add_child(ui)
		await process_frame
		await process_frame
		assert(ui.chip_grid.get_child_count() == 1)
		assert(ui.chip_selector_button.visible)
		assert(ui.chip_selector_button.custom_minimum_size.y >= 104)
		ui._on_banner_visibility_changed(true)
		ui._open_chip_picker()
		await process_frame
		assert(ui.chip_picker_overlay.visible)
		assert(ui.chip_buttons.size() == GameConstants.CHIP_VALUES.size())
		for button: Button in ui.chip_buttons.values():
			assert(button.custom_minimum_size.y >= 112)
		var logical_height: float = ui.get_viewport().get_visible_rect().size.y
		var sheet_rect: Rect2 = ui.chip_picker_sheet.get_global_rect()
		if sheet_rect.position.y < 20 or sheet_rect.end.y > logical_height - 190:
			printerr("Main chip picker is outside the banner safe area at ", viewport_size, ": ", sheet_rect)
			quit(1)
		ui._select_chip(50_000)
		await process_frame
		assert(root.get_node("GameSession").selected_chip == 50_000)
		assert(not ui.chip_picker_overlay.visible)
		assert("50K" in ui.chip_selector_button.text)
		ui.queue_free()
		await process_frame
	print("Main chip selector and picker layout passed")
	quit(0)
