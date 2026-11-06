extends SceneTree

const TEST_PATH := "user://journey-test.cfg"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_PATH)
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(absolute_path)
	var progress: Variant = load("res://scripts/core/engagement_progress.gd").new()
	progress.save_path = TEST_PATH
	root.add_child(progress)
	progress.reset()
	var favorite: String = progress.get_daily_favorite()
	var symbols := GameConstants.SYMBOLS
	for index in 3:
		progress.record_round({
			"bet_symbols": [favorite] if index == 0 else [],
			"results": [symbols[index]],
		})
	assert(progress.is_daily_complete())
	assert(progress.weekly_stamps() == 1)
	assert(progress.discovered_total() == 3)
	assert(progress.can_use_theme("dem"))
	assert(not progress.can_use_theme("vang"))
	progress.set_theme("dem")
	root.remove_child(progress)
	progress.free()
	var restored: Variant = load("res://scripts/core/engagement_progress.gd").new()
	restored.save_path = TEST_PATH
	root.add_child(restored)
	assert(restored.is_daily_complete())
	assert(restored.theme_id == "dem")
	assert(restored.discovered_total() == 3)
	root.remove_child(restored)
	restored.free()
	DirAccess.remove_absolute(absolute_path)
	print("Engagement progress tests passed.")
	quit(0)
