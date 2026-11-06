@tool
extends EditorPlugin

var _export_plugin: EditorExportPlugin

func _enter_tree() -> void:
	_export_plugin = NearbyExportPlugin.new()
	add_export_plugin(_export_plugin)

func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null

class NearbyExportPlugin extends EditorExportPlugin:
	func _get_name() -> String:
		return "NearbyConnections"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(_platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		var flavor := "debug" if debug else "release"
		return PackedStringArray([
			"godot_nearby/bin/%s/nearby-core-%s.aar" % [flavor, flavor],
			"godot_nearby/bin/%s/godot-bridge-%s.aar" % [flavor, flavor]
		])

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray([
			"com.google.android.gms:play-services-nearby:19.3.0",
			"org.jetbrains.kotlin:kotlin-stdlib:2.1.21"
		])
