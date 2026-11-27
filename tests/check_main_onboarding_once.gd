extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var settings = root.get_node("GameSettings")
	var original_seen: bool = settings.onboarding_seen
	settings.onboarding_seen = false
	var ui = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	root.add_child(ui)
	await process_frame
	await process_frame
	assert(ui.onboarding_popup.visible)
	ui.onboarding_popup.hide()
	await process_frame
	assert(settings.onboarding_seen)
	assert(root.get_node("AdPlacement").is_banner_allowed())
	ui.queue_free()
	await process_frame

	var second_ui = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	root.add_child(second_ui)
	await process_frame
	await process_frame
	assert(not second_ui.onboarding_popup.visible)
	second_ui.queue_free()
	settings.onboarding_seen = original_seen
	settings._save_settings()
	print("Onboarding closes permanently after the first dismissal")
	quit(0)
