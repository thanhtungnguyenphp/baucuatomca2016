extends Control

const MASCOT_CARD_SCENE := preload("res://scenes/components/MascotCard.tscn")
const SYMBOL_SHEET := preload("res://assets/art/bau-cua-symbol-sheet.png")

@onready var balance_label: Label = $SafeHeader/Stats/BalanceLabel
@onready var round_label: Label = $SafeHeader/Stats/RoundLabel
@onready var stake_label: Label = %StakeLabel
@onready var status_label: Label = %StatusLabel
@onready var results_label: Label = %ResultsLabel
@onready var mascot_grid: GridContainer = %MascotGrid
@onready var chip_grid: GridContainer = %ChipGrid
@onready var challenge_label: Label = %ChallengeLabel
@onready var bowl: BowlPresenter = %Bowl
@onready var lucky_burst: LuckyBurst = %LuckyBurst
@onready var settings_button: Button = $SafeHeader/Actions/SettingsButton
@onready var settings_popup: PopupPanel = %SettingsPopup
@onready var haptics_toggle: CheckButton = %HapticsToggle
@onready var sound_toggle: CheckButton = %SoundToggle
@onready var reduced_motion_toggle: CheckButton = %ReducedMotionToggle
@onready var rules_button: Button = $SafeHeader/Actions/RulesButton
@onready var history_button: Button = $SafeHeader/Actions/HistoryButton
@onready var rules_popup: PopupPanel = %RulesPopup
@onready var history_popup: PopupPanel = %HistoryPopup
@onready var history_label: Label = %HistoryLabel
@onready var onboarding_popup: PopupPanel = %OnboardingPopup
@onready var onboarding_start_button: Button = %OnboardingStartButton
@onready var reset_progress_button: Button = %ResetProgressButton
@onready var privacy_options_button: Button = %PrivacyOptionsButton
@onready var reset_dialog: ConfirmationDialog = %ResetDialog
@onready var settings_close_button: Button = %SettingsCloseButton
@onready var rules_close_button: Button = %RulesCloseButton
@onready var history_close_button: Button = %HistoryCloseButton

var mascot_buttons: Dictionary = {}
var chip_buttons: Dictionary = {}
var is_animating := false
var journey_button: Button
var journey_popup: PopupPanel
var daily_journey_label: Label
var weekly_journey_label: Label
var collection_cards: Dictionary = {}
var theme_buttons: Dictionary = {}

func _enter_tree() -> void:
	# Android decides whether to finish the Activity before dispatching Back to
	# the scene. Set this before the first frame, rather than when UI is ready.
	get_tree().quit_on_go_back = false

func _ready() -> void:
	get_window().go_back_requested.connect(_on_go_back_requested)
	_build_mascot_buttons()
	_build_chip_buttons()
	_build_journey_ui()
	_apply_portrait_layout()
	bowl.tapped.connect(_on_bowl_tapped)
	settings_button.pressed.connect(_show_settings)
	rules_button.pressed.connect(_show_rules)
	history_button.pressed.connect(_show_history)
	onboarding_start_button.pressed.connect(_finish_onboarding)
	reset_progress_button.pressed.connect(reset_dialog.popup_centered)
	privacy_options_button.pressed.connect(AdPlacement.show_privacy_options)
	AdPlacement.privacy_options_available.connect(func(available: bool) -> void:
		privacy_options_button.visible = available
	)
	AdPlacement.banner_visibility_changed.connect(_position_bottom_actions)
	_position_bottom_actions(AdPlacement.is_banner_visible())
	settings_close_button.pressed.connect(settings_popup.hide)
	rules_close_button.pressed.connect(rules_popup.hide)
	history_close_button.pressed.connect(history_popup.hide)
	reset_dialog.confirmed.connect(_reset_progress)
	haptics_toggle.toggled.connect(GameSettings.set_haptics_enabled)
	sound_toggle.toggled.connect(GameSettings.set_sound_enabled)
	reduced_motion_toggle.toggled.connect(GameSettings.set_reduce_motion)
	GameSession.session_changed.connect(_refresh)
	GameSession.round_resolved.connect(_on_round_resolved)
	EngagementProgress.progress_changed.connect(_on_journey_changed)
	haptics_toggle.button_pressed = GameSettings.haptics_enabled
	sound_toggle.button_pressed = GameSettings.sound_enabled
	reduced_motion_toggle.button_pressed = GameSettings.reduce_motion
	_configure_bottom_sheets()
	_on_journey_changed()
	_refresh()
	if not GameSettings.onboarding_seen:
		call_deferred("_show_onboarding")

func _apply_portrait_layout() -> void:
	var extra_height := maxf(0.0, get_viewport().get_visible_rect().size.y - 1920.0)
	var bowl_height := 360.0 + extra_height * 0.4
	var card_height := 185.0 + extra_height * 0.25
	bowl.custom_minimum_size.y = bowl_height
	for card: MascotCard in mascot_buttons.values():
		card.custom_minimum_size.y = card_height

func _pin_board_top() -> void:
	# The board no longer scrolls: this is intentionally a stable, glanceable
	# portrait composition, so focus changes cannot push the header off-screen.
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _hide_top_popup():
			get_viewport().set_input_as_handled()
		return
	if settings_popup.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_on_bowl_tapped()
		get_viewport().set_input_as_handled()

func _build_mascot_buttons() -> void:
	for symbol in GameConstants.SYMBOLS:
		var card: MascotCard = MASCOT_CARD_SCENE.instantiate()
		card.configure(symbol)
		card.pressed.connect(_place_bet.bind(symbol))
		mascot_grid.add_child(card)
		mascot_buttons[symbol] = card

func _build_chip_buttons() -> void:
	for value in GameConstants.CHIP_VALUES:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 70)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 31)
		button.text = _format_chip(value)
		button.pressed.connect(_select_chip.bind(value))
		chip_grid.add_child(button)
		chip_buttons[value] = button

func _build_journey_ui() -> void:
	journey_button = Button.new()
	journey_button.text = "HÀNH TRÌNH"
	journey_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journey_button.add_theme_font_size_override("font_size", 24)
	$SafeHeader/Actions.add_child(journey_button)
	$SafeHeader/Actions.move_child(journey_button, 1)
	journey_button.pressed.connect(_show_journey)

	journey_popup = PopupPanel.new()
	journey_popup.name = "JourneyPopup"
	add_child(journey_popup)
	var backdrop := ColorRect.new()
	backdrop.color = Color("1b0410")
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	journey_popup.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_top", 56)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_bottom", 56)
	journey_popup.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 24)
	margin.add_child(content)
	var title := Label.new()
	title.text = "HÀNH TRÌNH LỘC XUÂN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("ffe18a"))
	title.add_theme_font_size_override("font_size", 40)
	content.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 22)
	scroll.add_child(body)
	daily_journey_label = _journey_label(31, Color("fff1d0"))
	body.add_child(daily_journey_label)
	weekly_journey_label = _journey_label(28, Color("bdf0be"))
	body.add_child(weekly_journey_label)
	var collection_title := _journey_label(32, Color("ffe18a"))
	collection_title.text = "BỘ SƯU TẬP LINH VẬT"
	collection_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(collection_title)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	body.add_child(grid)
	for symbol in GameConstants.SYMBOLS:
		_add_collection_card(grid, symbol)
	var theme_title := _journey_label(30, Color("ffe18a"))
	theme_title.text = "GIAO DIỆN MỞ KHÓA"
	theme_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(theme_title)
	var theme_row := HBoxContainer.new()
	theme_row.add_theme_constant_override("separation", 10)
	body.add_child(theme_row)
	for theme in EngagementProgress.THEMES:
		var button := Button.new()
		button.custom_minimum_size.y = 68
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 23)
		button.pressed.connect(EngagementProgress.set_theme.bind(theme))
		theme_row.add_child(button)
		theme_buttons[theme] = button
	var party_button := Button.new()
	party_button.text = "CHƠI CÙNG BẠN · KHÔNG DÙNG LỘC"
	party_button.custom_minimum_size.y = 76
	party_button.add_theme_font_size_override("font_size", 27)
	party_button.pressed.connect(_show_party)
	_style_sheet_button(party_button)
	content.add_child(party_button)
	var close_button := Button.new()
	close_button.text = "ĐÓNG"
	close_button.custom_minimum_size.y = 82
	close_button.add_theme_font_size_override("font_size", 30)
	close_button.pressed.connect(journey_popup.hide)
	_style_sheet_button(close_button)
	content.add_child(close_button)

func _style_sheet_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("9a3d20")
	normal.border_color = Color("ffe59a")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(15)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_color_override("font_color", Color("fff7d4"))
	button.add_theme_color_override("font_disabled_color", Color("d3bda9"))

func _journey_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _add_collection_card(grid: GridContainer, symbol: String) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 230)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("48121b")
	style.border_color = Color("d3a447")
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	grid.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	var art := TextureRect.new()
	art.custom_minimum_size = Vector2(0, 155)
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var cell: Vector2i = MascotCard.SYMBOL_CELLS[symbol]
	var atlas := AtlasTexture.new()
	atlas.atlas = SYMBOL_SHEET
	atlas.filter_clip = true
	atlas.region = Rect2(cell.x * SYMBOL_SHEET.get_width() / 3.0, cell.y * SYMBOL_SHEET.get_height() / 2.0, SYMBOL_SHEET.get_width() / 3.0, SYMBOL_SHEET.get_height() / 2.0)
	art.texture = atlas
	column.add_child(art)
	var name_label := _journey_label(29, Color("fff1d0"))
	name_label.text = GameConstants.SYMBOL_LABELS[symbol].to_upper()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(name_label)
	var count_label := _journey_label(24, Color("ffe18a"))
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(count_label)
	collection_cards[symbol] = {"art": art, "count": count_label}

func _on_journey_changed() -> void:
	var favorite := EngagementProgress.get_daily_favorite()
	var mark := "✓" if EngagementProgress.daily_favorite_used else "○"
	daily_journey_label.text = "Hôm nay · %d/%d ván\nChọn %s ít nhất một lần %s" % [EngagementProgress.daily_rounds, EngagementProgress.DAILY_ROUNDS, GameConstants.SYMBOL_LABELS[favorite], mark]
	weekly_journey_label.text = "Dấu xuân tuần này: %d/7 ngày" % EngagementProgress.weekly_stamps()
	for symbol in GameConstants.SYMBOLS:
		var card: Dictionary = collection_cards[symbol]
		var count := EngagementProgress.discovery_count(symbol)
		(card["art"] as TextureRect).modulate = Color.WHITE if count > 0 else Color(0.4, 0.4, 0.4, 1)
		(card["count"] as Label).text = "%d lần" % count if count > 0 else "CHƯA GẶP"
	for theme in EngagementProgress.THEMES:
		var button: Button = theme_buttons[theme]
		var title: String = {"xuan": "ĐÀO XUÂN", "dem": "ĐÊM HỘI", "vang": "ÁNH VÀNG"}[theme]
		button.text = ("✓ " if EngagementProgress.theme_id == theme else "") + title
		button.disabled = not EngagementProgress.can_use_theme(theme)
	_apply_theme()
	_refresh()

func _apply_theme() -> void:
	var background := $SpringBackground as TextureRect
	var veil := $ContrastVeil as ColorRect
	match EngagementProgress.theme_id:
		"dem":
			background.modulate = Color(0.74, 0.80, 1.0, 0.86)
			veil.color = Color(0.02, 0.04, 0.16, 0.38)
		"vang":
			background.modulate = Color(1.0, 0.93, 0.72, 0.86)
			veil.color = Color(0.23, 0.09, 0.01, 0.30)
		_:
			background.modulate = Color(1, 1, 1, 0.8)
			veil.color = Color(0.18, 0.012, 0.028, 0.3)

func _show_journey() -> void:
	EngagementProgress.refresh_calendar()
	_on_journey_changed()
	_show_bottom_sheet(journey_popup, Vector2i(980, 1280))

func _position_bottom_actions(banner_visible: bool) -> void:
	var actions := $SafeHeader/Actions as HBoxContainer
	actions.offset_top = -372.0 if banner_visible else -182.0
	actions.offset_bottom = -300.0 if banner_visible else -110.0

func _show_party() -> void:
	journey_popup.hide()
	get_tree().change_scene_to_file("res://scenes/PartyMode.tscn")

func _place_bet(symbol: String) -> void:
	if GameSession.place_bet(symbol):
		GameSettings.tap_feedback()
		AudioDirector.play(NativeAudioDirector.Cue.TAP)
		status_label.text = "Đã chọn %s." % GameConstants.SYMBOL_LABELS[symbol]
	else:
		status_label.text = "Lộc hiện có không đủ cho lựa chọn này."

func _select_chip(value: int) -> void:
	GameSession.select_chip(value)
	GameSettings.tap_feedback()
	AudioDirector.play(NativeAudioDirector.Cue.TAP)
	status_label.text = "Đã chọn mệnh giá %s." % _format_chip(value)

func _on_bowl_tapped() -> void:
	if is_animating:
		return
	if bowl.is_revealed:
		_cover_bowl()
		return
	_shake()

func _cover_bowl() -> void:
	is_animating = true
	results_label.text = "Đậy tô…"
	status_label.text = "Sẵn sàng cho ván tiếp theo."
	await bowl.play_cover()
	results_label.text = "Chạm vào tô để lắc"
	_pin_board_top()
	is_animating = false
	_refresh()
	AdPlacement.on_bowl_covered(GameSession.session_rounds)

func _shake() -> void:
	if is_animating:
		return
	var summary := GameSession.begin_round()
	if summary.is_empty():
		status_label.text = "Chọn ít nhất một linh vật trước khi lắc."
		return
	is_animating = true
	results_label.text = "Đang lắc tô…"
	status_label.text = "Giữ chặt tô, kết quả sắp xuất hiện."
	_refresh()
	await bowl.play_reveal(summary["results"])
	# Do not retain an old focus offset after the bowl changes state.
	await get_tree().process_frame
	_pin_board_top()
	if summary["payout"] > 0:
		GameSettings.reward_feedback()
		AudioDirector.play(NativeAudioDirector.Cue.WIN)
		lucky_burst.play_at(bowl.get_global_rect().get_center())
	GameSession.settle_round(summary)
	is_animating = false
	_refresh()
	_stabilize_board_top()

func _stabilize_board_top() -> void:
	# Layout settles over several frames when the dice and result text change.
	for frame in 4:
		await get_tree().process_frame
		_pin_board_top()

func _on_round_resolved(summary: Dictionary) -> void:
	var labels: Array[String] = []
	for symbol in summary["results"]:
		labels.append(GameConstants.SYMBOL_LABELS[symbol])
	results_label.text = "Kết quả: " + " · ".join(labels)
	status_label.text = "Nhận %s · %s. Chạm tô để đậy lại." % [
		GameConstants.format_luck(summary["payout"]),
		GameConstants.format_signed_luck(summary["net"]),
	]
	_stabilize_board_top()

func _show_history() -> void:
	var entries: Array[String] = []
	for entry in GameSession.history:
		var summary: Dictionary = entry["summary"]
		var result_labels: Array[String] = []
		for symbol in summary["results"]:
			result_labels.append(GameConstants.SYMBOL_LABELS[symbol])
		entries.append("Ván %02d  ·  %s\n%s" % [
			int(entry["round"]),
			" · ".join(result_labels),
			GameConstants.format_signed_luck(summary["net"]),
		])
	history_label.text = "Chưa có ván nào hoàn tất." if entries.is_empty() else "\n\n".join(entries)
	_show_bottom_sheet(history_popup, Vector2i(960, 720))

func _show_settings() -> void:
	_show_bottom_sheet(settings_popup, Vector2i(960, 760))

func _show_rules() -> void:
	_show_bottom_sheet(rules_popup, Vector2i(960, 980))

func _configure_bottom_sheets() -> void:
	for popup: PopupPanel in [settings_popup, rules_popup, history_popup, onboarding_popup, journey_popup]:
		var panel := StyleBoxFlat.new()
		panel.bg_color = Color("260611")
		panel.border_color = Color("ffd75a")
		panel.set_border_width_all(3)
		panel.corner_radius_top_left = 30
		panel.corner_radius_top_right = 30
		panel.corner_radius_bottom_left = 30
		panel.corner_radius_bottom_right = 30
		panel.shadow_color = Color(0, 0, 0, 0.55)
		panel.shadow_size = 28
		popup.add_theme_stylebox_override("panel", panel)
	for button: Button in [settings_close_button, rules_close_button, history_close_button]:
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color("a84022")
		normal.border_color = Color("ffe59a")
		normal.set_border_width_all(2)
		normal.set_corner_radius_all(16)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", normal)
		button.add_theme_stylebox_override("pressed", normal)
		button.add_theme_color_override("font_color", Color("fff7d4"))
	_style_sheet_button(onboarding_start_button)

func _show_bottom_sheet(popup: PopupPanel, desired_size: Vector2i, bottom_gap: int = 36) -> void:
	var viewport_size := Vector2i(get_viewport().get_visible_rect().size)
	var width := mini(desired_size.x, viewport_size.x - 48)
	var height := mini(desired_size.y, viewport_size.y - 72)
	var position := Vector2i((viewport_size.x - width) / 2, viewport_size.y - height - bottom_gap)
	# PopupPanel may restore its authored offsets on popup(). Apply the final
	# geometry after it becomes visible so every sheet keeps the mobile width.
	popup.popup()
	popup.size = Vector2i(width, height)
	popup.position = position
	call_deferred("_lock_bottom_sheet_geometry", popup, Vector2i(width, height), position)

func _lock_bottom_sheet_geometry(popup: PopupPanel, size: Vector2i, position: Vector2i) -> void:
	if popup.visible:
		popup.size = size
		popup.position = position
		_layout_bottom_sheet_content(popup)

func _layout_bottom_sheet_content(popup: PopupPanel) -> void:
	# PopupPanel is a native window on Android, so outer Control offsets can be
	# reapplied by the OS. MarginContainer's internal padding remains stable and
	# gives every line a dependable mobile reading gutter.
	var margin := popup.get_node_or_null("Margin") as MarginContainer
	if margin == null:
		return
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_top", 56)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_bottom", 56)

func _show_onboarding() -> void:
	_show_bottom_sheet(onboarding_popup, Vector2i(860, 440), 100)

func _hide_top_popup() -> bool:
	if reset_dialog.visible:
		reset_dialog.hide()
		return true
	for popup: PopupPanel in [onboarding_popup, settings_popup, rules_popup, history_popup, journey_popup]:
		if popup.visible:
			popup.hide()
			return true
	return false

func _on_go_back_requested() -> void:
	if not _hide_top_popup():
		get_tree().quit()

func _finish_onboarding() -> void:
	GameSettings.mark_onboarding_seen()
	onboarding_popup.hide()
	call_deferred("_scroll_board_to_top")

func _scroll_board_to_top() -> void:
	await get_tree().process_frame
	_pin_board_top()

func _reset_progress() -> void:
	GameSession.reset()
	EngagementProgress.reset()
	results_label.text = "Kết quả sẽ hiện tại đây"
	status_label.text = "Đã bắt đầu một hành trình Lộc mới."
	settings_popup.hide()

func _refresh() -> void:
	balance_label.text = "LỘC: " + GameConstants.format_luck(GameSession.balance)
	round_label.text = "VÁN %02d" % GameSession.round
	stake_label.text = "TRÊN BÀN: " + GameConstants.format_luck(GameSession.total_bet())
	challenge_label.text = "HÔM NAY: HOÀN THÀNH ✓" if EngagementProgress.is_daily_complete() else "HÔM NAY: %d/%d VÁN · %s" % [EngagementProgress.daily_rounds, EngagementProgress.DAILY_ROUNDS, GameConstants.SYMBOL_LABELS[EngagementProgress.get_daily_favorite()]]
	for symbol in GameConstants.SYMBOLS:
		var button: MascotCard = mascot_buttons[symbol]
		var amount: int = GameSession.bets[symbol]
		button.set_bet(amount)
		button.disabled = GameSession.is_round_in_progress or bowl.is_revealed
	for value in GameConstants.CHIP_VALUES:
		var button: Button = chip_buttons[value]
		var selected: bool = value == GameSession.selected_chip
		button.disabled = GameSession.is_round_in_progress or bowl.is_revealed
		button.text = ("✓ " if selected else "") + _format_chip(value)
		_apply_chip_style(button, selected)
	settings_button.disabled = GameSession.is_round_in_progress
	journey_button.disabled = GameSession.is_round_in_progress
	rules_button.disabled = GameSession.is_round_in_progress
	history_button.disabled = GameSession.is_round_in_progress

func _format_chip(value: int) -> String:
	return "%dK" % (value / 1_000)

func _apply_chip_style(button: Button, selected: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("9a3d20") if selected else Color("4c151c")
	style.border_color = Color("ffd75a") if selected else Color("783128")
	style.set_border_width_all(3 if selected else 1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_color_override("font_color", Color("fff0bb") if selected else Color("f7d7ba"))
