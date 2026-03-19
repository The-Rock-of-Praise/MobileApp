// Enhanced UserModel for offline support

// Offline-first User Service
import 'dart:io';

import 'package:lyrics/Models/user_model.dart';
import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:lyrics/OfflineService/database_helper.dart';
import 'package:lyrics/Service/album_service.dart';
import 'package:lyrics/Service/artist_service.dart';
import 'package:lyrics/Service/search_service.dart';
import 'package:lyrics/Service/song_service.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:lyrics/Service/worship_note_service.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OfflineUserService {
  final UserService _onlineService;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  OfflineUserService({UserService? onlineService})
    : _onlineService = onlineService ?? UserService();

  // Sign up with offline support
  Future<Map<String, dynamic>> signUp(UserModel user) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.signUp(user);
        if (result['success']) {
          await UserService.saveuserID(result['userId']);
          await _cacheUser(user.copyWith(id: result['userId']));
          return result;
        }
      } catch (e) {
        print('❌ Online signup failed: $e');
        return {
          'success': false,
          'message':
              'Signup failed. Please check your connection and try again.',
        };
      }
    }

    return {
      'success': false,
      'message': 'Internet connection required for signup',
    };
  }

  // Login with offline support
  Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.login(
          emailOrPhone: emailOrPhone,
          password: password,
        );
        if (result['success']) {
          final user = result['user'] as UserModel;
          await UserService.saveuserID(user.id!);
          await UserService.saveIsPremium(user.isPremium ? 1 : 0);
          await _cacheUser(user);
          return result;
        }
      } catch (e) {
        print('❌ Online login failed: $e');
      }
    }

    // Try offline login if online fails
    return await _loginOffline(emailOrPhone, password);
  }

  // Get user profile with offline support
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.getUserProfile(userId);
        if (result['success']) {
          await _cacheUser(result['user']);
          return result;
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedUserProfile(userId);
  }

  // Get current user profile with offline support
  Future<Map<String, dynamic>> getCurrentUserProfile() async {
    final userId = await UserService.getUserID();
    if (userId.isEmpty) {
      return {
        'success': false,
        'message': 'No user ID found. Please login again.',
      };
    }

    return await getUserProfile(userId);
  }

  // Update user profile with offline support
  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    String? fullname,
    String? phonenumber,
    String? email,
    String? currentPassword,
    String? newPassword,
  }) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.updateUserProfile(
          userId: userId,
          fullname: fullname,
          phonenumber: phonenumber,
          email: email,
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
        if (result['success']) {
          await _cacheUser(result['user']);
          return result;
        }
      } catch (e) {
        print('❌ Online update failed, saving locally: $e');
      }
    }

    return await _updateUserProfileLocally(
      userId,
      fullname: fullname,
      phonenumber: phonenumber,
      email: email,
      newPassword: newPassword,
    );
  }

  // Update current user profile with offline support
  Future<Map<String, dynamic>> updateCurrentUserProfile({
    String? fullname,
    String? phonenumber,
    String? email,
    String? currentPassword,
    String? newPassword,
  }) async {
    final userId = await UserService.getUserID();
    if (userId.isEmpty) {
      return {
        'success': false,
        'message': 'No user ID found. Please login again.',
      };
    }

    return await updateUserProfile(
      userId: userId,
      fullname: fullname,
      phonenumber: phonenumber,
      email: email,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  // Get full profile with offline support
  Future<Map<String, dynamic>> getFullProfile(String userId) async {
    final isConnected = await _connectivityManager.isConnected();
    print('Connectivity check: $isConnected');

    if (isConnected) {
      try {
        print('Fetching full profile online for user: $userId');
        final result = await _onlineService.getFullProfile(userId);
        if (result['success']) {
          print('Online profile fetch success, caching...');
          await _cacheUserProfile(userId, result['profile']);
          return result;
        }
        print('Online profile fetch returned success=false');
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    print('Fetching full profile from offline cache for user: $userId');
    return await _getCachedFullProfile(userId);
  }

  // Update full profile with offline support
  Future<Map<String, dynamic>> updateFullProfile({
    required String userId,
    String? country,
    String? dateOfBirth,
    String? gender,
    String? preferredLanguage,
    String? bio,
    String? accountType,
    String? profileImage,
    List<String>? interests,
  }) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.updateFullProfile(
          userId: userId,
          country: country,
          dateOfBirth: dateOfBirth,
          gender: gender,
          preferredLanguage: preferredLanguage,
          bio: bio,
          accountType: accountType,
          interests: interests,
        );
        if (result['success']) {
          await _cacheUserProfile(userId, {
            'profile': {
              'country': country,
              'date_of_birth': dateOfBirth,
              'gender': gender,
              'preferred_language': preferredLanguage,
              'bio': bio,
              'account_type': accountType,
              'profile_image': profileImage,
            },
            'interests': interests,
          });
          return result;
        }
        print('❌ Online update failed, saving locally: ${result['message']}');
      } catch (e) {
        print('❌ Online update failed, saving locally: $e');
      }
    }

    return await _updateFullProfileLocally(
      userId,
      country: country,
      dateOfBirth: dateOfBirth,
      gender: gender,
      preferredLanguage: preferredLanguage,
      bio: bio,
      accountType: accountType,
      profileImage: profileImage,
      interests: interests,
    );
  }

  // Upload profile image (requires online connection)
  Future<Map<String, dynamic>> uploadProfileImage(
    int userId,
    File imageFile,
  ) async {
    final isConnected = await _connectivityManager.isConnected();

    if (!isConnected) {
      return {
        'success': false,
        'message': 'Internet connection required for image upload',
      };
    }

    try {
      return await _onlineService.uploadProfileImage(userId, imageFile);
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload image: $e'};
    }
  }

  // Private methods for caching and local operations
  Future<void> _cacheUser(UserModel user) async {
    final db = await _dbHelper.database;
    await db.insert(
      'users',
      user.toJson()..['synced'] = 1,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _cacheUserProfile(
    String userId,
    Map<String, dynamic> profile,
  ) async {
    final db = await _dbHelper.database;

    // Cache user profile details
    final innerProfile = profile['profile'] ?? {};
    
    await db.transaction((txn) async {
      final existing = await txn.query(
        'user_profile_details',
        where: 'user_id = ?',
        whereArgs: [int.parse(userId)],
      );

      final profileData = <String, dynamic>{
        'user_id': int.parse(userId),
        'synced': 1,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (innerProfile['country'] != null) profileData['country'] = innerProfile['country'];
      if (innerProfile['date_of_birth'] != null) profileData['date_of_birth'] = innerProfile['date_of_birth'];
      if (innerProfile['gender'] != null) profileData['gender'] = innerProfile['gender'];
      if (innerProfile['preferred_language'] != null) profileData['preferred_language'] = innerProfile['preferred_language'];
      if (innerProfile['bio'] != null) profileData['bio'] = innerProfile['bio'];
      if (innerProfile['profile_image'] != null) profileData['profile_image'] = innerProfile['profile_image'];
      if (innerProfile['account_type'] != null) profileData['account_type'] = innerProfile['account_type'];

      if (existing.isNotEmpty) {
        await txn.update(
          'user_profile_details',
          profileData,
          where: 'user_id = ?',
          whereArgs: [int.parse(userId)],
        );
      } else {
        await txn.insert('user_profile_details', profileData);
      }
    });

    // Cache user interests
    if (profile['interests'] != null) {
      final interests = List<String>.from(profile['interests']);
      await db.delete(
        'user_interests',
        where: 'user_id = ?',
        whereArgs: [int.parse(userId)],
      );
      for (final interest in interests) {
        await db.insert('user_interests', {
          'user_id': int.parse(userId),
          'interest': interest,
          'synced': 1,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  Future<Map<String, dynamic>> _loginOffline(
    String emailOrPhone,
    String password,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'users',
      where: '(email = ? OR phonenumber = ?) AND password = ?',
      whereArgs: [emailOrPhone, emailOrPhone, password],
    );

    if (maps.isNotEmpty) {
      final user = UserModel.fromJson(maps.first);
      await UserService.saveuserID(user.id!);
      await UserService.saveIsPremium(user.isPremium ? 1 : 0);

      return {
        'success': true,
        'message': 'Logged in offline',
        'user': user,
        'source': 'cache',
      };
    } else {
      return {
        'success': false,
        'message': 'Invalid credentials or user not found in offline cache',
      };
    }
  }

  Future<Map<String, dynamic>> _getCachedUserProfile(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [int.parse(userId)],
    );

    if (maps.isNotEmpty) {
      final user = UserModel.fromJson(maps.first);
      return {
        'success': true,
        'user': user,
        'message': 'User profile loaded from cache',
        'source': 'cache',
      };
    } else {
      return {'success': false, 'message': 'User not found in cache'};
    }
  }

  Future<Map<String, dynamic>> _getCachedFullProfile(String userId) async {
    final db = await _dbHelper.database;

    // Get user basic info
    final userMaps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [int.parse(userId)],
    );

    if (userMaps.isEmpty) {
      return {'success': false, 'message': 'User not found in cache'};
    }

    // Get user profile details
    final profileMaps = await db.query(
      'user_profile_details',
      where: 'user_id = ?',
      whereArgs: [int.parse(userId)],
    );

    // Get user interests
    final interestMaps = await db.query(
      'user_interests',
      where: 'user_id = ?',
      whereArgs: [int.parse(userId)],
    );

    final interests =
        interestMaps.map((map) => map['interest'] as String).toList();

    Map<String, dynamic> user = Map<String, dynamic>.from(userMaps.first);
    
    // Nestle the profile data to match online structure
    if (profileMaps.isNotEmpty) {
      user['profile'] = profileMaps.first;
    } else {
      user['profile'] = null;
    }
    user['interests'] = interests;

    return {
      'success': true,
      'profile': user,
      'message': 'Full profile loaded from cache',
      'source': 'cache',
    };
  }

  Future<Map<String, dynamic>> _updateUserProfileLocally(
    String userId, {
    String? fullname,
    String? phonenumber,
    String? email,
    String? newPassword,
  }) async {
    final db = await _dbHelper.database;

    final updateData = <String, dynamic>{
      'synced': 0,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (fullname != null) updateData['fullname'] = fullname;
    if (phonenumber != null) updateData['phonenumber'] = phonenumber;
    if (email != null) updateData['email'] = email;
    if (newPassword != null) updateData['password'] = newPassword;

    final rowsAffected = await db.update(
      'users',
      updateData,
      where: 'id = ?',
      whereArgs: [int.parse(userId)],
    );

    if (rowsAffected > 0) {
      return {
        'success': true,
        'message': '💾 Profile updated locally, will sync when online',
        'source': 'local',
        'pending_sync': true,
      };
    } else {
      return {'success': false, 'message': 'User not found in local database'};
    }
  }

  Future<Map<String, dynamic>> _updateFullProfileLocally(
    String userId, {
    String? country,
    String? dateOfBirth,
    String? gender,
    String? preferredLanguage,
    String? bio,
    String? accountType,
    String? profileImage,
    List<String>? interests,
  }) async {
    final db = await _dbHelper.database;

    // Use a transaction for consistency
    await db.transaction((txn) async {
      // Check if profile exists
      final existing = await txn.query(
        'user_profile_details',
        where: 'user_id = ?',
        whereArgs: [int.parse(userId)],
      );

      final profileUpdateData = <String, dynamic>{
        'synced': 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (country != null) profileUpdateData['country'] = country;
      if (dateOfBirth != null) profileUpdateData['date_of_birth'] = dateOfBirth;
      if (gender != null) profileUpdateData['gender'] = gender;
      if (preferredLanguage != null) {
        profileUpdateData['preferred_language'] = preferredLanguage;
      }
      if (bio != null) profileUpdateData['bio'] = bio;
      if (accountType != null) profileUpdateData['account_type'] = accountType;
      if (profileImage != null) profileUpdateData['profile_image'] = profileImage;

      if (existing.isNotEmpty) {
        // Update existing record
        await txn.update(
          'user_profile_details',
          profileUpdateData,
          where: 'user_id = ?',
          whereArgs: [int.parse(userId)],
        );
      } else {
        // Insert new record
        await txn.insert('user_profile_details', {
          'user_id': int.parse(userId),
          ...profileUpdateData,
        });
      }
    });

    // Update interests if provided
    if (interests != null) {
      await db.delete(
        'user_interests',
        where: 'user_id = ?',
        whereArgs: [int.parse(userId)],
      );

      for (final interest in interests) {
        await db.insert('user_interests', {
          'user_id': int.parse(userId),
          'interest': interest,
          'synced': 0,
        });
      }
    }

    return {
      'success': true,
      'message': '💾 Full profile updated locally, will sync when online',
      'source': 'local',
      'pending_sync': true,
    };
  }

  // Check server health (requires connection)
  Future<bool> checkServerHealth() async {
    final isConnected = await _connectivityManager.isConnected();
    if (!isConnected) return false;

    try {
      return await _onlineService.checkServerHealth();
    } catch (e) {
      return false;
    }
  }
}

// Offline Worship Notes Service
class OfflineWorshipNotesService {
  final WorshipNotesService _onlineService;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  OfflineWorshipNotesService({WorshipNotesService? onlineService})
    : _onlineService = onlineService ?? WorshipNotesService();

  // Create worship note with offline support
  Future<Map<String, dynamic>> createWorshipNote(String note) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.createWorshipNote(note);
        if (result['success']) {
          return result;
        }
      } catch (e) {
        print('❌ Online creation failed, saving locally: $e');
      }
    }

    return await _createWorshipNoteLocally(note);
  }

  // Get user worship notes with offline support
  Future<Map<String, dynamic>> getUserWorshipNotes() async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.getUserWorshipNotes();
        if (result['success']) {
          await _cacheWorshipNotes(result['notes']);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedWorshipNotes();
  }

  // Get worship note by ID with offline support
  Future<Map<String, dynamic>> getWorshipNote(String noteId) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.getWorshipNote(noteId);
        if (result['success']) {
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedWorshipNote(noteId);
  }

  // Update worship note with offline support
  Future<Map<String, dynamic>> updateWorshipNote({
    required String noteId,
    required String note,
  }) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.updateWorshipNote(
          noteId: noteId,
          note: note,
        );
        if (result['success']) {
          // Update cache with new data
          await _updateWorshipNoteInCache(noteId, note);
          return result;
        }
      } catch (e) {
        print('❌ Online update failed, saving locally: $e');
      }
    }

    return await _updateWorshipNoteLocally(noteId, note);
  }

  // Delete worship note with offline support
  Future<Map<String, dynamic>> deleteWorshipNote(String noteId) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.deleteWorshipNote(noteId);
        if (result['success']) {
          await _deleteWorshipNoteFromCache(noteId);
          return result;
        }
      } catch (e) {
        print('❌ Online delete failed, marking for deletion: $e');
      }
    }

    return await _markWorshipNoteForDeletion(noteId);
  }

  // Sync pending changes when back online
  Future<void> syncPendingChanges() async {
    final isConnected = await _connectivityManager.isConnected();
    if (!isConnected) return;

    final db = await _dbHelper.database;

    try {
      // Sync note deletions first
      await _syncPendingNoteDeletions(db);
      // Sync note creations
      await _syncPendingNoteCreations(db);
      // Sync note updates
      await _syncPendingNoteUpdates(db);
    } catch (e) {
      print('❌ Error syncing pending worship note changes: $e');
    }
  }

  // Get pending sync count
  Future<int> getPendingSyncCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM worship_notes WHERE synced = 0 OR synced = -1',
      );
      return result.first['count'] as int;
    } catch (e) {
      print('❌ Error getting pending sync count: $e');
      return 0;
    }
  }

  // Private methods for caching and local operations
  Future<void> _cacheWorshipNotes(List<dynamic> notes) async {
    final db = await _dbHelper.database;

    for (final note in notes) {
      await db.insert('worship_notes', {
        'id': note['id'],
        'user_id': note['user_id'],
        'note': note['note'],
        'created_at': note['created_at'],
        'updated_at': note['updated_at'],
        'synced': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    print('✅ Cached ${notes.length} worship notes');
  }

  Future<Map<String, dynamic>> _createWorshipNoteLocally(String note) async {
    final userId = await UserService.getUserID();
    if (userId.isEmpty) {
      return {
        'success': false,
        'message': 'No user ID found. Please login again.',
      };
    }

    final db = await _dbHelper.database;
    final tempId = -(DateTime.now().millisecondsSinceEpoch);
    final now = DateTime.now().toIso8601String();

    try {
      await db.insert('worship_notes', {
        'id': tempId,
        'user_id': int.parse(userId),
        'note': note,
        'created_at': now,
        'updated_at': now,
        'synced': 0,
      });

      return {
        'success': true,
        'note': {
          'id': tempId,
          'user_id': int.parse(userId),
          'note': note,
          'created_at': now,
          'updated_at': now,
        },
        'message': '💾 Worship note saved locally, will sync when online',
        'source': 'local',
        'pending_sync': true,
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to create note locally: $e'};
    }
  }

  Future<Map<String, dynamic>> _getCachedWorshipNotes() async {
    final userId = await UserService.getUserID();
    if (userId.isEmpty) {
      return {
        'success': false,
        'message': 'No user ID found. Please login again.',
      };
    }

    final db = await _dbHelper.database;
    final maps = await db.query(
      'worship_notes',
      where: 'user_id = ? AND synced != -1',
      whereArgs: [int.parse(userId)],
      orderBy: 'updated_at DESC',
    );

    return {
      'success': true,
      'notes': maps,
      'message': 'Worship notes loaded from cache',
      'source': 'cache',
    };
  }

  Future<Map<String, dynamic>> _getCachedWorshipNote(String noteId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'worship_notes',
      where: 'id = ? AND synced != -1',
      whereArgs: [int.parse(noteId)],
    );

    if (maps.isNotEmpty) {
      return {
        'success': true,
        'note': maps.first,
        'message': 'Worship note loaded from cache',
        'source': 'cache',
      };
    } else {
      return {'success': false, 'message': 'Worship note not found in cache'};
    }
  }

  Future<Map<String, dynamic>> _updateWorshipNoteLocally(
    String noteId,
    String note,
  ) async {
    final db = await _dbHelper.database;

    final rowsAffected = await db.update(
      'worship_notes',
      {
        'note': note,
        'updated_at': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [int.parse(noteId)],
    );

    if (rowsAffected > 0) {
      return {
        'success': true,
        'message': '💾 Worship note updated locally, will sync when online',
        'source': 'local',
        'pending_sync': true,
      };
    } else {
      return {
        'success': false,
        'message': 'Worship note not found in local database',
      };
    }
  }

  Future<void> _updateWorshipNoteInCache(String noteId, String note) async {
    final db = await _dbHelper.database;
    await db.update(
      'worship_notes',
      {
        'note': note,
        'updated_at': DateTime.now().toIso8601String(),
        'synced': 1,
      },
      where: 'id = ?',
      whereArgs: [int.parse(noteId)],
    );
  }

  Future<Map<String, dynamic>> _markWorshipNoteForDeletion(
    String noteId,
  ) async {
    final db = await _dbHelper.database;

    final rowsAffected = await db.update(
      'worship_notes',
      {'synced': -1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [int.parse(noteId)],
    );

    if (rowsAffected > 0) {
      return {
        'success': true,
        'message':
            '🗑️ Worship note marked for deletion, will sync when online',
        'source': 'local',
        'pending_sync': true,
      };
    } else {
      return {
        'success': false,
        'message': 'Worship note not found in local database',
      };
    }
  }

  Future<void> _deleteWorshipNoteFromCache(String noteId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'worship_notes',
      where: 'id = ?',
      whereArgs: [int.parse(noteId)],
    );
  }

  // Sync methods
  Future<void> _syncPendingNoteDeletions(Database db) async {
    try {
      final deletionMaps = await db.query(
        'worship_notes',
        where: 'synced = ?',
        whereArgs: [-1],
      );

      for (final noteData in deletionMaps) {
        final noteId = noteData['id'] as int;

        try {
          if (noteId > 0) {
            // Server record - try to delete from server
            final result = await _onlineService.deleteWorshipNote(
              noteId.toString(),
            );

            if (result['success']) {
              await db.delete(
                'worship_notes',
                where: 'id = ?',
                whereArgs: [noteId],
              );
              print('✅ Synced worship note deletion: $noteId');
            }
          } else {
            // Local-only record, just delete it
            await db.delete(
              'worship_notes',
              where: 'id = ?',
              whereArgs: [noteId],
            );
          }
        } catch (e) {
          print('❌ Failed to sync worship note deletion $noteId: $e');
        }
      }
    } catch (e) {
      print('❌ Error syncing pending note deletions: $e');
    }
  }

  Future<void> _syncPendingNoteCreations(Database db) async {
    try {
      final unsyncedMaps = await db.query(
        'worship_notes',
        where: 'synced = ?',
        whereArgs: [0],
      );

      for (final noteData in unsyncedMaps) {
        final noteId = noteData['id'] as int;

        try {
          if (noteId < 0) {
            // This is a locally created note
            final result = await _onlineService.createWorshipNote(
              noteData['note'] as String,
            );

            if (result['success']) {
              // Update local record with server data and mark as synced
              final serverNote = result['note'];
              await db.update(
                'worship_notes',
                {
                  'id': serverNote['id'],
                  'synced': 1,
                  'created_at': serverNote['created_at'],
                  'updated_at': serverNote['updated_at'],
                },
                where: 'id = ?',
                whereArgs: [noteId],
              );

              print(
                '✅ Synced local worship note creation: ${noteData['note']}',
              );
            }
          }
        } catch (e) {
          print('❌ Failed to sync worship note $noteId: $e');
        }
      }
    } catch (e) {
      print('❌ Error syncing pending note creations: $e');
    }
  }

  Future<void> _syncPendingNoteUpdates(Database db) async {
    try {
      final unsyncedMaps = await db.query(
        'worship_notes',
        where: 'synced = 0 AND id > 0', // Only sync updates for server records
        whereArgs: [],
      );

      for (final noteData in unsyncedMaps) {
        final noteId = noteData['id'] as int;

        try {
          final result = await _onlineService.updateWorshipNote(
            noteId: noteId.toString(),
            note: noteData['note'] as String,
          );

          if (result['success']) {
            // Mark as synced
            await db.update(
              'worship_notes',
              {'synced': 1, 'updated_at': DateTime.now().toIso8601String()},
              where: 'id = ?',
              whereArgs: [noteId],
            );
            print('✅ Synced worship note update: $noteId');
          }
        } catch (e) {
          print('❌ Failed to sync worship note update $noteId: $e');
        }
      }
    } catch (e) {
      print('❌ Error syncing pending note updates: $e');
    }
  }

  void dispose() {
    // Cleanup if needed
  }
}

// Offline Setlist Service

class SetListService {
  static const String baseUrl = 'https://api.therockofpraise.org';

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  // Get all folders for a user
  static Future<Map<String, dynamic>> getFolders(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/setlist/folders/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      final result = _handleResponse(response);

      // Normalize the response structure
      return {
        'success': true,
        'data': result['folders'] ?? result['data'] ?? [],
        'message': result['message'] ?? 'Folders loaded successfully',
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch folders: $e'};
    }
  }

  // Create new folder
  static Future<Map<String, dynamic>> createFolder(
    String userId,
    String folderName, {
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/setlist/folders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'folderName': folderName,
          'description': description,
        }),
      );
      final result = _handleResponse(response);

      // Normalize the response structure
      return {
        'success': result['success'] ?? true,
        'folder_id': result['folder_id'] ?? result['folderId'] ?? result['id'],
        'message': result['message'] ?? 'Folder created successfully',
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to create folder: $e'};
    }
  }

  // Add song to folder
  static Future<Map<String, dynamic>> addSongToFolder({
    required int folderId,
    required int songId,
    required String songName,
    required String artistName,
    required String songImage,
    required String lyricsFormat,
    required String savedLyrics,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/setlist/songs'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'folderId': folderId,
          'songId': songId,
          'songName': songName,
          'artistName': artistName,
          'songImage': songImage,
          'lyricsFormat': lyricsFormat,
          'savedLyrics': savedLyrics,
        }),
      );
      final result = _handleResponse(response);

      return {
        'success': result['success'] ?? true,
        'setlist_song_id': result['setlist_song_id'] ?? result['id'],
        'message': result['message'] ?? 'Song added successfully',
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to add song: $e'};
    }
  }

  // Get songs in a folder
  static Future<Map<String, dynamic>> getFolderSongs(int folderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/setlist/songs/$folderId'),
        headers: {'Content-Type': 'application/json'},
      );
      final result = _handleResponse(response);

      return {
        'success': true,
        'data': result['songs'] ?? result['data'] ?? [],
        'message': result['message'] ?? 'Songs loaded successfully',
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch songs: $e'};
    }
  }

  // Remove song from setlist
  static Future<Map<String, dynamic>> removeSongFromSetlist(
    int setlistSongId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/setlist/songs/$setlistSongId'),
        headers: {'Content-Type': 'application/json'},
      );
      final result = _handleResponse(response);

      return {
        'success': result['success'] ?? true,
        'message': result['message'] ?? 'Song removed successfully',
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to remove song: $e'};
    }
  }

  // Delete folder
  static Future<Map<String, dynamic>> deleteFolder(int folderId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/setlist/folders/$folderId'),
        headers: {'Content-Type': 'application/json'},
      );
      final result = _handleResponse(response);

      return {
        'success': result['success'] ?? true,
        'message': result['message'] ?? 'Folder deleted successfully',
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete folder: $e'};
    }
  }
}

class OfflineSetlistService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  // Get all folders for a user with offline support
  Future<Map<String, dynamic>> getFolders(String userId) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await SetListService.getFolders(userId);
        if (result['success']) {
          await _cacheFolders(result['data']);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedFolders(userId);
  }

  // Create new folder with offline support
  Future<Map<String, dynamic>> createFolder(
    String userId,
    String folderName, {
    String? description,
  }) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await SetListService.createFolder(
          userId,
          folderName,
          description: description,
        );
        if (result['success']) {
          return result;
        }
      } catch (e) {
        print('❌ Online creation failed, saving locally: $e');
      }
    }

    return await _createFolderLocally(
      userId,
      folderName,
      description: description,
    );
  }

  // Add song to folder with offline support
  Future<Map<String, dynamic>> addSongToFolder({
    required int folderId,
    required int songId,
    required String songName,
    required String artistName,
    required String songImage,
    required String lyricsFormat,
    required String savedLyrics,
  }) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await SetListService.addSongToFolder(
          folderId: folderId,
          songId: songId,
          songName: songName,
          artistName: artistName,
          songImage: songImage,
          lyricsFormat: lyricsFormat,
          savedLyrics: savedLyrics,
        );
        if (result['success']) {
          return result;
        }
      } catch (e) {
        print('❌ Online creation failed, saving locally: $e');
      }
    }

    return await _addSongToFolderLocally(
      folderId: folderId,
      songId: songId,
      songName: songName,
      artistName: artistName,
      songImage: songImage,
      lyricsFormat: lyricsFormat,
      savedLyrics: savedLyrics,
    );
  }

  // Get songs in a folder with offline support
  Future<Map<String, dynamic>> getFolderSongs(int folderId) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await SetListService.getFolderSongs(folderId);
        if (result['success']) {
          await _cacheFolderSongs(folderId, result['data']);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedFolderSongs(folderId);
  }

  // Remove song from setlist with offline support
  Future<Map<String, dynamic>> removeSongFromSetlist(int setlistSongId) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await SetListService.removeSongFromSetlist(
          setlistSongId,
        );
        if (result['success']) {
          await _removeSongFromCache(setlistSongId);
          return result;
        }
      } catch (e) {
        print('❌ Online delete failed, marking for deletion: $e');
      }
    }

    return await _markSongForDeletion(setlistSongId);
  }

  // Delete folder with offline support
  Future<Map<String, dynamic>> deleteFolder(int folderId) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await SetListService.deleteFolder(folderId);
        if (result['success']) {
          await _deleteFolderFromCache(folderId);
          return result;
        }
      } catch (e) {
        print('❌ Online delete failed, marking for deletion: $e');
      }
    }

    return await _markFolderForDeletion(folderId);
  }

  // Private methods for caching and local operations
  Future<void> _cacheFolders(List<dynamic> folders) async {
    final db = await _dbHelper.database;

    for (final folder in folders) {
      await db.insert('setlist_folders', {
        'id': folder['id'],
        'user_id': folder['user_id'],
        'folder_name': folder['folder_name'],
        'description': folder['description'],
        'created_at': folder['created_at'],
        'updated_at': folder['updated_at'],
        'synced': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    print('✅ Cached ${folders.length} setlist folders');
  }

  Future<void> _cacheFolderSongs(int folderId, List<dynamic> songs) async {
    final db = await _dbHelper.database;

    for (final song in songs) {
      await db.insert('setlist_songs', {
        'id': song['id'],
        'folder_id': folderId,
        'song_id': song['song_id'],
        'song_name': song['song_name'],
        'artist_name': song['artist_name'],
        'song_image': song['song_image'],
        'lyrics_format': song['lyrics_format'],
        'saved_lyrics': song['saved_lyrics'],
        'order_index': song['order_index'],
        'created_at': song['created_at'],
        'synced': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    print('✅ Cached ${songs.length} setlist songs');
  }

  Future<Map<String, dynamic>> _getCachedFolders(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'setlist_folders',
      where: 'user_id = ? AND synced != -1',
      whereArgs: [int.parse(userId)],
      orderBy: 'created_at DESC',
    );

    return {
      'success': true,
      'data': maps,
      'message': 'Setlist folders loaded from cache',
      'source': 'cache',
    };
  }

  Future<Map<String, dynamic>> _getCachedFolderSongs(int folderId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'setlist_songs',
      where: 'folder_id = ? AND synced != -1',
      whereArgs: [folderId],
      orderBy: 'order_index ASC',
    );

    return {
      'success': true,
      'data': maps,
      'message': 'Setlist songs loaded from cache',
      'source': 'cache',
    };
  }

  Future<Map<String, dynamic>> _createFolderLocally(
    String userId,
    String folderName, {
    String? description,
  }) async {
    final db = await _dbHelper.database;
    final tempId = -(DateTime.now().millisecondsSinceEpoch);
    final now = DateTime.now().toIso8601String();

    try {
      await db.insert('setlist_folders', {
        'id': tempId,
        'user_id': int.parse(userId),
        'folder_name': folderName,
        'description': description,
        'created_at': now,
        'updated_at': now,
        'synced': 0,
      });

      return {
        'success': true,
        'folder_id': tempId,
        'message': '💾 Setlist folder created locally, will sync when online',
        'source': 'local',
        'pending_sync': true,
      };
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        return {'success': false, 'message': 'Folder name already exists'};
      }
      return {'success': false, 'message': 'Failed to create folder: $e'};
    }
  }

  Future<Map<String, dynamic>> _addSongToFolderLocally({
    required int folderId,
    required int songId,
    required String songName,
    required String artistName,
    required String songImage,
    required String lyricsFormat,
    required String savedLyrics,
  }) async {
    final db = await _dbHelper.database;

    try {
      // Get next order index
      final orderResult = await db.rawQuery(
        'SELECT COALESCE(MAX(order_index), 0) + 1 as next_order FROM setlist_songs WHERE folder_id = ?',
        [folderId],
      );
      final nextOrder = orderResult.first['next_order'] as int;

      final tempId = -(DateTime.now().millisecondsSinceEpoch);

      await db.insert('setlist_songs', {
        'id': tempId,
        'folder_id': folderId,
        'song_id': songId,
        'song_name': songName,
        'artist_name': artistName,
        'song_image': songImage,
        'lyrics_format': lyricsFormat,
        'saved_lyrics': savedLyrics,
        'order_index': nextOrder,
        'created_at': DateTime.now().toIso8601String(),
        'synced': 0,
      });

      return {
        'success': true,
        'message': '💾 Song added to setlist locally, will sync when online',
        'source': 'local',
        'pending_sync': true,
      };
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        return {'success': false, 'message': 'Song already in this setlist'};
      }
      return {'success': false, 'message': 'Failed to add song to setlist: $e'};
    }
  }

  Future<Map<String, dynamic>> _markSongForDeletion(int setlistSongId) async {
    final db = await _dbHelper.database;

    final rowsAffected = await db.update(
      'setlist_songs',
      {'synced': -1},
      where: 'id = ?',
      whereArgs: [setlistSongId],
    );

    if (rowsAffected > 0) {
      return {
        'success': true,
        'message': '🗑️ Song marked for removal, will sync when online',
        'source': 'local',
        'pending_sync': true,
      };
    } else {
      return {'success': false, 'message': 'Setlist song not found'};
    }
  }

  Future<Map<String, dynamic>> _markFolderForDeletion(int folderId) async {
    final db = await _dbHelper.database;

    final rowsAffected = await db.update(
      'setlist_folders',
      {'synced': -1},
      where: 'id = ?',
      whereArgs: [folderId],
    );

    if (rowsAffected > 0) {
      // Also mark all songs in this folder for deletion
      await db.update(
        'setlist_songs',
        {'synced': -1},
        where: 'folder_id = ?',
        whereArgs: [folderId],
      );

      return {
        'success': true,
        'message': '🗑️ Folder marked for deletion, will sync when online',
        'source': 'local',
        'pending_sync': true,
      };
    } else {
      return {'success': false, 'message': 'Folder not found'};
    }
  }

  Future<void> _removeSongFromCache(int setlistSongId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'setlist_songs',
      where: 'id = ?',
      whereArgs: [setlistSongId],
    );
  }

  Future<void> _deleteFolderFromCache(int folderId) async {
    final db = await _dbHelper.database;
    await db.delete('setlist_folders', where: 'id = ?', whereArgs: [folderId]);
    await db.delete(
      'setlist_songs',
      where: 'folder_id = ?',
      whereArgs: [folderId],
    );
  }

  // Sync pending changes when back online
  Future<void> syncPendingChanges() async {
    final isConnected = await _connectivityManager.isConnected();
    if (!isConnected) return;

    final db = await _dbHelper.database;

    try {
      // Sync folder deletions first
      await _syncPendingFolderDeletions(db);
      // Sync song deletions
      await _syncPendingSongDeletions(db);
      // Sync folder creations
      await _syncPendingFolderCreations(db);
      // Sync song additions
      await _syncPendingSongAdditions(db);
    } catch (e) {
      print('❌ Error syncing pending setlist changes: $e');
    }
  }

  Future<void> _syncPendingFolderDeletions(Database db) async {
    try {
      final deletionMaps = await db.query(
        'setlist_folders',
        where: 'synced = ?',
        whereArgs: [-1],
      );

      for (final folderData in deletionMaps) {
        final folderId = folderData['id'] as int;

        try {
          if (folderId > 0) {
            final result = await SetListService.deleteFolder(folderId);

            if (result['success']) {
              await db.delete(
                'setlist_folders',
                where: 'id = ?',
                whereArgs: [folderId],
              );
              print('✅ Synced folder deletion: $folderId');
            }
          } else {
            await db.delete(
              'setlist_folders',
              where: 'id = ?',
              whereArgs: [folderId],
            );
          }
        } catch (e) {
          print('❌ Failed to sync folder deletion $folderId: $e');
        }
      }
    } catch (e) {
      print('❌ Error syncing pending folder deletions: $e');
    }
  }

  Future<void> _syncPendingSongDeletions(Database db) async {
    try {
      final deletionMaps = await db.query(
        'setlist_songs',
        where: 'synced = ?',
        whereArgs: [-1],
      );

      for (final songData in deletionMaps) {
        final songId = songData['id'] as int;

        try {
          if (songId > 0) {
            final result = await SetListService.removeSongFromSetlist(songId);

            if (result['success']) {
              await db.delete(
                'setlist_songs',
                where: 'id = ?',
                whereArgs: [songId],
              );
              print('✅ Synced setlist song deletion: $songId');
            }
          } else {
            await db.delete(
              'setlist_songs',
              where: 'id = ?',
              whereArgs: [songId],
            );
          }
        } catch (e) {
          print('❌ Failed to sync setlist song deletion $songId: $e');
        }
      }
    } catch (e) {
      print('❌ Error syncing pending song deletions: $e');
    }
  }

  Future<void> _syncPendingFolderCreations(Database db) async {
    try {
      final unsyncedMaps = await db.query(
        'setlist_folders',
        where: 'synced = ?',
        whereArgs: [0],
      );

      for (final folderData in unsyncedMaps) {
        final folderId = folderData['id'] as int;

        try {
          if (folderId < 0) {
            final result = await SetListService.createFolder(
              folderData['user_id'].toString(),
              folderData['folder_name'] as String,
              description: folderData['description'] as String?,
            );

            if (result['success']) {
              await db.update(
                'setlist_folders',
                {
                  'id': result['folder_id'],
                  'synced': 1,
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                },
                where: 'id = ?',
                whereArgs: [folderId],
              );

              await db.update(
                'setlist_songs',
                {'folder_id': result['folder_id']},
                where: 'folder_id = ?',
                whereArgs: [folderId],
              );

              print(
                '✅ Synced local folder creation: ${folderData['folder_name']}',
              );
            }
          }
        } catch (e) {
          print('❌ Failed to sync folder $folderId: $e');
        }
      }
    } catch (e) {
      print('❌ Error syncing pending folder creations: $e');
    }
  }

  Future<void> _syncPendingSongAdditions(Database db) async {
    try {
      final unsyncedMaps = await db.query(
        'setlist_songs',
        where: 'synced = ? AND folder_id > 0',
        whereArgs: [0],
      );

      for (final songData in unsyncedMaps) {
        final songId = songData['id'] as int;

        try {
          if (songId < 0) {
            final result = await SetListService.addSongToFolder(
              folderId: songData['folder_id'] as int,
              songId: songData['song_id'] as int,
              songName: songData['song_name'] as String,
              artistName: songData['artist_name'] as String,
              songImage: songData['song_image'] as String,
              lyricsFormat: songData['lyrics_format'] as String,
              savedLyrics: songData['saved_lyrics'] as String,
            );

            if (result['success']) {
              await db.update(
                'setlist_songs',
                {
                  'id': result['setlist_song_id'],
                  'synced': 1,
                  'created_at': DateTime.now().toIso8601String(),
                },
                where: 'id = ?',
                whereArgs: [songId],
              );
              print(
                '✅ Synced local setlist song addition: ${songData['song_name']}',
              );
            }
          }
        } catch (e) {
          print('❌ Failed to sync setlist song $songId: $e');
        }
      }
    } catch (e) {
      print('❌ Error syncing pending song additions: $e');
    }
  }

  // Get pending sync count
  Future<int> getPendingSyncCount() async {
    try {
      final db = await _dbHelper.database;
      final foldersResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM setlist_folders WHERE synced = 0 OR synced = -1',
      );
      final songsResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM setlist_songs WHERE synced = 0 OR synced = -1',
      );
      return (foldersResult.first['count'] as int) +
          (songsResult.first['count'] as int);
    } catch (e) {
      print('❌ Error getting pending sync count: $e');
      return 0;
    }
  }

  void dispose() {
    // Cleanup if needed
  }
}

// Offline Search Service
class OfflineSearchService {
  final SearchService _onlineService;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  OfflineSearchService({required String baseUrl, SearchService? onlineService})
    : _onlineService = onlineService ?? SearchService(baseUrl: baseUrl);

  // Search with offline support
  Future<Map<String, dynamic>> search(
    String query, {
    int page = 1,
    int limit = 10,
  }) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.search(
          query,
          page: page,
          limit: limit,
        );
        if (result['success']) {
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online search failed, searching cache: $e');
      }
    }

    return await _searchCache(query, page: page, limit: limit);
  }

  // Private method for cache search
  Future<Map<String, dynamic>> _searchCache(
    String query, {
    int page = 1,
    int limit = 10,
  }) async {
    final db = await _dbHelper.database;
    final offset = (page - 1) * limit;

    // Search albums
    final albumMaps = await db.rawQuery(
      '''
      SELECT albums.*, artists.name as artist_name, artists.image as artist_image
      FROM albums 
      LEFT JOIN artists ON albums.artist_id = artists.id 
      WHERE albums.synced != -1 AND (
        albums.name LIKE ? OR 
        artists.name LIKE ? OR 
        albums.description LIKE ?
      )
      ORDER BY albums.created_at DESC
      LIMIT ? OFFSET ?
    ''',
      ['%$query%', '%$query%', '%$query%', limit, offset],
    );

    // Search songs
    final songMaps = await db.rawQuery(
      '''
      SELECT songs.*, artists.name as artist_name, artists.image as artist_image, 
             albums.name as album_name, albums.image as album_image
      FROM songs 
      LEFT JOIN artists ON songs.artist_id = artists.id 
      LEFT JOIN albums ON songs.album_id = albums.id
      WHERE songs.synced != -1 AND (
        songs.songname LIKE ? OR 
        artists.name LIKE ? OR 
        songs.lyrics_si LIKE ? OR
        songs.lyrics_en LIKE ? OR
        songs.lyrics_ta LIKE ?
      )
      ORDER BY songs.created_at DESC
      LIMIT ? OFFSET ?
    ''',
      [
        '%$query%',
        '%$query%',
        '%$query%',
        '%$query%',
        '%$query%',
        limit,
        offset,
      ],
    );

    // Search artists
    final artistMaps = await db.rawQuery(
      '''
      SELECT * FROM artists 
      WHERE synced != -1 AND (
        name LIKE ? OR 
        bio LIKE ?
      )
      ORDER BY created_at DESC
      LIMIT ? OFFSET ?
    ''',
      ['%$query%', '%$query%', limit, offset],
    );

    final albums = albumMaps.map((map) => AlbumModel.fromJson(map)).toList();
    final songs = songMaps.map((map) => SongModel.fromJson(map)).toList();
    final artists = artistMaps.map((map) => ArtistModel.fromJson(map)).toList();

    return {
      'success': true,
      'albums': albums,
      'songs': songs,
      'artists': artists,
      'message': '🔍 Search completed in cache',
      'source': 'cache',
    };
  }
}
