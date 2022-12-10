import 'package:universal_io/io.dart';
import 'package:web_socket_channel/src/channel.dart';

import '../core/rsocket_requester.dart';
import '../duplex_connection.dart';
import '../frame/frame.dart';
import '../frame/frame_types.dart' as frame_types;
import '../payload.dart';
import '../rsocket.dart';

class BaseResponder {
  late SocketAcceptor socketAcceptor;
  late Uri uri;

  Future<void> receiveConnection(DuplexConnection duplexConn) async {
    RSocketRequester? rsocketRequester;
    duplexConn.receiveHandler = (chunk) {
      for (var frame in parseFrames(chunk)) {
        var header = frame.header;
        if (header.type == frame_types.SETUP) {
          var setupFrame = frame as SetupFrame;
          var connectionSetupPayload = ConnectionSetupPayload()
            ..keepAliveIntervalMs = setupFrame.keepAliveIntervalMs
            ..keepAliveMaxLifetimeMs = setupFrame.keepAliveMaxLifetimeMs
            ..metadataMimeType = setupFrame.metadataMimeType
            ..dataMimeType = setupFrame.dataMimeType
            ..data = setupFrame.payload?.data
            ..metadata = setupFrame.payload?.data;
          var temp =
              RSocketRequester('responder', connectionSetupPayload, duplexConn);
          var responder = socketAcceptor(connectionSetupPayload, temp);
          if (responder == null) {
            duplexConn.close();
            break;
          } else {
            temp.responder = responder;
            rsocketRequester = temp;
          }
        } else {
          rsocketRequester?.receiveFrame(frame);
        }
      }
    };
    duplexConn.init();
  }
}

class TcpRSocketResponder extends BaseResponder implements Closeable {
  late ServerSocket serverSocket;

  TcpRSocketResponder(
      Uri uri, ServerSocket serverSocket, SocketAcceptor socketAcceptor) {
    this.uri = uri;
    this.socketAcceptor = socketAcceptor;
    this.serverSocket = serverSocket;
  }

  void accept() {
    serverSocket.listen((socket) {
      receiveConnection(TcpDuplexConnection(socket)).then((value) => {});
    });
  }

  @override
  void close() {
    serverSocket.close();
  }
}

class WebSocketRSocketResponder extends BaseResponder implements Closeable {
  late HttpServer httpServer;

  WebSocketRSocketResponder(
      Uri uri, HttpServer httpServer, SocketAcceptor socketAcceptor) {
    this.uri = uri;
    this.socketAcceptor = socketAcceptor;
    this.httpServer = httpServer;
  }

  void accept() {
    httpServer.listen((HttpRequest req) {
      if (req.uri.path == uri.path) {
        WebSocketTransformer.upgrade(req)
            .then((webSocket) => receiveConnection(
                WebSocketDuplexConnection(webSocket as WebSocketChannel)))
            .then((value) => {});
      }
    });
  }

  @override
  void close() {
    httpServer.close();
  }
}
