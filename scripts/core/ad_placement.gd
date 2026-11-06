extends Node

const ADMOB_APP_ID := "ca-app-pub-6352554924566967~6336109870"
const BANNER_UNIT_ID := "ca-app-pub-6352554924566967/5111492266"
const INTERSTITIAL_UNIT_ID := "ca-app-pub-6352554924566967/4875241431"
const TEST_BANNER_UNIT_ID := "ca-app-pub-3940256099942544/6300978111"
const TEST_INTERSTITIAL_UNIT_ID := "ca-app-pub-3940256099942544/1033173712"
const ROUNDS_BETWEEN_ADS := 8
const MIN_SECONDS_BETWEEN_ADS := 180

signal interstitial_break_requested
signal privacy_options_available(available: bool)
signal banner_visibility_changed(visible: bool)

var _last_ad_round := 0
var _last_ad_time_ms := 0
var _banner: AdView
var _interstitial: InterstitialAd
var _loading_interstitial := false
var _banner_visible := false

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
	privacy_options_available.emit(required == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED)
	if status == ConsentInformation.ConsentStatus.REQUIRED:
		UserMessagingPlatform.load_consent_form(_on_form_loaded, _on_form_failed)
	else:
		_start_ads_if_permitted()

func _on_form_loaded(form: ConsentForm) -> void:
	form.show(func(_error: FormError) -> void: _start_ads_if_permitted())

func _on_form_failed(error: FormError) -> void:
	push_warning("[AdMob] Consent form unavailable: " + error.message)
	_start_ads_if_permitted()

func _on_consent_failed(error: FormError) -> void:
	push_warning("[AdMob] Consent update failed: " + error.message)
	_start_ads_if_permitted()

func _start_ads_if_permitted() -> void:
	var status := UserMessagingPlatform.consent_information.get_consent_status()
	if status != ConsentInformation.ConsentStatus.OBTAINED \
		and status != ConsentInformation.ConsentStatus.NOT_REQUIRED:
		print("[AdMob] Ads waiting for consent, status: ", status)
		return
	print("[AdMob] Starting banner and interstitial loading")
	MobileAds.initialize()
	var banner_id := TEST_BANNER_UNIT_ID if OS.is_debug_build() else BANNER_UNIT_ID
	_banner = AdView.new(banner_id, AdSize.BANNER, AdPosition.BOTTOM)
	_banner.ad_listener.on_ad_loaded = func() -> void:
		_banner_visible = true
		banner_visibility_changed.emit(true)
		print("[AdMob] Banner loaded")
	_banner.ad_listener.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_banner_visible = false
		banner_visibility_changed.emit(false)
		push_warning("[AdMob] Banner load failed: " + error.message)
	_banner.load_ad(AdRequest.new())
	_load_interstitial()

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
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		ad.destroy()
		_load_interstitial()
	ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void:
		ad.destroy()
		_load_interstitial()
	ad.show()

func show_privacy_options() -> void:
	UserMessagingPlatform.show_privacy_options_form()

func is_configured() -> bool:
	return ADMOB_APP_ID.begins_with("ca-app-pub-") \
		and "~" in ADMOB_APP_ID \
		and INTERSTITIAL_UNIT_ID.begins_with("ca-app-pub-") \
		and "/" in INTERSTITIAL_UNIT_ID

func is_banner_visible() -> bool:
	return _banner_visible

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
