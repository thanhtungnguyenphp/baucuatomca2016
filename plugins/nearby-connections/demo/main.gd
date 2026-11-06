extends Control

const SERVICE_ID := "vn.lamgame.nearby.demo"

var nearby := NearbyService.new()
var _display_name := "Device-%04d" % randi_range(1000, 9999)
var _pending_action := ""
var _pending_endpoint_id := ""
var _peer_id := ""
var _peer_buttons: Dictionary = {}
var _status: Label
var _log: RichTextLabel
var _peer_list: VBoxContainer
var _verify_dialog: ConfirmationDialog

func _ready() -> void:
	_build_ui()
	nearby.state_changed.connect(func(value: String) -> void: _set_status(value))
	nearby.error.connect(func(code: String, operation: String) -> void: _append("Lỗi %s: %s" % [code, operation]))
	nearby.endpoint_found.connect(_on_endpoint_found)
	nearby.endpoint_lost.connect(_on_endpoint_lost)
	nearby.connection_initiated.connect(_on_connection_initiated)
	nearby.connection_result.connect(_on_connection_result)
	nearby.endpoint_disconnected.connect(func(id: String) -> void:
		if _peer_id == id:
			_peer_id = ""
		_append("Đã ngắt: " + id)
	)
	nearby.payload_received.connect(_on_payload_received)
	nearby.permission_result.connect(_on_permission_result)
	_set_status("Sẵn sàng" if nearby.is_supported() else "Thiếu Google Play services / Android plugin")

func _exit_tree() -> void:
	nearby.stop_all()

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)
	var title := Label.new()
	title.text = "Nearby Connections · Echo Demo"
	title.add_theme_font_size_override("font_size", 30)
	column.add_child(title)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 24)
	column.add_child(_status)
	var row := HBoxContainer.new()
	column.add_child(row)
	_add_button(row, "Tạo phòng", func() -> void: _begin("host"))
	_add_button(row, "Tìm phòng", func() -> void: _begin("join"))
	_add_button(row, "Dừng", func() -> void:
		nearby.stop_all()
		_clear_peer_list()
	)
	_peer_list = VBoxContainer.new()
	column.add_child(_peer_list)
	_add_button(column, "Gửi PING", func() -> void:
		if not _peer_id.is_empty():
			nearby.send_bytes(_peer_id, "PING".to_utf8_buffer())
	)
	_log = RichTextLabel.new()
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.add_theme_font_size_override("normal_font_size", 21)
	column.add_child(_log)
	_verify_dialog = ConfirmationDialog.new()
	_verify_dialog.title = "Xác nhận thiết bị"
	_verify_dialog.ok_button_text = "Trùng mã · Kết nối"
	_verify_dialog.cancel_button_text = "Không trùng · Từ chối"
	add_child(_verify_dialog)
	_verify_dialog.confirmed.connect(_accept_pending)
	_verify_dialog.canceled.connect(_reject_pending)

func _add_button(parent: Node, label: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(0, 64)
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _clear_peer_list() -> void:
	_peer_buttons.clear()
	for child in _peer_list.get_children():
		_peer_list.remove_child(child)
		child.queue_free()

func _begin(action: String) -> void:
	if not nearby.is_supported():
		_append("Nearby chưa khả dụng trên máy này.")
		return
	if action == "join":
		_clear_peer_list()
	_pending_action = action
	if nearby.get_missing_permissions().is_empty():
		_run_pending_action()
	else:
		_append("Đang xin quyền Nearby cho chức năng chơi gần nhau.")
		nearby.request_permissions()

func _on_permission_result(granted: bool, missing: PackedStringArray) -> void:
	if granted:
		_run_pending_action()
	else:
		_append("Chưa có quyền: " + ", ".join(missing))

func _run_pending_action() -> void:
	match _pending_action:
		"host": nearby.start_advertising(SERVICE_ID, _display_name, "STAR")
		"join": nearby.start_discovery(SERVICE_ID, "STAR")
	_pending_action = ""

func _on_endpoint_found(id: String, name: String) -> void:
	if _peer_buttons.has(id):
		_peer_list.remove_child(_peer_buttons[id])
		_peer_buttons[id].queue_free()
	_append("Tìm thấy: " + name)
	_peer_buttons[id] = _add_button(_peer_list, "Vào phòng %s" % name, func() -> void:
		nearby.request_connection(id, _display_name)
	)

func _on_endpoint_lost(id: String) -> void:
	if _peer_buttons.has(id):
		_peer_list.remove_child(_peer_buttons[id])
		_peer_buttons[id].queue_free()
		_peer_buttons.erase(id)
	_append("Mất thiết bị: " + id)

func _on_connection_initiated(id: String, name: String, digits: String) -> void:
	_pending_endpoint_id = id
	_verify_dialog.dialog_text = "So mã trên cả hai máy trước khi chấp nhận:\n\n%s\n\nThiết bị: %s" % [digits, name]
	_verify_dialog.popup_centered()

func _accept_pending() -> void:
	if not _pending_endpoint_id.is_empty():
		nearby.accept_connection(_pending_endpoint_id)
		_pending_endpoint_id = ""

func _reject_pending() -> void:
	if not _pending_endpoint_id.is_empty():
		nearby.reject_connection(_pending_endpoint_id)
		_pending_endpoint_id = ""

func _on_connection_result(id: String, connected: bool, status_code: int) -> void:
	if _pending_endpoint_id == id:
		_pending_endpoint_id = ""
		_verify_dialog.hide()
	_append("Kết nối %s: %s (%d)" % [id, "thành công" if connected else "thất bại", status_code])
	if connected:
		_peer_id = id
		nearby.stop_discovery()

func _on_payload_received(id: String, bytes: PackedByteArray) -> void:
	var message := bytes.get_string_from_utf8()
	_append("Nhận: " + message)
	if message == "PING":
		nearby.send_bytes(id, "ECHO".to_utf8_buffer())

func _set_status(value: String) -> void:
	_status.text = "Trạng thái: " + value

func _append(value: String) -> void:
	_log.append_text(value + "\n")
