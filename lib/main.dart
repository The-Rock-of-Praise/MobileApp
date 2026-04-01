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
    String errorMessage = e.toString();
    bool isMissingPlugin = errorMessage.contains('MissingPluginException');
    
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 20),
                  const Text(
                    "Launch Error",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isMissingPlugin 
                      ? "The app's native plugins are not correctly linked."
                      : "The app failed to initialize correctly.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  if (isMissingPlugin) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Solution:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                          SizedBox(height: 8),
                          Text("1. Run 'flutter clean' in your terminal", style: TextStyle(color: Colors.white)),
                          Text("2. Run 'flutter pub get'", style: TextStyle(color: Colors.white)),
                          Text("3. Perform a COLD REBUILD (Stop and Start again)", style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SelectableText(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
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