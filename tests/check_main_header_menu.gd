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
		assert(not ui.get_node("SafeHeader/Actions").visible)
		assert(ui.header_menu_button.visible)
		assert(ui.header_menu_button.size.x >= 96)
		assert(ui.header_menu_button.size.y >= 72)
		assert(ui.header_menu_entries.size() == 5)
		assert(ui.header_menu_entries.has("nearby"))
		for entry: Button in ui.header_menu_entries.values():
			assert(entry.custom_minimum_size.y >= 112)
		ui._open_header_menu()
		await process_frame
		assert(ui.header_menu_overlay.visible)
		var viewport_rect := ui.get_viewport().get_visible_rect()
		var panel_rect: Rect2 = ui.header_menu_panel.get_global_rect()
		if panel_rect.position.x < 20 or panel_rect.end.x > viewport_rect.size.x - 20 or panel_rect.position.y < 20 or panel_rect.end.y > viewport_rect.size.y - 20:
			printerr("Header menu is outside viewport at ", viewport_size, ": ", panel_rect)
			quit(1)
		ui._close_header_menu()
		assert(not ui.header_menu_overlay.visible)
		if viewport_size == VIEWPORTS[0]:
			ui._open_header_menu()
			assert(ui._hide_top_popup())
			assert(not ui.header_menu_overlay.visible)
			var destinations := {
				"rules": ui.rules_popup,
				"journey": ui.journey_popup,
				"history": ui.history_popup,
				"settings": ui.settings_popup,
			}
			for key: String in destinations:
				ui._open_header_menu()
				(ui.header_menu_entries[key] as Button).pressed.emit()
				await process_frame
				assert(not ui.header_menu_overlay.visible)
				assert((destinations[key] as PopupPanel).visible)
				(destinations[key] as PopupPanel).hide()
		ui.queue_free()
		await process_frame
	print("Main expandable header menu layout passed")
	quit(0)
