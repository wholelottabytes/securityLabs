package com.example.dishes_app

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

object AccelerometerStreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    fun sendData(x: Float, y: Float, z: Float) {
        mainHandler.post {
            eventSink?.success(String.format("%.2f,%.2f,%.2f", x, y, z))
        }
    }
}