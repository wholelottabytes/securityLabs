package com.example.dishes_app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val accelerometerJNI = AccelerometerJNI()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor, "accelerometer_jni").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    AccelerometerStreamHandler.setEventSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    AccelerometerStreamHandler.setEventSink(null)
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor, "accelerometer_jni_method").setMethodCallHandler { call, result ->
            when (call.method) {
                "startAccelerometer" -> {
                    accelerometerJNI.startAccelerometer()
                    result.success(null)
                }
                "stopAccelerometer" -> {
                    accelerometerJNI.stopAccelerometer()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}