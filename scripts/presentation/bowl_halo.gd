class_name BowlHalo
extends Control

const RAY_COUNT := 24
const SPARK_COUNT := 14

var _phase := 0.0
var _flash := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _process(delta: float) -> void:
	if not GameSettings.reduce_motion:
		_phase = fmod(_phase + delta, TAU * 40.0)
	_flash = move_toward(_flash, 0.0, delta * 0.72)
	queue_redraw()

func play_shake() -> void:
	_flash = maxf(_flash, 0.78)
	queue_redraw()

func celebrate(strong: bool = true) -> void:
	_flash = 1.0 if strong else 0.72
	queue_redraw()

func calm() -> void:
	_flash = 0.0
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var pulse := 0.0 if GameSettings.reduce_motion else (sin(_phase * 2.1) + 1.0) * 0.5
	var base_alpha := 0.22 + pulse * 0.06 + _flash * 0.16
	var rotation := 0.0 if GameSettings.reduce_motion else _phase * 0.035

	# Compress the sunburst vertically so it follows the bowl silhouette. Crisp
	# polygons and rings replace the old large shadow, which looked like a blur.
	draw_set_transform(center, rotation, Vector2(1.0, 0.58))
	for index in RAY_COUNT:
		var angle := TAU * float(index) / float(RAY_COUNT)
		var half_width := TAU / float(RAY_COUNT * 5)
		var inner_radius := 245.0
		var outer_radius := 405.0 + (34.0 if index % 2 == 0 else 0.0) + _flash * 24.0
		var points := PackedVector2Array([
			Vector2.from_angle(angle - half_width) * inner_radius,
			Vector2.from_angle(angle) * outer_radius,
			Vector2.from_angle(angle + half_width) * inner_radius,
		])
		var ray_color := Color(1.0, 0.78, 0.23, base_alpha * (1.0 if index % 2 == 0 else 0.62))
		draw_colored_polygon(points, ray_color)

	draw_arc(Vector2.ZERO, 290.0, 0.0, TAU, 96, Color(1.0, 0.91, 0.48, 0.18 + _flash * 0.28), 3.0, true)
	draw_arc(Vector2.ZERO, 350.0 + _flash * 7.0, 0.0, TAU, 96, Color(1.0, 0.63, 0.12, 0.09 + _flash * 0.25), 2.0, true)
	draw_arc(Vector2.ZERO, 420.0 + _flash * 11.0, 0.0, TAU, 96, Color(1.0, 0.95, 0.66, 0.05 + _flash * 0.22), 2.0, true)

	for index in SPARK_COUNT:
		var angle := TAU * float(index) / float(SPARK_COUNT) - rotation * 1.8
		var radius := 345.0 + float(index % 3) * 34.0
		var point := Vector2.from_angle(angle) * radius
		var spark_radius := 2.8 + float(index % 2) * 1.8 + _flash * 2.5
		draw_circle(point, spark_radius, Color(1.0, 0.94, 0.64, 0.26 + _flash * 0.44))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
