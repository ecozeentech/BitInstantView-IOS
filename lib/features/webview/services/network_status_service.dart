import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper over `connectivity_plus`.
///
/// This is deliberately used only as a *supplementary* signal (e.g. to
/// decide whether to proactively show "you appear to be offline" copy
/// before even attempting a retry). It must never be the sole reason a
/// legitimate page load is treated as failed: a device can report an
/// active Wi-Fi or cellular interface while that network has no real
/// internet route, and conversely some captive/VPN configurations report
/// "no network" while a request would actually succeed. The authoritative
/// signal for whether the site loaded is always the WebView's own
/// navigation delegate.
class NetworkStatusService {
  const NetworkStatusService();

  Future<bool> hasActiveConnection() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  Stream<bool> get onConnectivityChanged =>
      Connectivity().onConnectivityChanged.map(
        (results) => results.any((result) => result != ConnectivityResult.none),
      );
}
