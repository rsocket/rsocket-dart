import 'dart:async';

import '../rsocket.dart';
import '../rsocket_connector.dart';

/// RSocket load balance
///
/// ```
/// var rsocket = LoadBalanceRSocket();
/// await rsocket.refreshUrl(['tcp://127.0.0.1:42252']);
/// ```
///
class LoadBalanceRSocket extends RSocket {
  List<String> lastRSocketUrls = [];
  Map<String, RSocket> activeRSockets = {};
  List<RSocket> roundRobin = [];
  List<String> unHealthyUrls = [];
  int poolSize = 0;
  int counter = 0;
  int lastRefreshTimeStamp = 0;
  static final Duration healthCheckIntervalSeconds =
      const Duration(seconds: 15);
  Timer healthCheckTimer;

  @override
  var fireAndForget;

  @override
  var metadataPush;

  @override
  var requestChannel;

  @override
  var requestResponse;

  @override
  var requestStream;

  LoadBalanceRSocket() {
    this
      ..fireAndForget = (payload) {
        return getRandomRSocket()?.fireAndForget(payload) ??
            Future.error(Exception('No available connection'));
      }
      ..requestResponse = (payload) {
        return getRandomRSocket()?.requestResponse(payload) ??
            Future.error(Exception('No available connection'));
      }
      ..requestStream = (payload) {
        return getRandomRSocket()?.requestStream(payload) ??
            Stream.error(Exception('No available connection'));
      }
      ..requestChannel = (payloads) {
        return getRandomRSocket()?.requestChannel(payloads) ??
            Stream.error(Exception('No available connection'));
      }
      ..metadataPush = (payload) {
        return getRandomRSocket()?.metadataPush(payload) ??
            Future.error(Exception('No available connection'));
      };
    healthCheckTimer = Timer.periodic(
        healthCheckIntervalSeconds, (Timer t) => checkActiveRSockets());
  }

  @override
  double availability() {
    return 1.0;
  }

  @override
  void close() {
    if (healthCheckTimer != null) {
      healthCheckTimer.cancel();
    }
    activeRSockets.forEach((url, rsocket) {
      print('Close RSocket: ${url}');
      rsocket.close();
    });
  }

  void closeStales(Map<String, RSocket> staleRSockets) async {
    await new Future.delayed(const Duration(seconds: 15));
    staleRSockets.forEach((url, rsocket) {
      print('Close RSocket: ${url}');
      rsocket.close();
    });
  }

  Future<void> refreshUrl(List<String> urls) async {
    lastRSocketUrls = urls;
    unHealthyUrls.clear();
    lastRefreshTimeStamp = DateTime.now().millisecondsSinceEpoch;
    var newRSockets = <RSocket>[];
    var newUrl2Conn = <String, RSocket>{};
    var staleRSockets = <String, RSocket>{};

    for (var url in urls) {
      var rsocket = activeRSockets[url];
      try {
        rsocket ??= await connect(url);
        newRSockets.add(rsocket);
        newUrl2Conn[url] = rsocket;
      } on Exception {
        unHealthyUrls.add(url);
      }
    }

    activeRSockets.forEach((url, rsocket) {
      if (newUrl2Conn[url] == null) {
        staleRSockets[url] = rsocket;
      }
    });
    roundRobin = newRSockets;
    activeRSockets = newUrl2Conn;
    poolSize = roundRobin.length;
    closeStales(staleRSockets);
  }

  RSocket getRandomRSocket() {
    if (poolSize == 0) {
      return null;
    }
    counter = counter + 1;
    if (counter >= 0x7FFFFFFF) {
      counter = 0;
    }
    var rsocket = roundRobin[counter % poolSize];
    if (rsocket.availability() == 0.0) {
      roundRobin.remove(rsocket);
      poolSize = roundRobin.length;
      activeRSockets.removeWhere((key, value) => value == rsocket);
      return getRandomRSocket();
    } else {
      return rsocket;
    }
  }

  void checkActiveRSockets() {
    //todo health check for active RSockets
  }

  void checkUnhealthyUris() {
    //todo unhealthy check
  }

  Future<RSocket> connect(String url) async {
    return RSocketConnector.create().connect(url);
  }
}
