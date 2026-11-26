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
	var nearby := scene.get_node("SafeHeader/NearbyQuickButton") as Button
	var menu := scene.get_node("SafeHeader/HeaderMenuButton") as Button
	var cards := scene.get_node("Margin/Content/MascotGrid") as GridContainer
	var summary := scene.session_summary_panel as PanelContainer
	print("chips=", chips.get_global_rect(), " cards=", cards.get_global_rect())
	print("status=", status.get_global_rect(), " actions=", actions.get_global_rect())
	var chip_width := (chips.get_child(0) as Button).size.x
	if actions.visible:
		printerr("Secondary bottom navigation should be hidden")
		quit(1)
	scene._on_banner_visibility_changed(true)
	if status.visible or summary.get_global_rect().end.y > nearby.get_global_rect().position.y:
		printerr("Summary overlaps featured Nearby CTA")
		quit(1)
	if menu.size.x < 96 or menu.size.y < 72:
		printerr("Header menu touch target is too small")
		quit(1)
	if not "CHƠI CÙNG BẠN Ở GẦN" in nearby.text or nearby.custom_minimum_size.y < 110:
		printerr("Nearby feature is not discoverable from the main screen")
		quit(1)
	if chips.get_child_count() != 1 or chip_width < chips.size.x * 0.9:
		printerr("Chip grid does not fill available width")
		quit(1)
	quit()
