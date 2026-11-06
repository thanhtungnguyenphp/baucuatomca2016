class_name NearbyService
extends RefCounted

signal state_changed(state: String)
signal error(code: String, operation: String)
signal endpoint_found(endpoint_id: String, name: String)
signal endpoint_lost(endpoint_id: String)
signal connection_initiated(endpoint_id: String, name: String, authentication_digits: String)
signal connection_result(endpoint_id: String, connected: bool, status_code: int)
signal endpoint_disconnected(endpoint_id: String)
signal payload_received(endpoint_id: String, bytes: PackedByteArray)
signal permission_result(granted: bool, missing: PackedStringArray)

var _native: Object

func _init() -> void:
	if not Engine.has_singleton("NearbyConnections"):
		return
	_native = Engine.get_singleton("NearbyConnections")
	_native.state_changed.connect(func(value: String) -> void: state_changed.emit(value))
	_native.error.connect(func(code: String, operation: String) -> void: error.emit(code, operation))
	_native.endpoint_found.connect(func(id: String, name: String) -> void: endpoint_found.emit(id, name))
	_native.endpoint_lost.connect(func(id: String) -> void: endpoint_lost.emit(id))
	_native.connection_initiated.connect(func(id: String, name: String, digits: String) -> void:
		connection_initiated.emit(id, name, digits)
	)
	_native.connection_result.connect(func(id: String, connected: bool, code: int) -> void:
		connection_result.emit(id, connected, code)
	)
	_native.endpoint_disconnected.connect(func(id: String) -> void: endpoint_disconnected.emit(id))
	_native.payload_received.connect(func(id: String, base64: String) -> void:
		payload_received.emit(id, Marshalls.base64_to_raw(base64))
	)
	_native.permission_result.connect(func(granted: bool, missing: String) -> void:
		permission_result.emit(granted, _parse_permissions(missing))
	)

func is_supported() -> bool:
	return _native != null and _native.isAvailable()

func get_state() -> String:
	return _native.getState() if _native != null else "UNAVAILABLE"

func get_missing_permissions() -> PackedStringArray:
	return _parse_permissions(_native.getMissingPermissions()) if _native != null else PackedStringArray()

func request_permissions() -> void:
	if _native != null:
		_native.requestPermissions()

func start_advertising(service_id: String, display_name: String, topology: String = "STAR") -> void:
	if _native != null:
		_native.startAdvertising(service_id, display_name, topology)

func start_discovery(service_id: String, topology: String = "STAR") -> void:
	if _native != null:
		_native.startDiscovery(service_id, topology)

func stop_discovery() -> void:
	if _native != null:
		_native.stopDiscovery()

func request_connection(endpoint_id: String, display_name: String) -> void:
	if _native != null:
		_native.requestConnection(endpoint_id, display_name)

func accept_connection(endpoint_id: String) -> void:
	if _native != null:
		_native.acceptConnection(endpoint_id)

func reject_connection(endpoint_id: String) -> void:
	if _native != null:
		_native.rejectConnection(endpoint_id)

func send_bytes(endpoint_id: String, bytes: PackedByteArray) -> void:
	if _native != null:
		_native.sendBytes(endpoint_id, Marshalls.raw_to_base64(bytes))

func disconnect_endpoint(endpoint_id: String) -> void:
	if _native != null:
		_native.call("disconnect", endpoint_id)

func stop_all() -> void:
	if _native != null:
		_native.stopAll()

func _parse_permissions(raw: String) -> PackedStringArray:
	return PackedStringArray() if raw.is_empty() else PackedStringArray(raw.split("|"))
