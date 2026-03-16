// services/connectivity_manager.dart
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityManager {
  static final ConnectivityManager _instance = ConnectivityManager._internal();
  factory ConnectivityManager() => _instance;
  ConnectivityManager._internal();

  final Connectivity _connectivity = Connectivity();

  Future<bool> isConnected() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Stream<ConnectivityResult> get connectivityStream =>
      _connectivity.onConnectivityChanged;
}
