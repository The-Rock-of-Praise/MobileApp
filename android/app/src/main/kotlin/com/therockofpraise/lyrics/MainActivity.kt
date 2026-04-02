package com.therockofpraise.lyrics

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.tekartik.sqflite.SqflitePlugin

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Explicitly register sqflite due to GitHub Actions build stripping it
        flutterEngine.plugins.add(SqflitePlugin())
    }
}
