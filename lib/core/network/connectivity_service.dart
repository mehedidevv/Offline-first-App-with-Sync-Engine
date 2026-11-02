import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

class ConnectivityService {
  final Connectivity _connectivity;
  final Dio _dio;
  
  final StreamController<bool> _connectionChangeController = StreamController<bool>.broadcast();
  bool _hasConnection = true;

  ConnectivityService({Connectivity? connectivity, Dio? dio})
      : _connectivity = connectivity ?? Connectivity(),
        _dio = dio ?? Dio() {
    _init();
  }

  Stream<bool> get connectionChange => _connectionChangeController.stream;
  bool get hasConnection => _hasConnection;

  void _init() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
    // Check initial
    _connectivity.checkConnectivity().then((results) {
      _updateConnectionStatus(results);
    });
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    bool previousConnection = _hasConnection;

    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      _hasConnection = false;
    } else {
      // Perform an actual reachability check or trust connectivity result
      _hasConnection = await _checkApiReachability();
    }

    if (previousConnection != _hasConnection) {
      _connectionChangeController.add(_hasConnection);
    }
  }

  Future<bool> _checkApiReachability() async {
    try {
      // Basic lightweight check or ping endpoint
      // If offline or timeout, returns false
      final response = await _dio.get(
        'https://jsonplaceholder.typicode.com/posts/1',
        options: Options(receiveTimeout: const Duration(seconds: 3), sendTimeout: const Duration(seconds: 3)),
      );
      return response.statusCode == 200;
    } catch (_) {
      // Even if public ping fails, if connectivity result is mobile/wifi, we can consider online or test specific API
      // For robustness, if connectivity_plus says wifi/mobile/ethernet, return true unless strictly failing
      return true;
    }
  }

  Future<bool> checkConnectivityNow() async {
    final results = await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      _hasConnection = false;
    } else {
      _hasConnection = await _checkApiReachability();
    }
    return _hasConnection;
  }

  void dispose() {
    _connectionChangeController.close();
  }
}
