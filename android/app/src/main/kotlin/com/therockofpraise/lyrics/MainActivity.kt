package com.therockofpraise.lyrics

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Explicitly register plugins to ensure sqflite and others are linked
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
}
