extends Control

const MASCOT_CARD_SCENE := preload("res://scenes/components/MascotCard.tscn")
const BOWL_SCENE := preload("res://scenes/components/Bowl.tscn")
const SPRING_BACKGROUND := preload("res://assets/art/spring-lucky-background.png")
const DealerPartyMatchScript := preload("res://scripts/core/dealer_party_match.gd")
const PartyNearbyAdapterV2Script := preload("res://scripts/core/party_nearby_adapter_v2.gd")

var room = PartyNearbyAdapterV2Script.new()
var _rooms_box: VBoxContainer
var _rooms_caption: Label
var _lobby: VBoxContainer
var _board: VBoxContainer
var _name_edit: LineEdit
var _status: Label
var _room_label: Label
var _role_label: Label
var _players_label: Label
var _scores_label: Label
var _instruction: Label
var _action: Button
var _client_controls: VBoxContainer
var _client_balance: Label
var _clear_bets_button: Button
var _confirm_bets_button: Button
var _reward_button: Button
var _content_margin: MarginContainer
var _bowl: BowlPresenter
var _cards: Dictionary = {}
var _chip_buttons: Dictionary = {}
var _verify_dialog: ConfirmationDialog
var _pending_endpoint := ""
var _shown_phase := ""
var _animating := false
var _selected_chip := 10_000
var _pending_reward_id := ""

func _enter_tree() -> void:
	get_tree().quit_on_go_back = false

func _ready() -> void:
	get_window().go_back_requested.connect(func() -> void: call_deferred("_go_back"))
	add_child(room)
	_build_ui()
	room.changed.connect(_refresh)
	room.rooms_changed.connect(_refresh_rooms)
	room.notice.connect(func(message: String) -> void: _status.text = message)
	room.verification_needed.connect(_on_verification_needed)
	AdPlacement.rewarded_availability_changed.connect(_on_rewarded_availability_changed)
	AdPlacement.rewarded_earned.connect(_on_rewarded_earned)
	AdPlacement.rewarded_failed.connect(_on_rewarded_failed)
	AdPlacement.banner_visibility_changed.connect(_on_banner_visibility_changed)
	_on_banner_visibility_changed(AdPlacement.is_banner_visible())
	_refresh()
	if not room.available():
		_status.text = "Cần điện thoại Android có Google Play services để chơi gần nhau."

func _exit_tree() -> void:
	room.leave()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and is_instance_valid(room) and not room.is_requesting_permissions() and not AdPlacement.is_fullscreen_ad_active():
		room.leave()
		if is_instance_valid(_status):
			_status.text = "Phòng đã đóng khi ứng dụng chuyển nền. Hãy tạo hoặc tìm lại phòng."

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		call_deferred("_go_back")

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
	_content_margin = margin
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 38)
	margin.add_theme_constant_override("margin_top", 54)
	margin.add_theme_constant_override("margin_bottom", 120)
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	margin.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var back := _button("‹ VỀ", 27, 150, 68)
	back.pressed.connect(func() -> void: call_deferred("_go_back"))
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
	_role_label = _label("", 27, Color("bdf0be"))
	_role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_role_label)
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
			_status.text = "Cần ít nhất 1 máy con trong phòng để bắt đầu."
	)
	_lobby.add_child(start)
	var lobby_note := _label("Tối đa 4 thiết bị: 1 chủ phòng điều khiển tô và 1–3 máy con đặt Lộc.", 27, Color("ffe0a5"))
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
	_client_controls = VBoxContainer.new()
	_client_controls.add_theme_constant_override("separation", 10)
	_board.add_child(_client_controls)
	_client_balance = _label("", 28, Color("ffe18a"))
	_client_balance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_client_controls.add_child(_client_balance)
	var chip_grid := GridContainer.new()
	chip_grid.columns = 3
	chip_grid.add_theme_constant_override("h_separation", 10)
	chip_grid.add_theme_constant_override("v_separation", 8)
	_client_controls.add_child(chip_grid)
	for value in GameConstants.CHIP_VALUES:
		var chip := _button(_format_chip(value), 25, 0, 62, value == _selected_chip)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.pressed.connect(_select_chip.bind(value))
		chip_grid.add_child(chip)
		_chip_buttons[value] = chip
	var bet_actions := HBoxContainer.new()
	bet_actions.add_theme_constant_override("separation", 12)
	_client_controls.add_child(bet_actions)
	_clear_bets_button = _button("XÓA CƯỢC", 27, 0, 72)
	_clear_bets_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clear_bets_button.pressed.connect(_clear_bets)
	bet_actions.add_child(_clear_bets_button)
	_confirm_bets_button = _button("XÁC NHẬN ĐẶT", 27, 0, 72, true)
	_confirm_bets_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm_bets_button.pressed.connect(_confirm_bets)
	bet_actions.add_child(_confirm_bets_button)
	_reward_button = _button("XEM VIDEO · NHẬN 200K LỘC", 27, 0, 72, true)
	_reward_button.pressed.connect(_watch_rewarded)
	_client_controls.add_child(_reward_button)
	_action = _button("", 31, 0, 88, true)
	_action.pressed.connect(_on_bowl_tapped)
	_board.add_child(_action)
	var board_note := _label("Chủ phòng chỉ lắc, mở và đậy tô · Kết quả và trả thưởng đồng bộ đến mọi máy", 26, Color("ffe0a5"))
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
	var active: bool = not room.state.is_empty()
	_lobby.visible = not active
	_board.visible = active
	_rooms_caption.visible = room.mode != "host" and room.local_seat < 0
	_rooms_box.visible = _rooms_caption.visible
	_room_label.text = "PHÒNG %s · 1 CHỦ + %d/3 NGƯỜI CHƠI" % [room.room_id, room.players.size()] if not room.room_id.is_empty() else ""
	_role_label.text = "CHỦ PHÒNG · NGƯỜI LẮC" if room.mode == "host" else "MÁY CON · NGƯỜI ĐẶT" if room.mode == "guest" and room.local_seat >= 0 else ""
	if room.mode == "host":
		_players_label.text = "Máy con: " + ", ".join(room.players) if not room.players.is_empty() else "Chưa có máy con vào phòng."
	elif room.mode == "guest":
		_players_label.text = "Đã vào phòng: " + ", ".join(room.players) if room.local_seat >= 0 else "Đang tìm hoặc kết nối phòng…"
	else:
		_players_label.text = ""
	var start: Button = _lobby.get_node("StartButton")
	start.visible = room.mode == "host"
	start.disabled = room.players.is_empty() or room.players.size() > 3
	_refresh_rooms()
	if not active:
		if room.mode == "guest" and room.local_seat >= 0:
			_status.text = "Đã vào phòng. Chờ chủ phòng bắt đầu."
		elif room.mode == "host" and not room.players.is_empty():
			_status.text = "Đã có người chơi. Chủ phòng có thể bắt đầu ván."
		_shown_phase = ""
		return
	_status.text = "Bạn là chủ phòng: theo dõi cược và điều khiển tô." if room.mode == "host" else "Đặt Lộc, xác nhận rồi chờ chủ phòng lắc tô."
	var phase: String = str(room.state.get("phase", ""))
	var turn: int = int(room.state.get("round_number", 1))
	var match_players: Array = room.state.get("players", [])
	var status_parts: Array[String] = []
	if phase == "settled" or phase == "finished":
		for row: Dictionary in room.state.get("leaderboard", []):
			status_parts.append("%d. %s · %s · Dư %s" % [
				int(row.get("rank", 0)),
				row.get("name", "Người chơi"),
				GameConstants.format_signed_luck(int(row.get("total_net", 0))),
				GameConstants.format_luck(int(row.get("balance", 0))),
			])
	else:
		for player: Dictionary in match_players:
			var state_text := "KHÁN GIẢ" if player.get("spectator", false) else "ĐÃ CHỐT" if player.get("ready", false) else "ĐANG ĐẶT"
			status_parts.append("%s · %s · %s" % [player.get("name", "Người chơi"), GameConstants.format_luck(int(player.get("balance", 0))), state_text])
	_scores_label.text = "\n".join(status_parts)
	var is_host: bool = room.mode == "host"
	var local_player: Dictionary = room.get_local_player()
	var local_ready := bool(local_player.get("ready", false))
	var local_spectator := bool(local_player.get("spectator", false))
	if not _pending_reward_id.is_empty() and not local_player.is_empty() and not local_spectator:
		_pending_reward_id = ""
	var local_total_bet := 0
	for amount: Variant in local_player.get("bets", {}).values():
		local_total_bet += int(amount)
	var can_edit_bets := not is_host and phase == "betting" and not local_ready and not local_spectator and not _animating
	_client_controls.visible = not is_host
	_action.visible = is_host
	if phase == "settled":
		_client_balance.text = "NHẬN %s · LƯỢT NÀY %s · SỐ DƯ %s" % [
			GameConstants.format_luck(int(local_player.get("round_payout", 0))),
			GameConstants.format_signed_luck(int(local_player.get("round_net", 0))),
			GameConstants.format_luck(int(local_player.get("balance", 0))),
		]
	elif phase == "finished":
		var local_rank := 0
		for row: Dictionary in room.state.get("leaderboard", []):
			if row.get("player_id", "") == room.local_player_id:
				local_rank = int(row.get("rank", 0))
		_client_balance.text = "HẠNG %d · TỔNG %s · SỐ DƯ %s" % [local_rank, GameConstants.format_signed_luck(int(local_player.get("total_net", 0))), GameConstants.format_luck(int(local_player.get("balance", 0)))]
	else:
		_client_balance.text = "SỐ DƯ: %s · ĐANG ĐẶT: %s" % [GameConstants.format_luck(int(local_player.get("balance", 0))), GameConstants.format_luck(local_total_bet)]
	_clear_bets_button.disabled = not can_edit_bets or local_total_bet <= 0
	_confirm_bets_button.disabled = not can_edit_bets or local_total_bet <= 0
	_reward_button.visible = local_spectator
	_reward_button.disabled = not AdPlacement.is_rewarded_ready() or not _pending_reward_id.is_empty()
	_reward_button.text = "XEM VIDEO · NHẬN 200K LỘC" if AdPlacement.is_rewarded_ready() else "ĐANG TẢI VIDEO THƯỞNG…"
	for value in GameConstants.CHIP_VALUES:
		var chip: Button = _chip_buttons[value]
		chip.text = ("✓ " if value == _selected_chip else "") + _format_chip(value)
		chip.disabled = not can_edit_bets
	match phase:
		"betting":
			if is_host:
				_instruction.text = "Lượt %d/5 · Máy con đang đặt và xác nhận" % turn
			else:
				_instruction.text = "Lượt %d/5 · %s" % [turn, "Hết Lộc · Bạn đang xem với vai trò khán giả" if local_spectator else "Đã chốt cược · Chờ người còn lại" if local_ready else "Chọn chip, đặt lên linh vật rồi xác nhận"]
			_action.text = "CHỜ MÁY CON XÁC NHẬN"
			_action.disabled = true
		"locked":
			_instruction.text = "Lượt %d/5 · Tất cả người chơi đã xác nhận" % turn
			_action.text = "LẮC TÔ" if is_host else "CHỜ CHỦ PHÒNG LẮC"
			_action.disabled = not is_host or _animating
		"settled":
			var result_names: Array[String] = []
			for symbol: String in room.state.get("results", []):
				result_names.append(GameConstants.SYMBOL_LABELS[symbol])
			_instruction.text = "Lượt %d/5 · Kết quả: %s" % [turn, " · ".join(result_names)]
			_action.text = "ĐẬY TÔ · TIẾP TỤC" if turn < DealerPartyMatchScript.TOTAL_ROUNDS else "XEM BẢNG XẾP HẠNG"
			_action.disabled = not is_host or _animating
		"finished":
			var board: Array = room.state.get("leaderboard", [])
			_instruction.text = "Kết thúc! %s dẫn đầu với %s." % [board[0].get("name", "Người chơi"), GameConstants.format_signed_luck(int(board[0].get("total_net", 0)))] if not board.is_empty() else "Kết thúc ván."
			_action.text = "CHƠI LẠI" if is_host else "CHỜ CHỦ PHÒNG CHƠI LẠI"
			_action.disabled = not is_host or _animating
	for symbol in GameConstants.SYMBOLS:
		var owners: Array[String] = []
		for player: Dictionary in match_players:
			var amount := int(player.get("bets", {}).get(symbol, 0))
			if amount > 0:
				owners.append("%s %s" % [player.get("name", "Người chơi"), GameConstants.format_luck(amount)])
		var card: MascotCard = _cards[symbol]
		card.set_party_state(" · ".join(owners) if not owners.is_empty() else "CHƯA CÓ CƯỢC", not owners.is_empty())
		card.disabled = is_host or phase != "betting" or local_ready or local_spectator or _animating
	if phase != _shown_phase:
		_shown_phase = phase
		if phase == "settled":
			_play_reveal()
		elif _bowl.is_revealed:
			_play_cover()

func _play_reveal() -> void:
	_animating = true
	_refresh()
	var results: Array[String] = []
	for symbol: String in room.state.get("results", []):
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
	if room.place_bet(symbol, _selected_chip):
		GameSettings.tap_feedback()
		AudioDirector.play(NativeAudioDirector.Cue.TAP)

func _select_chip(value: int) -> void:
	if not GameConstants.CHIP_VALUES.has(value):
		return
	_selected_chip = value
	GameSettings.tap_feedback()
	_refresh()

func _clear_bets() -> void:
	if room.clear_bets():
		GameSettings.tap_feedback()

func _confirm_bets() -> void:
	if room.confirm_bets():
		GameSettings.tap_feedback()

func _watch_rewarded() -> void:
	if room.mode != "guest" or room.local_player_id.is_empty() or not _pending_reward_id.is_empty():
		return
	_pending_reward_id = "%s:%s:%d" % [room.room_id, room.local_player_id, Time.get_ticks_msec()]
	if not AdPlacement.show_rewarded(_pending_reward_id):
		_pending_reward_id = ""
		_status.text = "Video thưởng chưa sẵn sàng. Vui lòng thử lại sau."
	_refresh()

func _on_rewarded_earned(request_id: String) -> void:
	if request_id != _pending_reward_id:
		return
	if room.request_reward(request_id):
		_status.text = "Đã xem xong. Đang xác nhận Lộc với chủ phòng…"
	else:
		_pending_reward_id = ""
		_status.text = "Không thể gửi phần thưởng đến chủ phòng."

func _on_rewarded_failed(request_id: String, message: String) -> void:
	if request_id != _pending_reward_id:
		return
	_pending_reward_id = ""
	_status.text = message
	_refresh()

func _on_rewarded_availability_changed(_available: bool) -> void:
	_refresh()

func _on_banner_visibility_changed(visible: bool) -> void:
	if not is_instance_valid(_content_margin):
		return
	# The native banner is drawn over the Godot surface. Reserve space only
	# after it actually loads so a no-fill response never leaves a blank strip.
	_content_margin.add_theme_constant_override("margin_bottom", 270 if visible else 120)

func _format_chip(value: int) -> String:
	return "%dK" % (value / 1000)

func _on_bowl_tapped() -> void:
	if _animating or room.mode != "host":
		return
	match room.state.get("phase", ""):
		"locked":
			if not room.roll():
				_status.text = "Chờ tất cả máy con xác nhận cược."
		"settled":
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
