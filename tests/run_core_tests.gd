extends SceneTree

func _init() -> void:
	_test_symbol_payout()
	_test_combo_bonus()
	_test_challenge_bonus()
	print("Core rule tests passed.")
	quit(0)

func _test_symbol_payout() -> void:
	var bets := GameConstants.empty_bets()
	bets["bau"] = 10_000
	var summary := RoundResolver.resolve(bets, ["bau", "bau", "ca"], 0, false)
	assert(summary["stake"] == 10_000)
	assert(summary["symbol_payout"] == 30_000)
	assert(summary["payout"] == 30_000)
	assert(summary["net"] == 20_000)

func _test_combo_bonus() -> void:
	var bets := GameConstants.empty_bets()
	bets["bau"] = 10_000
	bets["ca"] = 20_000
	var summary := RoundResolver.resolve(bets, ["bau", "ca", "tom"], 0, false)
	assert(summary["symbol_payout"] == 60_000)
	assert(summary["combo"]["name"] == "No Đủ")
	assert(summary["combo_bonus"] == 50_000)
	assert(summary["payout"] == 110_000)

func _test_challenge_bonus() -> void:
	var bets := GameConstants.empty_bets()
	bets["nai"] = 10_000
	var summary := RoundResolver.resolve(bets, ["bau", "cua", "tom"], 2, false)
	assert(summary["symbol_payout"] == 0)
	assert(summary["mission_bonus"] == 200_000)
	assert(summary["challenge_completed"])
	assert(summary["net"] == 190_000)
