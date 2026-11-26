class_name MascotCard
extends Button

const SYMBOL_SHEET := preload("res://assets/art/bau-cua-symbol-sheet.png")
const MOTION_SHEETS := {
	"bau": preload("res://assets/art/bau-cua-gourd-breeze-sheet.png"),
	"cua": preload("res://assets/art/bau-cua-crab-scuttle-pinch-sheet.png"),
	"tom": preload("res://assets/art/bau-cua-shrimp-swim-nibble-sheet.png"),
	"ca": preload("res://assets/art/bau-cua-fish-circle-swim-sheet.png"),
	"ga": preload("res://assets/art/bau-cua-rooster-walk-sheet.png"),
	"nai": preload("res://assets/art/bau-cua-deer-walk-graze-sheet.png"),
}
const REACTION_SHEETS := {
	"bau": preload("res://assets/art/reactions/gourd-result-atlas.png"),
	"cua": preload("res://assets/art/reactions/crab-result-atlas.png"),
	"tom": preload("res://assets/art/reactions/shrimp-result-atlas.png"),
	"ca": preload("res://assets/art/reactions/fish-result-atlas.png"),
	"ga": preload("res://assets/art/reactions/rooster-result-atlas.png"),
	"nai": preload("res://assets/art/reactions/deer-result-atlas.png"),
}
const SYMBOL_CELLS := {
	"bau": Vector2i(0, 0),
	"cua": Vector2i(1, 0),
	"tom": Vector2i(2, 0),
	"ca": Vector2i(0, 1),
	"ga": Vector2i(1, 1),
	"nai": Vector2i(2, 1),
}
const RESULT_NONE := "none"
const RESULT_HIT := "hit"
const RESULT_MISS := "miss"

@onready var art: TextureRect = %Art
@onready var title: Label = %Title
@onready var stake: Label = %Stake

var symbol_id := ""
var bet_amount := 0
var caption_override := ""
var highlighted := false
var result_state := RESULT_NONE
var _symbol_atlas: AtlasTexture
var _result_atlas: AtlasTexture
var _frame_tween: Tween
var _motion_tween: Tween

func configure(symbol: String) -> void:
	symbol_id = symbol
	if is_node_ready():
		reset_result_state()
		_refresh()

func set_bet(amount: int) -> void:
	var increased := amount > bet_amount
	bet_amount = amount
	if is_node_ready():
		_refresh()
		if increased:
			_play_selection_feedback()

func set_party_state(caption: String, selected: bool) -> void:
	caption_override = caption
	highlighted = selected
	if is_node_ready():
		_refresh()

func play_result(hit: bool, occurrences: int, emphasized: bool) -> void:
	if symbol_id.is_empty() or not is_node_ready():
		return
	_stop_result_tweens()
	scale = Vector2.ONE
	result_state = RESULT_HIT if hit else RESULT_MISS
	_apply_card_style()
	art.pivot_offset = art.size * 0.5
	art.scale = Vector2.ONE
	art.rotation = 0.0
	art.modulate = Color.WHITE if hit else Color(0.62, 0.66, 0.70, 0.92) if emphasized else Color(0.72, 0.74, 0.76, 0.82)

	# Existing motion frames build anticipation; the new pose sheet lands the
	# expressive hit/miss beat. Only result ids travel over Nearby.
	_frame_tween = create_tween()
	for frame in 4:
		_frame_tween.tween_callback(_set_sheet_frame.bind(MOTION_SHEETS[symbol_id], 4, frame))
		_frame_tween.tween_interval(_animation_duration(0.055))
	var reaction_frames := ([1, 3] if symbol_id == "ga" else [1, 3, 4]) if hit else [0, 1, 2]
	for frame in reaction_frames:
		_frame_tween.tween_callback(_set_sheet_frame.bind(REACTION_SHEETS[symbol_id], 6, frame))
		_frame_tween.tween_interval(_animation_duration(0.11))

	_motion_tween = create_tween()
	if hit:
		var strength := 1.16 + minf(0.08, maxf(0.0, float(occurrences - 1)) * 0.04)
		_motion_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_motion_tween.tween_property(art, "scale", Vector2(strength, strength), _animation_duration(0.24))
		_motion_tween.tween_property(art, "scale", Vector2.ONE, _animation_duration(0.22))
	else:
		_motion_tween.set_trans(Tween.TRANS_SINE)
		_motion_tween.tween_property(art, "rotation", -0.055, _animation_duration(0.10))
		_motion_tween.tween_property(art, "rotation", 0.045, _animation_duration(0.10))
		_motion_tween.tween_property(art, "rotation", 0.0, _animation_duration(0.13))

func reset_result_state() -> void:
	_stop_result_tweens()
	scale = Vector2.ONE
	result_state = RESULT_NONE
	if not is_node_ready():
		return
	art.scale = Vector2.ONE
	art.rotation = 0.0
	art.modulate = Color.WHITE
	_refresh_art()
	_apply_card_style()

func _ready() -> void:
	resized.connect(_layout_art)
	call_deferred("_layout_art")
	_refresh()

func _refresh() -> void:
	if symbol_id.is_empty():
		return
	if result_state == RESULT_NONE:
		_refresh_art()
	title.text = GameConstants.SYMBOL_LABELS[symbol_id].to_upper()
	stake.text = caption_override if not caption_override.is_empty() else (GameConstants.format_luck(bet_amount) if bet_amount > 0 else "")
	stake.add_theme_font_size_override("font_size", 16 if stake.text.length() > 34 else 18 if stake.text.length() > 24 else 20)
	if result_state == RESULT_NONE:
		art.modulate = Color(0.88, 1.0, 0.90, 1.0) if bet_amount > 0 or highlighted else Color.WHITE
	_apply_card_style()

func _refresh_art() -> void:
	if _symbol_atlas == null:
		var cell: Vector2i = SYMBOL_CELLS[symbol_id]
		var cell_width := float(SYMBOL_SHEET.get_width()) / 3.0
		var cell_height := float(SYMBOL_SHEET.get_height()) / 2.0
		_symbol_atlas = AtlasTexture.new()
		_symbol_atlas.atlas = SYMBOL_SHEET
		_symbol_atlas.filter_clip = true
		_symbol_atlas.region = Rect2(cell.x * cell_width, cell.y * cell_height, cell_width, cell_height)
	art.texture = _symbol_atlas

func _set_sheet_frame(sheet: Texture2D, frame_count: int, frame: int) -> void:
	if not is_instance_valid(art) or sheet == null:
		return
	var cell_width := float(sheet.get_width()) / frame_count
	var region_width := cell_width
	var region_x := cell_width * clampi(frame, 0, frame_count - 1)
	if _result_atlas == null:
		_result_atlas = AtlasTexture.new()
	_result_atlas.atlas = sheet
	_result_atlas.filter_clip = true
	_result_atlas.region = Rect2(region_x, 0.0, region_width, float(sheet.get_height()))
	art.texture = _result_atlas

func _stop_result_tweens() -> void:
	if _frame_tween != null and _frame_tween.is_valid():
		_frame_tween.kill()
	if _motion_tween != null and _motion_tween.is_valid():
		_motion_tween.kill()

func _animation_duration(seconds: float) -> float:
	var settings := get_node_or_null("/root/GameSettings")
	return settings.animation_duration(seconds) if settings != null else seconds

func _play_selection_feedback() -> void:
	if _motion_tween != null and _motion_tween.is_valid():
		_motion_tween.kill()
	pivot_offset = size * 0.5
	scale = Vector2(0.96, 0.96)
	_motion_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "scale", Vector2(1.045, 1.045), _animation_duration(0.13))
	_motion_tween.tween_property(self, "scale", Vector2.ONE, _animation_duration(0.15))

func _layout_art() -> void:
	art.offset_left = 2.0
	art.offset_top = 2.0
	art.offset_right = -2.0
	art.offset_bottom = -66.0
	art.pivot_offset = art.size * 0.5

func _apply_card_style() -> void:
	var normal := StyleBoxFlat.new()
	if result_state == RESULT_HIT:
		normal.bg_color = Color("5f3211")
		normal.border_color = Color("ffe36b")
		normal.shadow_color = Color(1.0, 0.72, 0.18, 0.42)
		normal.shadow_size = 12
	elif result_state == RESULT_MISS:
		normal.bg_color = Color("28151b")
		normal.border_color = Color("875a61")
	elif bet_amount > 0 or highlighted:
		normal.bg_color = Color("68161a")
		normal.border_color = Color("ffe15a")
		normal.shadow_color = Color(1.0, 0.58, 0.08, 0.55)
		normal.shadow_size = 14
	else:
		normal.bg_color = Color("4a111a")
		normal.border_color = Color("b67a2c")
	normal.set_border_width_all(4 if result_state == RESULT_HIT or bet_amount > 0 or highlighted else 2)
	normal.set_corner_radius_all(18)
	normal.content_margin_left = 8.0
	normal.content_margin_right = 8.0

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("691827") if result_state == RESULT_NONE else normal.bg_color
	hover.border_color = Color("ffd75a") if result_state == RESULT_NONE else normal.border_color
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("7c2421") if result_state == RESULT_NONE else normal.bg_color
	pressed.border_color = Color("fff0a6") if result_state == RESULT_NONE else normal.border_color
	var disabled := normal.duplicate() as StyleBoxFlat
	if result_state == RESULT_NONE:
		disabled.bg_color = Color("2b1117")
		disabled.border_color = Color("704b33")

	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", pressed)
	add_theme_stylebox_override("disabled", disabled)
