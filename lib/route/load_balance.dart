import '../rsocket.dart';
import '../rsocket_connector.dart';

/// RSocket load balance
///
/// ```
/// var rsocket = LoadBalanceRSocket();
/// await rsocket.refreshUrl(['tcp://127.0.0.1:42252']);
/// ```
///
/// todo: health check, try to reconnection
class LoadBalanceRSocket extends RSocket {
  List<RSocket> connections = [];
  Map<String, RSocket> url2Conn = {};
  int poolSize = 0;
  int counter = 0;

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
        return getRandomRSocket()?.fireAndForget(payload) ?? Future.error(Exception('No available connection'));
      }
      ..requestResponse = (payload) {
        return getRandomRSocket()?.requestResponse(payload) ?? Future.error(Exception('No available connection'));
      }
      ..requestStream = (payload) {
        return getRandomRSocket()?.requestStream(payload) ?? Stream.error(Exception('No available connection'));
      }
      ..requestChannel = (payloads) {
        return getRandomRSocket()?.requestChannel(payloads) ?? Stream.error(Exception('No available connection'));
      }
      ..metadataPush = (payload) {
        return getRandomRSocket()?.metadataPush(payload) ?? Future.error(Exception('No available connection'));
      };
  }

  @override
  double availability() {
    return 1.0;
  }

  @override
  void close() {
    url2Conn.forEach((url, rsocket) {
      print('Close RSocket: ${url}');
      rsocket.close();
    });
  }

  void closeStales(Map<String, RSocket> staleConnections) {
    staleConnections.forEach((url, rsocket) {
      print('Close RSocket: ${url}');
      rsocket.close();
    });
  }

  Future<void> refreshUrl(List<String> urls) async {
    var newConnections = <RSocket>[];
    var newUrl2Conn = <String, RSocket>{};
    var staleConnections = <String, RSocket>{};

    for (var url in urls) {
      var rsocket = url2Conn[url];
      rsocket ??= await _connect(url);
      newConnections.add(rsocket);
      newUrl2Conn[url] = rsocket;
    }

    url2Conn.forEach((url, rsocket) {
      if (newUrl2Conn[url] == null) {
        staleConnections[url] = rsocket;
      }
    });
    connections = newConnections;
    url2Conn = newUrl2Conn;
    poolSize = connections.length;
    closeStales(staleConnections);
  }

  RSocket getRandomRSocket() {
    if (poolSize == 0) {
      return null;
    }
    counter = counter + 1;
    if (counter > poolSize) {
      counter = 0;
    }
    var rsocket = connections[counter % poolSize];
    if (rsocket.availability() == 0.0) {
      connections.remove(rsocket);
      poolSize = connections.length;
      url2Conn.removeWhere((key, value) => value == rsocket);
      return getRandomRSocket();
    } else {
      return rsocket;
    }
  }

  Future<RSocket> _connect(String url) async {
    return RSocketConnector.create().connect(url);
  }
}
