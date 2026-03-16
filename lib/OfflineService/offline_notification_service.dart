import 'package:lyrics/Models/notification_model.dart';
import 'package:lyrics/OfflineService/database_helper.dart';
import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:lyrics/Service/notification_service.dart';
import 'package:sqflite/sqflite.dart';

class OfflineNotificationService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationService _onlineService = NotificationService();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  // Sync notifications from online to offline
  Future<Map<String, dynamic>> syncNotifications() async {
    final isConnected = await _connectivityManager.isConnected();
    if (!isConnected) {
      return {'success': false, 'message': 'No internet connection'};
    }

    try {
      final result = await _onlineService.getAllNotifications();
      if (result['success']) {
        final List<NotificationModel> onlineNotifications =
            result['notifications'];
        final db = await _dbHelper.database;

        // Get all online IDs
        final List<int> onlineIds =
            onlineNotifications.map((n) => n.id!).toList();

        // 1. Remove local notifications that are no longer on the server
        if (onlineIds.isEmpty) {
          await db.delete('notifications');
        } else {
          await db.delete(
            'notifications',
            where: 'id NOT IN (${onlineIds.join(',')})',
          );
        }

        // 2. Sync online notifications to local (updates/inserts)
        final batch = db.batch();
        for (var notification in onlineNotifications) {
          batch.insert(
            'notifications',
            {
              'id': notification.id,
              'title': notification.title,
              'message': notification.message,
              'date': notification.date,
              'created_at': notification.createdAt.toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        await batch.commit();
        return {'success': true, 'message': 'Notifications synced successfully'};
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get all notifications (from local db)
  Future<List<NotificationModel>> getNotifications() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return NotificationModel(
        id: maps[i]['id'],
        title: maps[i]['title'],
        message: maps[i]['message'],
        date: maps[i]['date'],
        createdAt: DateTime.parse(maps[i]['created_at']),
        isRead: maps[i]['is_read'] == 1,
      );
    });
  }

  // Mark notification as read
  Future<void> markAsRead(int id) async {
    final db = await _dbHelper.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE is_read = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  void dispose() {
    _onlineService.dispose();
  }
}
