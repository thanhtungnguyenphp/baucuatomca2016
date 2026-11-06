class_name LuckyBurst
extends Control

const PIECE_COUNT := 22
const LIFE_SECONDS := 0.62

var _pieces: Array[ColorRect] = []
var _random := RandomNumberGenerator.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_random.randomize()
	for index in PIECE_COUNT:
		var piece := ColorRect.new()
		piece.custom_minimum_size = Vector2(14.0, 14.0)
		piece.size = Vector2(14.0, 14.0)
		piece.pivot_offset = Vector2(7.0, 7.0)
		piece.visible = false
		add_child(piece)
		_pieces.append(piece)

func play_at(global_center: Vector2) -> void:
	if GameSettings.reduce_motion:
		return
	var center: Vector2 = global_center - global_position
	for piece in _pieces:
		var angle := _random.randf_range(-PI, 0.0)
		var distance := _random.randf_range(90.0, 220.0)
		var destination: Vector2 = center + Vector2(cos(angle), sin(angle)) * distance
		destination.y += _random.randf_range(40.0, 160.0)
		piece.position = center - piece.size * 0.5
		piece.rotation = _random.randf_range(-PI, PI)
		piece.modulate = Color(1.0, 1.0, 1.0, 1.0)
		piece.color = _pick_color()
		piece.visible = true

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(piece, "position", destination - piece.size * 0.5, LIFE_SECONDS)
		tween.tween_property(piece, "rotation", piece.rotation + _random.randf_range(-8.0, 8.0), LIFE_SECONDS)
		tween.tween_property(piece, "modulate:a", 0.0, LIFE_SECONDS).set_delay(0.18)
		tween.chain().tween_callback(piece.hide)

func _pick_color() -> Color:
	var colors := [
		Color("ffd75a"),
		Color("fff4ba"),
		Color("f6a642"),
		Color("e85e51"),
	]
	return colors[_random.randi_range(0, colors.size() - 1)]
