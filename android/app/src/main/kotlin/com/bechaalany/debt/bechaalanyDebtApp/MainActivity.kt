package com.bechaalany.debt.bechaalanyDebtApp

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Suppress Google Play Services warnings on emulators
        // These warnings are expected when Google Play Services are not fully available
        try {
            // Filter out known warning patterns
            System.setProperty("org.apache.commons.logging.Log", "org.apache.commons.logging.impl.NoOpLog")
        } catch (e: Exception) {
            // Ignore if property setting fails
        }
    }
}
