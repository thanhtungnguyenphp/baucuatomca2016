# Feature charter: Nearby Connections multiplayer

**Branch:** `codex/feature-nearby-connections`
**Base:** `main` at `4db4744`
**Purpose:** build a reusable nearby-device transport, then use it for Bầu Cua Tôm Cá multiplayer on Android.

## Goal and user outcome

Two to four people in the same place can play a complete five-round Bầu Cua match on separate Android phones without an Internet connection. One phone hosts the room and owns the authoritative match state. Players can discover a room, compare the Nearby authentication code, join, choose a symbol, see the same roll and scores, and rematch or leave. The existing single-device party mode remains available.

The connection layer must also work outside this game: a plain Android app can use the Kotlin core library, and another Godot game can install the Godot addon without importing Bầu Cua code or assets.

## Deliverables in priority order

1. **Reusable transport (NBY-01–07):** standalone `nearby-core` Android library, Godot Android plugin v2 bridge, stable connection/permission/bytes API, independent Kotlin and Godot demos. Validate a two-device echo flow, then a four-device `P2P_STAR` room on real phones before locking the plugin API.
2. **Game integration (NBY-08–11):** extract pure party match rules, implement versioned game messages and host authority, build room/permission/pairing UI, handle disconnect and rematch.
3. **Release readiness (NBY-12–13):** device matrix and regression checks, merged-manifest review, privacy and Data safety updates, internal testing. A release build is a separate decision after these checks.

## Acceptance gates

- The transport builds and runs in a standalone demo without the Bầu Cua project. The Android core is usable without Godot.
- On real devices, one host can connect to three guests and exchange bytes. Permission rejection and missing Google Play services produce clear errors, while local play still works.
- Both sides explicitly verify and accept the Nearby connection authentication code. The game rejects invalid, duplicate, stale, or out-of-room messages.
- During a five-round match, all connected devices show the same roll, turn, and score. Only the host generates rolls and settles points.
- The plugin contains no Bầu Cua package ID, game rules, assets, AdMob dependency, or release signing material. `service_id` is supplied by each consuming app.
- Keystore, App Bundles, build caches, and local machine configuration remain outside Git.

## Technical constraints and assumptions

- Android first; current game is Godot 4.7.x with Gradle Android export.
- Google Nearby Connections chooses Bluetooth, BLE, or Wi-Fi and requires Google Play services on Android. The feature is labelled “Chơi gần nhau”, not “Bluetooth only”.
- `P2P_STAR`, one host and at most three guests, bytes payloads only in the first version. No Internet matchmaking, file transfer, real-money rewards, or iOS bridge in this branch.
- Actual radio behavior, permission prompts, reconnection, and privacy disclosures must be checked against the SDK version used by the implementation and on real devices.

## Sequencing and commit policy

This charter is the first feature-branch commit and is pushed before any implementation. Later commits should be scoped by module or milestone, explain the change and its verification, and stay on this branch until the feature is ready for review. The full architecture and task checklist are in [ARCHITECTURE.md](ARCHITECTURE.md) and [TASKS.md](TASKS.md).
