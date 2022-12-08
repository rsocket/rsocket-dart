import 'dart:typed_data';

import 'core/rsocket_error.dart';
import 'core/rsocket_requester.dart';
import 'duplex_connection.dart';
import 'payload.dart';
import 'rsocket.dart';

class RSocketConnector {
  Payload? payload;
  int keepAliveInterval = 20;
  int keepAliveMaxLifeTime = 90;
  String _dataMimeType = 'application/json';
  String _metadataMimeType = 'message/x.rsocket.composite-metadata.v0';
  ErrorConsumer? _errorConsumer;
  SocketAcceptor? _acceptor;

  RSocketConnector.create();

  RSocketConnector acceptor(SocketAcceptor socketAcceptor) {
    this._acceptor = socketAcceptor;
    return this;
  }

  RSocketConnector setupPayload(Payload payload) {
    this.payload = payload;
    return this;
  }

  RSocketConnector dataMimeType(String dataMimeType) {
    _dataMimeType = dataMimeType;
    return this;
  }

  RSocketConnector metadataMimeType(String metadataMimeType) {
    _metadataMimeType = metadataMimeType;
    return this;
  }

  RSocketConnector errorConsumer(ErrorConsumer errorConsumer) {
    _errorConsumer = errorConsumer;
    return this;
  }

  // set the keep alive, and unit is second
  RSocketConnector keepAlive(int interval, int maxLifeTime) {
    this.keepAliveInterval = interval;
    this.keepAliveMaxLifeTime = maxLifeTime;
    return this;
  }

  Future<RSocket> connect(String url) async {
    TcpChunkHandler handler = (Uint8List chunk) {};
    var connectionSetupPayload = ConnectionSetupPayload()
      ..keepAliveInterval = keepAliveInterval
      ..keepAliveMaxLifetime = keepAliveMaxLifeTime
      ..metadataMimeType = _metadataMimeType
      ..dataMimeType = _dataMimeType
      ..data = payload?.data
      ..metadata = payload?.metadata;
    return connectRSocket(url, handler).then((conn) {
      var rsocketRequester =
          RSocketRequester('requester', connectionSetupPayload, conn);
      if (_acceptor != null) {
        rsocketRequester.responder =
            _acceptor!(connectionSetupPayload, rsocketRequester);
        if (rsocketRequester.responder == null) {
          rsocketRequester.close();
          return Future.error(
              'RSOCKET-0x00000003: Connection refused, please check setup and security!');
        }
      } else {
        rsocketRequester.responder = RSocket();
      }
      rsocketRequester.errorConsumer = _errorConsumer;
      rsocketRequester.sendSetupPayload();
      return rsocketRequester;
    });
  }
}
