import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:lyrics/OfflineService/database_helper.dart';
import 'package:lyrics/OfflineService/sync_manager.dart';
import 'package:lyrics/Screens/splash_screen.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:lyrics/Controllers/payment_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:get/get.dart';
import 'package:lyrics/Controllers/profile_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {

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

    // 💎 SESSION VALIDATION: Check Pro status & Due Date on Launch
    final String userId = await UserService.getUserID();
    if (userId.isNotEmpty) {
      debugPrint("💎 Validating subscription for user: $userId");
      await PaymentController().validateSubscriptionStatus(userId);
    }

    connectivityManager.connectivityStream.listen((result) {
      if (result != ConnectivityResult.none) {
        SyncManager().performFullSync();
      }
    });
    runApp(const MyApp());
  } catch (e) {
    debugPrint("Failed to start app correctly: $e");
    // Only show the error UI if it was a missing plugin - otherwise, just try to start
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject ProfileController globally to manage premium status reactively
    Get.put(ProfileController(), permanent: true);

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'The Rock Of Praise',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: SplashScreen(),
    );
  }
}