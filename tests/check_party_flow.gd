extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var party = (load("res://scenes/PartyMode.tscn") as PackedScene).instantiate()
	add_child(party)
	await get_tree().process_frame
	party._start_party()
	assert(party.phase == "choose")
	party._choose_symbol("bau")
	party._choose_symbol("cua")
	assert(party.chooser == 2)
	party._undo_choice()
	assert(party.chooser == 1)
	party._choose_symbol("tom")
	await party._roll_party()
	assert(party.phase == "revealed")
	assert(party._bowl.is_revealed)
	await party._cover_party()
	assert(party.phase == "choose")
	assert(party.turn_number == 2)
	assert(not party._bowl.is_revealed)
	print("Party flow passed")
	get_tree().quit(0)
