class_name PartyNearbyAdapterV2
extends Node

## Dealer/client game protocol v2. The reusable Nearby addon remains transport-only.
signal changed
signal rooms_changed
signal verification_needed(endpoint_id: String, name: String, digits: String)
signal notice(message: String)

const DealerPartyMatchScript := preload("res://scripts/core/dealer_party_match.gd")
const SERVICE_ID := "vn.lamgame.baucuatomca.party.v2"
const PROTOCOL_VERSION := 2
const MAX_MESSAGE_BYTES := 16 * 1024
const MAX_CLIENTS := 3

var nearby := NearbyService.new()
var mode := "idle" # idle, host, guest
var room_id := ""
var local_name := ""
var host_endpoint := ""
var local_seat := -1 # Host has no seat; client seats start at 1.
var local_player_id := ""
var players: Array[String] = [] # Client names only; host is excluded.
var rooms: Dictionary = {}
var state: Dictionary = {} # Empty in lobby; authoritative match snapshot after start.

var _match = DealerPartyMatchScript.new()
var _endpoints: Array[String] = []
var _endpoint_players: Dictionary = {}
var _last_seq: Dictionary = {}
var _processed_actions: Dictionary = {}
var _seq := 0
var _action_seq := 0
var _pending_action := ""
var _discovery_coarse_retry_attempted := false
var _discovery_fine_retry_attempted := false
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	nearby.endpoint_found.connect(_on_endpoint_found)
	nearby.endpoint_lost.connect(_on_endpoint_lost)
	nearby.connection_initiated.connect(_on_connection_initiated)
	nearby.connection_result.connect(_on_connection_result)
	nearby.endpoint_disconnected.connect(_on_endpoint_disconnected)
	nearby.payload_received.connect(_on_payload)
	nearby.permission_result.connect(_on_permission_result)
	nearby.error.connect(_on_nearby_error)

func _exit_tree() -> void:
	nearby.stop_all()

func available() -> bool:
	return nearby.is_supported()

func is_requesting_permissions() -> bool:
	return not _pending_action.is_empty()

func create_room(name: String) -> void:
	if not available():
		notice.emit("Chơi gần nhau chỉ dùng được trên Android có Google Play services.")
		return
	leave()
	mode = "host"
	local_name = _clean_name(name)
	room_id = "%06d" % _rng.randi_range(0, 999999)
	changed.emit()
	notice.emit("Đã tạo phòng. Máy này là chủ phòng và chỉ điều khiển tô.")
	_start_with_permissions("host")

func find_rooms(name: String) -> void:
	if not available():
		notice.emit("Chơi gần nhau chỉ dùng được trên Android có Google Play services.")
		return
	leave()
	mode = "guest"
	local_name = _clean_name(name)
	rooms.clear()
	rooms_changed.emit()
	changed.emit()
	notice.emit("Đang tìm phòng ở gần…")
	_start_with_permissions("guest")

func join_room(endpoint_id: String) -> void:
	if mode != "guest" or not rooms.has(endpoint_id) or not host_endpoint.is_empty():
		return
	host_endpoint = endpoint_id
	nearby.request_connection(endpoint_id, local_name)
	changed.emit()

func accept_pairing(endpoint_id: String) -> void:
	nearby.accept_connection(endpoint_id)

func reject_pairing(endpoint_id: String) -> void:
	nearby.reject_connection(endpoint_id)
	if mode == "guest" and endpoint_id == host_endpoint:
		host_endpoint = ""
		changed.emit()

func start_match() -> bool:
	if mode != "host" or _match.players.is_empty() or not _match.start_match():
		return false
	_processed_actions.clear()
	_publish_state()
	return true

func place_bet(symbol: String, amount: int) -> bool:
	if mode != "guest" or state.get("phase", "") != DealerPartyMatchScript.PHASE_BETTING:
		return false
	if not GameConstants.SYMBOLS.has(symbol) or not GameConstants.CHIP_VALUES.has(amount):
		return false
	_send_action("PLACE_BET", {"symbol": symbol, "amount": amount})
	return true

func clear_bets() -> bool:
	if mode != "guest" or state.get("phase", "") != DealerPartyMatchScript.PHASE_BETTING:
		return false
	_send_action("CLEAR_BETS", {})
	return true

func confirm_bets() -> bool:
	if mode != "guest" or state.get("phase", "") != DealerPartyMatchScript.PHASE_BETTING:
		return false
	_send_action("CONFIRM_BETS", {})
	return true

func request_reward(reward_id: String) -> bool:
	if mode != "guest" or reward_id.is_empty() or host_endpoint.is_empty():
		return false
	_send_action("REWARD_CLAIM", {"reward_id": reward_id})
	return true

func roll() -> bool:
	if mode != "host" or _match.phase != DealerPartyMatchScript.PHASE_LOCKED:
		return false
	if not _match.settle(RoundResolver.roll_results(_rng)):
		return false
	_publish_state()
	return true

func advance() -> bool:
	if mode != "host" or not _match.advance_round():
		return false
	_processed_actions.clear()
	_publish_state()
	return true

func get_local_player() -> Dictionary:
	if local_player_id.is_empty() or state.is_empty():
		return {}
	for player: Dictionary in state.get("players", []):
		if player.get("player_id", "") == local_player_id:
			return player
	return {}

func leave() -> void:
	if mode == "host":
		for endpoint in _endpoints:
			_send(endpoint, "LEAVE", {})
	nearby.stop_all()
	mode = "idle"
	room_id = ""
	host_endpoint = ""
	local_seat = -1
	local_player_id = ""
	players.clear()
	rooms.clear()
	state.clear()
	_endpoints.clear()
	_endpoint_players.clear()
	_last_seq.clear()
	_processed_actions.clear()
	_seq = 0
	_action_seq = 0
	_pending_action = ""
	_discovery_coarse_retry_attempted = false
	_discovery_fine_retry_attempted = false
	_match = DealerPartyMatchScript.new()
	rooms_changed.emit()
	changed.emit()

func _on_nearby_error(code: String, operation: String) -> void:
	if mode == "guest" and operation == "startDiscovery" and code == "SDK_8034" and not _discovery_coarse_retry_attempted:
		_discovery_coarse_retry_attempted = true
		_pending_action = "guest"
		notice.emit("Máy này cần thêm quyền vị trí gần đúng để tìm phòng ở gần.")
		nearby.request_permissions()
		return
	if mode == "guest" and operation == "startDiscovery" and code == "SDK_8036" and not _discovery_fine_retry_attempted:
		_discovery_fine_retry_attempted = true
		_pending_action = "guest"
		notice.emit("Máy này cần thêm quyền vị trí chính xác để tìm phòng ở gần.")
		nearby.request_permissions()
		return
	notice.emit("Kết nối lỗi: %s (%s)" % [code, operation])

func _start_with_permissions(action: String) -> void:
	_pending_action = action
	if nearby.get_missing_permissions().is_empty():
		_run_pending_action()
	else:
		notice.emit("Cần quyền thiết bị ở gần để tìm và kết nối phòng chơi.")
		nearby.request_permissions()

func _on_permission_result(granted: bool, missing: PackedStringArray) -> void:
	if granted:
		_run_pending_action()
	else:
		_pending_action = ""
		notice.emit("Chưa cấp quyền: " + ", ".join(missing))

func _run_pending_action() -> void:
	if _pending_action == "host" and mode == "host":
		nearby.start_advertising(SERVICE_ID, local_name, "STAR")
		notice.emit("Phòng đã sẵn sàng. Chờ người chơi vào phòng.")
	elif _pending_action == "guest" and mode == "guest":
		nearby.start_discovery(SERVICE_ID, "STAR")
		notice.emit("Đang tìm phòng ở gần…")
	_pending_action = ""

func _on_endpoint_found(id: String, name: String) -> void:
	if mode == "guest" and host_endpoint.is_empty():
		rooms[id] = name
		rooms_changed.emit()

func _on_endpoint_lost(id: String) -> void:
	if rooms.erase(id):
		rooms_changed.emit()

func _on_connection_initiated(id: String, name: String, digits: String) -> void:
	if mode == "idle":
		nearby.reject_connection(id)
		return
	if mode == "host" and (_endpoints.size() >= MAX_CLIENTS or _match.phase != DealerPartyMatchScript.PHASE_LOBBY):
		nearby.reject_connection(id)
		return
	if mode == "guest" and id != host_endpoint:
		nearby.reject_connection(id)
		return
	verification_needed.emit(id, _clean_name(name), digits)

func _on_connection_result(id: String, connected: bool, status_code: int) -> void:
	if mode == "idle":
		if connected:
			nearby.disconnect_endpoint(id)
		return
	if not connected:
		if mode == "guest" and id == host_endpoint:
			host_endpoint = ""
		notice.emit("Không kết nối được (%d)." % status_code)
		changed.emit()
		return
	_last_seq[id] = 0
	if mode == "guest" and id == host_endpoint:
		nearby.stop_discovery()
		_send(id, "HELLO", {"name": local_name})
		changed.emit()

func _on_endpoint_disconnected(id: String) -> void:
	_last_seq.erase(id)
	if mode == "guest" and id == host_endpoint:
		_close_guest_room("Chủ phòng đã ngắt kết nối. Ván chơi kết thúc.")
	elif mode == "host" and _endpoint_players.has(id):
		var player_id: String = _endpoint_players[id]
		_endpoint_players.erase(id)
		_endpoints.erase(id)
		_match.disconnect_player(player_id)
		_processed_actions.clear()
		if _match.phase == DealerPartyMatchScript.PHASE_LOBBY or _match.players.is_empty():
			_publish_lobby()
		else:
			_publish_state()
		notice.emit("Một người chơi đã rời phòng; cược chưa chốt đã được hoàn.")

func _on_payload(id: String, bytes: PackedByteArray) -> void:
	if bytes.is_empty() or bytes.size() > MAX_MESSAGE_BYTES:
		return
	if mode == "host" and not _last_seq.has(id):
		return
	if mode == "guest" and id != host_endpoint:
		return
	var parsed: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if not parsed is Dictionary:
		return
	var msg: Dictionary = parsed
	if msg.get("v") != PROTOCOL_VERSION:
		notice.emit("Phiên bản game không tương thích. Hãy cập nhật cả hai máy.")
		nearby.disconnect_endpoint(id)
		return
	if not _is_int_number(msg.get("seq")) or not msg.get("type") is String or not msg.get("payload") is Dictionary:
		return
	var seq := int(msg["seq"])
	if seq <= int(_last_seq.get(id, 0)) or seq < 1:
		return
	var kind: String = msg["type"]
	var payload: Dictionary = msg["payload"]
	if mode == "host":
		if kind == "HELLO" and str(msg.get("room", "")).is_empty():
			_last_seq[id] = seq
			_accept_hello(id, payload)
		elif str(msg.get("room", "")) == room_id and _endpoint_players.has(id):
			_last_seq[id] = seq
			if kind == "LEAVE":
				nearby.disconnect_endpoint(id)
			else:
				_accept_client_action(id, kind, payload)
	elif mode == "guest":
		if not room_id.is_empty() and str(msg.get("room", "")) != room_id:
			return
		_last_seq[id] = seq
		if kind == "STATE":
			_accept_state(payload)
		elif kind == "ACTION_RESULT":
			notice.emit(str(payload.get("message", "Đã cập nhật.")))
		elif kind == "LEAVE":
			_close_guest_room("Chủ phòng đã đóng phòng.")
		elif kind == "ERROR":
			notice.emit(str(payload.get("message", "Kết nối phòng gặp lỗi.")))

func _accept_hello(id: String, payload: Dictionary) -> void:
	if _endpoint_players.has(id):
		_send_state(id)
		return
	if _match.players.size() >= MAX_CLIENTS or _match.phase != DealerPartyMatchScript.PHASE_LOBBY:
		nearby.disconnect_endpoint(id)
		return
	var player_id := "p%d-%06d" % [_match.players.size() + 1, _rng.randi_range(0, 999999)]
	if not _match.add_player(player_id, _clean_name(str(payload.get("name", "Người chơi")))):
		nearby.disconnect_endpoint(id)
		return
	_endpoints.append(id)
	_endpoint_players[id] = player_id
	_publish_lobby()

func _accept_client_action(id: String, kind: String, payload: Dictionary) -> void:
	if not ["PLACE_BET", "CLEAR_BETS", "CONFIRM_BETS", "REWARD_CLAIM"].has(kind):
		_send_action_result(id, kind, false, "Thao tác không được hỗ trợ.")
		return
	var action_id := str(payload.get("action_id", ""))
	if action_id.is_empty() or action_id.length() > 64:
		_send_action_result(id, kind, false, "Mã thao tác không hợp lệ.")
		return
	var action_key := id + ":" + action_id
	if _processed_actions.has(action_key):
		_send_state(id)
		return
	_processed_actions[action_key] = true
	var player_id: String = _endpoint_players[id]
	var accepted := false
	var message := "Không thể thực hiện lúc này."
	if kind == "REWARD_CLAIM":
		accepted = _match.grant_reward(player_id, str(payload.get("reward_id", "")))
		message = "Đã nhận %s." % GameConstants.format_luck(DealerPartyMatchScript.REWARD_AMOUNT) if accepted else "Không thể nhận thêm Lộc lúc này."
	else:
		if payload.get("round") != _match.round_number:
			_send_action_result(id, kind, false, "Lượt đặt đã hết hạn.")
			return
		match kind:
			"PLACE_BET":
				if _is_int_number(payload.get("amount")):
					accepted = _match.place_bet(player_id, str(payload.get("symbol", "")), int(payload["amount"]))
				message = "Đã nhận cược." if accepted else "Cược không hợp lệ hoặc vượt số dư."
			"CLEAR_BETS":
				accepted = _match.clear_bets(player_id)
				message = "Đã xóa cược." if accepted else "Không thể xóa cược đã xác nhận."
			"CONFIRM_BETS":
				accepted = _match.confirm_bets(player_id)
				message = "Đã khóa cược, chờ chủ phòng lắc." if accepted else "Hãy đặt ít nhất một chip trước khi xác nhận."
	_send_action_result(id, kind, accepted, message)
	if accepted:
		_publish_state()

func _accept_state(payload: Dictionary) -> bool:
	if not payload.get("room") is String or not _is_int_number(payload.get("seat")) or not payload.get("player_id") is String or not payload.get("players") is Array or not payload.get("match") is Dictionary:
		return false
	var incoming_room: String = payload["room"]
	var incoming_names: Array = payload["players"]
	var incoming_player_id: String = payload["player_id"]
	var seat := int(payload["seat"])
	if incoming_room.length() != 6 or incoming_player_id.is_empty() or incoming_names.size() < 1 or incoming_names.size() > MAX_CLIENTS or seat < 1 or seat > MAX_CLIENTS:
		return false
	for name: Variant in incoming_names:
		if not name is String or name.length() > 24:
			return false
	var incoming_match: Dictionary = payload["match"]
	if not incoming_match.is_empty() and not _valid_match(incoming_match, incoming_names.size()):
		return false
	if not room_id.is_empty() and incoming_room != room_id:
		return false
	room_id = incoming_room
	local_seat = seat
	local_player_id = incoming_player_id
	players.clear()
	for name: String in incoming_names:
		players.append(name)
	state = _normalize_match(incoming_match)
	changed.emit()
	return true

func _valid_match(value: Dictionary, count: int) -> bool:
	if not value.get("phase") is String or not _is_int_number(value.get("round_number")) or not value.get("players") is Array or not value.get("results") is Array or not value.get("leaderboard") is Array:
		return false
	if not ["betting", "locked", "settled", "finished"].has(value["phase"]):
		return false
	if int(value["round_number"]) < 1 or int(value["round_number"]) > DealerPartyMatchScript.TOTAL_ROUNDS or value["players"].size() != count:
		return false
	if not (value["results"].is_empty() or value["results"].size() == 3):
		return false
	for symbol: Variant in value["results"]:
		if not symbol is String or not GameConstants.SYMBOLS.has(symbol):
			return false
	for player: Variant in value["players"]:
		if not player is Dictionary or not _valid_player(player):
			return false
	return value["leaderboard"].size() == count

func _valid_player(player: Dictionary) -> bool:
	if not player.get("player_id") is String or not player.get("name") is String or not player.get("bets") is Dictionary:
		return false
	for key in ["seat", "balance", "round_stake", "round_payout", "round_net", "total_net", "wins", "reward_count"]:
		if not _is_int_number(player.get(key)):
			return false
	if int(player["seat"]) < 1 or int(player["seat"]) > MAX_CLIENTS or int(player["balance"]) < 0:
		return false
	for symbol in GameConstants.SYMBOLS:
		if not _is_int_number(player["bets"].get(symbol, 0)) or int(player["bets"].get(symbol, 0)) < 0:
			return false
	return true

func _normalize_match(value: Dictionary) -> Dictionary:
	if value.is_empty():
		return {}
	var normalized := value.duplicate(true)
	normalized["round_number"] = int(normalized["round_number"])
	var normalized_players: Array[Dictionary] = []
	for source: Dictionary in normalized["players"]:
		var player := source.duplicate(true)
		for key in ["seat", "balance", "round_stake", "round_payout", "round_net", "total_net", "wins", "reward_count"]:
			player[key] = int(player[key])
		for symbol in GameConstants.SYMBOLS:
			player["bets"][symbol] = int(player["bets"].get(symbol, 0))
		normalized_players.append(player)
	normalized["players"] = normalized_players
	var normalized_board: Array[Dictionary] = []
	for source: Dictionary in normalized["leaderboard"]:
		var row := source.duplicate(true)
		for key in ["rank", "seat", "balance", "round_net", "total_net", "wins"]:
			row[key] = int(row.get(key, 0))
		normalized_board.append(row)
	normalized["leaderboard"] = normalized_board
	return normalized

func _publish_lobby() -> void:
	_sync_public_state()
	for endpoint in _endpoints:
		_send_state(endpoint)
	changed.emit()

func _publish_state() -> void:
	_sync_public_state()
	for endpoint in _endpoints:
		_send_state(endpoint)
	changed.emit()

func _sync_public_state() -> void:
	players.clear()
	for player: Dictionary in _match.players:
		players.append(player["name"])
	state = {} if _match.phase == DealerPartyMatchScript.PHASE_LOBBY else _match.snapshot()

func _send_state(endpoint: String) -> void:
	if not _endpoint_players.has(endpoint):
		return
	var player_id: String = _endpoint_players[endpoint]
	var player := _match.get_player(player_id)
	if player.is_empty():
		return
	_send(endpoint, "STATE", {
		"room": room_id,
		"seat": int(player["seat"]),
		"player_id": player_id,
		"players": players,
		"match": state,
	})

func _send_action(kind: String, data: Dictionary) -> void:
	_action_seq += 1
	var payload := data.duplicate(true)
	payload["action_id"] = "%d-%d" % [int(state.get("round_number", 0)), _action_seq]
	if kind != "REWARD_CLAIM":
		payload["round"] = int(state.get("round_number", 0))
	_send(host_endpoint, kind, payload)

func _send_action_result(endpoint: String, action: String, accepted: bool, message: String) -> void:
	_send(endpoint, "ACTION_RESULT", {"action": action, "accepted": accepted, "message": message})

func _send(endpoint: String, kind: String, payload: Dictionary) -> void:
	if endpoint.is_empty():
		return
	_seq += 1
	var msg := {"v": PROTOCOL_VERSION, "room": room_id, "seq": _seq, "type": kind, "payload": payload}
	var bytes := JSON.stringify(msg).to_utf8_buffer()
	if bytes.size() <= MAX_MESSAGE_BYTES:
		nearby.send_bytes(endpoint, bytes)

func _close_guest_room(message: String) -> void:
	nearby.stop_all()
	mode = "idle"
	room_id = ""
	host_endpoint = ""
	local_seat = -1
	local_player_id = ""
	state.clear()
	players.clear()
	rooms.clear()
	rooms_changed.emit()
	notice.emit(message)
	changed.emit()

func _clean_name(value: String) -> String:
	var clean := value.strip_edges().substr(0, 24)
	return clean if not clean.is_empty() else "Người chơi"

func _is_int_number(value: Variant) -> bool:
	return (value is int or value is float) and float(value) == floorf(float(value))
