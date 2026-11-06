#!/usr/bin/env bash
set -euo pipefail

plugin_root="$(cd "$(dirname "$0")" && pwd)"
addon_bin="$plugin_root/../../addons/godot_nearby/bin"
mkdir -p "$addon_bin/debug" "$addon_bin/release"
cp "$plugin_root/nearby-core/build/outputs/aar/nearby-core-debug.aar" "$addon_bin/debug/"
cp "$plugin_root/nearby-core/build/outputs/aar/nearby-core-release.aar" "$addon_bin/release/"
cp "$plugin_root/godot-bridge/build/outputs/aar/godot-bridge-debug.aar" "$addon_bin/debug/"
cp "$plugin_root/godot-bridge/build/outputs/aar/godot-bridge-release.aar" "$addon_bin/release/"
mkdir -p "$plugin_root/demo/addons"
cp -R "$plugin_root/../../addons/godot_nearby" "$plugin_root/demo/addons/"
