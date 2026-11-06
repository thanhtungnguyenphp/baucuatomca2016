extends SceneTree

func _init() -> void:
	_test_two_players_and_duplicate_result()
	_test_full_five_turns()
	_test_four_players_out_of_order()
	print("PartyMatch rules passed")
	quit(0)

func _test_two_players_and_duplicate_result() -> void:
	var party := PartyMatch.new()
	assert(party.start())
	assert(party.choose_next("bau"))
	assert(party.choose_next("cua"))
	assert(party.all_chosen())
	assert(not party.settle(["bau", "invalid", "cua"]))
	assert(party.scores == [0, 0])
	assert(party.settle(["bau", "bau", "ca"]))
	assert(party.scores == [2, 0])
	assert(not party.settle(["bau", "bau", "ca"]))
	assert(party.scores == [2, 0])
	assert(party.advance())
	assert(party.turn_number == 2)
	assert(party.choices == ["", ""])

func _test_full_five_turns() -> void:
	var party := PartyMatch.new()
	assert(party.start())
	for turn in PartyMatch.TOTAL_TURNS:
		assert(party.choose_next("bau"))
		assert(party.choose_next("cua"))
		assert(party.settle(["bau", "cua", "nai"]))
		assert(party.advance())
		if turn < PartyMatch.TOTAL_TURNS - 1:
			assert(party.turn_number == turn + 2)
		else:
			assert(party.turn_number == PartyMatch.TOTAL_TURNS)
	assert(party.phase == "finished")
	assert(party.scores == [5, 5])
	assert(not party.advance())
	assert(party.start())
	assert(party.scores == [0, 0])

func _test_four_players_out_of_order() -> void:
	var party := PartyMatch.new()
	assert(party.set_player_count(4))
	assert(party.start())
	assert(party.set_choice(3, "ga"))
	assert(party.chooser == 0)
	assert(party.choose_next("bau"))
	assert(party.choose_next("cua"))
	assert(party.choose_next("tom"))
	assert(party.all_chosen())
	assert(party.settle(["ga", "ga", "bau"]))
	assert(party.scores == [1, 0, 0, 2])
