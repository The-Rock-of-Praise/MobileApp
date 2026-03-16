// widgets/sync_indicator.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:lyrics/OfflineService/sync_manager.dart';

class SyncIndicator extends StatefulWidget {
  const SyncIndicator({super.key});

  @override
  _SyncIndicatorState createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator> {
  final SyncManager _syncManager = SyncManager();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  bool _isOnline = false;
  bool _isSyncing = false;
  DateTime? _lastSync;

  @override
  void initState() {
    super.initState();
    _checkStatus();

    // Listen for connectivity changes
    _connectivityManager.connectivityStream.listen((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
    });
  }

  Future<void> _checkStatus() async {
    final isOnline = await _connectivityManager.isConnected();
    final lastSync = await _syncManager.getLastSyncTime();

    setState(() {
      _isOnline = isOnline;
      _lastSync = lastSync;
      _isSyncing = _syncManager.isSyncing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isOnline ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isOnline ? Icons.cloud_done : Icons.cloud_off,
            size: 16,
            color: _isOnline ? Colors.green : Colors.orange,
          ),
          SizedBox(width: 4),
          Text(
            _isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              color: _isOnline ? Colors.green[700] : Colors.orange[700],
            ),
          ),
          if (_isSyncing) ...[
            SizedBox(width: 8),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }
}
