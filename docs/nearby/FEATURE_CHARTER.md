# Feature charter: Nearby Connections multiplayer

**Branch:** `codex/feature-nearby-connections`
**Base:** `main` at `4db4744`
**Purpose:** build a reusable nearby-device transport, then use it for Bầu Cua Tôm Cá multiplayer on Android.

## Goal and user outcome

Two to six devices in the same place can run a complete five-round Bầu Cua match without an Internet connection. One phone is the dealer host and owns the authoritative match state; it does not bet or appear in rankings. One to five client phones place virtual-Lộc bets, confirm them, see the same roll, receive host-settled payouts and view the same leaderboard. The existing single-device modes remain available.

The connection layer must also work outside this game: a plain Android app can use the Kotlin core library, and another Godot game can install the Godot addon without importing Bầu Cua code or assets.

## Deliverables in priority order

1. **Reusable transport (NBY-01–07):** standalone `nearby-core` Android library, Godot Android plugin v2 bridge, stable connection/permission/bytes API, independent Kotlin and Godot demos. Validate a two-device echo flow, then a four-device `P2P_STAR` room on real phones before locking the plugin API.
2. **Game integration v1 (NBY-08–11):** prove versioned messages, host authority, room UI, synchronized rolls and disconnect/rematch behavior.
3. **Dealer/client gameplay v2 (NBY-14–21):** remove host from player seats, add virtual bets, balances, host settlement, leaderboard, rewarded recovery and a safe banner layout.
4. **Release readiness (NBY-22–23, NBY-32):** test one host with up to five clients, review manifest/consent/privacy and run internal testing. A release build is a separate decision after these checks.

## Acceptance gates

- The transport builds and runs in a standalone demo without the Bầu Cua project. The Android core is usable without Godot.
- On real devices, one host can connect to five guests and exchange bytes. Permission rejection and missing Google Play services produce clear errors, while local play still works.
- Both sides explicitly verify and accept the Nearby connection authentication code. The game rejects invalid, duplicate, stale, or out-of-room messages.
- During a five-round match, all connected devices show the same bets, roll, balances, payout and leaderboard. Only the host generates rolls and settles rewards; host controls cannot place a bet.
- Rewarded-ad grants are excluded from leaderboard net results and watching a full-screen ad does not disconnect the client.
- The plugin contains no Bầu Cua package ID, game rules, assets, AdMob dependency, or release signing material. `service_id` is supplied by each consuming app.
- Keystore, App Bundles, build caches, and local machine configuration remain outside Git.

## Technical constraints and assumptions

- Android first; current game is Godot 4.7.x with Gradle Android export.
- Google Nearby Connections chooses Bluetooth, BLE, or Wi-Fi and requires Google Play services on Android. The feature is labelled “Chơi gần nhau”, not “Bluetooth only”.
- `P2P_STAR`, one dealer host and at most five client players, bytes payloads only. No Internet matchmaking, file transfer, real-money rewards, transferable currency or iOS bridge in this branch.
- Actual radio behavior, permission prompts, reconnection, and privacy disclosures must be checked against the SDK version used by the implementation and on real devices.

## Sequencing and commit policy

This charter is the first feature-branch commit and is pushed before any implementation. Later commits should be scoped by module or milestone, explain the change and its verification, and stay on this branch until the feature is ready for review. The full architecture and task checklist are in [ARCHITECTURE.md](ARCHITECTURE.md) and [TASKS.md](TASKS.md).
