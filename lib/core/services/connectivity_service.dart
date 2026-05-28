import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();

  static Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result.any((status) =>
        status == ConnectivityResult.wifi ||
        status == ConnectivityResult.mobile ||
        status == ConnectivityResult.ethernet);
  }

  static Future<bool> isOffline() async {
    return !(await isConnected());
  }

  static Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
