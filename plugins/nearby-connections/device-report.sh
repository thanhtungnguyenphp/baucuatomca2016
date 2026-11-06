#!/usr/bin/env bash
set -euo pipefail

if ! command -v adb >/dev/null 2>&1; then
    printf 'adb is required (Android platform-tools).\n' >&2
    exit 2
fi

serials=("$@")
if [ "${#serials[@]}" -eq 0 ]; then
    while IFS= read -r serial; do
        [ -n "$serial" ] && serials+=("$serial")
    done < <(adb devices | awk 'NR > 1 && $2 == "device" { print $1 }')
fi
if [ "${#serials[@]}" -eq 0 ]; then
    printf 'No authorized Android device is visible to adb.\n' >&2
    exit 2
fi

read_setting() {
    local serial="$1" namespace="$2" key="$3"
    adb -s "$serial" shell settings get "$namespace" "$key" 2>/dev/null | tr -d '\r'
}

package_status() {
    local serial="$1" package="$2"
    if adb -s "$serial" shell pm path "$package" 2>/dev/null | rg -q '^package:'; then
        printf 'installed'
    else
        printf 'absent'
    fi
}

for serial in "${serials[@]}"; do
    if ! adb -s "$serial" get-state 2>/dev/null | rg -q '^device$'; then
        printf '%s: not authorized or disconnected\n' "$serial" >&2
        continue
    fi
    model="$(adb -s "$serial" shell getprop ro.product.model | tr -d '\r')"
    api="$(adb -s "$serial" shell getprop ro.build.version.sdk | tr -d '\r')"
    android="$(adb -s "$serial" shell getprop ro.build.version.release | tr -d '\r')"
    printf '\nDevice %s: %s, Android %s (API %s)\n' "$serial" "$model" "$android" "$api"
    printf 'Radio: bluetooth=%s wifi=%s location_mode=%s\n' \
        "$(read_setting "$serial" global bluetooth_on)" \
        "$(read_setting "$serial" global wifi_on)" \
        "$(read_setting "$serial" secure location_mode)"
    printf 'Google Play services: %s\n' "$(package_status "$serial" com.google.android.gms)"
    for package in \
        vn.lamgame.nearby.demo \
        vn.lamgame.nearby.androiddemo \
        vn.lamgame.baucuatomca \
        vn.lamgame.baucuatomca.dev; do
        printf '%s: %s\n' "$package" "$(package_status "$serial" "$package")"
    done
    for package in vn.lamgame.nearby.demo vn.lamgame.nearby.androiddemo; do
        if [ "$(package_status "$serial" "$package")" != installed ]; then
            continue
        fi
        printf 'Runtime permission grants for %s:\n' "$package"
        adb -s "$serial" shell dumpsys package "$package" \
            | tr -d '\r' \
            | rg 'android.permission.(ACCESS_FINE_LOCATION|ACCESS_COARSE_LOCATION|BLUETOOTH_ADVERTISE|BLUETOOTH_CONNECT|BLUETOOTH_SCAN|NEARBY_WIFI_DEVICES): granted=' \
            || true
    done
done
