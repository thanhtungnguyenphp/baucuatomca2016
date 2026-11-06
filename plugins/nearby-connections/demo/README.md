# Godot echo demo

Build the two Android libraries and run `../sync-addon.sh` before opening this project. The sync script copies the distributable addon into `demo/addons/`.

Create an Android debug export preset with Gradle build enabled and package `vn.lamgame.nearby.demo`, then install the demo on two real Android phones. On one phone select **Tạo phòng**; on the other select **Tìm phòng** and pick the discovered device. Compare the authentication digits shown on both phones and accept only if they match. Press **Gửi PING**; the other phone responds with **ECHO**.

Test permission rejection, Bluetooth/Wi-Fi off, and stopping a session. Repeat with four devices after the two-device path works. The desktop editor can parse this project but has no Android Nearby singleton.
