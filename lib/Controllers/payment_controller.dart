import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lyrics/Controllers/profile_controller.dart';
import 'package:lyrics/OfflineService/database_helper.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:intl/intl.dart';

class PaymentController {
  final UserService _userService = UserService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Primary function to handle successful payment
  Future<bool> handlePaymentSuccess({
    required String email,
    required String userId,
    required String paymentId,
  }) async {
    try {
      debugPrint('💳 Processing Payment Success for $email ($userId)');

      // 1. Show Loading Overlay (Real-time sync period)
      Get.dialog(
        PopScope(
          canPop: false,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900]?.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.orangeAccent, strokeWidth: 3),
                  SizedBox(height: 24),
                  Text(
                    "Syncing PRO Status...",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.none,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Activating your worship journey",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      decoration: TextDecoration.none,
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Give the system a small buffer as requested by user (3 seconds)
      await Future.delayed(const Duration(seconds: 3));

      // 2. Update Backend
      final backendResult = await _userService.updatePremiumStatusByEmail(
        email: email,
        isPremium: true,
        paymentId: paymentId,
      );

      if (!backendResult['success']) {
        debugPrint('⚠️ Backend sync failed: ${backendResult['message']}');
      }

      // 3. Calculate next due date (1 month from now)
      final DateTime now = DateTime.now();
      final DateTime nextDueDate = DateTime(now.year, now.month + 1, now.day);
      final String dueDateStr = DateFormat('yyyy-MM-dd').format(nextDueDate);

      // 4. Update Local SQLite
      await _dbHelper.updateUserPremiumStatus(
        int.parse(userId),
        true,
        dueDate: dueDateStr,
        paymentStatus: 'active',
      );

      // 5. Update Shared Preferences (Session Cache)
      await UserService.saveIsPremium(1);

      // 6. REAL-TIME UI REFRESH: Notify the ProfileController
      if (Get.isRegistered<ProfileController>()) {
        await Get.find<ProfileController>().refreshStatus();
      }

      // Close Loading Overlay
      Get.back();

      debugPrint('✅ Payment successfully synchronized. Next due date: $dueDateStr');
      return true;
    } catch (e) {
      if (Get.isOverlaysOpen) Get.back();
      debugPrint('💥 Error in handlePaymentSuccess: $e');
      return false;
    }
  }

  // Function to check and handle expired subscriptions (Session Validation)
  Future<void> validateSubscriptionStatus(String userId) async {
    try {
      final status = await _dbHelper.getUserPremiumStatus(int.parse(userId));
      if (status == null || status['account_type'] != 'Pro') return;

      final String? dueDateStr = status['due_date'];
      if (dueDateStr == null || dueDateStr.isEmpty) return;

      final DateTime dueDate = DateFormat('yyyy-MM-dd').parse(dueDateStr);
      final DateTime now = DateTime.now();
      
      // Allow 3-day grace period
      final DateTime gracePeriodEnd = dueDate.add(const Duration(days: 3));

      if (now.isAfter(gracePeriodEnd)) {
        debugPrint('🚫 Subscription expired (Grace period exceeded). Downgrading...');
        await _performDowngrade(userId);
      } else if (now.isAfter(dueDate)) {
        debugPrint('⚠️ Subscription expired but within grace period.');
      }
    } catch (e) {
      debugPrint('💥 Error in validateSubscriptionStatus: $e');
    }
  }

  Future<void> _performDowngrade(String userId) async {
    try {
      debugPrint('📉 Downgrading user $userId...');
      
      // 1. Get user details from local DB to find email for backend update
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> userResults = await db.query(
        'users',
        columns: ['email'],
        where: 'id = ?',
        whereArgs: [int.parse(userId)],
      );

      if (userResults.isNotEmpty) {
        final String email = userResults.first['email'];

        // 2. Notify Backend of Downgrade (This also triggers admin panel notification)
        await _userService.updatePremiumStatusByEmail(
          email: email,
          isPremium: false,
        );
      }

      // 3. Update local status (SQFLite)
      await _dbHelper.updateUserPremiumStatus(
        int.parse(userId),
        false,
        paymentStatus: 'expired',
      );

      // 4. Update Shared Preferences
      await UserService.saveIsPremium(0);

      debugPrint('✅ Downgrade complete for user $userId');
    } catch (e) {
      debugPrint('💥 Error in _performDowngrade: $e');
    }
  }
}
