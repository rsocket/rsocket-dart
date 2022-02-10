
import 'package:universal_io/io.dart';

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
    var scheme = uri.scheme;
    if (scheme == 'tcp') {
      return ServerSocket.bind(uri.host, uri.port).then((serverSocket) {
        return TcpRSocketResponder(uri, serverSocket, socketAcceptor)..accept();
      });
    } else if (scheme == 'ws' || scheme == 'wss') {
      return HttpServer.bind(uri.host, uri.port).then((httpServer) {
        return WebSocketRSocketResponder(uri, httpServer, socketAcceptor)
          ..accept();
      });
    } else {
      return Future.error('${scheme} unsupported');
    }
  }
}
