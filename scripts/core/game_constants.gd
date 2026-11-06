class_name GameConstants
extends RefCounted

const INITIAL_BALANCE := 1_000_000
const SYMBOLS := ["bau", "cua", "tom", "ca", "ga", "nai"]
const SYMBOL_LABELS := {
	"bau": "Bầu",
	"cua": "Cua",
	"tom": "Tôm",
	"ca": "Cá",
	"ga": "Gà",
	"nai": "Nai",
}
const CHIP_VALUES := [10_000, 20_000, 50_000, 100_000, 200_000, 500_000]
const COMBOS := [
	{"symbols": ["bau", "ca"], "name": "No Đủ", "bonus": 50_000},
	{"symbols": ["cua", "tom"], "name": "Biển Lộc", "bonus": 50_000},
	{"symbols": ["ga", "nai"], "name": "Phú Quý", "bonus": 50_000},
]

static func empty_bets() -> Dictionary:
	var bets := {}
	for symbol in SYMBOLS:
		bets[symbol] = 0
	return bets

static func format_luck(value: int) -> String:
	return "%s Lộc" % _group_digits(abs(value))

static func format_signed_luck(value: int) -> String:
	return ("+" if value >= 0 else "−") + format_luck(value)

static func _group_digits(value: int) -> String:
	var text := str(value)
	var chunks: Array[String] = []
	while text.length() > 3:
		chunks.push_front(text.right(3))
		text = text.left(text.length() - 3)
	chunks.push_front(text)
	return ".".join(chunks)
