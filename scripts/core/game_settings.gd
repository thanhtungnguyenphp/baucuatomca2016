class_name MobileGameSettings
extends Node

signal settings_changed

const SAVE_PATH := "user://settings.cfg"
const SECTION := "accessibility"

var haptics_enabled := true
var reduce_motion := false
var sound_enabled := true
var onboarding_seen := false

func _ready() -> void:
	_load_settings()

func set_haptics_enabled(enabled: bool) -> void:
	if haptics_enabled == enabled:
		return
	haptics_enabled = enabled
	_save_settings()
	settings_changed.emit()

func set_reduce_motion(enabled: bool) -> void:
	if reduce_motion == enabled:
		return
	reduce_motion = enabled
	_save_settings()
	settings_changed.emit()

func set_sound_enabled(enabled: bool) -> void:
	if sound_enabled == enabled:
		return
	sound_enabled = enabled
	_save_settings()
	settings_changed.emit()

func mark_onboarding_seen() -> void:
	if onboarding_seen:
		return
	onboarding_seen = true
	_save_settings()

func animation_duration(seconds: float) -> float:
	return 0.01 if reduce_motion else seconds

func tap_feedback() -> void:
	_vibrate(12, 0.16)

func shake_feedback() -> void:
	_vibrate(28, 0.38)

func reward_feedback() -> void:
	_vibrate(55, 0.60)

func _vibrate(duration_ms: int, amplitude: float) -> void:
	if haptics_enabled:
		Input.vibrate_handheld(duration_ms, amplitude)

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	haptics_enabled = bool(config.get_value(SECTION, "haptics_enabled", true))
	reduce_motion = bool(config.get_value(SECTION, "reduce_motion", false))
	sound_enabled = bool(config.get_value(SECTION, "sound_enabled", true))
	onboarding_seen = bool(config.get_value(SECTION, "onboarding_seen", false))

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(SECTION, "haptics_enabled", haptics_enabled)
	config.set_value(SECTION, "reduce_motion", reduce_motion)
	config.set_value(SECTION, "sound_enabled", sound_enabled)
	config.set_value(SECTION, "onboarding_seen", onboarding_seen)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Không thể lưu thiết lập cục bộ: %s" % error)
