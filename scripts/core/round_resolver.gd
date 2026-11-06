class_name RoundResolver
extends RefCounted

## Pure game rules. It does not know about scenes, animation, sound, or input.

static func roll_results(rng: RandomNumberGenerator) -> Array[String]:
	var results: Array[String] = []
	for _index in 3:
		results.append(GameConstants.SYMBOLS[rng.randi_range(0, GameConstants.SYMBOLS.size() - 1)])
	return results

static func resolve(
	bets: Dictionary,
	results: Array[String],
	session_rounds: int,
	challenge_completed: bool
) -> Dictionary:
	var counts := GameConstants.empty_bets()
	for symbol in results:
		counts[symbol] += 1

	var stake := 0
	var symbol_payout := 0
	for symbol in GameConstants.SYMBOLS:
		var amount: int = bets.get(symbol, 0)
		stake += amount
		if amount > 0 and counts[symbol] > 0:
			symbol_payout += amount * (counts[symbol] + 1)

	var combo := _activated_combo(results, bets)
	var combo_bonus: int = combo.get("bonus", 0) if not combo.is_empty() else 0
	var next_session_rounds := session_rounds + 1
	var mission_bonus := 0
	if not challenge_completed and next_session_rounds >= 3:
		mission_bonus = 200_000

	var payout := symbol_payout + combo_bonus + mission_bonus
	return {
		"results": results,
		"counts": counts,
		"stake": stake,
		"symbol_payout": symbol_payout,
		"combo": combo,
		"combo_bonus": combo_bonus,
		"mission_bonus": mission_bonus,
		"payout": payout,
		"net": payout - stake,
		"next_session_rounds": next_session_rounds,
		"challenge_completed": challenge_completed or mission_bonus > 0,
	}

static func _activated_combo(results: Array[String], bets: Dictionary) -> Dictionary:
	for combo in GameConstants.COMBOS:
		var symbols: Array = combo["symbols"]
		if symbols.all(func(symbol: String) -> bool: return results.has(symbol) and bets.get(symbol, 0) > 0):
			return combo
	return {}
