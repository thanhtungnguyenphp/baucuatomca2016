class_name BowlPresenter
extends Control

signal tapped

@onready var tray: TextureRect = %Tray
@onready var lid: TextureRect = %Lid
@onready var dice_row: HBoxContainer = %DiceRow
@onready var dice: Array[DiceView] = [%DiceLeft, %DiceCenter, %DiceRight]

var _tray_rest_offsets := Vector4.ZERO
var _lid_rest_offsets := Vector4.ZERO
var is_revealed := false
var is_transitioning := false

func _ready() -> void:
	_tray_rest_offsets = _get_offsets(tray)
	_lid_rest_offsets = _get_offsets(lid)
	dice_row.modulate.a = 0.0
	gui_input.connect(_on_gui_input)

func _get_offsets(item: Control) -> Vector4:
	return Vector4(item.offset_left, item.offset_top, item.offset_right, item.offset_bottom)

func _restore_offsets(item: Control, offsets: Vector4) -> void:
	item.offset_left = offsets.x
	item.offset_top = offsets.y
	item.offset_right = offsets.z
	item.offset_bottom = offsets.w

func _on_gui_input(event: InputEvent) -> void:
	var was_tapped: bool = (
		event is InputEventScreenTouch and event.pressed
		or event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	)
	if was_tapped:
		accept_event()
		tapped.emit()

func play_reveal(results: Array[String]) -> void:
	is_transitioning = true
	for index in dice.size():
		dice[index].set_face(results[index])
	_restore_offsets(tray, _tray_rest_offsets)
	_restore_offsets(lid, _lid_rest_offsets)
	var tray_start_x := tray.position.x
	var lid_start_y := lid.position.y
	lid.rotation = 0.0
	lid.modulate.a = 1.0
	lid.z_index = 1
	lid.visible = true
	dice_row.modulate.a = 0.0
	GameSettings.shake_feedback()
	AudioDirector.play(NativeAudioDirector.Cue.SHAKE)

	var shake := create_tween()
	shake.set_trans(Tween.TRANS_SINE)
	shake.tween_property(tray, "position:x", tray_start_x - 18.0, GameSettings.animation_duration(0.08))
	shake.tween_property(tray, "position:x", tray_start_x + 18.0, GameSettings.animation_duration(0.08))
	shake.tween_property(tray, "position:x", tray_start_x - 12.0, GameSettings.animation_duration(0.08))
	shake.tween_property(tray, "position:x", tray_start_x + 9.0, GameSettings.animation_duration(0.08))
	shake.tween_property(tray, "position:x", tray_start_x, GameSettings.animation_duration(0.08))
	await shake.finished
	_restore_offsets(tray, _tray_rest_offsets)
	AudioDirector.play(NativeAudioDirector.Cue.REVEAL)

	var reveal := create_tween().set_parallel(true)
	reveal.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reveal.tween_property(lid, "position:y", lid_start_y - 142.0, GameSettings.animation_duration(0.46))
	reveal.tween_property(lid, "rotation", -0.14, GameSettings.animation_duration(0.46))
	reveal.tween_property(lid, "modulate:a", 0.16, GameSettings.animation_duration(0.46))
	reveal.tween_property(dice_row, "modulate:a", 1.0, GameSettings.animation_duration(0.30)).set_delay(GameSettings.animation_duration(0.16))
	await reveal.finished
	# Keep the lid fully present at its resting rect to preserve Bowl's minimum
	# size. Put it behind the tray rather than hiding/fading it, so it cannot
	# cover the dice while the result is visible.
	_restore_offsets(lid, _lid_rest_offsets)
	lid.rotation = 0.0
	lid.modulate.a = 1.0
	lid.z_index = -1
	is_revealed = true
	is_transitioning = false

func play_cover() -> void:
	if not is_revealed or is_transitioning:
		return
	is_transitioning = true
	lid.visible = true
	_restore_offsets(lid, _lid_rest_offsets)
	var tray_start_y := tray.position.y
	lid.rotation = 0.0
	lid.z_index = 1
	lid.modulate.a = 0.0

	var cover := create_tween().set_parallel(true)
	cover.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	cover.tween_property(dice_row, "modulate:a", 0.0, GameSettings.animation_duration(0.20))
	cover.tween_property(lid, "modulate:a", 1.0, GameSettings.animation_duration(0.26))
	cover.tween_property(tray, "position:y", tray_start_y + 8.0, GameSettings.animation_duration(0.10))
	cover.chain().tween_property(tray, "position:y", tray_start_y, GameSettings.animation_duration(0.12))
	await cover.finished
	_restore_offsets(tray, _tray_rest_offsets)
	_restore_offsets(lid, _lid_rest_offsets)
	is_revealed = false
	is_transitioning = false
