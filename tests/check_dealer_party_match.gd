extends SceneTree

const DealerPartyMatchScript := preload("res://scripts/core/dealer_party_match.gd")

func _init() -> void:
	var match = DealerPartyMatchScript.new()
	assert(match.players.is_empty()) # Dealer host is not a player seat.
	assert(match.add_player("p1", "An"))
	assert(match.add_player("p2", "Bình"))
	assert(match.add_player("p3", "Chi"))
	assert(match.add_player("p4", "Dũng"))
	assert(match.add_player("p5", "Giang"))
	assert(not match.add_player("p6", "Hà"))
	assert(not match.add_player("p1", "Trùng"))
	assert(match.start_match())

	# Multiple symbols are allowed, but balance and chip denominations are enforced.
	assert(match.place_bet("p1", "bau", 10_000))
	assert(match.place_bet("p1", "cua", 20_000))
	assert(not match.place_bet("p1", "tom", 9_999))
	assert(not match.place_bet("p1", "tom", 1_000_000))
	assert(match.place_bet("p2", "cua", 10_000))
	assert(match.place_bet("p3", "bau", 10_000))
	assert(match.place_bet("p4", "cua", 10_000))
	assert(match.place_bet("p5", "cua", 10_000))
	assert(match.confirm_bets("p1"))
	assert(match.confirm_bets("p2"))
	assert(match.confirm_bets("p3"))
	assert(match.confirm_bets("p4"))
	assert(match.confirm_bets("p5"))
	assert(match.phase == DealerPartyMatchScript.PHASE_LOCKED)
	assert(not match.place_bet("p1", "ca", 10_000))

	assert(match.settle(["bau", "bau", "ca"]))
	assert(not match.settle(["bau", "bau", "ca"])) # Settle is idempotent.
	var p1: Dictionary = match.get_player("p1")
	var p2: Dictionary = match.get_player("p2")
	var p3: Dictionary = match.get_player("p3")
	assert(p1["balance"] == 1_000_000) # Stake 30k, payout 30k.
	assert(p1["total_net"] == 0)
	assert(p2["balance"] == 990_000 and p2["total_net"] == -10_000)
	assert(p3["balance"] == 1_020_000 and p3["total_net"] == 20_000)
	var board: Array[Dictionary] = match.leaderboard()
	assert(board[0]["player_id"] == "p3" and board[0]["rank"] == 1)
	assert(board[1]["player_id"] == "p1")
	assert(board[2]["player_id"] == "p2")

	assert(match.advance_round())
	assert(match.phase == DealerPartyMatchScript.PHASE_BETTING and match.round_number == 2)
	# Leaving before settlement cancels the round and refunds all confirmed stakes.
	assert(match.place_bet("p1", "ga", 50_000))
	assert(match.place_bet("p2", "nai", 20_000))
	assert(match.confirm_bets("p1"))
	assert(match.confirm_bets("p2"))
	var balance_before := int(match.get_player("p1")["balance"]) + 50_000
	assert(match.disconnect_player("p2"))
	assert(match.phase == DealerPartyMatchScript.PHASE_BETTING)
	assert(match.get_player("p1")["balance"] == balance_before)
	assert(match.get_player("p1")["bets"] == GameConstants.empty_bets())

	# The host closes betting after 30 seconds. Pending bets are auto-confirmed,
	# while a player who did not bet joins the round with a zero stake.
	var timeout_match = DealerPartyMatchScript.new()
	assert(timeout_match.add_player("fast", "Nhanh"))
	assert(timeout_match.add_player("idle", "Chưa đặt"))
	assert(timeout_match.start_match())
	assert(timeout_match.place_bet("fast", "tom", 50_000))
	assert(timeout_match.expire_betting())
	assert(timeout_match.phase == DealerPartyMatchScript.PHASE_LOCKED)
	assert(timeout_match.get_player("fast")["ready"])
	assert(timeout_match.get_player("fast")["round_stake"] == 50_000)
	assert(timeout_match.get_player("fast")["balance"] == DealerPartyMatchScript.INITIAL_BALANCE - 50_000)
	assert(timeout_match.get_player("idle")["ready"])
	assert(timeout_match.get_player("idle")["round_stake"] == 0)
	assert(timeout_match.get_player("idle")["balance"] == DealerPartyMatchScript.INITIAL_BALANCE)
	assert(not timeout_match.expire_betting())

	# Equal totals keep the original seat order.
	var tie = DealerPartyMatchScript.new()
	assert(tie.add_player("first", "Một"))
	assert(tie.add_player("second", "Hai"))
	var tie_board: Array[Dictionary] = tie.leaderboard()
	assert(tie_board[0]["player_id"] == "first")
	assert(tie_board[1]["player_id"] == "second")
	var duplicate_names = DealerPartyMatchScript.new()
	assert(duplicate_names.add_player("n1", "An"))
	assert(duplicate_names.add_player("n2", "An"))
	assert(duplicate_names.add_player("n3", "An"))
	assert(duplicate_names.add_player("n4", "An"))
	assert(duplicate_names.add_player("n5", "An"))
	assert(duplicate_names.get_player("n1")["name"] == "An")
	assert(duplicate_names.get_player("n2")["name"] == "An (2)")
	assert(duplicate_names.get_player("n3")["name"] == "An (3)")
	assert(duplicate_names.get_player("n4")["name"] == "An (4)")
	assert(duplicate_names.get_player("n5")["name"] == "An (5)")

	print("Dealer party match v2 passed")
	quit(0)
