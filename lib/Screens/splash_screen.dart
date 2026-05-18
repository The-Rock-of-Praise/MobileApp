import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lyrics/Controllers/profile_controller.dart';
import 'package:lyrics/Models/user_model.dart';
import 'package:lyrics/OfflineService/database_helper.dart';
import 'package:lyrics/Screens/AuthScreens/login_page.dart';
import 'package:lyrics/Screens/HomeScreen/home_screen.dart';
import 'package:lyrics/Service/user_service.dart';
import '../OfflineService/connectivity_manager.dart';
import '../OfflineService/sync_manager.dart';
import 'package:lyrics/Service/push_notification_service.dart';

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

    // Sync premium status from backend (with local-DB fallback)
    await getProfile();

    // Initialize Push Notifications safely after UI has started rendering
    try {
      await PushNotificationService().initialize();
    } catch (e) {
      debugPrint("❌ PushNotificationService initialization failed: $e");
    }

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
      // Re-read SharedPreferences (which getProfile() may have just updated)
      // so the reactive ProfileController reflects the freshest status.
      if (Get.isRegistered<ProfileController>()) {
        await Get.find<ProfileController>().refreshStatus();
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  /// Syncs the user's premium status on every app launch using a two-source
  /// validation strategy to prevent false downgrades:
  ///
  ///  Source A — Backend (via /api/auth/profile/:id, which runs
  ///             syncSubscriptionStatus to check expiry server-side).
  ///  Source B — Local SQLite user_profile_details (due_date column).
  ///
  ///  Rules:
  ///   • Backend says Pro              → always save isPremium=1 ✅
  ///   • Backend says Free + SQLite Pro (due date valid) → keep isPremium=1
  ///     (backend may not have been updated yet due to payment API race)
  ///   • Backend says Free + SQLite Free/expired        → save isPremium=0
  ///   • Network error                                  → keep cached value
  Future<void> getProfile() async {
    final UserService userService = UserService();
    final String userId = await UserService.getUserID();
    if (userId.isEmpty) return;

    try {
      // ── Source A: backend ──────────────────────────────────────────────
      // getCurrentUserProfile() hits /api/auth/profile/:userId which internally
      // calls syncSubscriptionStatus() — so it validates the renewal date
      // server-side before returning isPremium.
      final Map<String, dynamic> response =
          await userService.getCurrentUserProfile();

      if (response['success'] == true && response['user'] != null) {
        final UserModel userModel = response['user'] as UserModel;

        if (userModel.isPremium) {
          // ✅ Backend confirms Pro — always trust this.
          await UserService.saveIsPremium(1);
          debugPrint('✅ SplashScreen: Backend confirmed PRO → saved isPremium=1');
          return;
        }

        // Backend says Free — before we downgrade, check local SQLite.
        // ── Source B: local SQLite ─────────────────────────────────────
        final localStatus = await DatabaseHelper()
            .getUserPremiumStatus(int.parse(userId));

        final bool localIsPro =
            localStatus != null &&
            localStatus['account_type'] == 'Pro' &&
            _isSubscriptionStillValid(localStatus['due_date'] as String?);

        if (localIsPro) {
          // Local SQLite says subscription is still valid.
          // The backend may not have been updated yet (e.g. payment API call
          // failed silently). Keep Pro status — validateSubscriptionStatus()
          // in main.dart will correctly expire it when the due date passes.
          debugPrint(
              '⚠️ SplashScreen: Backend says Free but local DB says Pro '
              '(due date still valid) — keeping isPremium=1.');
          await UserService.saveIsPremium(1);
        } else {
          // Both sources agree the subscription is not active → downgrade.
          await UserService.saveIsPremium(0);
          debugPrint('ℹ️ SplashScreen: Both sources confirm Free → saved isPremium=0');
        }
      }
      // If success:false, keep whatever is in SharedPreferences unchanged.
    } catch (e) {
      // Network error or parse failure — intentionally do NOT overwrite
      // SharedPreferences so offline Pro users remain unlocked.
      debugPrint(
          '⚠️ SplashScreen getProfile: server unreachable — '
          'keeping cached premium status. Error: $e');
    }
  }

  /// Returns true if the subscription is still within the grace period.
  /// A null / empty due-date means the date was never set (first payment
  /// before the IPN arrived) — treat as still valid.
  bool _isSubscriptionStillValid(String? dueDateStr) {
    if (dueDateStr == null || dueDateStr.isEmpty) return true;
    try {
      final DateTime dueDate = DateFormat('yyyy-MM-dd').parse(dueDateStr);
      // Allow same 3-day grace period as PaymentController.validateSubscriptionStatus
      final DateTime gracePeriodEnd = dueDate.add(const Duration(days: 3));
      return DateTime.now().isBefore(gracePeriodEnd);
    } catch (_) {
      return false;
    }
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
