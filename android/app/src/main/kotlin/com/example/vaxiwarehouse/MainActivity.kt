package com.example.vaxiwarehouse  // ✅ your correct package name
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.content.pm.PackageManager
import android.os.Build
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.io.OutputStream
import java.util.*

class MainActivity : FlutterActivity() {
    // Channels
    private val STAR_CHANNEL = "star_printer"
    private val BT_CHANNEL = "printer_channel"

    // Bluetooth (generic printer)
    private var socket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null
    private val adapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        

        // ==========================
        // Generic Bluetooth Printer
        // ==========================
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BT_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scanPrinters" -> result.success(scanPrinters())

                    "connectPrinter" -> {
                        val address = call.argument<String>("address")
                        if (address != null) {
                            val success = connectPrinter(address)
                            result.success(success)
                        } else {
                            result.success(false)
                        }
                    }

                    "printText" -> {
                        val text = call.argument<String>("text")
                        if (text != null) {
                            printText(text)
                            result.success(null)
                        } else {
                            result.error("NO_TEXT", "Text is null", null)
                        }
                    }

                    "printBytes" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        if (bytes != null) {
                            val success = printBytes(bytes)
                            result.success(success)
                        } else {
                            result.error("NO_BYTES", "Bytes are null", null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // ==========================
    // Bluetooth Printer Functions
    // ==========================
    private fun scanPrinters(): List<Map<String, String>> {
        if (!checkAndRequestBluetoothPermissions()) return emptyList()

        val list = mutableListOf<Map<String, String>>()
        val bondedDevices = adapter?.bondedDevices
        bondedDevices?.forEach { device ->
            list.add(mapOf("name" to (device.name ?: "Unknown"), "address" to device.address))
        }
        return list
    }

    private fun connectPrinter(address: String): Boolean {
        val device: BluetoothDevice = adapter?.getRemoteDevice(address) ?: return false
        return try {
            val uuid: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
            socket = device.createRfcommSocketToServiceRecord(uuid)
            socket?.connect()
            outputStream = socket?.outputStream
            true
        } catch (e: IOException) {
            e.printStackTrace()
            false
        }
    }

    private fun printText(text: String) {
        try {
            outputStream?.write((text + "\n").toByteArray())
            outputStream?.flush()
        } catch (e: IOException) {
            e.printStackTrace()
        }
    }

    private fun printBytes(bytes: ByteArray): Boolean {
        return try {
            outputStream?.write(bytes)
            outputStream?.flush()
            true
        } catch (e: IOException) {
            e.printStackTrace()
            false
        }
    }
    private val REQUEST_BLUETOOTH_PERMISSIONS = 1001

    private fun checkAndRequestBluetoothPermissions(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val permissions = arrayOf(
                android.Manifest.permission.BLUETOOTH_CONNECT,
                android.Manifest.permission.BLUETOOTH_SCAN
            )

            val missing = permissions.filter {
                ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
            }

            if (missing.isNotEmpty()) {
                ActivityCompat.requestPermissions(this, missing.toTypedArray(), 1)
                return false
            }
        }
        return true
    }

}
