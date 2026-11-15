extends Control

const MASCOT_CARD_SCENE := preload("res://scenes/components/MascotCard.tscn")
const BOWL_SCENE := preload("res://scenes/components/Bowl.tscn")
const SPRING_BACKGROUND := preload("res://assets/art/spring-lucky-background.png")

var room := PartyNearbyAdapter.new()
var _rooms_box: VBoxContainer
var _rooms_caption: Label
var _lobby: VBoxContainer
var _board: VBoxContainer
var _name_edit: LineEdit
var _status: Label
var _room_label: Label
var _players_label: Label
var _scores_label: Label
var _instruction: Label
var _action: Button
var _bowl: BowlPresenter
var _cards: Dictionary = {}
var _verify_dialog: ConfirmationDialog
var _pending_endpoint := ""
var _shown_phase := ""
var _animating := false

func _enter_tree() -> void:
	get_tree().quit_on_go_back = false

func _ready() -> void:
	get_window().go_back_requested.connect(_go_back)
	add_child(room)
	_build_ui()
	room.changed.connect(_refresh)
	room.rooms_changed.connect(_refresh_rooms)
	room.notice.connect(func(message: String) -> void: _status.text = message)
	room.verification_needed.connect(_on_verification_needed)
	_refresh()
	if not room.available():
		_status.text = "Cần điện thoại Android có Google Play services để chơi gần nhau."

func _exit_tree() -> void:
	room.leave()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and is_instance_valid(room) and not room.is_requesting_permissions():
		room.leave()
		if is_instance_valid(_status):
			_status.text = "Phòng đã đóng khi ứng dụng chuyển nền. Hãy tạo hoặc tìm lại phòng."

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_go_back()
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	var backdrop := TextureRect.new()
	backdrop.texture = SPRING_BACKGROUND
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.modulate = Color(0.65, 0.60, 0.68, 0.95)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var veil := ColorRect.new()
	veil.color = Color(0.13, 0.01, 0.035, 0.68)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 38)
	margin.add_theme_constant_override("margin_top", 54)
	margin.add_theme_constant_override("margin_bottom", 210)
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	margin.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var back := _button("‹ VỀ", 27, 150, 68)
	back.pressed.connect(_go_back)
	header.add_child(back)
	var title := _label("CHƠI GẦN NHAU", 45, Color("ffe18a"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var spacer := Control.new()
	spacer.custom_minimum_size.x = 150
	header.add_child(spacer)
	_status = _label("Tạo phòng hoặc tìm phòng trên điện thoại bên cạnh.", 28, Color("fff1d0"))
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.custom_minimum_size.y = 70
	content.add_child(_status)
	_room_label = _label("", 32, Color("ffe18a"))
	_room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_room_label)
	_lobby = VBoxContainer.new()
	_lobby.add_theme_constant_override("separation", 20)
	_lobby.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_lobby)
	var name_caption := _label("Tên hiển thị trong phòng", 29, Color("fff1d0"))
	_lobby.add_child(name_caption)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Nhập tên của bạn"
	_name_edit.text = "Người chơi %04d" % randi_range(0, 9999)
	_name_edit.max_length = 24
	_name_edit.custom_minimum_size.y = 82
	_name_edit.add_theme_font_size_override("font_size", 30)
	_lobby.add_child(_name_edit)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_lobby.add_child(row)
	var create := _button("TẠO PHÒNG", 30, 0, 88, true)
	create.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create.pressed.connect(func() -> void: room.create_room(_name_edit.text))
	row.add_child(create)
	var find := _button("TÌM PHÒNG", 30, 0, 88)
	find.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	find.pressed.connect(func() -> void: room.find_rooms(_name_edit.text))
	row.add_child(find)
	_rooms_caption = _label("Phòng ở gần", 32, Color("ffe18a"))
	_lobby.add_child(_rooms_caption)
	_rooms_box = VBoxContainer.new()
	_rooms_box.add_theme_constant_override("separation", 12)
	_lobby.add_child(_rooms_box)
	_players_label = _label("", 29, Color("bdf0be"))
	_lobby.add_child(_players_label)
	var start := _button("BẮT ĐẦU 5 LƯỢT", 31, 0, 88, true)
	start.name = "StartButton"
	start.pressed.connect(func() -> void:
		if not room.start_match():
			_status.text = "Cần ít nhất 2 người trong phòng để bắt đầu."
	)
	_lobby.add_child(start)
	var lobby_note := _label("Tối đa 4 người. Chủ phòng là người lắc tô; mỗi người chọn 1 linh vật mỗi lượt. Chỉ tính điểm, không dùng Lộc.", 27, Color("ffe0a5"))
	_lobby.add_child(lobby_note)
	_board = VBoxContainer.new()
	_board.add_theme_constant_override("separation", 14)
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_board)
	_scores_label = _label("", 29, Color("bdf0be"))
	_scores_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_board.add_child(_scores_label)
	_instruction = _label("", 29, Color("fff1d0"))
	_instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_board.add_child(_instruction)
	_bowl = BOWL_SCENE.instantiate()
	_bowl.custom_minimum_size.y = 430
	_bowl.tapped.connect(_on_bowl_tapped)
	_board.add_child(_bowl)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	_board.add_child(grid)
	for symbol in GameConstants.SYMBOLS:
		var card: MascotCard = MASCOT_CARD_SCENE.instantiate()
		card.configure(symbol)
		card.custom_minimum_size.y = 205
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.pressed.connect(_choose.bind(symbol))
		grid.add_child(card)
		_cards[symbol] = card
	_action = _button("", 31, 0, 88, true)
	_action.pressed.connect(_on_bowl_tapped)
	_board.add_child(_action)
	var board_note := _label("Chủ phòng lắc và đậy tô · Mỗi mặt trùng được 1 điểm · 5 lượt", 26, Color("ffe0a5"))
	board_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_board.add_child(board_note)
	_verify_dialog = ConfirmationDialog.new()
	_verify_dialog.title = "XÁC NHẬN NGƯỜI CHƠI"
	_verify_dialog.ok_button_text = "TRÙNG MÃ · KẾT NỐI"
	_verify_dialog.cancel_button_text = "KHÔNG TRÙNG · TỪ CHỐI"
	_verify_dialog.min_size = Vector2i(850, 440)
	var dialog_style := StyleBoxFlat.new()
	dialog_style.bg_color = Color("1b0410")
	dialog_style.border_color = Color("ffe39a")
	dialog_style.set_border_width_all(3)
	dialog_style.set_corner_radius_all(20)
	dialog_style.set_content_margin_all(36)
	_verify_dialog.add_theme_stylebox_override("panel", dialog_style)
	_verify_dialog.add_theme_font_size_override("title_font_size", 32)
	_verify_dialog.get_label().add_theme_font_size_override("font_size", 31)
	_verify_dialog.get_label().add_theme_color_override("font_color", Color("fff1d0"))
	_verify_dialog.get_ok_button().add_theme_font_size_override("font_size", 28)
	_verify_dialog.get_ok_button().custom_minimum_size.y = 80
	_verify_dialog.get_cancel_button().add_theme_font_size_override("font_size", 28)
	_verify_dialog.get_cancel_button().custom_minimum_size.y = 80
	add_child(_verify_dialog)
	_verify_dialog.confirmed.connect(_accept_pairing)
	_verify_dialog.canceled.connect(_reject_pairing)

func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(value: String, size: int, width: int, height: int, prominent: bool = false) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(width, height)
	button.add_theme_font_size_override("font_size", size)
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
	return button

func _refresh_rooms() -> void:
	if not is_instance_valid(_rooms_box):
		return
	for child in _rooms_box.get_children():
		child.queue_free()
	if room.rooms.is_empty():
		_rooms_box.add_child(_label("Chưa thấy phòng. Hai máy cần bật Bluetooth và Wi-Fi, đặt gần nhau.", 27, Color("fff1d0")))
		return
	for endpoint: String in room.rooms:
		var button := _button("VÀO PHÒNG · " + str(room.rooms[endpoint]), 29, 0, 78)
		button.pressed.connect(room.join_room.bind(endpoint))
		_rooms_box.add_child(button)

func _refresh() -> void:
	if not is_instance_valid(_lobby):
		return
	var active := not room.state.is_empty()
	_lobby.visible = not active
	_board.visible = active
	_rooms_caption.visible = room.mode != "host" and room.local_seat < 0
	_rooms_box.visible = _rooms_caption.visible
	_room_label.text = "PHÒNG %s · %d/4 NGƯỜI" % [room.room_id, room.players.size()] if not room.room_id.is_empty() else ""
	if room.mode == "host":
		_players_label.text = "Trong phòng: " + ", ".join(room.players)
	elif room.mode == "guest":
		_players_label.text = "Đã vào phòng: " + ", ".join(room.players) if room.local_seat >= 0 else "Đang tìm hoặc kết nối phòng…"
	else:
		_players_label.text = ""
	var start: Button = _lobby.get_node("StartButton")
	start.visible = room.mode == "host"
	start.disabled = room.players.size() < 2 or room.players.size() > 4
	_refresh_rooms()
	if not active:
		_shown_phase = ""
		return
	var phase: String = str(room.state.get("phase", ""))
	var turn: int = int(room.state.get("turn_number", 1))
	var choices: Array = room.state.get("choices", [])
	var scores: Array = room.state.get("scores", [])
	var score_parts: Array[String] = []
	for seat in scores.size():
		score_parts.append("%s: %d" % [room.players[seat], scores[seat]])
	_scores_label.text = "  ·  ".join(score_parts)
	var my_choice := room.local_seat >= 0 and room.local_seat < choices.size() and not str(choices[room.local_seat]).is_empty()
	var all_chosen := true
	for choice: Variant in choices:
		if str(choice).is_empty():
			all_chosen = false
	var is_host := room.mode == "host"
	match phase:
		"choose":
			_instruction.text = "Lượt %d/5 · %s" % [turn, "Chạm tô để lắc" if all_chosen and is_host else "Chờ chủ phòng lắc" if all_chosen else "Chọn một linh vật" if not my_choice else "Chờ mọi người chọn"]
			_action.text = "LẮC TÔ" if is_host and all_chosen else "CHỜ MỌI NGƯỜI CHỌN"
			_action.disabled = not (is_host and all_chosen) or _animating
		"revealed":
			var result_names: Array[String] = []
			for symbol: String in room.state.get("last_results", []):
				result_names.append(GameConstants.SYMBOL_LABELS[symbol])
			_instruction.text = "Lượt %d/5 · Kết quả: %s" % [turn, " · ".join(result_names)]
			_action.text = "ĐẬY TÔ · TIẾP TỤC" if turn < PartyMatch.TOTAL_TURNS else "XEM KẾT QUẢ"
			_action.disabled = not is_host or _animating
		"finished":
			var best: int = scores.max()
			var winners: Array[String] = []
			for seat in scores.size():
				if scores[seat] == best:
					winners.append(room.players[seat])
			_instruction.text = "Kết thúc! %s dẫn đầu với %d điểm." % [" và ".join(winners), best]
			_action.text = "CHỦ PHÒNG CHƠI LẠI"
			_action.disabled = not is_host or _animating
	for symbol in GameConstants.SYMBOLS:
		var owners: Array[String] = []
		for seat in choices.size():
			if choices[seat] == symbol:
				owners.append(room.players[seat])
		var card: MascotCard = _cards[symbol]
		card.set_party_state(", ".join(owners) if not owners.is_empty() else "CHỌN MẶT", not owners.is_empty())
		card.disabled = phase != "choose" or my_choice or _animating
	if phase != _shown_phase:
		_shown_phase = phase
		if phase == "revealed":
			_play_reveal()
		elif _bowl.is_revealed:
			_play_cover()

func _play_reveal() -> void:
	_animating = true
	_refresh()
	var results: Array[String] = []
	for symbol: String in room.state.get("last_results", []):
		results.append(symbol)
	if results.size() == 3:
		await _bowl.play_reveal(results)
	_animating = false
	_refresh()

func _play_cover() -> void:
	_animating = true
	_refresh()
	await _bowl.play_cover()
	_animating = false
	_refresh()

func _choose(symbol: String) -> void:
	if room.choose(symbol):
		GameSettings.tap_feedback()
		AudioDirector.play(NativeAudioDirector.Cue.TAP)

func _on_bowl_tapped() -> void:
	if _animating or room.mode != "host":
		return
	match room.state.get("phase", ""):
		"choose":
			if not room.roll():
				_status.text = "Chờ tất cả người chơi chọn linh vật."
		"revealed":
			_animating = true
			_refresh()
			await _bowl.play_cover()
			room.advance()
			_animating = false
			_refresh()
		"finished":
			room.start_match()

func _on_verification_needed(id: String, name: String, digits: String) -> void:
	_pending_endpoint = id
	_verify_dialog.dialog_text = "Đối chiếu mã trên cả hai điện thoại:\n\n%s\n\nThiết bị: %s\n\nChỉ xác nhận nếu mã giống nhau." % [digits, name]
	_verify_dialog.popup_centered()

func _accept_pairing() -> void:
	if not _pending_endpoint.is_empty():
		room.accept_pairing(_pending_endpoint)
		_pending_endpoint = ""

func _reject_pairing() -> void:
	if not _pending_endpoint.is_empty():
		room.reject_pairing(_pending_endpoint)
		_pending_endpoint = ""

func _go_back() -> void:
	if not _pending_endpoint.is_empty():
		_reject_pairing()
	room.leave()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
