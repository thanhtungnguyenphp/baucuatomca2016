class_name PartyMatch
extends RefCounted

## Pure five-turn party rules shared by local and future Nearby presentation.
const TOTAL_TURNS := 5

var player_count := 2
var turn_number := 1
var scores: Array[int] = []
var choices: Array[String] = []
var chooser := 0
var phase := "setup"
var last_results: Array[String] = []

func set_player_count(count: int) -> bool:
	if phase != "setup" and phase != "finished":
		return false
	if count < 2 or count > 4:
		return false
	player_count = count
	return true

func start() -> bool:
	if phase != "setup" and phase != "finished":
		return false
	scores.clear()
	for _index in player_count:
		scores.append(0)
	turn_number = 1
	last_results.clear()
	_reset_choices()
	phase = "choose"
	return true

func choose_next(symbol: String) -> bool:
	if phase != "choose" or chooser >= player_count:
		return false
	return set_choice(chooser, symbol)

func set_choice(player_index: int, symbol: String) -> bool:
	if phase != "choose" or player_index < 0 or player_index >= player_count:
		return false
	if not GameConstants.SYMBOLS.has(symbol) or not choices[player_index].is_empty():
		return false
	choices[player_index] = symbol
	chooser = _first_unselected_player()
	return true

func undo_last_choice() -> bool:
	if phase != "choose":
		return false
	var index := -1
	for player_index in player_count:
		if not choices[player_index].is_empty():
			index = player_index
	if index < 0:
		return false
	choices[index] = ""
	chooser = _first_unselected_player()
	return true

func all_chosen() -> bool:
	return phase == "choose" and _first_unselected_player() == player_count

func settle(results: Array[String]) -> bool:
	if phase != "choose" and phase != "rolling":
		return false
	if _first_unselected_player() != player_count or results.size() != 3:
		return false
	for symbol in results:
		if not GameConstants.SYMBOLS.has(symbol):
			return false
	for player_index in player_count:
		for symbol in results:
			if choices[player_index] == symbol:
				scores[player_index] += 1
	last_results = results.duplicate()
	phase = "revealed"
	return true

func advance() -> bool:
	if phase != "revealed":
		return false
	if turn_number >= TOTAL_TURNS:
		phase = "finished"
	else:
		turn_number += 1
		last_results.clear()
		_reset_choices()
		phase = "choose"
	return true

func snapshot() -> Dictionary:
	return {
		"player_count": player_count,
		"turn_number": turn_number,
		"scores": scores.duplicate(),
		"choices": choices.duplicate(),
		"chooser": chooser,
		"phase": phase,
		"last_results": last_results.duplicate(),
	}

func _reset_choices() -> void:
	choices.clear()
	for _index in player_count:
		choices.append("")
	chooser = 0

func _first_unselected_player() -> int:
	for index in player_count:
		if choices[index].is_empty():
			return index
	return player_count
