import 'dart:typed_data';

import 'core/rsocket_error.dart';
import 'payload.dart';
import 'rsocket.dart';

import 'core/rsocket_requester.dart';
import 'duplex_connection.dart';

class RSocketConnector {
  Payload payload;
  int keepAliveInterval = 20;
  int keepAliveMaxLifeTime = 90;
  String dataMimeType = 'application/json';
  String metadataMimeType = 'message/x.rsocket.composite-metadata.v0';
  ErrorConsumer _errorConsumer;
  SocketAcceptor acceptor;

  RSocketConnector.create();

  Future<RSocket> connect(String url) async {
    TcpChunkHandler handler = (Uint8List chunk) {};
    var connectionSetupPayload = ConnectionSetupPayload()
      ..keepAliveInterval = keepAliveInterval * 1000
      ..keepAliveMaxLifetime = keepAliveMaxLifeTime * 1000
      ..metadataMimeType = metadataMimeType
      ..dataMimeType = dataMimeType
      ..data = payload?.data
      ..metadata = payload?.metadata;
    return connectRSocket(url, handler).then((conn) {
      var rsocketRequester = RSocketRequester('requester', connectionSetupPayload, conn);
      if (acceptor != null) {
        rsocketRequester.responder = acceptor(connectionSetupPayload, rsocketRequester);
        if (rsocketRequester.responder == null) {
          rsocketRequester.close();
          return Future.error('RSOCKET-0x00000003: Connection refused, please check setup and security!');
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
