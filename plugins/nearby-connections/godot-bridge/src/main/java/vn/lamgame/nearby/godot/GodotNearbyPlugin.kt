package vn.lamgame.nearby.godot

import android.content.pm.PackageManager
import android.util.Base64
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot
import vn.lamgame.nearby.core.NearbyListener
import vn.lamgame.nearby.core.NearbyTopology
import vn.lamgame.nearby.core.NearbyTransport

/** Godot v2 adapter; game protocol and UI live in the consuming project. */
class GodotNearbyPlugin(godot: Godot) : GodotPlugin(godot), NearbyListener {
    companion object { private const val PERMISSION_REQUEST = 46328 }

    private val transportDelegate = lazy { NearbyTransport(requireNotNull(getActivity()).applicationContext, this) }
    private val transport by transportDelegate

    override fun getPluginName() = "NearbyConnections"

    override fun getPluginSignals(): Set<SignalInfo> = setOf(
        SignalInfo("state_changed", String::class.java),
        SignalInfo("error", String::class.java, String::class.java),
        SignalInfo("endpoint_found", String::class.java, String::class.java),
        SignalInfo("endpoint_lost", String::class.java),
        SignalInfo("connection_initiated", String::class.java, String::class.java, String::class.java),
        SignalInfo("connection_result", String::class.java, Boolean::class.javaObjectType, Int::class.javaObjectType),
        SignalInfo("endpoint_disconnected", String::class.java),
        SignalInfo("payload_received", String::class.java, String::class.java),
        SignalInfo("permission_result", Boolean::class.javaObjectType, String::class.java)
    )

    @UsedByGodot fun isAvailable(): Boolean = transport.isPlayServicesAvailable()
    @UsedByGodot fun getState(): String = transport.state()
    @UsedByGodot fun getMissingPermissions(): String = transport.missingPermissions().joinToString("|")
    @UsedByGodot fun getMaxPayloadBytes(): Int = NearbyTransport.MAX_PAYLOAD_BYTES

    @UsedByGodot fun requestPermissions() {
        val missing = transport.missingPermissions()
        if (missing.isEmpty()) {
            signal("permission_result", true, "")
            return
        }
        runOnUiThread {
            val activity = getActivity()
            if (activity == null) signal("error", "ACTIVITY_UNAVAILABLE", "requestPermissions")
            else activity.requestPermissions(missing, PERMISSION_REQUEST)
        }
    }

    override fun onMainRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onMainRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != PERMISSION_REQUEST) return
        val granted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            && transport.missingPermissions().isEmpty()
        signal("permission_result", granted, transport.missingPermissions().joinToString("|"))
    }

    @UsedByGodot fun startAdvertising(serviceId: String, localName: String, topology: String) {
        val mode = NearbyTopology.parse(topology)
        if (mode == null) {
            signal("error", "INVALID_ARGUMENT", "startAdvertising")
            return
        }
        transport.startAdvertising(serviceId, localName, mode)
    }

    @UsedByGodot fun startDiscovery(serviceId: String, topology: String) {
        val mode = NearbyTopology.parse(topology)
        if (mode == null) {
            signal("error", "INVALID_ARGUMENT", "startDiscovery")
            return
        }
        transport.startDiscovery(serviceId, mode)
    }

    @UsedByGodot fun stopDiscovery() = transport.stopDiscovery()
    @UsedByGodot fun requestConnection(endpointId: String, localName: String) =
        transport.requestConnection(endpointId, localName)
    @UsedByGodot fun acceptConnection(endpointId: String) = transport.acceptConnection(endpointId)
    @UsedByGodot fun rejectConnection(endpointId: String) = transport.rejectConnection(endpointId)
    @UsedByGodot fun disconnect(endpointId: String) = transport.disconnect(endpointId)
    @UsedByGodot fun stopAll() = transport.stopAll()

    @UsedByGodot fun sendBytes(endpointId: String, base64: String) {
        val bytes = try { Base64.decode(base64, Base64.NO_WRAP) } catch (_: IllegalArgumentException) {
            signal("error", "INVALID_ARGUMENT", "sendBytes")
            return
        }
        transport.sendBytes(endpointId, bytes)
    }

    override fun onMainStop() {
        if (transportDelegate.isInitialized()) transport.stopAll()
        super.onMainStop()
    }

    override fun onMainDestroy() {
        if (transportDelegate.isInitialized()) transport.stopAll()
        super.onMainDestroy()
    }

    override fun onStateChanged(state: String) = signal("state_changed", state)
    override fun onError(code: String, operation: String) = signal("error", code, operation)
    override fun onEndpointFound(endpointId: String, name: String) = signal("endpoint_found", endpointId, name)
    override fun onEndpointLost(endpointId: String) = signal("endpoint_lost", endpointId)
    override fun onConnectionInitiated(endpointId: String, name: String, authenticationDigits: String) =
        signal("connection_initiated", endpointId, name, authenticationDigits)
    override fun onConnectionResult(endpointId: String, connected: Boolean, statusCode: Int) =
        signal("connection_result", endpointId, connected, statusCode)
    override fun onEndpointDisconnected(endpointId: String) = signal("endpoint_disconnected", endpointId)
    override fun onBytesReceived(endpointId: String, bytes: ByteArray) =
        signal("payload_received", endpointId, Base64.encodeToString(bytes, Base64.NO_WRAP))

    private fun signal(name: String, vararg args: Any) {
        runOnRenderThread { emitSignal(name, *args) }
    }
}
