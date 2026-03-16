import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lyrics/OfflineService/database_helper.dart';
import 'package:lyrics/Screens/AuthScreens/login_page.dart';
import 'package:lyrics/Screens/HomeScreen/home_screen.dart';
import 'package:lyrics/Service/user_service.dart';
import '../OfflineService/connectivity_manager.dart';
import '../OfflineService/sync_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _ensureDatabaseReady();
  }

  Future<void> _ensureDatabaseReady() async {
    try {
      // Initialize database AFTER Flutter engine is ready
      await DatabaseHelper().database;
      debugPrint("✅ Database initialized in SplashScreen");

      // Initialize connectivity and sync
      final connectivityManager = ConnectivityManager();
      if (await connectivityManager.isConnected()) {
        SyncManager().performFullSync();
      }

      // Set up connectivity listener
      connectivityManager.connectivityStream.listen((result) {
        if (result != ConnectivityResult.none) {
          SyncManager().performFullSync();
        }
      });
    } catch (e) {
      debugPrint("❌ Database initialization failed: $e");
    }

    // Get user profile
    await getProfile();

    // Wait for splash duration
    await Future.delayed(const Duration(seconds: 3));

    // Navigate AFTER everything is ready
    if (!mounted) return;
    final page = await UserService.getUserID();

    if (page != '') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  Future<void> getProfile() async {
    final UserService userService = UserService();
    final page = await UserService.getUserID();
    try {
      final response = await userService.getFullProfile(page);

      if (response['success']) {
        await UserService.saveIsPremium(response['profile']['isPremium']);
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset('assets/splash_screen.png', fit: BoxFit.cover),
      ),
    );
  }
}
