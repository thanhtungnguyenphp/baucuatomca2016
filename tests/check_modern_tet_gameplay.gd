extends SceneTree

const VIEWPORTS := [Vector2i(720, 1650), Vector2i(1080, 1920), Vector2i(1080, 2400)]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session = root.get_node("GameSession")
	var ads = root.get_node("AdPlacement")
	root.get_node("GameSettings").onboarding_seen = true
	for viewport_size in VIEWPORTS:
		session.reset()
		root.size = viewport_size
		var ui = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
		root.add_child(ui)
		await process_frame
		await process_frame
		assert(ui.brand_label.text == "lamgame.vn")
		assert(ui.hud_panel.visible)
		assert(ui.tap_hint_button.custom_minimum_size.y >= 56)
		assert(ui.tap_hint_button.custom_minimum_size.x < 700)
		assert(not ui.tap_hint_button.disabled)
		assert(ui.bowl_halo != null)
		assert(not ui.get_node("SafeHeader/Actions").visible)
		assert("CHẠM" in ui.results_label.text.to_upper() and "LẮC" in ui.results_label.text.to_upper())
		assert("CHƠI CÙNG BẠN Ở GẦN" in ui.nearby_quick_button.text)
		assert(ads.is_banner_allowed())
		assert(session.place_bet("bau"))
		await process_frame
		assert(not ui.tap_hint_button.disabled)
		ui._open_header_menu()
		assert(ads.is_banner_allowed())
		ui._close_header_menu()
		assert(ads.is_banner_allowed())
		ui._show_rules()
		assert(ads.is_banner_allowed())
		ui.rules_popup.hide()
		await process_frame
		assert(ads.is_banner_allowed())
		ui._on_banner_visibility_changed(true)
		var chip_rect: Rect2 = ui.chip_grid.get_global_rect()
		var nearby_rect: Rect2 = ui.nearby_quick_button.get_global_rect()
		if chip_rect.end.y > nearby_rect.position.y:
			printerr("Bet controls overlap the Nearby CTA at ", viewport_size)
			quit(1)
		ui.queue_free()
		await process_frame

	var nearby = (load("res://scenes/NearbyPartyMode.tscn") as PackedScene).instantiate()
	root.add_child(nearby)
	await process_frame
	assert(not ads.is_banner_allowed())
	nearby.queue_free()
	print("Modern Tet gameplay hierarchy and ad routing passed")
	quit(0)
