import 'dart:io';

import 'core/rsocket_responder.dart';
import 'rsocket.dart';

class RSocketServer {
  SocketAcceptor socketAcceptor;

  RSocketServer(this.socketAcceptor);

  static RSocketServer create(SocketAcceptor socketAcceptor) {
    return RSocketServer(socketAcceptor);
  }

  Future<Closeable> bind(String url) {
    var uri = Uri.parse(url);
    var schema = uri.scheme;
    if (schema == 'tcp') {
      return ServerSocket.bind(uri.host, uri.port).then((serverSocket) {
        return TcpRSocketResponder(uri, serverSocket, socketAcceptor)..accept();
      });
    } else if (schema == 'ws' || schema == 'wss') {
      return HttpServer.bind(uri.host, uri.port).then((httpServer) {
        return WebSocketRSocketResponder(uri, httpServer, socketAcceptor)..accept();
      });
    } else {
      return Future.error('${schema} unsupported');
    }
  }
}
