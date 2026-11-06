package vn.lamgame.nearby.androiddemo

import android.app.Activity
import android.app.AlertDialog
import android.os.Bundle
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import vn.lamgame.nearby.core.NearbyListener
import vn.lamgame.nearby.core.NearbyTopology
import vn.lamgame.nearby.core.NearbyTransport

/** Standalone client proves nearby-core is usable without Godot. */
class MainActivity : Activity(), NearbyListener {
    companion object {
        private const val SERVICE_ID = "vn.lamgame.nearby.demo"
        private const val PERMISSION_REQUEST = 46329
    }

    private lateinit var transport: NearbyTransport
    private lateinit var status: TextView
    private lateinit var log: TextView
    private lateinit var found: LinearLayout
    private var pendingAction = ""
    private val connected = linkedSetOf<String>()
    private val displayName = "Android-${(1000..9999).random()}"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        transport = NearbyTransport(this, this)
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(24, 24, 24, 24)
        }
        val scroll = ScrollView(this)
        scroll.addView(root)
        setContentView(scroll)
        status = TextView(this).apply { textSize = 20f }
        root.addView(status)
        button(root, "Tạo phòng") { begin("host") }
        button(root, "Tìm phòng") { begin("join") }
        button(root, "Dừng") { transport.stopAll(); connected.clear() }
        found = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        root.addView(found)
        button(root, "Gửi PING") {
            for (id in connected) transport.sendBytes(id, "PING".toByteArray())
        }
        log = TextView(this).apply { textSize = 16f }
        root.addView(log)
        status.text = if (transport.isPlayServicesAvailable()) "Sẵn sàng" else "Thiếu Google Play services"
    }

    private fun button(parent: LinearLayout, title: String, action: () -> Unit) {
        parent.addView(Button(this).apply {
            text = title
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
            setOnClickListener { action() }
        })
    }

    private fun begin(action: String) {
        if (!transport.isPlayServicesAvailable()) {
            append("Nearby không khả dụng")
            return
        }
        pendingAction = action
        val missing = transport.missingPermissions()
        if (missing.isEmpty()) runPending() else requestPermissions(missing, PERMISSION_REQUEST)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != PERMISSION_REQUEST) return
        if (transport.missingPermissions().isEmpty()) runPending()
        else append("Thiếu quyền: ${transport.missingPermissions().joinToString()}")
    }

    private fun runPending() {
        when (pendingAction) {
            "host" -> transport.startAdvertising(SERVICE_ID, displayName, NearbyTopology.STAR)
            "join" -> transport.startDiscovery(SERVICE_ID, NearbyTopology.STAR)
        }
        pendingAction = ""
    }

    override fun onStop() {
        transport.stopAll()
        connected.clear()
        super.onStop()
    }

    override fun onStateChanged(state: String) { status.text = "Trạng thái: $state" }
    override fun onError(code: String, operation: String) { append("Lỗi $code: $operation") }
    override fun onEndpointFound(endpointId: String, name: String) {
        button(found, "Vào phòng $name") { transport.requestConnection(endpointId, displayName) }
    }
    override fun onEndpointLost(endpointId: String) { append("Mất thiết bị $endpointId") }
    override fun onConnectionInitiated(endpointId: String, name: String, authenticationDigits: String) {
        AlertDialog.Builder(this)
            .setTitle("Xác nhận thiết bị")
            .setMessage("So mã trên cả hai máy:\n\n$authenticationDigits\n\nThiết bị: $name")
            .setPositiveButton("Trùng mã") { _, _ -> transport.acceptConnection(endpointId) }
            .setNegativeButton("Không trùng") { _, _ -> transport.rejectConnection(endpointId) }
            .setOnCancelListener { transport.rejectConnection(endpointId) }
            .show()
    }
    override fun onConnectionResult(endpointId: String, connectedNow: Boolean, statusCode: Int) {
        if (connectedNow) {
            connected.add(endpointId)
            transport.stopDiscovery()
        }
        append("Kết nối $endpointId: $connectedNow ($statusCode)")
    }
    override fun onEndpointDisconnected(endpointId: String) {
        connected.remove(endpointId)
        append("Đã ngắt $endpointId")
    }
    override fun onBytesReceived(endpointId: String, bytes: ByteArray) {
        val message = bytes.toString(Charsets.UTF_8)
        append("Nhận $message")
        if (message == "PING") transport.sendBytes(endpointId, "ECHO".toByteArray())
    }
    private fun append(message: String) { log.append("$message\n") }
}
