import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:lyrics/OfflineService/database_helper.dart';
import 'package:lyrics/OfflineService/sync_manager.dart';
import 'package:lyrics/Screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Try to initialize database, but don't crash if it fails in release mode
    try {
      await DatabaseHelper().database;
      debugPrint("✅ Database initialized in main()");
    } catch (dbError) {
      debugPrint(
        "⚠️ Database init failed in main(), will retry in SplashScreen: $dbError",
      );
      // Don't crash - SplashScreen will initialize it
    }

    final connectivityManager = ConnectivityManager();
    if (await connectivityManager.isConnected()) {
      SyncManager().performFullSync();
    }

    await Firebase.initializeApp();
    await initializeDateFormatting();

    connectivityManager.connectivityStream.listen((result) {
      if (result != ConnectivityResult.none) {
        SyncManager().performFullSync();
      }
    });
    runApp(const MyApp());
  } catch (e) {
    debugPrint("Initialization Failed: $e");
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    "Initialization Failed",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(e.toString(), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'The Rock Of Praise',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: SplashScreen(),
    );
  }
}