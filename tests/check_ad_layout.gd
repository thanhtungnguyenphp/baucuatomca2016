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
		var actions := main.get_node("SafeHeader/Actions") as HBoxContainer
		var without_banner_top := actions.offset_top
		main._position_bottom_actions(true)
		assert(actions.offset_top < without_banner_top)
		assert(actions.offset_bottom <= -300.0)
		main.queue_free()
		await process_frame

		var nearby := (load("res://scenes/NearbyPartyMode.tscn") as PackedScene).instantiate()
		root.add_child(nearby)
		await process_frame
		nearby._on_banner_visibility_changed(true)
		assert(nearby._content_margin.get_theme_constant("margin_bottom") == 270)
		nearby._on_banner_visibility_changed(false)
		assert(nearby._content_margin.get_theme_constant("margin_bottom") == 120)
		nearby.queue_free()
		await process_frame
	print("Adaptive banner layout passed at 720x1650 and 1080x2400")
	quit(0)
