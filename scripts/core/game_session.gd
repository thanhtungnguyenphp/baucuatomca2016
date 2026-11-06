extends Node

signal session_changed
signal round_resolved(summary: Dictionary)

const SAVE_PATH := "user://session.cfg"
const SAVE_SECTION := "session"

var balance := GameConstants.INITIAL_BALANCE
var round := 1
var selected_chip := 10_000
var bets := GameConstants.empty_bets()
var history: Array[Dictionary] = []
var session_rounds := 0
var win_streak := 0
var challenge_completed := false
var last_combo: Dictionary = {}
var is_round_in_progress := false
var _pending_summary: Dictionary = {}

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_load_progress()

func total_bet() -> int:
	var total := 0
	for amount in bets.values():
		total += amount
	return total

func select_chip(value: int) -> void:
	if is_round_in_progress:
		return
	if GameConstants.CHIP_VALUES.has(value):
		selected_chip = value
		session_changed.emit()

func place_bet(symbol: String) -> bool:
	if is_round_in_progress:
		return false
	if not GameConstants.SYMBOLS.has(symbol):
		return false
	if balance - total_bet() < selected_chip:
		return false
	bets[symbol] += selected_chip
	session_changed.emit()
	return true

func clear_bets() -> void:
	if is_round_in_progress:
		return
	bets = GameConstants.empty_bets()
	session_changed.emit()

func begin_round() -> Dictionary:
	if is_round_in_progress:
		return {}
	var stake := total_bet()
	if stake == 0 or stake > balance:
		return {}

	balance -= stake
	_pending_summary = RoundResolver.resolve(
		bets,
		RoundResolver.roll_results(_rng),
		session_rounds,
		challenge_completed
	)
	var bet_symbols: Array[String] = []
	for symbol in GameConstants.SYMBOLS:
		if bets[symbol] > 0:
			bet_symbols.append(symbol)
	_pending_summary["bet_symbols"] = bet_symbols
	is_round_in_progress = true
	session_changed.emit()
	return _pending_summary

func settle_round(summary: Dictionary) -> Dictionary:
	if not is_round_in_progress or summary != _pending_summary:
		return {}

	balance += summary.payout
	session_rounds = summary.next_session_rounds
	challenge_completed = summary.challenge_completed
	last_combo = summary.combo
	win_streak = win_streak + 1 if summary.net > 0 else 0
	history.push_front({"round": round, "summary": summary})
	if history.size() > 3:
		history.pop_back()
	round += 1
	bets = GameConstants.empty_bets()
	is_round_in_progress = false
	_pending_summary = {}
	_save_progress()
	session_changed.emit()
	round_resolved.emit(summary)
	return summary

func play_round() -> Dictionary:
	var summary := begin_round()
	if summary.is_empty():
		return {}
	return settle_round(summary)

func reset() -> void:
	balance = GameConstants.INITIAL_BALANCE
	round = 1
	selected_chip = 10_000
	bets = GameConstants.empty_bets()
	history.clear()
	session_rounds = 0
	win_streak = 0
	challenge_completed = false
	last_combo = {}
	is_round_in_progress = false
	_pending_summary = {}
	_save_progress()
	session_changed.emit()

func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	balance = max(0, int(config.get_value(SAVE_SECTION, "balance", GameConstants.INITIAL_BALANCE)))
	round = max(1, int(config.get_value(SAVE_SECTION, "round", 1)))
	session_rounds = max(0, int(config.get_value(SAVE_SECTION, "session_rounds", 0)))
	win_streak = max(0, int(config.get_value(SAVE_SECTION, "win_streak", 0)))
	challenge_completed = bool(config.get_value(SAVE_SECTION, "challenge_completed", false))
	var saved_history: Variant = config.get_value(SAVE_SECTION, "history", [])
	if saved_history is Array:
		for entry in saved_history:
			if entry is Dictionary and entry.has("round") and entry.has("summary"):
				history.append(entry)
		history = history.slice(0, 3)

func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value(SAVE_SECTION, "balance", balance)
	config.set_value(SAVE_SECTION, "round", round)
	config.set_value(SAVE_SECTION, "session_rounds", session_rounds)
	config.set_value(SAVE_SECTION, "win_streak", win_streak)
	config.set_value(SAVE_SECTION, "challenge_completed", challenge_completed)
	config.set_value(SAVE_SECTION, "history", history)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Không thể lưu tiến trình cục bộ: %s" % error)
