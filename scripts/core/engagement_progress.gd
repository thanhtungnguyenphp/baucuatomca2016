extends Node

signal progress_changed

const SECTION := "journey"
const DAILY_ROUNDS := 3
const THEMES := ["xuan", "dem", "vang"]

var day_key := ""
var week_key := ""
var daily_rounds := 0
var daily_favorite_used := false
var completed_days: Array[String] = []
var discovery_counts: Dictionary = {}
var theme_id := "xuan"
var save_path := "user://journey.cfg"

func _ready() -> void:
	_load_progress()
	_roll_day_if_needed()
	GameSession.round_resolved.connect(record_round)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED:
		refresh_calendar()

func get_daily_favorite() -> String:
	var day_number := int(Time.get_unix_time_from_datetime_string(day_key + "T00:00:00") / 86400.0)
	return GameConstants.SYMBOLS[day_number % GameConstants.SYMBOLS.size()]

func is_daily_complete() -> bool:
	return completed_days.has(day_key)

func refresh_calendar() -> void:
	_roll_day_if_needed()

func weekly_stamps() -> int:
	return completed_days.size()

func discovery_count(symbol: String) -> int:
	return int(discovery_counts.get(symbol, 0))

func discovered_total() -> int:
	var total := 0
	for symbol in GameConstants.SYMBOLS:
		if discovery_count(symbol) > 0:
			total += 1
	return total

func can_use_theme(value: String) -> bool:
	match value:
		"xuan": return true
		"dem": return discovered_total() >= 3
		"vang": return discovered_total() >= 6
	return false

func set_theme(value: String) -> void:
	if not THEMES.has(value) or not can_use_theme(value) or theme_id == value:
		return
	theme_id = value
	_save_progress()
	progress_changed.emit()

func record_round(summary: Dictionary) -> void:
	_roll_day_if_needed()
	daily_rounds = mini(DAILY_ROUNDS, daily_rounds + 1)
	if summary.get("bet_symbols", []).has(get_daily_favorite()):
		daily_favorite_used = true
	for symbol in summary.get("results", []):
		if GameConstants.SYMBOLS.has(symbol):
			discovery_counts[symbol] = discovery_count(symbol) + 1
	if daily_rounds >= DAILY_ROUNDS and daily_favorite_used and not completed_days.has(day_key):
		completed_days.append(day_key)
	_save_progress()
	progress_changed.emit()

func reset() -> void:
	daily_rounds = 0
	daily_favorite_used = false
	completed_days.clear()
	discovery_counts.clear()
	theme_id = "xuan"
	day_key = Time.get_date_string_from_system()
	week_key = _week_start(day_key)
	_save_progress()
	progress_changed.emit()

func _roll_day_if_needed() -> void:
	var today := Time.get_date_string_from_system()
	var current_week := _week_start(today)
	if today == day_key and current_week == week_key:
		return
	if today != day_key:
		daily_rounds = 0
		daily_favorite_used = false
	if current_week != week_key:
		completed_days.clear()
	day_key = today
	week_key = current_week
	_save_progress()
	progress_changed.emit()

func _week_start(date_text: String) -> String:
	var midnight := Time.get_unix_time_from_datetime_string(date_text + "T00:00:00")
	var weekday := int(Time.get_datetime_dict_from_unix_time(midnight)["weekday"])
	return Time.get_date_string_from_unix_time(midnight - ((weekday + 6) % 7) * 86400)

func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		for entry in GameSession.history:
			for symbol in entry.get("summary", {}).get("results", []):
				if GameConstants.SYMBOLS.has(symbol):
					discovery_counts[symbol] = discovery_count(symbol) + 1
		return
	day_key = str(config.get_value(SECTION, "day_key", ""))
	week_key = str(config.get_value(SECTION, "week_key", ""))
	daily_rounds = clampi(int(config.get_value(SECTION, "daily_rounds", 0)), 0, DAILY_ROUNDS)
	daily_favorite_used = bool(config.get_value(SECTION, "daily_favorite_used", false))
	for value in config.get_value(SECTION, "completed_days", []):
		if value is String and not completed_days.has(value):
			completed_days.append(value)
	var saved_counts: Variant = config.get_value(SECTION, "discovery_counts", {})
	if saved_counts is Dictionary:
		for symbol in GameConstants.SYMBOLS:
			discovery_counts[symbol] = maxi(0, int(saved_counts.get(symbol, 0)))
	var saved_theme := str(config.get_value(SECTION, "theme_id", "xuan"))
	theme_id = saved_theme if THEMES.has(saved_theme) and can_use_theme(saved_theme) else "xuan"

func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value(SECTION, "day_key", day_key)
	config.set_value(SECTION, "week_key", week_key)
	config.set_value(SECTION, "daily_rounds", daily_rounds)
	config.set_value(SECTION, "daily_favorite_used", daily_favorite_used)
	config.set_value(SECTION, "completed_days", completed_days)
	config.set_value(SECTION, "discovery_counts", discovery_counts)
	config.set_value(SECTION, "theme_id", theme_id)
	var error := config.save(save_path)
	if error != OK:
		push_warning("Không thể lưu Hành trình: %s" % error)
