class_name MascotCard
extends Button

const SYMBOL_SHEET := preload("res://assets/art/bau-cua-symbol-sheet.png")
const SYMBOL_CELLS := {
	"bau": Vector2i(0, 0),
	"cua": Vector2i(1, 0),
	"tom": Vector2i(2, 0),
	"ca": Vector2i(0, 1),
	"ga": Vector2i(1, 1),
	"nai": Vector2i(2, 1),
}

@onready var art: TextureRect = %Art
@onready var title: Label = %Title
@onready var stake: Label = %Stake

var symbol_id := ""
var bet_amount := 0
var caption_override := ""
var highlighted := false
var _symbol_atlas: AtlasTexture

func configure(symbol: String) -> void:
	symbol_id = symbol
	if is_node_ready():
		_refresh()

func set_bet(amount: int) -> void:
	bet_amount = amount
	if is_node_ready():
		_refresh()

func set_party_state(caption: String, selected: bool) -> void:
	caption_override = caption
	highlighted = selected
	if is_node_ready():
		_refresh()

func _ready() -> void:
	_apply_card_style()
	resized.connect(_layout_art)
	call_deferred("_layout_art")
	_refresh()

func _refresh() -> void:
	if symbol_id.is_empty():
		return
	_refresh_art()
	title.text = GameConstants.SYMBOL_LABELS[symbol_id].to_upper()
	stake.text = caption_override if not caption_override.is_empty() else (GameConstants.format_luck(bet_amount) if bet_amount > 0 else "CHỌN LỘC")
	modulate = Color(0.85, 1.0, 0.88, 1.0) if bet_amount > 0 or highlighted else Color.WHITE

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

func _layout_art() -> void:
	# The source sprites have generous transparent padding. Give their visual
	# subject more of the card, while preserving the label band at the bottom.
	art.offset_left = 2.0
	art.offset_top = 2.0
	art.offset_right = -2.0
	art.offset_bottom = -66.0

func _apply_card_style() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("4a111a")
	normal.border_color = Color("b67a2c")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(18)
	normal.content_margin_left = 8.0
	normal.content_margin_right = 8.0

	var hover := normal.duplicate()
	hover.bg_color = Color("691827")
	hover.border_color = Color("ffd75a")

	var pressed := normal.duplicate()
	pressed.bg_color = Color("7c2421")
	pressed.border_color = Color("fff0a6")

	var disabled := normal.duplicate()
	disabled.bg_color = Color("2b1117")
	disabled.border_color = Color("704b33")

	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", pressed)
	add_theme_stylebox_override("disabled", disabled)
