package com.pulse.card.cardpulse

import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.pulse.card.cardpulse/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSmsMessages") {
                if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_SMS)
                    != PackageManager.PERMISSION_GRANTED
                ) {
                    result.error("PERMISSION_DENIED", "SMS permission not granted", null)
                } else {
                    try {
                        val messages = readSmsAndMmsInbox()
                        result.success(messages)
                    } catch (e: Exception) {
                        result.error("SMS_ERROR", e.localizedMessage, null)
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun readSmsAndMmsInbox(): List<Map<String, Any>> {
        val messages = mutableListOf<Map<String, Any>>()

        // 1. Read SMS Inbox
        try {
            val uri = Uri.parse("content://sms/inbox")
            val projection = arrayOf("_id", "address", "body", "date")
            contentResolver.query(uri, projection, null, null, "date DESC LIMIT 400")?.use { cursor ->
                val addressIdx = cursor.getColumnIndex("address")
                val bodyIdx = cursor.getColumnIndex("body")
                val dateIdx = cursor.getColumnIndex("date")

                while (cursor.moveToNext()) {
                    val address = if (addressIdx != -1) cursor.getString(addressIdx) ?: "" else ""
                    val body = if (bodyIdx != -1) cursor.getString(bodyIdx) ?: "" else ""
                    val date = if (dateIdx != -1) cursor.getLong(dateIdx) else 0L

                    if (body.isNotEmpty()) {
                        val map = HashMap<String, Any>()
                        map["address"] = address
                        map["body"] = body
                        map["date"] = date
                        messages.add(map)
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // 2. Read MMS / RCS Text Parts (e.g. Google Messages RCS)
        try {
            val mmsUri = Uri.parse("content://mms")
            val mmsProjection = arrayOf("_id", "date")
            contentResolver.query(mmsUri, mmsProjection, null, null, "date DESC LIMIT 150")?.use { cursor ->
                val idIdx = cursor.getColumnIndex("_id")
                val dateIdx = cursor.getColumnIndex("date")

                while (cursor.moveToNext()) {
                    val mmsId = if (idIdx != -1) cursor.getString(idIdx) else continue
                    var date = if (dateIdx != -1) cursor.getLong(dateIdx) else 0L
                    if (date in 1..9999999999L) { // MMS timestamp is in seconds
                        date *= 1000L
                    }

                    val partUri = Uri.parse("content://mms/part")
                    val partProjection = arrayOf("ct", "text")
                    val selection = "mid=?"
                    val selectionArgs = arrayOf(mmsId)

                    contentResolver.query(partUri, partProjection, selection, selectionArgs, null)?.use { partCursor ->
                        val ctIdx = partCursor.getColumnIndex("ct")
                        val textIdx = partCursor.getColumnIndex("text")

                        while (partCursor.moveToNext()) {
                            val ct = if (ctIdx != -1) partCursor.getString(ctIdx) ?: "" else ""
                            if (ct == "text/plain") {
                                val body = if (textIdx != -1) partCursor.getString(textIdx) ?: "" else ""
                                if (body.isNotEmpty()) {
                                    val map = HashMap<String, Any>()
                                    map["address"] = "RCS"
                                    map["body"] = body
                                    map["date"] = if (date > 0) date else System.currentTimeMillis()
                                    messages.add(map)
                                }
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // Sort combined list descending by date
        messages.sortByDescending { (it["date"] as? Long) ?: 0L }
        return messages
    }
}
