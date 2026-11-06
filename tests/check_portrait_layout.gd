extends SceneTree

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	root.size = Vector2i(1080, 1920)
	var scene: Control = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var chips := scene.get_node("Margin/Content/ChipGrid") as GridContainer
	var status := scene.get_node("Margin/Content/StatusLabel") as Label
	var actions := scene.get_node("SafeHeader/Actions") as HBoxContainer
	var cards := scene.get_node("Margin/Content/MascotGrid") as GridContainer
	print("chips=", chips.get_global_rect(), " cards=", cards.get_global_rect())
	print("status=", status.get_global_rect(), " actions=", actions.get_global_rect())
	var chip_width := (chips.get_child(0) as Button).size.x
	if status.get_global_rect().end.y > actions.get_global_rect().position.y:
		printerr("Status overlaps bottom navigation")
		quit(1)
	if chip_width < chips.size.x / 4.0:
		printerr("Chip grid does not fill available width")
		quit(1)
	quit()
