extends Control

const MASCOT_CARD_SCENE := preload("res://scenes/components/MascotCard.tscn")
const BOWL_SCENE := preload("res://scenes/components/Bowl.tscn")
const SPRING_BACKGROUND := preload("res://assets/art/spring-lucky-background.png")
const TOTAL_TURNS := 5

var player_count := 2
var turn_number := 1
var scores: Array[int] = []
var choices: Array[String] = []
var chooser := 0
var phase := "setup"
var is_animating := false
var _rng := RandomNumberGenerator.new()
var _cards: Dictionary = {}
var _bowl: BowlPresenter
var _count_label: Label
var _score_label: Label
var _instruction_label: Label
var _action_button: Button
var _undo_button: Button
var _start_button: Button
var _minus_button: Button
var _plus_button: Button

func _ready() -> void:
	_rng.randomize()
	_build_ui()
	_refresh()

func _build_ui() -> void:
	var backdrop := TextureRect.new()
	backdrop.texture = SPRING_BACKGROUND
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.modulate = Color(0.68, 0.63, 0.72, 0.9)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var veil := ColorRect.new()
	veil.color = Color(0.20, 0.015, 0.04, 0.42)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_top", 54)
	margin.add_theme_constant_override("margin_bottom", 240)
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var back := Button.new()
	back.text = "‹ VỀ"
	back.custom_minimum_size = Vector2(150, 68)
	back.add_theme_font_size_override("font_size", 27)
	_style_button(back)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/Main.tscn"))
	header.add_child(back)
	var title := _label("CHƠI CÙNG BẠN", 48, Color("ffe18a"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title)
	var spacer := Control.new()
	spacer.custom_minimum_size.x = 150
	header.add_child(spacer)
	var setup := HBoxContainer.new()
	setup.add_theme_constant_override("separation", 16)
	setup.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(setup)
	_minus_button = _small_button("−")
	_minus_button.pressed.connect(func() -> void: _change_player_count(-1))
	setup.add_child(_minus_button)
	_count_label = _label("", 30, Color("fff1d0"))
	_count_label.custom_minimum_size.x = 180
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	setup.add_child(_count_label)
	_plus_button = _small_button("+")
	_plus_button.pressed.connect(func() -> void: _change_player_count(1))
	setup.add_child(_plus_button)
	_start_button = _small_button("BẮT ĐẦU")
	_start_button.custom_minimum_size.x = 250
	_style_button(_start_button, true)
	_start_button.pressed.connect(_start_party)
	setup.add_child(_start_button)
	_score_label = _label("", 29, Color("bdf0be"))
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_score_label)
	_instruction_label = _label("", 28, Color("fff1d0"))
	_instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_instruction_label)
	_bowl = BOWL_SCENE.instantiate()
	_bowl.custom_minimum_size.y = 470.0 + maxf(0.0, get_viewport().get_visible_rect().size.y - 1920.0) * 0.25
	_bowl.tapped.connect(_on_bowl_tapped)
	content.add_child(_bowl)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	content.add_child(grid)
	for symbol in GameConstants.SYMBOLS:
		var card: MascotCard = MASCOT_CARD_SCENE.instantiate()
		card.configure(symbol)
		card.custom_minimum_size.y = 215.0
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.pressed.connect(_choose_symbol.bind(symbol))
		grid.add_child(card)
		_cards[symbol] = card
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 12)
	content.add_child(action_row)
	_undo_button = Button.new()
	_undo_button.text = "ĐỔI LỰA CHỌN"
	_undo_button.custom_minimum_size = Vector2(260, 82)
	_undo_button.add_theme_font_size_override("font_size", 24)
	_style_button(_undo_button)
	_undo_button.pressed.connect(_undo_choice)
	action_row.add_child(_undo_button)
	_action_button = Button.new()
	_action_button.custom_minimum_size.y = 82
	_action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_button.add_theme_font_size_override("font_size", 31)
	_style_button(_action_button, true)
	_action_button.pressed.connect(_on_bowl_tapped)
	action_row.add_child(_action_button)
	var note := _label("5 lượt · Mỗi mặt trùng được 1 điểm · Không dùng Lộc", 26, Color("ffe0a5"))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(note)

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _small_button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(80, 66)
	button.add_theme_font_size_override("font_size", 28)
	_style_button(button)
	return button

func _style_button(button: Button, prominent: bool = false) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("a34424") if prominent else Color("4a1420")
	normal.border_color = Color("ffe39a")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(16)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("391921")
	disabled.border_color = Color("795642")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color("fff7d4"))
	button.add_theme_color_override("font_disabled_color", Color("b9a99e"))

func _change_player_count(delta: int) -> void:
	if phase != "setup" and phase != "finished":
		return
	player_count = clampi(player_count + delta, 2, 4)
	_refresh()

func _start_party() -> void:
	if phase != "setup" and phase != "finished":
		return
	scores.clear()
	for index in player_count:
		scores.append(0)
	turn_number = 1
	_reset_choices()
	phase = "choose"
	_refresh()

func _reset_choices() -> void:
	choices.clear()
	for index in player_count:
		choices.append("")
	chooser = 0

func _choose_symbol(symbol: String) -> void:
	if phase != "choose" or is_animating or chooser >= player_count:
		return
	choices[chooser] = symbol
	chooser += 1
	GameSettings.tap_feedback()
	AudioDirector.play(NativeAudioDirector.Cue.TAP)
	_refresh()

func _undo_choice() -> void:
	if phase != "choose" or chooser <= 0 or is_animating:
		return
	chooser -= 1
	choices[chooser] = ""
	_refresh()

func _on_bowl_tapped() -> void:
	if is_animating:
		return
	if phase == "choose":
		if chooser < player_count:
			_instruction_label.text = "Mỗi người chọn một linh vật trước khi lắc."
			return
		_roll_party()
	elif phase == "revealed":
		_cover_party()

func _roll_party() -> void:
	is_animating = true
	phase = "rolling"
	_refresh()
	var results := RoundResolver.roll_results(_rng)
	await _bowl.play_reveal(results)
	for index in player_count:
		for symbol in results:
			if symbol == choices[index]:
				scores[index] += 1
	var labels: Array[String] = []
	for symbol in results:
		labels.append(GameConstants.SYMBOL_LABELS[symbol])
	is_animating = false
	phase = "revealed"
	_instruction_label.text = "Kết quả: " + " · ".join(labels)
	_refresh()

func _cover_party() -> void:
	is_animating = true
	await _bowl.play_cover()
	is_animating = false
	if turn_number >= TOTAL_TURNS:
		phase = "finished"
	else:
		turn_number += 1
		_reset_choices()
		phase = "choose"
	_refresh()

func _refresh() -> void:
	_count_label.text = "%d NGƯỜI" % player_count
	_minus_button.disabled = (phase != "setup" and phase != "finished") or player_count <= 2
	_plus_button.disabled = (phase != "setup" and phase != "finished") or player_count >= 4
	_start_button.disabled = phase != "setup" and phase != "finished"
	_start_button.text = "CHƠI LẠI" if phase == "finished" else "BẮT ĐẦU"
	var score_parts: Array[String] = []
	for index in scores.size():
		score_parts.append("Người %d: %d" % [index + 1, scores[index]])
	_score_label.text = "   ·   ".join(score_parts) if not score_parts.is_empty() else "Chọn 2–4 người để bắt đầu"
	match phase:
		"setup":
			_instruction_label.text = "Mỗi người chọn một linh vật, cùng lắc một lần."
			_action_button.text = "CHỌN SỐ NGƯỜI VÀ BẮT ĐẦU"
		"choose":
			_instruction_label.text = "Lượt %d/%d · Người %d chọn linh vật" % [turn_number, TOTAL_TURNS, chooser + 1] if chooser < player_count else "Lượt %d/%d · Chạm tô để lắc" % [turn_number, TOTAL_TURNS]
			_action_button.text = "LẮC TÔ" if chooser >= player_count else "CHỜ NGƯỜI %d CHỌN" % (chooser + 1)
		"rolling":
			_instruction_label.text = "Đang lắc tô…"
			_action_button.text = "ĐANG LẮC…"
		"revealed":
			_action_button.text = "ĐẬY TÔ · TIẾP TỤC" if turn_number < TOTAL_TURNS else "XEM KẾT QUẢ"
		"finished":
			var best: int = scores.max()
			var winners: Array[String] = []
			for index in scores.size():
				if scores[index] == best:
					winners.append("Người %d" % (index + 1))
			_instruction_label.text = "Hoàn thành! %s dẫn đầu với %d điểm." % [" và ".join(winners), best]
			_action_button.text = "CHỌN CHƠI LẠI"
	_action_button.disabled = phase == "setup" or phase == "rolling" or phase == "finished" or (phase == "choose" and chooser < player_count)
	_undo_button.disabled = phase != "choose" or chooser <= 0
	for symbol in GameConstants.SYMBOLS:
		var owners: Array[String] = []
		for index in choices.size():
			if choices[index] == symbol:
				owners.append(str(index + 1))
		var card: MascotCard = _cards[symbol]
		card.set_party_state("NGƯỜI " + ", ".join(owners) if not owners.is_empty() else "CHỌN MẶT", not owners.is_empty())
		card.disabled = phase != "choose" or chooser >= player_count
