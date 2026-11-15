class_name PartyNearbyAdapter
extends Node

## Game-specific room protocol. The Nearby addon remains transport-only.
signal changed
signal rooms_changed
signal verification_needed(endpoint_id: String, name: String, digits: String)
signal notice(message: String)

const SERVICE_ID := "vn.lamgame.baucuatomca.party.v1"
const PROTOCOL_VERSION := 1
const MAX_MESSAGE_BYTES := 4096
const MAX_PLAYERS := 4

var nearby := NearbyService.new()
var mode := "idle" # idle, host, guest
var room_id := ""
var local_name := ""
var host_endpoint := ""
var local_seat := -1
var players: Array[String] = []
var rooms: Dictionary = {} # endpoint -> advertised name
var state: Dictionary = {}
var _match := PartyMatch.new()
var _endpoints: Array[String] = [] # seat 1..3, host only
var _last_seq: Dictionary = {}
var _seq := 0
var _pending_action := ""
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
	nearby.error.connect(func(code: String, operation: String) -> void:
		notice.emit("Kết nối lỗi: %s (%s)" % [code, operation])
	)

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
	local_seat = 0
	room_id = "%06d" % _rng.randi_range(0, 999999)
	players = [local_name]
	state = {}
	changed.emit()
	notice.emit("Đã tạo phòng. Chờ bạn bè tìm thấy và vào phòng.")
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
	if mode != "host" or players.size() < 2 or players.size() > MAX_PLAYERS:
		return false
	if not state.is_empty() and state.get("phase", "") != "finished":
		return false
	_match.set_player_count(players.size())
	if not _match.start():
		return false
	_publish_state()
	return true

func choose(symbol: String) -> bool:
	if not GameConstants.SYMBOLS.has(symbol) or state.get("phase", "") != "choose":
		return false
	if local_seat < 0 or local_seat >= players.size():
		return false
	var choices: Array = state.get("choices", [])
	if local_seat >= choices.size() or not str(choices[local_seat]).is_empty():
		return false
	if mode == "host":
		if not _match.set_choice(0, symbol):
			return false
		_publish_state()
	else:
		_send(host_endpoint, "CHOICE", {"turn": int(state.get("turn_number", 0)), "symbol": symbol})
		notice.emit("Đã gửi lựa chọn, chờ chủ phòng xác nhận.")
	return true

func roll() -> bool:
	if mode != "host" or not _match.all_chosen():
		return false
	var results := RoundResolver.roll_results(_rng)
	if not _match.settle(results):
		return false
	_publish_state()
	return true

func advance() -> bool:
	if mode != "host" or not _match.advance():
		return false
	_publish_state()
	return true

func leave() -> void:
	if mode == "host":
		for endpoint in _endpoints:
			_send(endpoint, "LEAVE", {})
	nearby.stop_all()
	mode = "idle"
	room_id = ""
	host_endpoint = ""
	local_seat = -1
	players.clear()
	rooms.clear()
	state.clear()
	_endpoints.clear()
	_last_seq.clear()
	_seq = 0
	_pending_action = ""
	rooms_changed.emit()
	changed.emit()

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
	elif _pending_action == "guest" and mode == "guest":
		nearby.start_discovery(SERVICE_ID, "STAR")
	_pending_action = ""

func _on_endpoint_found(id: String, name: String) -> void:
	if mode != "guest" or not host_endpoint.is_empty():
		return
	rooms[id] = name
	rooms_changed.emit()

func _on_endpoint_lost(id: String) -> void:
	if rooms.erase(id):
		rooms_changed.emit()

func _on_connection_initiated(id: String, name: String, digits: String) -> void:
	if mode == "idle":
		nearby.reject_connection(id)
		return
	if mode == "host" and (players.size() >= MAX_PLAYERS or not state.is_empty() and state.get("phase", "") != "finished"):
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
	if mode == "host":
		# A connected endpoint must send HELLO before it receives a seat.
		return
	if mode == "guest" and id == host_endpoint:
		nearby.stop_discovery()
		_send(id, "HELLO", {"name": local_name})
		changed.emit()

func _on_endpoint_disconnected(id: String) -> void:
	_last_seq.erase(id)
	if mode == "guest" and id == host_endpoint:
		nearby.stop_all()
		mode = "idle"
		host_endpoint = ""
		room_id = ""
		local_seat = -1
		state.clear()
		players.clear()
		notice.emit("Chủ phòng đã ngắt kết nối. Ván chơi kết thúc.")
		changed.emit()
	elif mode == "host" and _endpoints.has(id):
		var seat := _endpoints.find(id) + 1
		_endpoints.remove_at(seat - 1)
		players.remove_at(seat)
		if not state.is_empty() and state.get("phase", "") != "finished":
			_match = PartyMatch.new()
			state.clear()
			notice.emit("Một người đã rời phòng. Ván hiện tại dừng; chủ phòng có thể bắt đầu lại.")
		_publish_lobby()

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
	if msg.get("v") != PROTOCOL_VERSION or not _is_int_number(msg.get("seq")) or not msg.get("type") is String or not msg.get("payload") is Dictionary:
		return
	var seq: int = int(msg["seq"])
	if seq <= int(_last_seq.get(id, 0)) or seq < 1:
		return
	var kind: String = msg["type"]
	var payload: Dictionary = msg["payload"]
	if mode == "host":
		if kind == "HELLO" and str(msg.get("room", "")).is_empty():
			_last_seq[id] = seq
			_accept_hello(id, payload)
		elif str(msg.get("room", "")) == room_id and _endpoints.has(id):
			_last_seq[id] = seq
			if kind == "CHOICE":
				_accept_choice(id, payload)
			elif kind == "LEAVE":
				nearby.disconnect_endpoint(id)
	elif mode == "guest":
		if kind == "STATE" and (room_id.is_empty() or str(msg.get("room", "")) == room_id):
			if str(msg.get("room", "")) == str(payload.get("room", "")) and _accept_state(payload):
				_last_seq[id] = seq
		elif kind == "LEAVE" and str(msg.get("room", "")) == room_id:
			nearby.stop_all()
			mode = "idle"
			room_id = ""
			host_endpoint = ""
			state.clear()
			players.clear()
			local_seat = -1
			notice.emit("Chủ phòng đã đóng phòng.")
			changed.emit()

func _accept_hello(id: String, payload: Dictionary) -> void:
	if _endpoints.has(id):
		_send_state(id)
		return
	if players.size() >= MAX_PLAYERS or not state.is_empty() and state.get("phase", "") != "finished":
		nearby.disconnect_endpoint(id)
		return
	_endpoints.append(id)
	players.append(_clean_name(str(payload.get("name", "Người chơi"))))
	_publish_lobby()

func _accept_choice(id: String, payload: Dictionary) -> void:
	if state.get("phase", "") != "choose" or payload.get("turn") != _match.turn_number:
		return
	var symbol: String = str(payload.get("symbol", ""))
	var seat := _endpoints.find(id) + 1
	if seat <= 0 or not _match.set_choice(seat, symbol):
		return
	_publish_state()

func _accept_state(payload: Dictionary) -> bool:
	if not payload.get("room") is String or not _is_int_number(payload.get("seat")) or not payload.get("players") is Array or not payload.get("match") is Dictionary:
		return false
	var incoming_room: String = payload["room"]
	var incoming_players: Array = payload["players"]
	var seat: int = int(payload["seat"])
	if incoming_room.length() != 6 or incoming_players.size() < 1 or incoming_players.size() > MAX_PLAYERS or seat < 1 or seat >= incoming_players.size():
		return false
	for name: Variant in incoming_players:
		if not name is String or name.length() > 24:
			return false
	var incoming_match: Dictionary = payload["match"]
	if not incoming_match.is_empty() and not _valid_match(incoming_match, incoming_players.size()):
		return false
	if not room_id.is_empty() and incoming_room != room_id:
		return false
	room_id = incoming_room
	local_seat = seat
	players.clear()
	for name: String in incoming_players:
		players.append(name)
	state = incoming_match.duplicate(true)
	if not state.is_empty():
		state["player_count"] = int(state["player_count"])
		state["turn_number"] = int(state["turn_number"])
		state["chooser"] = int(state["chooser"])
		var normalized_scores: Array[int] = []
		for score: Variant in state["scores"]:
			normalized_scores.append(int(score))
		state["scores"] = normalized_scores
	changed.emit()
	return true

func _valid_match(value: Dictionary, count: int) -> bool:
	if value.get("player_count") != count or not _is_int_number(value.get("turn_number")) or not _is_int_number(value.get("chooser")) or not value.get("scores") is Array or not value.get("choices") is Array or not value.get("last_results") is Array:
		return false
	if int(value["turn_number"]) < 1 or int(value["turn_number"]) > PartyMatch.TOTAL_TURNS or int(value["chooser"]) < 0 or int(value["chooser"]) > count:
		return false
	if value["scores"].size() != count or value["choices"].size() != count or value["last_results"].size() > 3:
		return false
	if not ["choose", "revealed", "finished"].has(value.get("phase", "")):
		return false
	for score: Variant in value["scores"]:
		if not _is_int_number(score) or score < 0 or score > PartyMatch.TOTAL_TURNS * 3:
			return false
	for symbol: Variant in value["choices"]:
		if not symbol is String or not (symbol.is_empty() or GameConstants.SYMBOLS.has(symbol)):
			return false
	for symbol: Variant in value["last_results"]:
		if not symbol is String or not GameConstants.SYMBOLS.has(symbol):
			return false
	return true

func _publish_lobby() -> void:
	state.clear()
	for endpoint in _endpoints:
		_send_state(endpoint)
	changed.emit()

func _publish_state() -> void:
	state = _match.snapshot()
	for endpoint in _endpoints:
		_send_state(endpoint)
	changed.emit()

func _send_state(endpoint: String) -> void:
	var seat := _endpoints.find(endpoint) + 1
	if seat <= 0:
		return
	_send(endpoint, "STATE", {"room": room_id, "seat": seat, "players": players, "match": state})

func _send(endpoint: String, kind: String, payload: Dictionary) -> void:
	if endpoint.is_empty():
		return
	_seq += 1
	var msg := {"v": PROTOCOL_VERSION, "room": room_id, "seq": _seq, "type": kind, "payload": payload}
	var bytes := JSON.stringify(msg).to_utf8_buffer()
	if bytes.size() <= MAX_MESSAGE_BYTES:
		nearby.send_bytes(endpoint, bytes)

func _clean_name(value: String) -> String:
	var clean := value.strip_edges().substr(0, 24)
	return clean if not clean.is_empty() else "Người chơi"

func _is_int_number(value: Variant) -> bool:
	return (value is int or value is float) and float(value) == floorf(float(value))
