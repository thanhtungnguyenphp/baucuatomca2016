extends Control

const MASCOT_CARD_SCENE := preload("res://scenes/components/MascotCard.tscn")
const BOWL_SCENE := preload("res://scenes/components/Bowl.tscn")
const LUCKY_BURST_SCENE := preload("res://scenes/components/LuckyBurst.tscn")
const SPRING_BACKGROUND := preload("res://assets/art/spring-lucky-background.png")
const DealerPartyMatchScript := preload("res://scripts/core/dealer_party_match.gd")
const PartyNearbyAdapterV2Script := preload("res://scripts/core/party_nearby_adapter_v2.gd")

var room = PartyNearbyAdapterV2Script.new()
var _rooms_box: VBoxContainer
var _rooms_caption: Label
var _lobby: VBoxContainer
var _setup_panel: VBoxContainer
var _seats_panel: PanelContainer
var _waiting_panel: PanelContainer
var _host_identity: Label
var _waiting_indicator: Label
var _waiting_hint: Label
var _search_loading_label: Label
var _waiting_frame := 0
var _join_buttons: Array[Button] = []
var _board: VBoxContainer
var _name_edit: LineEdit
var _status: Label
var _room_label: Label
var _role_label: Label
var _players_label: Label
var _lobby_slots: Array[Label] = []
var _scores_label: Label
var _countdown_label: Label
var _instruction: Label
var _action: Button
var _board_note: Label
var _client_panel: PanelContainer
var _client_controls: VBoxContainer
var _client_balance: Label
var _chip_selector_button: Button
var _chip_picker_overlay: ColorRect
var _chip_picker_sheet: PanelContainer
var _chip_picker_balance: Label
var _bet_actions: HBoxContainer
var _clear_bets_button: Button
var _confirm_bets_button: Button
var _reward_button: Button
var _content_margin: MarginContainer
var _bowl: BowlPresenter
var _cards: Dictionary = {}
var _chip_buttons: Dictionary = {}
var _verify_dialog: ConfirmationDialog
var _pending_endpoint := ""
var _pairing_queue: Array[Dictionary] = []
var _start_button: Button
var _start_dialog: ConfirmationDialog
var _shown_phase := ""
var _animating := false
var _selected_chip := 10_000
var _pending_reward_id := ""
var _round_feedback: PanelContainer
var _round_feedback_label: Label
var _round_feedback_tween: Tween
var _lucky_burst: LuckyBurst
var _feedback_round_key := ""

func _enter_tree() -> void:
	get_tree().quit_on_go_back = false

func _ready() -> void:
	get_window().go_back_requested.connect(func() -> void: call_deferred("_go_back"))
	AdPlacement.set_banner_allowed(false)
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
		if is_instance_valid(_chip_picker_overlay) and _chip_picker_overlay.visible:
			_close_chip_picker()
			return
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
	var back := _button("‹ VỀ", 27, 170, 80)
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
	_setup_panel = VBoxContainer.new()
	_setup_panel.add_theme_constant_override("separation", 18)
	_lobby.add_child(_setup_panel)
	var name_caption := _label("Tên hiển thị trong phòng", 29, Color("fff1d0"))
	_setup_panel.add_child(name_caption)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Nhập tên của bạn"
	_name_edit.text = GameSettings.player_name
	_name_edit.max_length = 24
	_name_edit.custom_minimum_size.y = 96
	_name_edit.add_theme_font_size_override("font_size", 30)
	_name_edit.text_submitted.connect(func(_value: String) -> void: _commit_player_name())
	_name_edit.focus_exited.connect(_commit_player_name)
	_setup_panel.add_child(_name_edit)
	var name_note := _label("Tên được lưu trên thiết bị và hiển thị cùng cược, kết quả, bảng xếp hạng.", 24, Color("d9c8ae"))
	_setup_panel.add_child(name_note)
	var steps := _label("1  NHẬP TÊN   →   2  TẠO / TÌM PHÒNG   →   3  SO MÃ   →   4  CHỜ BẠN   →   5  BẮT ĐẦU", 23, Color("ffe18a"))
	steps.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_setup_panel.add_child(steps)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	_setup_panel.add_child(row)
	var create := _button("TẠO PHÒNG\nMÁY NÀY LẮC TÔ", 28, 0, 112, true)
	create.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create.pressed.connect(_create_room)
	row.add_child(create)
	var find := _button("TÌM PHÒNG\nTHAM GIA ĐẶT LỘC", 28, 0, 112)
	find.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	find.pressed.connect(_find_rooms)
	row.add_child(find)
	_rooms_caption = _label("CHỌN PHÒNG ĐỂ THAM GIA", 32, Color("ffe18a"))
	_lobby.add_child(_rooms_caption)
	_rooms_box = VBoxContainer.new()
	_rooms_box.add_theme_constant_override("separation", 12)
	_lobby.add_child(_rooms_box)
	_waiting_panel = PanelContainer.new()
	var waiting_style := StyleBoxFlat.new()
	waiting_style.bg_color = Color("260912")
	waiting_style.border_color = Color("ffe39a")
	waiting_style.set_border_width_all(3)
	waiting_style.set_corner_radius_all(24)
	waiting_style.set_content_margin_all(22)
	_waiting_panel.add_theme_stylebox_override("panel", waiting_style)
	_lobby.add_child(_waiting_panel)
	var waiting_box := VBoxContainer.new()
	waiting_box.add_theme_constant_override("separation", 14)
	_waiting_panel.add_child(waiting_box)
	var host_card := PanelContainer.new()
	var host_style := StyleBoxFlat.new()
	host_style.bg_color = Color("5a1c24")
	host_style.border_color = Color("ffd86a")
	host_style.set_border_width_all(3)
	host_style.set_corner_radius_all(20)
	host_style.set_content_margin_all(18)
	host_card.add_theme_stylebox_override("panel", host_style)
	host_card.custom_minimum_size.y = 150
	waiting_box.add_child(host_card)
	_host_identity = _label("", 31, Color("fff1d0"))
	_host_identity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_host_identity.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	host_card.add_child(_host_identity)
	_waiting_indicator = _label("●  ○  ○   ĐANG CHỜ KẾT NỐI", 27, Color("ffe18a"))
	_waiting_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	waiting_box.add_child(_waiting_indicator)
	_players_label = _label("", 29, Color("bdf0be"))
	_players_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	waiting_box.add_child(_players_label)
	_seats_panel = PanelContainer.new()
	var seats_style := StyleBoxFlat.new()
	seats_style.bg_color = Color("2b0a15")
	seats_style.border_color = Color("a8763c")
	seats_style.set_border_width_all(2)
	seats_style.set_corner_radius_all(18)
	seats_style.set_content_margin_all(18)
	_seats_panel.add_theme_stylebox_override("panel", seats_style)
	waiting_box.add_child(_seats_panel)
	var seats_box := GridContainer.new()
	seats_box.columns = 2
	seats_box.add_theme_constant_override("h_separation", 12)
	seats_box.add_theme_constant_override("v_separation", 12)
	_seats_panel.add_child(seats_box)
	for seat in range(1, PartyNearbyAdapterV2Script.MAX_CLIENTS + 1):
		var slot := PanelContainer.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.custom_minimum_size.y = 82
		var slot_style := StyleBoxFlat.new()
		slot_style.bg_color = Color("35101a")
		slot_style.border_color = Color("765040")
		slot_style.set_border_width_all(2)
		slot_style.set_corner_radius_all(14)
		slot_style.set_content_margin_all(10)
		slot.add_theme_stylebox_override("panel", slot_style)
		seats_box.add_child(slot)
		var seat_label := _label("VỊ TRÍ %d\nĐANG CHỜ" % seat, 24, Color("d9c8ae"))
		seat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		seat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(seat_label)
		_lobby_slots.append(seat_label)
	_waiting_hint = _label("", 25, Color("d9c8ae"))
	_waiting_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	waiting_box.add_child(_waiting_hint)
	_start_button = _button("BẮT ĐẦU", 31, 0, 104, true)
	_start_button.name = "StartButton"
	_start_button.pressed.connect(_request_start_match)
	_lobby.add_child(_start_button)
	var lobby_note := _label("Phòng dùng kết nối thiết bị ở gần (Bluetooth + Wi-Fi), không cần Internet. 1 chủ bàn lắc tô, 1–5 máy con đặt Lộc.", 26, Color("ffe0a5"))
	lobby_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lobby.add_child(lobby_note)
	_board = VBoxContainer.new()
	_board.add_theme_constant_override("separation", 14)
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_board)
	_scores_label = _label("", 29, Color("bdf0be"))
	_scores_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_board.add_child(_scores_label)
	_countdown_label = _label("", 36, Color("bdf0be"))
	_countdown_label.name = "BettingCountdown"
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.custom_minimum_size.y = 48
	_board.add_child(_countdown_label)
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
	_client_panel = PanelContainer.new()
	var client_style := StyleBoxFlat.new()
	client_style.bg_color = Color("260912")
	client_style.border_color = Color("c99b51")
	client_style.set_border_width_all(2)
	client_style.set_corner_radius_all(20)
	client_style.set_content_margin_all(16)
	_client_panel.add_theme_stylebox_override("panel", client_style)
	_board.add_child(_client_panel)
	_client_controls = VBoxContainer.new()
	_client_controls.add_theme_constant_override("separation", 10)
	_client_panel.add_child(_client_controls)
	_client_balance = _label("", 28, Color("ffe18a"))
	_client_balance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_client_controls.add_child(_client_balance)
	_chip_selector_button = _button("●  MỆNH GIÁ: 10K   ▼", 30, 0, 104, true)
	_chip_selector_button.pressed.connect(_open_chip_picker)
	_client_controls.add_child(_chip_selector_button)
	_bet_actions = HBoxContainer.new()
	_bet_actions.add_theme_constant_override("separation", 18)
	_client_controls.add_child(_bet_actions)
	_clear_bets_button = _button("XÓA TẤT CẢ", 30, 0, 120)
	_clear_bets_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clear_bets_button.size_flags_stretch_ratio = 0.35
	_clear_bets_button.pressed.connect(_clear_bets)
	_bet_actions.add_child(_clear_bets_button)
	_confirm_bets_button = _button("XÁC NHẬN", 32, 0, 120, true)
	_confirm_bets_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm_bets_button.size_flags_stretch_ratio = 0.65
	_confirm_bets_button.pressed.connect(_confirm_bets)
	_bet_actions.add_child(_confirm_bets_button)
	_reward_button = _button("XEM VIDEO · NHẬN 200K LỘC", 30, 0, 112, true)
	_reward_button.pressed.connect(_watch_rewarded)
	_client_controls.add_child(_reward_button)
	_action = _button("", 31, 0, 88, true)
	_action.pressed.connect(_on_bowl_tapped)
	_board.add_child(_action)
	_board_note = _label("Chủ phòng chỉ lắc, mở và đậy tô · Kết quả và trả thưởng đồng bộ đến mọi máy", 26, Color("ffe0a5"))
	_board_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_board.add_child(_board_note)
	_build_round_feedback()
	_build_chip_picker()
	_verify_dialog = ConfirmationDialog.new()
	_verify_dialog.title = "SO MÃ KẾT NỐI"
	_verify_dialog.ok_button_text = "MÃ GIỐNG NHAU\nKẾT NỐI"
	_verify_dialog.cancel_button_text = "MÃ KHÁC NHAU\nTỪ CHỐI"
	_verify_dialog.min_size = Vector2i(980, 650)
	_verify_dialog.exclusive = true
	_verify_dialog.unresizable = true
	var dialog_style := StyleBoxFlat.new()
	dialog_style.bg_color = Color("1b0410")
	dialog_style.border_color = Color("ffe39a")
	dialog_style.set_border_width_all(3)
	dialog_style.set_corner_radius_all(20)
	dialog_style.set_content_margin_all(36)
	_verify_dialog.add_theme_stylebox_override("panel", dialog_style)
	_verify_dialog.add_theme_font_size_override("title_font_size", 32)
	_verify_dialog.get_label().add_theme_font_size_override("font_size", 36)
	_verify_dialog.get_label().add_theme_color_override("font_color", Color("fff1d0"))
	_verify_dialog.get_label().horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_verify_dialog.get_label().vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_verify_dialog.get_label().custom_minimum_size.y = 350
	add_child(_verify_dialog)
	_style_dialog_actions(_verify_dialog, true)
	_verify_dialog.confirmed.connect(_accept_pairing)
	_verify_dialog.canceled.connect(_reject_pairing)
	_start_dialog = ConfirmationDialog.new()
	_start_dialog.title = "BẮT ĐẦU PHÒNG"
	_start_dialog.ok_button_text = "BẮT ĐẦU NGAY"
	_start_dialog.cancel_button_text = "CHỜ THÊM BẠN"
	_start_dialog.min_size = Vector2i(940, 520)
	_start_dialog.exclusive = true
	_start_dialog.unresizable = true
	_start_dialog.add_theme_stylebox_override("panel", dialog_style.duplicate())
	_start_dialog.add_theme_font_size_override("title_font_size", 32)
	_start_dialog.get_label().add_theme_font_size_override("font_size", 32)
	_start_dialog.get_label().add_theme_color_override("font_color", Color("fff1d0"))
	_start_dialog.get_label().horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_start_dialog.get_label().custom_minimum_size.y = 230
	add_child(_start_dialog)
	_style_dialog_actions(_start_dialog, true)
	_start_dialog.confirmed.connect(_start_match_now)
	var waiting_timer := Timer.new()
	waiting_timer.wait_time = 0.45
	waiting_timer.autostart = true
	waiting_timer.timeout.connect(_tick_waiting)
	add_child(waiting_timer)

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

func _style_dialog_actions(dialog: ConfirmationDialog, confirm_positive: bool) -> void:
	var ok := dialog.get_ok_button()
	var cancel := dialog.get_cancel_button()
	for button: Button in [ok, cancel]:
		button.custom_minimum_size = Vector2(410, 112)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 28)
	var actions := ok.get_parent()
	if actions is BoxContainer:
		(actions as BoxContainer).add_theme_constant_override("separation", 28)
	_style_dialog_button(ok, Color("267044") if confirm_positive else Color("a34424"), Color("ffe39a"))
	_style_dialog_button(cancel, Color("651d29"), Color("e59a92"))

func _style_dialog_button(button: Button, background: Color, border: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = background
	normal.border_color = border
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(18)
	normal.content_margin_left = 64
	normal.content_margin_right = 64
	normal.content_margin_top = 24
	normal.content_margin_bottom = 24
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_color_override("font_color", Color("fff7d4"))

func _build_chip_picker() -> void:
	_chip_picker_overlay = ColorRect.new()
	_chip_picker_overlay.color = Color(0.03, 0.0, 0.01, 0.78)
	_chip_picker_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_chip_picker_overlay.z_index = 80
	_chip_picker_overlay.visible = false
	add_child(_chip_picker_overlay)
	_chip_picker_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chip_picker_sheet = PanelContainer.new()
	var sheet_style := StyleBoxFlat.new()
	sheet_style.bg_color = Color("210810")
	sheet_style.border_color = Color("ffe39a")
	sheet_style.set_border_width_all(3)
	sheet_style.set_corner_radius_all(24)
	sheet_style.set_content_margin_all(26)
	sheet_style.shadow_color = Color(0, 0, 0, 0.65)
	sheet_style.shadow_size = 24
	_chip_picker_sheet.add_theme_stylebox_override("panel", sheet_style)
	_chip_picker_overlay.add_child(_chip_picker_sheet)
	_chip_picker_sheet.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_chip_picker_sheet.offset_left = -502
	_chip_picker_sheet.offset_right = 502
	_chip_picker_sheet.offset_top = -720
	_chip_picker_sheet.offset_bottom = -120
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	_chip_picker_sheet.add_child(content)
	var title := _label("CHỌN MỆNH GIÁ", 38, Color("ffe18a"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	_chip_picker_balance = _label("", 27, Color("bdf0be"))
	_chip_picker_balance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_chip_picker_balance)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	content.add_child(grid)
	for value in GameConstants.CHIP_VALUES:
		var chip := _button(_format_chip(value), 32, 0, 112, value == _selected_chip)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.pressed.connect(_select_chip.bind(value))
		grid.add_child(chip)
		_chip_buttons[value] = chip
	var close := _button("ĐÓNG", 29, 0, 92)
	close.pressed.connect(_close_chip_picker)
	content.add_child(close)

func _open_chip_picker() -> void:
	if _chip_selector_button.disabled:
		return
	GameSettings.tap_feedback()
	_chip_picker_overlay.visible = true
	_refresh()

func _close_chip_picker() -> void:
	_chip_picker_overlay.visible = false

func _style_chip_choice(button: Button, selected: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("a34424") if selected else Color("42131d")
	normal.border_color = Color("ffe36b") if selected else Color("a8763c")
	normal.set_border_width_all(4 if selected else 2)
	normal.set_corner_radius_all(18)
	normal.set_content_margin_all(12)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("302027")
	disabled.border_color = Color("6f5a50")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_stylebox_override("disabled", disabled)

func _build_round_feedback() -> void:
	_lucky_burst = LUCKY_BURST_SCENE.instantiate()
	add_child(_lucky_burst)
	_lucky_burst.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_round_feedback = PanelContainer.new()
	_round_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_round_feedback.z_index = 20
	_round_feedback.visible = false
	_round_feedback.modulate.a = 0.0
	_round_feedback.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_round_feedback.offset_left = -455.0
	_round_feedback.offset_top = 300.0
	_round_feedback.offset_right = 455.0
	_round_feedback.offset_bottom = 450.0
	add_child(_round_feedback)
	_round_feedback_label = _label("", 38, Color("fff4c2"))
	_round_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_round_feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_round_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_round_feedback.add_child(_round_feedback_label)

func _style_round_feedback(win: bool, draw: bool = false) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("163d25") if win else Color("563019") if draw else Color("4a1820")
	style.border_color = Color("ffe36b") if win else Color("efc47c") if draw else Color("e58b86")
	style.set_border_width_all(4)
	style.set_corner_radius_all(24)
	style.set_content_margin_all(24)
	style.shadow_color = Color(0, 0, 0, 0.58)
	style.shadow_size = 20
	_round_feedback.add_theme_stylebox_override("panel", style)

func _commit_player_name() -> String:
	var clean := GameSettings.set_player_name(_name_edit.text)
	_name_edit.text = clean
	return clean

func _create_room() -> void:
	room.create_room(_commit_player_name())

func _find_rooms() -> void:
	room.find_rooms(_commit_player_name())

func _refresh_rooms() -> void:
	if not is_instance_valid(_rooms_box):
		return
	_join_buttons.clear()
	_search_loading_label = null
	for child in _rooms_box.get_children():
		child.queue_free()
	if room.rooms.is_empty():
		var empty := _label("ĐANG TÌM PHÒNG…\nBật Bluetooth và Wi-Fi, đặt các thiết bị gần nhau.", 28, Color("fff1d0"))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.custom_minimum_size.y = 110
		_rooms_box.add_child(empty)
		_search_loading_label = empty
		return
	for endpoint: String in room.rooms:
		var card := PanelContainer.new()
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color("35101a")
		card_style.border_color = Color("c99b51")
		card_style.set_border_width_all(2)
		card_style.set_corner_radius_all(18)
		card_style.set_content_margin_all(16)
		card.add_theme_stylebox_override("panel", card_style)
		_rooms_box.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 18)
		card.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 4)
		row.add_child(info)
		var room_name := _label(str(room.rooms[endpoint]), 30, Color("fff1d0"))
		room_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		info.add_child(room_name)
		info.add_child(_label("Chủ bàn ở gần · chạm nút để tham gia", 23, Color("d9c8ae")))
		var button := _button("THAM GIA", 28, 250, 104, true)
		button.disabled = not room.host_endpoint.is_empty()
		button.pressed.connect(_join_room.bind(endpoint, button))
		row.add_child(button)
		_join_buttons.append(button)

func _join_room(endpoint: String, selected: Button) -> void:
	for button: Button in _join_buttons:
		button.disabled = true
	selected.text = "ĐANG KẾT NỐI…"
	_status.text = "Đang gửi yêu cầu tham gia. Chuẩn bị so mã trên cả hai thiết bị."
	GameSettings.tap_feedback()
	room.join_room(endpoint)

func _refresh() -> void:
	if not is_instance_valid(_lobby):
		return
	var active: bool = not room.state.is_empty()
	_countdown_label.visible = false
	_name_edit.editable = room.mode == "idle"
	_lobby.visible = not active
	_board.visible = active
	_setup_panel.visible = room.mode == "idle"
	var searching_room: bool = room.mode == "guest" and room.local_seat < 0
	var showing_lobby_seats: bool = room.mode == "host" or (room.mode == "guest" and room.local_seat >= 0)
	_rooms_caption.visible = searching_room
	_rooms_box.visible = _rooms_caption.visible
	_waiting_panel.visible = showing_lobby_seats
	_room_label.text = "PHÒNG %s · 1 CHỦ + %d/%d NGƯỜI CHƠI" % [room.room_id, room.players.size(), PartyNearbyAdapterV2Script.MAX_CLIENTS] if not room.room_id.is_empty() else ""
	var role_name: String = str(room.local_name)
	var known_local := room.get_local_player()
	if not known_local.is_empty():
		role_name = str(known_local.get("name", role_name))
	if role_name.is_empty():
		role_name = "Chủ bàn" if room.mode == "host" else "Người chơi"
	_role_label.text = "BẠN LÀ CHỦ PHÒNG" if room.mode == "host" else "BẠN · %s · ĐÃ THAM GIA" % role_name if room.mode == "guest" and room.local_seat >= 0 else ""
	var visible_host_name: String = room.host_name if not room.host_name.is_empty() else room.local_name
	_host_identity.text = "CHỦ BÀN · NGƯỜI LẮC\n%s\nĐANG MỞ PHÒNG" % visible_host_name.to_upper() if showing_lobby_seats else ""
	if room.mode == "host":
		_players_label.text = "%d/%d NGƯỜI CHƠI ĐÃ THAM GIA" % [room.players.size(), PartyNearbyAdapterV2Script.MAX_CLIENTS]
		_waiting_hint.text = "Tiếp tục chờ thêm bạn, hoặc bấm BẮT ĐẦU khi đã sẵn sàng."
	elif room.mode == "guest":
		_players_label.text = "%d/%d NGƯỜI CHƠI ĐÃ THAM GIA" % [room.players.size(), PartyNearbyAdapterV2Script.MAX_CLIENTS] if room.local_seat >= 0 else "ĐANG TÌM HOẶC KẾT NỐI PHÒNG…"
		_waiting_hint.text = "Bạn đã vào phòng · Chờ chủ bàn bắt đầu trận."
	else:
		_players_label.text = ""
		_waiting_hint.text = ""
	for index in _lobby_slots.size():
		var occupied: bool = index < room.players.size()
		var is_you: bool = room.mode == "guest" and room.local_seat == index + 1
		_lobby_slots[index].text = "%sVỊ TRÍ %d\n%s\nĐÃ SẴN SÀNG" % ["BẠN · " if is_you else "", index + 1, room.players[index]] if occupied else "VỊ TRÍ %d\nĐANG CHỜ" % (index + 1)
		_lobby_slots[index].add_theme_color_override("font_color", Color("bdf0be") if occupied else Color("d9c8ae"))
	_start_button.visible = room.mode == "host"
	_start_button.disabled = room.players.is_empty() or room.players.size() > PartyNearbyAdapterV2Script.MAX_CLIENTS
	if room.players.size() >= PartyNearbyAdapterV2Script.MAX_CLIENTS:
		_start_button.text = "ĐỦ PHÒNG · BẮT ĐẦU 5 LƯỢT"
	elif not room.players.is_empty():
		_start_button.text = "BẮT ĐẦU VỚI %d BẠN" % room.players.size()
	else:
		_start_button.text = "CHỜ ÍT NHẤT 1 MÁY CON"
	_refresh_rooms()
	if not active:
		if room.mode == "guest" and room.local_seat >= 0:
			_status.text = "Đã vào phòng. Chờ chủ bàn và các bạn khác cùng kết nối."
		elif room.mode == "host" and not room.players.is_empty():
			_status.text = "Đã nhận người chơi mới. Phòng vẫn mở để chờ thêm bạn."
		_shown_phase = ""
		return
	_status.text = "Bạn là chủ phòng: theo dõi cược và điều khiển tô." if room.mode == "host" else "Đặt Lộc, xác nhận rồi chờ chủ phòng lắc tô."
	var phase: String = str(room.state.get("phase", ""))
	var turn: int = int(room.state.get("round_number", 1))
	var betting_seconds_left: int = int(room.state.get("betting_seconds_left", 0))
	_countdown_label.visible = phase == "betting"
	if _countdown_label.visible:
		_countdown_label.text = "⏱  CÒN %02d GIÂY ĐỂ ĐẶT CƯỢC" % betting_seconds_left
		_countdown_label.add_theme_color_override("font_color", Color("ff7b65") if betting_seconds_left <= 5 else Color("ffe18a") if betting_seconds_left <= 10 else Color("bdf0be"))
	var match_players: Array = room.state.get("players", [])
	var status_parts: Array[String] = []
	if phase == "settled" or phase == "finished":
		for row: Dictionary in room.state.get("leaderboard", []):
			var round_net := int(row.get("round_net", 0))
			var outcome := "THẮNG" if round_net > 0 else "HÒA" if round_net == 0 else "THUA"
			var you := "BẠN · " if row.get("player_id", "") == room.local_player_id else ""
			status_parts.append("%d. %s%s · %s %s · Tổng %s" % [
				int(row.get("rank", 0)),
				you,
				row.get("name", "Người chơi"),
				outcome,
				GameConstants.format_signed_luck(round_net),
				GameConstants.format_signed_luck(int(row.get("total_net", 0))),
			])
	else:
		for player: Dictionary in match_players:
			var state_text := "KHÁN GIẢ" if player.get("spectator", false) else "ĐÃ CHỐT" if player.get("ready", false) else "ĐANG ĐẶT"
			var you := "BẠN · " if player.get("player_id", "") == room.local_player_id else ""
			status_parts.append("%s%s · %s · %s" % [you, player.get("name", "Người chơi"), GameConstants.format_luck(int(player.get("balance", 0))), state_text])
	_scores_label.text = "\n".join(status_parts)
	var is_host: bool = room.mode == "host"
	_bowl.custom_minimum_size.y = 430 if is_host else 260
	for card: MascotCard in _cards.values():
		card.custom_minimum_size.y = 205 if is_host else 170
	_board_note.visible = is_host
	var local_player: Dictionary = room.get_local_player()
	var local_ready := bool(local_player.get("ready", false))
	var local_spectator := bool(local_player.get("spectator", false))
	if not _pending_reward_id.is_empty() and not local_player.is_empty() and not local_spectator:
		_pending_reward_id = ""
	var local_total_bet := 0
	for amount: Variant in local_player.get("bets", {}).values():
		local_total_bet += int(amount)
	var can_edit_bets := not is_host and phase == "betting" and betting_seconds_left > 0 and not local_ready and not local_spectator and not _animating
	_client_panel.visible = not is_host
	_client_controls.visible = not is_host
	_action.visible = is_host
	if phase == "settled":
		var local_outcome := "THẮNG" if int(local_player.get("round_net", 0)) > 0 else "HÒA" if int(local_player.get("round_net", 0)) == 0 else "THUA"
		_client_balance.text = "%s · NHẬN %s · LƯỢT NÀY %s · SỐ DƯ %s" % [
			local_outcome,
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
	var show_bet_editor: bool = not is_host and phase == "betting" and not local_ready and not local_spectator
	var show_ready_action: bool = not is_host and local_ready and (phase == "betting" or phase == "locked")
	_chip_selector_button.visible = show_bet_editor
	_chip_selector_button.disabled = not can_edit_bets
	_chip_selector_button.text = "●  MỆNH GIÁ: %s   ▼" % _format_chip(_selected_chip)
	_bet_actions.visible = show_bet_editor or show_ready_action
	_clear_bets_button.visible = show_bet_editor
	_clear_bets_button.disabled = not can_edit_bets or local_total_bet <= 0
	_confirm_bets_button.disabled = show_ready_action or not can_edit_bets or local_total_bet <= 0
	_confirm_bets_button.text = "ĐÃ CHỐT · CHỜ CHỦ BÀN" if show_ready_action else "CHỌN CỬA ĐỂ ĐẶT" if local_total_bet <= 0 else "XÁC NHẬN · %s" % _format_chip(local_total_bet)
	_reward_button.visible = local_spectator
	_reward_button.disabled = not AdPlacement.is_rewarded_ready() or not _pending_reward_id.is_empty()
	_reward_button.text = "XEM VIDEO · NHẬN 200K LỘC" if AdPlacement.is_rewarded_ready() else "ĐANG TẢI VIDEO THƯỞNG…"
	var remaining_balance: int = maxi(0, int(local_player.get("balance", 0)) - local_total_bet)
	_chip_picker_balance.text = "CÒN CÓ THỂ ĐẶT: %s" % GameConstants.format_luck(remaining_balance)
	if _chip_picker_overlay.visible and not show_bet_editor:
		_chip_picker_overlay.visible = false
	for value in GameConstants.CHIP_VALUES:
		var chip: Button = _chip_buttons[value]
		chip.text = ("✓ " if value == _selected_chip else "") + _format_chip(value)
		chip.disabled = not can_edit_bets or value > remaining_balance
		_style_chip_choice(chip, value == _selected_chip)
	match phase:
		"betting":
			if is_host:
				_instruction.text = "Lượt %d/5 · Máy con đang đặt · Hết giờ sẽ tự chốt" % turn
			else:
				_instruction.text = "Lượt %d/5 · %s" % [turn, "Hết Lộc · Bạn đang xem với vai trò khán giả" if local_spectator else "Đã chốt cược · Chờ người còn lại" if local_ready else "Chọn chip, đặt lên linh vật rồi xác nhận trước khi hết giờ"]
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
		var total_on_symbol := 0
		for player: Dictionary in match_players:
			var amount := int(player.get("bets", {}).get(symbol, 0))
			if amount > 0:
				total_on_symbol += amount
				owners.append("%s %s" % [player.get("name", "Người chơi"), GameConstants.format_luck(amount)])
		var card: MascotCard = _cards[symbol]
		var bet_caption := (" · ".join(owners) if owners.size() <= 2 else "%d NGƯỜI · TỔNG %s" % [owners.size(), GameConstants.format_luck(total_on_symbol)]) if not owners.is_empty() else "CHƯA CÓ CƯỢC"
		var caption := bet_caption
		if phase == "settled" or phase == "finished":
			var hit_count: int = room.state.get("results", []).count(symbol)
			var result_caption := "TRÚNG ×%d" % hit_count if hit_count > 0 else "KHÔNG TRÚNG"
			caption = result_caption + (" · " + bet_caption if not owners.is_empty() else "")
		card.set_party_state(caption, not owners.is_empty())
		card.disabled = is_host or phase != "betting" or betting_seconds_left <= 0 or local_ready or local_spectator or _animating
	if phase != _shown_phase:
		if phase == "betting" or phase == "locked":
			_reset_result_feedback()
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
		_play_result_feedback(results)
	_animating = false
	_refresh()

func _play_result_feedback(results: Array) -> void:
	var local_player := room.get_local_player()
	var local_bets: Dictionary = local_player.get("bets", {})
	for symbol in GameConstants.SYMBOLS:
		var occurrences := results.count(symbol)
		var emphasized := int(local_bets.get(symbol, 0)) > 0
		(_cards[symbol] as MascotCard).play_result(occurrences > 0, occurrences, emphasized)

	var round_key := "%s:%d" % [room.room_id, int(room.state.get("round_number", 0))]
	if round_key == _feedback_round_key:
		return
	_feedback_round_key = round_key
	if room.mode == "host":
		var outcomes: Array[String] = []
		for player: Dictionary in room.state.get("players", []):
			var net := int(player.get("round_net", 0))
			var word := "thắng" if net > 0 else "hòa" if net == 0 else "thua"
			outcomes.append("%s %s %s" % [player.get("name", "Người chơi"), word, GameConstants.format_signed_luck(net)])
		_show_round_feedback("KẾT QUẢ ĐÃ ĐỒNG BỘ\n" + "  ·  ".join(outcomes), true, true)
		return
	if local_player.is_empty():
		return
	var local_name := str(local_player.get("name", "Bạn"))
	var local_net := int(local_player.get("round_net", 0))
	if local_net > 0:
		GameSettings.reward_feedback()
		AudioDirector.play(NativeAudioDirector.Cue.WIN)
		_lucky_burst.play_at(_bowl.get_global_rect().get_center())
		_show_round_feedback("%s THẮNG!\n%s" % [local_name.to_upper(), GameConstants.format_signed_luck(local_net)], true)
	elif local_net < 0:
		GameSettings.loss_feedback()
		AudioDirector.play(NativeAudioDirector.Cue.LOSE)
		_show_round_feedback("%s CHƯA GẶP LỘC\n%s" % [local_name.to_upper(), GameConstants.format_signed_luck(local_net)], false)
	else:
		GameSettings.tap_feedback()
		_show_round_feedback("%s HÒA VỐN\n%s" % [local_name.to_upper(), GameConstants.format_signed_luck(local_net)], false, true)

func _show_round_feedback(message: String, win: bool, draw: bool = false) -> void:
	if _round_feedback_tween != null and _round_feedback_tween.is_valid():
		_round_feedback_tween.kill()
	_style_round_feedback(win, draw)
	_round_feedback_label.text = message
	_round_feedback_label.add_theme_font_size_override("font_size", 30 if message.length() > 90 else 34 if message.length() > 55 else 38)
	_round_feedback.visible = true
	_round_feedback.modulate.a = 0.0
	_round_feedback.scale = Vector2(0.94, 0.94)
	_round_feedback.pivot_offset = _round_feedback.size * 0.5
	_round_feedback_tween = create_tween()
	_round_feedback_tween.set_parallel(true)
	_round_feedback_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_round_feedback_tween.tween_property(_round_feedback, "modulate:a", 1.0, GameSettings.animation_duration(0.22))
	_round_feedback_tween.tween_property(_round_feedback, "scale", Vector2.ONE, GameSettings.animation_duration(0.26))
	_round_feedback_tween.set_parallel(false)
	_round_feedback_tween.tween_interval(GameSettings.animation_duration(1.55))
	_round_feedback_tween.tween_property(_round_feedback, "modulate:a", 0.0, GameSettings.animation_duration(0.24))
	_round_feedback_tween.tween_callback(_round_feedback.hide)

func _reset_result_feedback() -> void:
	_feedback_round_key = ""
	if _round_feedback_tween != null and _round_feedback_tween.is_valid():
		_round_feedback_tween.kill()
	if is_instance_valid(_round_feedback):
		_round_feedback.hide()
		_round_feedback.modulate.a = 0.0
	for card: MascotCard in _cards.values():
		card.reset_result_state()

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
	_close_chip_picker()
	_refresh()
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
	if is_instance_valid(_chip_picker_sheet):
		_chip_picker_sheet.offset_top = -870 if visible else -720
		_chip_picker_sheet.offset_bottom = -270 if visible else -120

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

func _request_start_match() -> void:
	if room.players.is_empty():
		_status.text = "Cần ít nhất 1 máy con trong phòng để bắt đầu."
		return
	if room.players.size() < PartyNearbyAdapterV2Script.MAX_CLIENTS:
		_start_dialog.dialog_text = "Hiện có %d/%d máy con.\n\nBạn có thể bắt đầu ngay, hoặc tiếp tục chờ để mọi người cùng vào phòng." % [room.players.size(), PartyNearbyAdapterV2Script.MAX_CLIENTS]
		_start_dialog.popup_centered()
		return
	_start_match_now()

func _start_match_now() -> void:
	if not room.start_match():
		_status.text = "Không thể bắt đầu. Hãy kiểm tra lại các máy đã kết nối."

func _on_verification_needed(id: String, name: String, digits: String) -> void:
	if id == _pending_endpoint:
		return
	for request: Dictionary in _pairing_queue:
		if request.get("id", "") == id:
			return
	_pairing_queue.append({"id": id, "name": name, "digits": digits})
	_show_next_pairing()

func _show_next_pairing() -> void:
	if not _pending_endpoint.is_empty() or _pairing_queue.is_empty():
		return
	var request: Dictionary = _pairing_queue.pop_front()
	_pending_endpoint = str(request.get("id", ""))
	_verify_dialog.dialog_text = "ĐỐI CHIẾU TRÊN CẢ HAI THIẾT BỊ\n\n%s\n\nThiết bị: %s\n\nChỉ bấm KẾT NỐI khi hai mã hoàn toàn giống nhau." % [_format_auth_code(str(request.get("digits", ""))), request.get("name", "Người chơi")]
	_verify_dialog.popup_centered()

func _format_auth_code(digits: String) -> String:
	var parts: PackedStringArray = []
	for index in digits.length():
		parts.append(digits.substr(index, 1))
	return "   ".join(parts)

func _tick_waiting() -> void:
	_waiting_frame = (_waiting_frame + 1) % 3
	var pulse: Array[String] = ["●  ○  ○", "○  ●  ○", "○  ○  ●"]
	if is_instance_valid(_waiting_indicator):
		_waiting_indicator.text = "%s   ĐANG CHỜ KẾT NỐI" % pulse[_waiting_frame]
	if is_instance_valid(_search_loading_label):
		_search_loading_label.text = "%s   ĐANG TÌM PHÒNG…\nBật Bluetooth và Wi-Fi, đặt các thiết bị gần nhau." % pulse[_waiting_frame]

func _accept_pairing() -> void:
	if not _pending_endpoint.is_empty():
		var endpoint := _pending_endpoint
		_pending_endpoint = ""
		_verify_dialog.hide()
		GameSettings.tap_feedback()
		room.accept_pairing(endpoint)
		call_deferred("_show_next_pairing")

func _reject_pairing() -> void:
	if not _pending_endpoint.is_empty():
		var endpoint := _pending_endpoint
		_pending_endpoint = ""
		_verify_dialog.hide()
		GameSettings.tap_feedback()
		room.reject_pairing(endpoint)
		call_deferred("_show_next_pairing")

func _go_back() -> void:
	if is_instance_valid(_chip_picker_overlay) and _chip_picker_overlay.visible:
		_close_chip_picker()
		return
	if not _pending_endpoint.is_empty():
		_reject_pairing()
	for request: Dictionary in _pairing_queue:
		room.reject_pairing(str(request.get("id", "")))
	_pairing_queue.clear()
	room.leave()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
