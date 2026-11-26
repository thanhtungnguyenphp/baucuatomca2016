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
var nearby_quick_button: Button
var header_menu_button: Button
var header_menu_overlay: ColorRect
var header_menu_panel: PanelContainer
var header_menu_entries: Dictionary = {}
var brand_label: Label
var hud_panel: PanelContainer
var shake_button: Button
var session_summary_panel: PanelContainer
var tap_hint_panel: PanelContainer
var subtitle_ribbon: PanelContainer
var result_overlay: PanelContainer
var result_overlay_label: Label
var _result_feedback_token := 0
var chip_selector_button: Button
var chip_picker_overlay: ColorRect
var chip_picker_sheet: PanelContainer
var chip_picker_balance: Label
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
	_build_modern_tet_layout()
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
	AdPlacement.set_banner_allowed(GameSettings.onboarding_seen)
	AdPlacement.banner_visibility_changed.connect(_on_banner_visibility_changed)
	_on_banner_visibility_changed(AdPlacement.is_banner_visible())
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
	for popup: PopupPanel in [settings_popup, rules_popup, history_popup, journey_popup]:
		popup.popup_hide.connect(_on_info_popup_hidden)
	_on_journey_changed()
	_refresh()
	if not GameSettings.onboarding_seen:
		call_deferred("_show_onboarding")

func _apply_portrait_layout() -> void:
	var viewport_height := get_viewport().get_visible_rect().size.y
	var layout_t := clampf((viewport_height - 1650.0) / 750.0, 0.0, 1.0)
	var bowl_height := lerpf(250.0, 500.0, layout_t)
	var card_height := lerpf(160.0, 280.0, layout_t)
	bowl.custom_minimum_size.y = bowl_height
	for card: MascotCard in mascot_buttons.values():
		card.custom_minimum_size.y = card_height
	shake_button.custom_minimum_size.y = lerpf(104.0, 136.0, layout_t)
	$Margin.offset_top = lerpf(270.0, 350.0, layout_t)
	($Margin/Content as VBoxContainer).add_theme_constant_override("separation", int(lerpf(8.0, 18.0, layout_t)))
	$SafeHeader/Subtitle.visible = true

func _pin_board_top() -> void:
	# The board no longer scrolls: this is intentionally a stable, glanceable
	# portrait composition, so focus changes cannot push the header off-screen.
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if is_instance_valid(header_menu_overlay) and header_menu_overlay.visible:
			_close_header_menu()
			get_viewport().set_input_as_handled()
			return
		if is_instance_valid(chip_picker_overlay) and chip_picker_overlay.visible:
			_close_chip_picker()
			get_viewport().set_input_as_handled()
			return
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
	chip_grid.columns = 1
	chip_selector_button = Button.new()
	chip_selector_button.name = "ChipSelectorButton"
	chip_selector_button.custom_minimum_size.y = 104
	chip_selector_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip_selector_button.add_theme_font_size_override("font_size", 30)
	chip_selector_button.pressed.connect(_open_chip_picker)
	_style_sheet_button(chip_selector_button)
	chip_grid.add_child(chip_selector_button)
	_build_chip_picker()

func _build_chip_picker() -> void:
	chip_picker_overlay = ColorRect.new()
	chip_picker_overlay.name = "ChipPickerOverlay"
	chip_picker_overlay.color = Color(0.03, 0.0, 0.01, 0.78)
	chip_picker_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	chip_picker_overlay.z_index = 80
	chip_picker_overlay.visible = false
	add_child(chip_picker_overlay)
	chip_picker_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	chip_picker_sheet = PanelContainer.new()
	chip_picker_sheet.name = "ChipPickerSheet"
	var sheet_style := StyleBoxFlat.new()
	sheet_style.bg_color = Color("260611")
	sheet_style.border_color = Color("ffd75a")
	sheet_style.set_border_width_all(3)
	sheet_style.set_corner_radius_all(28)
	sheet_style.set_content_margin_all(30)
	chip_picker_sheet.add_theme_stylebox_override("panel", sheet_style)
	chip_picker_overlay.add_child(chip_picker_sheet)
	chip_picker_sheet.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	chip_picker_sheet.offset_left = -502
	chip_picker_sheet.offset_right = 502
	chip_picker_sheet.offset_top = -720
	chip_picker_sheet.offset_bottom = -120

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	chip_picker_sheet.add_child(content)
	var title := Label.new()
	title.text = "CHỌN MỆNH GIÁ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("ffe18a"))
	content.add_child(title)
	chip_picker_balance = Label.new()
	chip_picker_balance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_picker_balance.add_theme_font_size_override("font_size", 27)
	chip_picker_balance.add_theme_color_override("font_color", Color("bdf0be"))
	content.add_child(chip_picker_balance)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	content.add_child(grid)
	for value in GameConstants.CHIP_VALUES:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 112)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 32)
		button.text = _format_chip(value)
		button.pressed.connect(_select_chip.bind(value))
		grid.add_child(button)
		chip_buttons[value] = button
	var close := Button.new()
	close.text = "ĐÓNG"
	close.custom_minimum_size.y = 92
	close.add_theme_font_size_override("font_size", 29)
	close.pressed.connect(_close_chip_picker)
	_style_sheet_button(close)
	content.add_child(close)

func _open_chip_picker() -> void:
	if not is_instance_valid(chip_selector_button) or not is_instance_valid(chip_picker_overlay):
		return
	if chip_selector_button.disabled:
		return
	GameSettings.tap_feedback()
	_refresh()
	chip_picker_overlay.visible = true

func _close_chip_picker() -> void:
	if is_instance_valid(chip_picker_overlay):
		chip_picker_overlay.visible = false

func _build_journey_ui() -> void:
	var actions := $SafeHeader/Actions as HBoxContainer
	actions.visible = false
	rules_button.text = "HƯỚNG DẪN"
	history_button.text = "LỊCH SỬ"
	settings_button.text = "ÂM THANH"
	for button: Button in [rules_button, history_button, settings_button]:
		button.custom_minimum_size.y = 92
		button.add_theme_font_size_override("font_size", 22)
		_style_nav_button(button)
	journey_button = Button.new()
	journey_button.text = "THỐNG KÊ"
	journey_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journey_button.custom_minimum_size.y = 92
	journey_button.add_theme_font_size_override("font_size", 22)
	_style_nav_button(journey_button)
	actions.add_child(journey_button)
	journey_button.pressed.connect(_show_journey)
	nearby_quick_button = Button.new()
	nearby_quick_button.name = "NearbyQuickButton"
	nearby_quick_button.text = "◆  CHƠI CÙNG BẠN Ở GẦN\n2–6 THIẾT BỊ · KHÔNG CẦN INTERNET"
	nearby_quick_button.custom_minimum_size.y = 116
	nearby_quick_button.add_theme_font_size_override("font_size", 27)
	nearby_quick_button.pressed.connect(_show_nearby_party)
	_style_nearby_cta(nearby_quick_button)
	$SafeHeader.add_child(nearby_quick_button)
	nearby_quick_button.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nearby_quick_button.offset_left = 38.0
	nearby_quick_button.offset_right = -38.0
	_build_header_menu()

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
	var nearby_button := Button.new()
	nearby_button.text = "CHƠI GẦN NHAU · 2–6 THIẾT BỊ"
	nearby_button.custom_minimum_size.y = 76
	nearby_button.add_theme_font_size_override("font_size", 27)
	nearby_button.pressed.connect(_show_nearby_party)
	_style_sheet_button(nearby_button)
	content.add_child(nearby_button)
	var close_button := Button.new()
	close_button.text = "ĐÓNG"
	close_button.custom_minimum_size.y = 82
	close_button.add_theme_font_size_override("font_size", 30)
	close_button.pressed.connect(journey_popup.hide)
	_style_sheet_button(close_button)
	content.add_child(close_button)

func _build_modern_tet_layout() -> void:
	brand_label = Label.new()
	brand_label.name = "BrandLabel"
	brand_label.text = "lamgame.vn"
	brand_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand_label.add_theme_font_size_override("font_size", 25)
	brand_label.add_theme_color_override("font_color", Color("fff0c2"))
	brand_label.add_theme_constant_override("outline_size", 4)
	brand_label.add_theme_color_override("font_outline_color", Color("5b0810"))
	$SafeHeader.add_child(brand_label)
	brand_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	brand_label.offset_left = 300.0
	brand_label.offset_top = 22.0
	brand_label.offset_right = -300.0
	brand_label.offset_bottom = 58.0
	var title := $SafeHeader/Title as Label
	title.offset_top = 54.0
	title.offset_bottom = 142.0
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_constant_override("outline_size", 7)
	title.add_theme_color_override("font_outline_color", Color("7f120c"))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 7)
	title.add_theme_color_override("font_shadow_color", Color(0.14, 0.0, 0.0, 0.75))

	var subtitle := $SafeHeader/Subtitle as Label
	subtitle.offset_top = 148.0
	subtitle.offset_bottom = 204.0
	subtitle.add_theme_font_size_override("font_size", 29)
	subtitle.add_theme_constant_override("outline_size", 3)
	subtitle.add_theme_color_override("font_outline_color", Color("6e0d0a"))
	subtitle_ribbon = PanelContainer.new()
	subtitle_ribbon.name = "SubtitleRibbon"
	subtitle_ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ribbon_style := StyleBoxFlat.new()
	ribbon_style.bg_color = Color("a91e12e8")
	ribbon_style.border_color = Color("f2a137")
	ribbon_style.set_border_width_all(2)
	ribbon_style.set_corner_radius_all(12)
	subtitle_ribbon.add_theme_stylebox_override("panel", ribbon_style)
	var subtitle_index := subtitle.get_index()
	$SafeHeader.add_child(subtitle_ribbon)
	$SafeHeader.move_child(subtitle_ribbon, subtitle_index)
	subtitle_ribbon.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subtitle_ribbon.offset_left = 258.0
	subtitle_ribbon.offset_top = 148.0
	subtitle_ribbon.offset_right = -258.0
	subtitle_ribbon.offset_bottom = 204.0

	var stats := $SafeHeader/Stats as HBoxContainer
	hud_panel = PanelContainer.new()
	hud_panel.name = "HUDPanel"
	var hud_style := StyleBoxFlat.new()
	hud_style.bg_color = Color("4b1017ed")
	hud_style.border_color = Color("f2ad43")
	hud_style.set_border_width_all(2)
	hud_style.set_corner_radius_all(32)
	hud_style.set_content_margin_all(10)
	hud_panel.add_theme_stylebox_override("panel", hud_style)
	var stats_index := stats.get_index()
	$SafeHeader.add_child(hud_panel)
	$SafeHeader.move_child(hud_panel, stats_index)
	hud_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud_panel.offset_left = 138.0
	hud_panel.offset_top = 220.0
	hud_panel.offset_right = -138.0
	hud_panel.offset_bottom = 302.0
	stats.set_anchors_preset(Control.PRESET_TOP_WIDE)
	stats.offset_left = 168.0
	stats.offset_top = 234.0
	stats.offset_right = -168.0
	stats.offset_bottom = 288.0
	stats.add_theme_constant_override("separation", 82)
	balance_label.add_theme_font_size_override("font_size", 34)
	round_label.add_theme_font_size_override("font_size", 34)

	var surface := PanelContainer.new()
	surface.name = "GameplaySurface"
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var surface_style := StyleBoxFlat.new()
	surface_style.bg_color = Color(0.20, 0.025, 0.045, 0.12)
	surface_style.border_color = Color(0.92, 0.52, 0.16, 0.18)
	surface_style.set_border_width_all(1)
	surface_style.set_corner_radius_all(28)
	surface.add_theme_stylebox_override("panel", surface_style)
	var margin_index := $Margin.get_index()
	add_child(surface)
	move_child(surface, margin_index)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.offset_left = 20.0
	surface.offset_top = 310.0
	surface.offset_right = -20.0
	surface.offset_bottom = -174.0
	$Margin.offset_top = 350.0
	$Margin.offset_bottom = -300.0
	var content := $Margin/Content as VBoxContainer
	content.add_theme_constant_override("separation", 18)
	bowl.expand_stage_visual(135.0, 54.0)

	# Warm stage glow makes the bowl the visual anchor without another bitmap.
	var bowl_glow := PanelContainer.new()
	bowl_glow.name = "BowlGlow"
	bowl_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_style := StyleBoxFlat.new()
	glow_style.bg_color = Color(0.70, 0.16, 0.02, 0.10)
	glow_style.border_color = Color(1.0, 0.64, 0.16, 0.0)
	glow_style.set_corner_radius_all(220)
	glow_style.shadow_color = Color(1.0, 0.44, 0.06, 0.55)
	glow_style.shadow_size = 52
	bowl_glow.add_theme_stylebox_override("panel", glow_style)
	bowl.add_child(bowl_glow)
	bowl.move_child(bowl_glow, 0)
	bowl_glow.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	bowl_glow.offset_left = -250.0
	bowl_glow.offset_top = -88.0
	bowl_glow.offset_right = 250.0
	bowl_glow.offset_bottom = 88.0

	# The mockup presents the bowl instruction as a pill, not floating copy.
	var hint_index := results_label.get_index()
	tap_hint_panel = PanelContainer.new()
	tap_hint_panel.name = "TapHintPanel"
	tap_hint_panel.custom_minimum_size.y = 66
	var hint_style := StyleBoxFlat.new()
	hint_style.bg_color = Color("5b1118e8")
	hint_style.border_color = Color("ffd456")
	hint_style.set_border_width_all(3)
	hint_style.set_corner_radius_all(32)
	hint_style.content_margin_left = 28.0
	hint_style.content_margin_right = 28.0
	tap_hint_panel.add_theme_stylebox_override("panel", hint_style)
	content.add_child(tap_hint_panel)
	content.move_child(tap_hint_panel, hint_index)
	results_label.reparent(tap_hint_panel)
	results_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	results_label.add_theme_font_size_override("font_size", 30)
	results_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	shake_button = Button.new()
	shake_button.name = "PrimaryShakeButton"
	shake_button.custom_minimum_size.y = 136
	shake_button.add_theme_font_size_override("font_size", 48)
	shake_button.pressed.connect(_on_bowl_tapped)
	_style_primary_action(shake_button)
	content.add_child(shake_button)
	content.move_child(shake_button, chip_grid.get_index() + 1)

	# Compact status capsule lives directly above the permanent utility bar.
	session_summary_panel = PanelContainer.new()
	session_summary_panel.name = "SessionSummaryPanel"
	var summary_style := StyleBoxFlat.new()
	summary_style.bg_color = Color("4b1017e8")
	summary_style.border_color = Color("df8b35")
	summary_style.set_border_width_all(2)
	summary_style.set_corner_radius_all(26)
	session_summary_panel.add_theme_stylebox_override("panel", summary_style)
	$SafeHeader.add_child(session_summary_panel)
	session_summary_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	session_summary_panel.offset_left = 70.0
	session_summary_panel.offset_top = -270.0
	session_summary_panel.offset_right = -70.0
	session_summary_panel.offset_bottom = -176.0
	var summary_row := HBoxContainer.new()
	summary_row.alignment = BoxContainer.ALIGNMENT_CENTER
	summary_row.add_theme_constant_override("separation", 48)
	session_summary_panel.add_child(summary_row)
	stake_label.reparent(summary_row)
	challenge_label.reparent(summary_row)
	stake_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	challenge_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stake_label.add_theme_font_size_override("font_size", 25)
	challenge_label.add_theme_font_size_override("font_size", 25)
	status_label.visible = false
	results_label.text = "CHẠM VÀO TÔ ĐỂ LẮC"
	status_label.text = "Chọn mệnh giá và linh vật, sau đó bấm LẮC."
	_build_result_overlay()

func _build_result_overlay() -> void:
	result_overlay = PanelContainer.new()
	result_overlay.name = "ResultOverlay"
	result_overlay.z_index = 70
	result_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_overlay.visible = false
	var overlay_style := StyleBoxFlat.new()
	overlay_style.bg_color = Color("500b12f2")
	overlay_style.border_color = Color("fff06a")
	overlay_style.set_border_width_all(5)
	overlay_style.set_corner_radius_all(34)
	overlay_style.shadow_color = Color(1.0, 0.55, 0.06, 0.72)
	overlay_style.shadow_size = 28
	overlay_style.content_margin_left = 28.0
	overlay_style.content_margin_right = 28.0
	overlay_style.content_margin_top = 22.0
	overlay_style.content_margin_bottom = 22.0
	result_overlay.add_theme_stylebox_override("panel", overlay_style)
	add_child(result_overlay)
	result_overlay.anchor_left = 0.0
	result_overlay.anchor_top = 0.42
	result_overlay.anchor_right = 1.0
	result_overlay.anchor_bottom = 0.42
	result_overlay.offset_left = 42.0
	result_overlay.offset_top = -116.0
	result_overlay.offset_right = -42.0
	result_overlay.offset_bottom = 116.0
	result_overlay_label = Label.new()
	result_overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_overlay_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_overlay_label.add_theme_font_size_override("font_size", 48)
	result_overlay_label.add_theme_color_override("font_color", Color("fff49a"))
	result_overlay_label.add_theme_constant_override("outline_size", 6)
	result_overlay_label.add_theme_color_override("font_outline_color", Color("8f140d"))
	result_overlay.add_child(result_overlay_label)

func _style_primary_action(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("ffd36a")
	normal.border_color = Color("fff4aa")
	normal.set_border_width_all(5)
	normal.set_corner_radius_all(64)
	normal.shadow_color = Color(1.0, 0.55, 0.08, 0.46)
	normal.shadow_size = 18
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("e9b84e")
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("d5a43c")
	disabled.border_color = Color("f3cb65")
	disabled.shadow_color = Color(1.0, 0.49, 0.04, 0.20)
	disabled.shadow_size = 8
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color("650b0c"))
	button.add_theme_color_override("font_pressed_color", Color("650b0c"))
	button.add_theme_color_override("font_disabled_color", Color("7c2415"))

func _style_quick_nav_button(button: Button, emphasized: bool = false) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("5a1118") if emphasized else Color("3a0b13e8")
	normal.border_color = Color("f0a63b") if emphasized else Color("8d4b2c")
	normal.set_border_width_all(2 if emphasized else 1)
	normal.set_corner_radius_all(18)
	normal.set_content_margin_all(7)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("84201b")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_color", Color("ffd85f"))
	button.add_theme_color_override("font_disabled_color", Color("8d7763"))

func _style_nearby_cta(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("a33a18")
	normal.border_color = Color("ffe36a")
	normal.set_border_width_all(4)
	normal.set_corner_radius_all(22)
	normal.shadow_color = Color(1.0, 0.55, 0.08, 0.45)
	normal.shadow_size = 14
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("7e2513")
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("56301f")
	disabled.shadow_size = 0
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color("fff6c7"))
	button.add_theme_color_override("font_disabled_color", Color("a48c78"))

func _build_header_menu() -> void:
	# Secondary utilities live in the expandable menu. The main board reserves
	# its bottom region for the highlighted Nearby CTA and the native AdMob view.
	$SafeHeader/Actions.visible = false
	$SafeHeader/Title.offset_left = 150.0
	$SafeHeader/Title.offset_right = -150.0

	header_menu_button = Button.new()
	header_menu_button.name = "HeaderMenuButton"
	header_menu_button.text = "☰"
	header_menu_button.tooltip_text = "Mở menu game"
	header_menu_button.add_theme_font_size_override("font_size", 42)
	header_menu_button.pressed.connect(_open_header_menu)
	_style_nav_button(header_menu_button)
	$SafeHeader.add_child(header_menu_button)
	header_menu_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	header_menu_button.offset_left = -142.0
	header_menu_button.offset_top = 48.0
	header_menu_button.offset_right = -38.0
	header_menu_button.offset_bottom = 128.0

	header_menu_overlay = ColorRect.new()
	header_menu_overlay.name = "HeaderMenuOverlay"
	header_menu_overlay.color = Color(0.03, 0.0, 0.01, 0.80)
	header_menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	header_menu_overlay.z_index = 90
	header_menu_overlay.visible = false
	add_child(header_menu_overlay)
	header_menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	header_menu_panel = PanelContainer.new()
	header_menu_panel.name = "HeaderMenuPanel"
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("260611")
	panel_style.border_color = Color("ffd75a")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(28)
	panel_style.set_content_margin_all(30)
	header_menu_panel.add_theme_stylebox_override("panel", panel_style)
	header_menu_overlay.add_child(header_menu_panel)
	header_menu_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header_menu_panel.offset_left = 38.0
	header_menu_panel.offset_top = 176.0
	header_menu_panel.offset_right = -38.0
	header_menu_panel.offset_bottom = 1080.0

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	header_menu_panel.add_child(content)
	var title := Label.new()
	title.text = "MENU GAME"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("ffe18a"))
	content.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Tiện ích và thông tin · Có thể mở rộng thêm chức năng"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color("d9c8ae"))
	content.add_child(subtitle)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var entries := VBoxContainer.new()
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries.add_theme_constant_override("separation", 12)
	scroll.add_child(entries)
	_add_header_menu_entry(entries, "nearby", "01 · CHƠI CÙNG BẠN Ở GẦN", "2–6 thiết bị · không cần Internet", _show_nearby_party)
	_add_header_menu_entry(entries, "rules", "02 · LUẬT CHƠI", "Cách đặt Lộc và cách tính thưởng", _show_rules)
	_add_header_menu_entry(entries, "journey", "03 · NHIỆM VỤ & THỐNG KÊ", "Quà, tiến độ ngày và bộ sưu tập", _show_journey)
	_add_header_menu_entry(entries, "history", "04 · LỊCH SỬ", "Kết quả các ván vừa chơi", _show_history)
	_add_header_menu_entry(entries, "settings", "05 · CÀI ĐẶT", "Âm thanh, rung và quyền riêng tư", _show_settings)
	var close := Button.new()
	close.name = "HeaderMenuClose"
	close.text = "ĐÓNG MENU"
	close.custom_minimum_size.y = 92
	close.add_theme_font_size_override("font_size", 29)
	close.pressed.connect(_close_header_menu)
	_style_sheet_button(close)
	content.add_child(close)

func _add_header_menu_entry(parent: VBoxContainer, key: String, title: String, subtitle: String, action: Callable) -> void:
	var entry := Button.new()
	entry.name = "Menu" + key.capitalize()
	entry.text = title + "\n" + subtitle
	entry.alignment = HORIZONTAL_ALIGNMENT_LEFT
	entry.custom_minimum_size.y = 116
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.add_theme_font_size_override("font_size", 27)
	entry.pressed.connect(func() -> void:
		_close_header_menu()
		action.call()
	)
	_style_menu_entry(entry)
	parent.add_child(entry)
	header_menu_entries[key] = entry

func _style_menu_entry(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("48121b")
	normal.border_color = Color("a8763c")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(18)
	normal.content_margin_left = 28.0
	normal.content_margin_right = 20.0
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_color_override("font_color", Color("fff1d0"))
	button.add_theme_color_override("font_disabled_color", Color("9f8b82"))

func _open_header_menu() -> void:
	if header_menu_button.disabled:
		return
	if is_instance_valid(chip_picker_overlay) and chip_picker_overlay.visible:
		_close_chip_picker()
	GameSettings.tap_feedback()
	header_menu_overlay.visible = true
	AdPlacement.set_banner_allowed(true)

func _close_header_menu() -> void:
	header_menu_overlay.visible = false
	AdPlacement.set_banner_allowed(true)

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

func _style_nav_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("3b101a")
	normal.border_color = Color("c99b51")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(16)
	normal.set_content_margin_all(8)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_color_override("font_color", Color("fff1d0"))

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
	# The native AdMob view owns the bottom strip. The featured multiplayer CTA
	# and compact status capsule move together only after the ad reports loaded.
	if not is_instance_valid(nearby_quick_button) or not is_instance_valid(session_summary_panel):
		return
	if banner_visible:
		nearby_quick_button.offset_top = -325.0
		nearby_quick_button.offset_bottom = -205.0
		session_summary_panel.offset_top = -435.0
		session_summary_panel.offset_bottom = -343.0
		$Margin.offset_bottom = -450.0
	else:
		nearby_quick_button.offset_top = -150.0
		nearby_quick_button.offset_bottom = -30.0
		session_summary_panel.offset_top = -260.0
		session_summary_panel.offset_bottom = -168.0
		$Margin.offset_bottom = -278.0

func _on_banner_visibility_changed(visible: bool) -> void:
	_position_bottom_actions(visible)
	if is_instance_valid(chip_picker_sheet):
		chip_picker_sheet.offset_top = -870 if visible else -720
		chip_picker_sheet.offset_bottom = -270 if visible else -120

func _show_party() -> void:
	journey_popup.hide()
	AdPlacement.set_banner_allowed(false)
	get_tree().change_scene_to_file("res://scenes/PartyMode.tscn")

func _show_nearby_party() -> void:
	journey_popup.hide()
	AdPlacement.set_banner_allowed(false)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/NearbyPartyMode.tscn")

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
	if is_instance_valid(chip_picker_overlay):
		_close_chip_picker()

func _on_bowl_tapped() -> void:
	if is_animating:
		return
	if bowl.is_revealed:
		_cover_bowl()
		return
	_shake()

func _cover_bowl() -> void:
	is_animating = true
	_hide_round_result_feedback()
	results_label.text = "ĐANG ĐẬY TÔ…"
	status_label.text = "Sẵn sàng cho ván tiếp theo."
	_refresh()
	await bowl.play_cover()
	results_label.text = "CHẠM VÀO TÔ ĐỂ LẮC"
	_pin_board_top()
	is_animating = false
	_refresh()
	# Modern Tet placement policy: active gameplay never triggers an
	# interstitial. A future Home/session-summary route may call the ad service
	# at a natural transition point instead.

func _shake() -> void:
	if is_animating:
		return
	var summary := GameSession.begin_round()
	if summary.is_empty():
		status_label.text = "Chọn ít nhất một linh vật trước khi lắc."
		return
	is_animating = true
	results_label.text = "ĐANG LẮC · GIỮ TÔ ỔN ĐỊNH"
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
	results_label.text = "CHẠM TÔ ĐỂ ĐẬY LẠI"
	status_label.text = "Nhận %s · %s. Chạm tô để đậy lại." % [
		GameConstants.format_luck(summary["payout"]),
		GameConstants.format_signed_luck(summary["net"]),
	]
	_show_round_result_feedback(summary)
	_stabilize_board_top()

func _show_round_result_feedback(summary: Dictionary) -> void:
	_result_feedback_token += 1
	var token := _result_feedback_token
	var labels: Array[String] = []
	var counts: Dictionary = {}
	for raw_symbol in summary["results"]:
		var symbol := str(raw_symbol)
		labels.append(GameConstants.SYMBOL_LABELS[symbol].to_upper())
		counts[symbol] = int(counts.get(symbol, 0)) + 1
	for symbol in GameConstants.SYMBOLS:
		var occurrences := int(counts.get(symbol, 0))
		(mascot_buttons[symbol] as MascotCard).play_result(occurrences > 0, occurrences, true)
	result_overlay_label.text = "KẾT QUẢ\n" + "  ·  ".join(labels)
	result_overlay.visible = true
	result_overlay.modulate.a = 0.0
	result_overlay.scale = Vector2(0.86, 0.86)
	result_overlay.pivot_offset = result_overlay.size * 0.5
	var appear := create_tween().set_parallel(true)
	appear.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	appear.tween_property(result_overlay, "modulate:a", 1.0, GameSettings.animation_duration(0.22))
	appear.tween_property(result_overlay, "scale", Vector2.ONE, GameSettings.animation_duration(0.28))
	await get_tree().create_timer(3.0).timeout
	if token != _result_feedback_token:
		return
	_hide_round_result_feedback()

func _hide_round_result_feedback() -> void:
	_result_feedback_token += 1
	if is_instance_valid(result_overlay):
		result_overlay.visible = false
		result_overlay.modulate.a = 1.0
		result_overlay.scale = Vector2.ONE
	for card: MascotCard in mascot_buttons.values():
		card.reset_result_state()

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

func _show_bottom_sheet(popup: PopupPanel, desired_size: Vector2i, bottom_gap: int = 36, allow_banner: bool = true) -> void:
	AdPlacement.set_banner_allowed(allow_banner)
	var geometry := _bottom_sheet_geometry(desired_size, bottom_gap, AdPlacement.is_banner_visible())
	var size := geometry.size
	var position := geometry.position
	# PopupPanel may restore its authored offsets on popup(). Apply the final
	# geometry after it becomes visible so every sheet keeps the mobile width.
	popup.popup()
	popup.size = size
	popup.position = position
	call_deferred("_lock_bottom_sheet_geometry", popup, size, position)

func _bottom_sheet_geometry(desired_size: Vector2i, bottom_gap: int, banner_visible: bool) -> Rect2i:
	var viewport_size := Vector2i(get_viewport().get_visible_rect().size)
	var safe_bottom_gap := bottom_gap + (190 if banner_visible else 0)
	var width := mini(desired_size.x, viewport_size.x - 48)
	var height := maxi(1, mini(desired_size.y, viewport_size.y - safe_bottom_gap - 36))
	var position := Vector2i((viewport_size.x - width) / 2, viewport_size.y - height - safe_bottom_gap)
	return Rect2i(position, Vector2i(width, height))

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
	_show_bottom_sheet(onboarding_popup, Vector2i(860, 440), 100, false)

func _on_info_popup_hidden() -> void:
	AdPlacement.set_banner_allowed(true)

func _hide_top_popup() -> bool:
	if is_instance_valid(header_menu_overlay) and header_menu_overlay.visible:
		_close_header_menu()
		return true
	if is_instance_valid(chip_picker_overlay) and chip_picker_overlay.visible:
		_close_chip_picker()
		return true
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
	AdPlacement.set_banner_allowed(true)
	call_deferred("_scroll_board_to_top")

func _scroll_board_to_top() -> void:
	await get_tree().process_frame
	_pin_board_top()

func _reset_progress() -> void:
	GameSession.reset()
	EngagementProgress.reset()
	_hide_round_result_feedback()
	results_label.text = "CHẠM VÀO TÔ ĐỂ LẮC"
	status_label.text = "Đã bắt đầu một hành trình Lộc mới."
	settings_popup.hide()

func _refresh() -> void:
	balance_label.text = "●  LỘC: " + GameConstants.format_luck(GameSession.balance)
	round_label.text = "▣  VÁN: %02d" % GameSession.round
	stake_label.text = "TRÊN BÀN: " + GameConstants.format_luck(GameSession.total_bet())
	challenge_label.text = "HÔM NAY: HOÀN THÀNH ✓" if EngagementProgress.is_daily_complete() else "HÔM NAY: %d/%d VÁN" % [EngagementProgress.daily_rounds, EngagementProgress.DAILY_ROUNDS]
	for symbol in GameConstants.SYMBOLS:
		var button: MascotCard = mascot_buttons[symbol]
		var amount: int = GameSession.bets[symbol]
		button.set_bet(amount)
		button.disabled = GameSession.is_round_in_progress or bowl.is_revealed
	for value in GameConstants.CHIP_VALUES:
		var button: Button = chip_buttons[value]
		var selected: bool = value == GameSession.selected_chip
		button.disabled = GameSession.is_round_in_progress or bowl.is_revealed or value > GameSession.balance - GameSession.total_bet()
		button.text = ("✓ " if selected else "") + _format_chip(value)
		_apply_chip_style(button, selected)
	if is_instance_valid(chip_selector_button):
		chip_selector_button.text = "●  MỆNH GIÁ: %s   ▼" % _format_chip(GameSession.selected_chip)
		chip_selector_button.disabled = GameSession.is_round_in_progress or bowl.is_revealed
	if is_instance_valid(chip_picker_balance):
		chip_picker_balance.text = "CÒN CÓ THỂ ĐẶT: %s" % GameConstants.format_luck(maxi(0, GameSession.balance - GameSession.total_bet()))
	if is_instance_valid(chip_picker_overlay) and is_instance_valid(chip_selector_button) and chip_picker_overlay.visible and chip_selector_button.disabled:
		chip_picker_overlay.visible = false
	var total_bet := GameSession.total_bet()
	shake_button.disabled = is_animating or (not bowl.is_revealed and total_bet <= 0)
	if is_animating:
		shake_button.text = "ĐANG XỬ LÝ…"
	elif bowl.is_revealed:
		shake_button.text = "ĐẬY TÔ · VÁN TIẾP"
	elif total_bet <= 0:
		shake_button.text = "◆  LẮC"
	else:
		shake_button.text = "◆  LẮC · %s" % GameConstants.format_luck(total_bet)
	settings_button.disabled = GameSession.is_round_in_progress
	journey_button.disabled = GameSession.is_round_in_progress
	rules_button.disabled = GameSession.is_round_in_progress
	history_button.disabled = GameSession.is_round_in_progress
	header_menu_button.disabled = GameSession.is_round_in_progress
	nearby_quick_button.disabled = GameSession.is_round_in_progress
	for entry: Button in header_menu_entries.values():
		entry.disabled = GameSession.is_round_in_progress
	if GameSession.is_round_in_progress and header_menu_overlay.visible:
		_close_header_menu()

func _format_chip(value: int) -> String:
	return "%dK" % (value / 1_000)

func _apply_chip_style(button: Button, selected: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("ffd346") if selected else Color("62131b")
	style.border_color = Color("fff29c") if selected else Color("e28b35")
	style.set_border_width_all(4 if selected else 2)
	style.set_corner_radius_all(38)
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.shadow_color = Color(1.0, 0.58, 0.08, 0.48) if selected else Color.TRANSPARENT
	style.shadow_size = 12 if selected else 0
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", style)
	button.add_theme_color_override("font_color", Color("7b130d") if selected else Color("fff0bb"))
	button.add_theme_color_override("font_disabled_color", Color("8d6c60"))
