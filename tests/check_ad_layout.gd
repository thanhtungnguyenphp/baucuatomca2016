extends SceneTree

const VIEWPORTS := [Vector2i(720, 1650), Vector2i(1080, 2400)]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for viewport_size in VIEWPORTS:
		root.size = viewport_size
		var main := (load("res://scenes/Main.tscn") as PackedScene).instantiate()
		root.add_child(main)
		await process_frame
		main._position_bottom_actions(false)
		var margin := main.get_node("Margin") as Control
		var surface := main.gameplay_surface as PanelContainer
		var without_banner_bottom := margin.offset_bottom
		main._position_bottom_actions(true)
		assert(margin.offset_bottom < without_banner_bottom)
		assert(margin.offset_bottom <= -190.0)
		assert(surface.offset_bottom <= -182.0)
		var geometry: Rect2i = main._bottom_sheet_geometry(Vector2i(960, 980), 36, true)
		var logical_height := int(main.get_viewport().get_visible_rect().size.y)
		assert(geometry.end.y <= logical_height - 226)
		main.queue_free()
		await process_frame

		var nearby_mode := (load("res://scenes/NearbyPartyMode.tscn") as PackedScene).instantiate()
		root.add_child(nearby_mode)
		await process_frame
		nearby_mode._on_banner_visibility_changed(true)
		assert(nearby_mode._content_margin.get_theme_constant("margin_bottom") == 270)
		nearby_mode._on_banner_visibility_changed(false)
		assert(nearby_mode._content_margin.get_theme_constant("margin_bottom") == 120)
		nearby_mode.queue_free()
		await process_frame
	print("Adaptive banner layout passed at 720x1650 and 1080x2400")
	quit(0)
