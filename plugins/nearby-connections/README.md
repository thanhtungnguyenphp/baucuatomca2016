# Godot Nearby Connections

Reusable Android Nearby Connections transport in two modules:

- `nearby-core`: Kotlin Android library with no Godot or game dependency.
- `godot-bridge`: Godot 4.7 Android plugin v2 adapter. The distributable addon is `../../addons/godot_nearby`.

The two-device byte echo demo passed on Android 15 (Godot host) and Android 11 (Kotlin guest) on 2026-11-06. See `../../docs/nearby/PROGRESS.md` for the device matrix and remaining tests. The game must not depend on the plugin until that flow and the four-device `P2P_STAR` flow are verified on real phones.

## Build

Use JDK 17+ and Android SDK 36. Run `./gradlew assembleDebug assembleRelease` in this directory, then `./sync-addon.sh` to copy both AARs into `../../addons/godot_nearby/bin`. Godot Android export requires Gradle build. The addon declares the Nearby and Kotlin runtime Maven dependencies.

Do not commit `local.properties`, build output, keystores, or App Bundles. Android applications that do not use Godot can depend on `nearby-core` alone.

## Runtime contract

The Android core accepts a caller supplied `serviceId` and topology (`STAR`, `CLUSTER`, `POINT_TO_POINT`). It advertises or discovers, requires both devices to accept an authentication code, and sends byte payloads up to 16 KiB. The Godot facade exposes this as `NearbyService` and converts `PackedByteArray` to Base64 across the Java bridge. The plugin does not own rooms, players, scoring, or UI.

See [feature charter](../../docs/nearby/FEATURE_CHARTER.md) and [architecture](../../docs/nearby/ARCHITECTURE.md).

## Android Wi-Fi permissions

Keep `ACCESS_WIFI_STATE` and `CHANGE_WIFI_STATE` in the merged manifest on current Android versions. With `play-services-nearby:19.3.0`, an Android 15 device returned `ConnectionsStatusCodes.MISSING_PERMISSION_ACCESS_WIFI_STATE` (8032) when `ACCESS_WIFI_STATE` had `maxSdkVersion=32`; advertising worked after removing that cap. Both are normal permissions.
