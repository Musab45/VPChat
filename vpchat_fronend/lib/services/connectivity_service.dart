import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  // Callbacks
  Function(bool isOnline)? onConnectivityChanged;

  Future<void> initialize() async {
    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
        onError: (error) {
          print('❌ Connectivity listener error: $error');
          // Assume online if plugin fails
          _isOnline = true;
        },
      );
    } catch (e) {
      print('❌ Failed to initialize connectivity service: $e');
      // Assume online if plugin not available
      _isOnline = true;
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;

    // Check if any connection is available
    _isOnline = results.any((result) => result != ConnectivityResult.none);

    // Notify if status changed
    if (wasOnline != _isOnline) {
      print('📡 Network status changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
      onConnectivityChanged?.call(_isOnline);
    }
  }

  Future<bool> checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      return _isOnline;
    } catch (e) {
      print('❌ Failed to check connectivity: $e');
      // Return current state if check fails
      return _isOnline;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
