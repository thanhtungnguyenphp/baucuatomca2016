extends SceneTree

const MatchScript := preload("res://scripts/core/dealer_party_match.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/NearbyPartyMode.tscn") as PackedScene
	var ui = scene.instantiate()
	root.add_child(ui)
	await process_frame
	ui.room.mode = "host"
	ui.room.room_id = "123456"
	var match = MatchScript.new()
	assert(match.add_player("p1", "An"))
	assert(match.add_player("p2", "Bình"))
	ui.room._match = match
	assert(ui.room.start_match())

	for round_index in MatchScript.TOTAL_ROUNDS:
		assert(match.place_bet("p1", "bau", 10_000))
		assert(match.place_bet("p2", "cua", 10_000))
		assert(match.confirm_bets("p1"))
		assert(match.confirm_bets("p2"))
		assert(match.settle(["bau", "bau", "ca"]))
		ui.room._publish_state()
		var board: Array[Dictionary] = match.leaderboard()
		assert(board[0]["player_id"] == "p1" and board[0]["rank"] == 1)
		assert(board[1]["player_id"] == "p2" and board[1]["rank"] == 2)
		assert(ui.room.state["results"] == ["bau", "bau", "ca"])
		if round_index < MatchScript.TOTAL_ROUNDS - 1:
			assert(match.advance_round())

	ui._shown_phase = "settled" # Skip animation; this test checks presentation text.
	ui._refresh()
	assert("1. An" in ui._scores_label.text)
	assert("+100.000 Lộc" in ui._scores_label.text)
	assert(match.get_player("p1")["balance"] == 1_100_000)
	assert(match.get_player("p2")["balance"] == 950_000)

	# Rewarded balance is deliberately excluded from total_net and ranking.
	var second := match.get_player("p2")
	var net_before := int(second["total_net"])
	second["balance"] = 0
	second["spectator"] = true
	assert(match.grant_reward("p2", "reward-one"))
	assert(second["balance"] == MatchScript.REWARD_AMOUNT)
	assert(second["total_net"] == net_before)
	assert(match.leaderboard()[0]["player_id"] == "p1")

	assert(match.advance_round())
	ui.room._publish_state()
	assert(ui.room.state["phase"] == "finished")
	assert(ui.room.start_match())
	assert(match.round_number == 1 and match.phase == "betting")
	for player: Dictionary in match.players:
		assert(player["balance"] == MatchScript.INITIAL_BALANCE)
		assert(player["total_net"] == 0 and player["wins"] == 0)
	print("Nearby payout, leaderboard and rematch passed")
	quit(0)
