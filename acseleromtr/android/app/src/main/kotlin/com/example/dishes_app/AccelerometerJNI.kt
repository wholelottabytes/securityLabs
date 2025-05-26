package com.example.dishes_app

class AccelerometerJNI {
    external fun startAccelerometer()
    external fun stopAccelerometer()

    fun onAccelerometerData(x: Float, y: Float, z: Float) {
        AccelerometerStreamHandler.sendData(x, y, z)
    }

    companion object {
        init {
            System.loadLibrary("accelerometerjni")
        }
    }
}
