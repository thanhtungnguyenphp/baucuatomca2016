extends Node

const ADMOB_APP_ID := "ca-app-pub-6352554924566967~6336109870"
const BANNER_UNIT_ID := "ca-app-pub-6352554924566967/5111492266"
const INTERSTITIAL_UNIT_ID := "ca-app-pub-6352554924566967/4875241431"
const REWARDED_UNIT_ID := "ca-app-pub-6352554924566967/7706970639"
const TEST_BANNER_UNIT_ID := "ca-app-pub-3940256099942544/6300978111"
const TEST_INTERSTITIAL_UNIT_ID := "ca-app-pub-3940256099942544/1033173712"
const TEST_REWARDED_UNIT_ID := "ca-app-pub-3940256099942544/5224354917"
const ROUNDS_BETWEEN_ADS := 8
const MIN_SECONDS_BETWEEN_ADS := 180

signal interstitial_break_requested
signal privacy_options_available(available: bool)
signal banner_visibility_changed(visible: bool)
signal ad_status_changed(message: String)
signal rewarded_availability_changed(available: bool)
signal rewarded_earned(request_id: String)
signal rewarded_failed(request_id: String, message: String)
signal fullscreen_ad_state_changed(active: bool)

var _last_ad_round := 0
var _last_ad_time_ms := 0
var _banner: AdView
var _interstitial: InterstitialAd
var _rewarded: RewardedAd
var _loading_interstitial := false
var _loading_rewarded := false
var _banner_visible := false
var _fullscreen_ad_active := false
var _reward_request_id := ""
var _reward_was_earned := false

func _ready() -> void:
	if OS.get_name() != "Android" or not Engine.has_singleton("PoingGodotAdMob"):
		return
	interstitial_break_requested.connect(_show_interstitial)
	UserMessagingPlatform.consent_information.update(
		ConsentRequestParameters.new(), _on_consent_updated, _on_consent_failed
	)

func _on_consent_updated() -> void:
	var status := UserMessagingPlatform.consent_information.get_consent_status()
	var required := UserMessagingPlatform.consent_information.get_privacy_options_requirement_status()
	print("[AdMob] Consent status: ", status, "; privacy options: ", required)
	ad_status_changed.emit("Consent status: %s" % status)
	privacy_options_available.emit(required == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED)
	if status == ConsentInformation.ConsentStatus.REQUIRED:
		UserMessagingPlatform.load_consent_form(_on_form_loaded, _on_form_failed)
	else:
		_start_ads_if_permitted()

func _on_form_loaded(form: ConsentForm) -> void:
	form.show(func(_error: FormError) -> void: _start_ads_if_permitted())

func _on_form_failed(error: FormError) -> void:
	push_warning("[AdMob] Consent form unavailable: " + error.message)
	ad_status_changed.emit("Consent form unavailable: " + error.message)
	_start_ads_if_permitted()

func _on_consent_failed(error: FormError) -> void:
	push_warning("[AdMob] Consent update failed: " + error.message)
	ad_status_changed.emit("Consent update failed: " + error.message)
	_start_ads_if_permitted()

func _start_ads_if_permitted() -> void:
	var status := UserMessagingPlatform.consent_information.get_consent_status()
	if status != ConsentInformation.ConsentStatus.OBTAINED \
		and status != ConsentInformation.ConsentStatus.NOT_REQUIRED:
		print("[AdMob] Ads waiting for consent, status: ", status)
		ad_status_changed.emit("Ads waiting for valid consent state: %s" % status)
		return
	print("[AdMob] Starting banner and interstitial loading")
	ad_status_changed.emit("Loading ads")
	MobileAds.initialize()
	var banner_id := TEST_BANNER_UNIT_ID if OS.is_debug_build() else BANNER_UNIT_ID
	var banner_size := AdSize.get_current_orientation_anchored_adaptive_banner_ad_size(AdSize.FULL_WIDTH)
	if banner_size.width <= 0 or banner_size.height <= 0:
		banner_size = AdSize.BANNER
	_banner = AdView.new(banner_id, banner_size, AdPosition.BOTTOM)
	_banner.ad_listener.on_ad_loaded = func() -> void:
		_banner_visible = true
		banner_visibility_changed.emit(true)
		ad_status_changed.emit("Banner loaded: %dx%d px" % [_banner.get_width_in_pixels(), _banner.get_height_in_pixels()])
		print("[AdMob] Banner loaded")
	_banner.ad_listener.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_banner_visible = false
		banner_visibility_changed.emit(false)
		ad_status_changed.emit("Banner load failed: " + error.message)
		push_warning("[AdMob] Banner load failed: " + error.message)
	_banner.load_ad(AdRequest.new())
	_load_interstitial()
	_load_rewarded()

func _load_interstitial() -> void:
	if _loading_interstitial or _interstitial != null:
		return
	_loading_interstitial = true
	var callback := InterstitialAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_loading_interstitial = false
		_interstitial = ad
		print("[AdMob] Interstitial loaded")
	callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_loading_interstitial = false
		push_warning("[AdMob] Interstitial load failed: " + error.message)
	var unit_id := TEST_INTERSTITIAL_UNIT_ID if OS.is_debug_build() else INTERSTITIAL_UNIT_ID
	InterstitialAdLoader.new().load(unit_id, AdRequest.new(), callback)

func _show_interstitial() -> void:
	if _interstitial == null:
		_load_interstitial()
		return
	var ad := _interstitial
	_interstitial = null
	_last_ad_time_ms = Time.get_ticks_msec()
	_set_fullscreen_ad_active(true)
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		ad.destroy()
		_set_fullscreen_ad_active(false)
		_load_interstitial()
	ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void:
		ad.destroy()
		_set_fullscreen_ad_active(false)
		_load_interstitial()
	ad.show()

func _load_rewarded() -> void:
	if _loading_rewarded or _rewarded != null:
		return
	var unit_id := TEST_REWARDED_UNIT_ID if OS.is_debug_build() else REWARDED_UNIT_ID
	if not unit_id.begins_with("ca-app-pub-") or not ("/" in unit_id):
		rewarded_availability_changed.emit(false)
		return
	_loading_rewarded = true
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		_loading_rewarded = false
		_rewarded = ad
		rewarded_availability_changed.emit(true)
		print("[AdMob] Rewarded loaded")
	callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_loading_rewarded = false
		_rewarded = null
		rewarded_availability_changed.emit(false)
		push_warning("[AdMob] Rewarded load failed: " + error.message)
	RewardedAdLoader.new().load(unit_id, AdRequest.new(), callback)

func show_rewarded(request_id: String) -> bool:
	if request_id.is_empty() or _rewarded == null or _fullscreen_ad_active:
		if _rewarded == null:
			_load_rewarded()
		return false
	var ad := _rewarded
	_rewarded = null
	_reward_request_id = request_id
	_reward_was_earned = false
	rewarded_availability_changed.emit(false)
	_set_fullscreen_ad_active(true)
	var reward_listener := OnUserEarnedRewardListener.new()
	reward_listener.on_user_earned_reward = func(_item: RewardedItem) -> void:
		if _reward_was_earned:
			return
		_reward_was_earned = true
		rewarded_earned.emit(_reward_request_id)
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		if not _reward_was_earned:
			rewarded_failed.emit(_reward_request_id, "Bạn cần xem hết video để nhận Lộc.")
		_finish_rewarded(ad)
	ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(error: AdError) -> void:
		rewarded_failed.emit(_reward_request_id, "Không mở được quảng cáo: " + error.message)
		_finish_rewarded(ad)
	ad.show(reward_listener)
	return true

func _finish_rewarded(ad: RewardedAd) -> void:
	ad.destroy()
	_reward_request_id = ""
	_reward_was_earned = false
	_set_fullscreen_ad_active(false)
	_load_rewarded()

func _set_fullscreen_ad_active(active: bool) -> void:
	if _fullscreen_ad_active == active:
		return
	_fullscreen_ad_active = active
	fullscreen_ad_state_changed.emit(active)

func show_privacy_options() -> void:
	UserMessagingPlatform.show_privacy_options_form()

func is_configured() -> bool:
	return ADMOB_APP_ID.begins_with("ca-app-pub-") \
		and "~" in ADMOB_APP_ID \
		and BANNER_UNIT_ID.begins_with("ca-app-pub-") \
		and "/" in BANNER_UNIT_ID \
		and INTERSTITIAL_UNIT_ID.begins_with("ca-app-pub-") \
		and "/" in INTERSTITIAL_UNIT_ID \
		and REWARDED_UNIT_ID.begins_with("ca-app-pub-") \
		and "/" in REWARDED_UNIT_ID

func is_banner_visible() -> bool:
	return _banner_visible

func is_rewarded_ready() -> bool:
	return _rewarded != null and not _fullscreen_ad_active

func is_fullscreen_ad_active() -> bool:
	return _fullscreen_ad_active

func on_bowl_covered(completed_rounds: int) -> void:
	if not is_configured():
		return
	if completed_rounds - _last_ad_round < ROUNDS_BETWEEN_ADS:
		return
	if _last_ad_time_ms > 0 and Time.get_ticks_msec() - _last_ad_time_ms < MIN_SECONDS_BETWEEN_ADS * 1000:
		return
	if interstitial_break_requested.get_connections().is_empty():
		return
	if _interstitial == null:
		_load_interstitial()
		return
	_last_ad_round = completed_rounds
	interstitial_break_requested.emit()
