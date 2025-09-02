import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  Future<bool> isOnline() async {
    final res = await Connectivity().checkConnectivity();
    return res.contains(ConnectivityResult.mobile) ||
        res.contains(ConnectivityResult.wifi) ||
        res.contains(ConnectivityResult.ethernet) ||
        res.contains(ConnectivityResult.vpn);
  }
}
