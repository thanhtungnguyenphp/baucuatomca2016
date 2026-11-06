class_name DiceView
extends TextureRect

const DICE_SHEET := preload("res://assets/art/bau-cua-3d-mascot-dice-sheet.png")
# Each source cell has a large transparent area below the die. Crop it out so
# the actual result face, rather than empty alpha, determines its on-screen size.
const CELL_WIDTH := 362.0
const DICE_ART_TOP := 88.0
const DICE_ART_HEIGHT := 450.0

func set_face(symbol: String) -> void:
	var index := GameConstants.SYMBOLS.find(symbol)
	var atlas := AtlasTexture.new()
	atlas.atlas = DICE_SHEET
	atlas.region = Rect2(index * CELL_WIDTH, DICE_ART_TOP, CELL_WIDTH, DICE_ART_HEIGHT)
	texture = atlas
