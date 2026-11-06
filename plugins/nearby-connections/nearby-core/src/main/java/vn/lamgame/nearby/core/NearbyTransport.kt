package vn.lamgame.nearby.core

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.nearby.Nearby
import com.google.android.gms.nearby.connection.AdvertisingOptions
import com.google.android.gms.nearby.connection.ConnectionInfo
import com.google.android.gms.nearby.connection.ConnectionLifecycleCallback
import com.google.android.gms.nearby.connection.ConnectionResolution
import com.google.android.gms.nearby.connection.ConnectionsClient
import com.google.android.gms.nearby.connection.ConnectionsStatusCodes
import com.google.android.gms.nearby.connection.DiscoveredEndpointInfo
import com.google.android.gms.nearby.connection.DiscoveryOptions
import com.google.android.gms.nearby.connection.EndpointDiscoveryCallback
import com.google.android.gms.nearby.connection.Payload
import com.google.android.gms.nearby.connection.PayloadCallback
import com.google.android.gms.nearby.connection.PayloadTransferUpdate
import com.google.android.gms.nearby.connection.Strategy

/** Connection topology. A caller must use the same topology on both sides. */
enum class NearbyTopology(val native: Strategy) {
    STAR(Strategy.P2P_STAR),
    CLUSTER(Strategy.P2P_CLUSTER),
    POINT_TO_POINT(Strategy.P2P_POINT_TO_POINT);

    companion object {
        fun parse(value: String): NearbyTopology? = entries.firstOrNull { it.name == value }
    }
}

/** Callbacks are dispatched on the Android main thread. */
interface NearbyListener {
    fun onStateChanged(state: String)
    fun onError(code: String, operation: String)
    fun onEndpointFound(endpointId: String, name: String)
    fun onEndpointLost(endpointId: String)
    fun onConnectionInitiated(endpointId: String, name: String, authenticationDigits: String)
    fun onConnectionResult(endpointId: String, connected: Boolean, statusCode: Int)
    fun onEndpointDisconnected(endpointId: String)
    fun onBytesReceived(endpointId: String, bytes: ByteArray)
}

/**
 * Nearby Connections transport with no Godot, UI, game protocol, or persistence dependency.
 * Public commands may be called from any thread; work and listener events run on main.
 */
class NearbyTransport(context: Context, private val listener: NearbyListener) {
    companion object { const val MAX_PAYLOAD_BYTES = 16 * 1024 }

    private val appContext = context.applicationContext
    private val main = Handler(Looper.getMainLooper())
    private val client: ConnectionsClient by lazy { Nearby.getConnectionsClient(appContext) }
    private val connected = linkedSetOf<String>()
    private val pending = linkedSetOf<String>()
    private var advertising = false
    private var discovering = false
    private var generation = 0
    @Volatile private var currentState = "IDLE"

    fun state(): String = currentState

    fun isPlayServicesAvailable(): Boolean =
        GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(appContext) == ConnectionResult.SUCCESS

    fun requiredRuntimePermissions(): Array<String> {
        val permissions = mutableListOf<String>()
        when {
            Build.VERSION.SDK_INT <= 28 -> permissions += Manifest.permission.ACCESS_COARSE_LOCATION
            Build.VERSION.SDK_INT <= 32 -> permissions += Manifest.permission.ACCESS_FINE_LOCATION
        }
        if (Build.VERSION.SDK_INT >= 31) {
            permissions += Manifest.permission.BLUETOOTH_ADVERTISE
            permissions += Manifest.permission.BLUETOOTH_CONNECT
            permissions += Manifest.permission.BLUETOOTH_SCAN
        }
        if (Build.VERSION.SDK_INT >= 33) {
            permissions += Manifest.permission.NEARBY_WIFI_DEVICES
        }
        return permissions.toTypedArray()
    }

    fun missingPermissions(): Array<String> = requiredRuntimePermissions().filter {
        appContext.checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED
    }.toTypedArray()

    fun startAdvertising(serviceId: String, localName: String, topology: NearbyTopology) = onMain {
        if (!preflight("startAdvertising") || !validateIdentity(serviceId, localName)) return@onMain
        if (advertising || discovering || connected.isNotEmpty()) {
            error("BUSY", "startAdvertising")
            return@onMain
        }
        val token = ++generation
        state("STARTING")
        val options = AdvertisingOptions.Builder().setStrategy(topology.native).build()
        client.startAdvertising(localName, serviceId, connectionCallback, options)
            .addOnSuccessListener {
                if (token != generation) {
                    client.stopAdvertising()
                    return@addOnSuccessListener
                }
                advertising = true
                updateState()
            }
            .addOnFailureListener {
                if (token == generation) {
                    updateState()
                    error("SDK_ERROR", "startAdvertising")
                }
            }
    }

    fun startDiscovery(serviceId: String, topology: NearbyTopology) = onMain {
        if (!preflight("startDiscovery") || serviceId.isBlank()) {
            if (serviceId.isBlank()) error("INVALID_ARGUMENT", "startDiscovery")
            return@onMain
        }
        if (advertising || discovering || connected.isNotEmpty()) {
            error("BUSY", "startDiscovery")
            return@onMain
        }
        val token = ++generation
        state("STARTING")
        val options = DiscoveryOptions.Builder().setStrategy(topology.native).build()
        client.startDiscovery(serviceId, discoveryCallback, options)
            .addOnSuccessListener {
                if (token != generation) {
                    client.stopDiscovery()
                    return@addOnSuccessListener
                }
                discovering = true
                updateState()
            }
            .addOnFailureListener {
                if (token == generation) {
                    updateState()
                    error("SDK_ERROR", "startDiscovery")
                }
            }
    }

    fun stopDiscovery() = onMain {
        if (discovering) client.stopDiscovery()
        discovering = false
        updateState()
    }

    fun requestConnection(endpointId: String, localName: String) = onMain {
        if (!preflight("requestConnection") || endpointId.isBlank() || localName.isBlank()) {
            if (endpointId.isBlank() || localName.isBlank()) error("INVALID_ARGUMENT", "requestConnection")
            return@onMain
        }
        client.requestConnection(localName, endpointId, connectionCallback)
            .addOnFailureListener { error("SDK_ERROR", "requestConnection") }
    }

    fun acceptConnection(endpointId: String) = onMain {
        if (!pending.contains(endpointId)) {
            error("NOT_PENDING", "acceptConnection")
            return@onMain
        }
        client.acceptConnection(endpointId, payloadCallback)
            .addOnFailureListener { error("SDK_ERROR", "acceptConnection") }
    }

    fun rejectConnection(endpointId: String) = onMain {
        if (!pending.remove(endpointId)) {
            error("NOT_PENDING", "rejectConnection")
            return@onMain
        }
        client.rejectConnection(endpointId)
            .addOnFailureListener { error("SDK_ERROR", "rejectConnection") }
        updateState()
    }

    fun sendBytes(endpointId: String, bytes: ByteArray) = onMain {
        if (!connected.contains(endpointId)) {
            error("NOT_CONNECTED", "sendBytes")
            return@onMain
        }
        if (bytes.isEmpty() || bytes.size > MAX_PAYLOAD_BYTES) {
            error("INVALID_PAYLOAD_SIZE", "sendBytes")
            return@onMain
        }
        client.sendPayload(endpointId, Payload.fromBytes(bytes.copyOf()))
            .addOnFailureListener { error("SDK_ERROR", "sendBytes") }
    }

    fun disconnect(endpointId: String) = onMain {
        client.disconnectFromEndpoint(endpointId)
        connected.remove(endpointId)
        pending.remove(endpointId)
        updateState()
    }

    fun stopAll() = onMain {
        generation++
        client.stopAdvertising()
        client.stopDiscovery()
        client.stopAllEndpoints()
        advertising = false
        discovering = false
        pending.clear()
        connected.clear()
        state("IDLE")
    }

    private fun preflight(operation: String): Boolean {
        if (!isPlayServicesAvailable()) {
            error("PLAY_SERVICES_UNAVAILABLE", operation)
            return false
        }
        if (missingPermissions().isNotEmpty()) {
            error("MISSING_PERMISSION", operation)
            return false
        }
        return true
    }

    private fun validateIdentity(serviceId: String, localName: String): Boolean {
        if (serviceId.isBlank() || localName.isBlank() || localName.length > 64) {
            error("INVALID_ARGUMENT", "startAdvertising")
            return false
        }
        return true
    }

    private val discoveryCallback = object : EndpointDiscoveryCallback() {
        override fun onEndpointFound(id: String, info: DiscoveredEndpointInfo) = onMain {
            listener.onEndpointFound(id, info.endpointName)
        }
        override fun onEndpointLost(id: String) = onMain { listener.onEndpointLost(id) }
    }

    private val connectionCallback = object : ConnectionLifecycleCallback() {
        override fun onConnectionInitiated(id: String, info: ConnectionInfo) = onMain {
            pending.add(id)
            updateState()
            listener.onConnectionInitiated(id, info.endpointName, info.authenticationDigits)
        }

        override fun onConnectionResult(id: String, result: ConnectionResolution) = onMain {
            pending.remove(id)
            val code = result.status.statusCode
            val success = code == ConnectionsStatusCodes.STATUS_OK
            if (success) connected.add(id) else connected.remove(id)
            updateState()
            listener.onConnectionResult(id, success, code)
        }

        override fun onDisconnected(id: String) = onMain {
            connected.remove(id)
            pending.remove(id)
            updateState()
            listener.onEndpointDisconnected(id)
        }
    }

    private val payloadCallback = object : PayloadCallback() {
        override fun onPayloadReceived(id: String, payload: Payload) = onMain {
            val bytes = if (payload.type == Payload.Type.BYTES) payload.asBytes() else null
            if (bytes == null || bytes.isEmpty() || bytes.size > MAX_PAYLOAD_BYTES) {
                error("INVALID_PAYLOAD_SIZE", "receiveBytes")
                return@onMain
            }
            listener.onBytesReceived(id, bytes)
        }
        override fun onPayloadTransferUpdate(id: String, update: PayloadTransferUpdate) = Unit
    }

    private fun updateState() {
        state(when {
            connected.isNotEmpty() -> "CONNECTED"
            pending.isNotEmpty() -> "PAIRING"
            advertising -> "ADVERTISING"
            discovering -> "DISCOVERING"
            else -> "IDLE"
        })
    }

    private fun state(value: String) {
        if (currentState == value) return
        currentState = value
        listener.onStateChanged(value)
    }

    private fun error(code: String, operation: String) = listener.onError(code, operation)

    private fun onMain(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) block() else main.post(block)
    }
}
