import 'dart:io';
import 'dart:typed_data';

import 'io/bytes.dart';
import 'rsocket.dart';

abstract class DuplexConnection implements Closeable, Availability {
  double _availability = 1.0;
  TcpChunkHandler? receiveHandler;
  CloseHandler? closeHandler;

  void init();

  void write(Uint8List chunk);

  @override
  double availability() {
    return _availability;
  }
}

typedef TcpChunkHandler = void Function(Uint8List chunk);
typedef CloseHandler = void Function();

class TcpDuplexConnection extends DuplexConnection {
  Socket socket;
  bool closed = false;

  TcpDuplexConnection(this.socket);

  @override
  void init() {
    socket.listen((data) {
      receiveHandler!(data);
    }, onDone: () {
      close();
    }, onError: (e) {
      close();
    });
  }

  @override
  void close() {
    if (!closed) {
      closed = true;
      _availability = 0.0;
      socket.close();
      closeHandler?.call();
    }
  }

  @override
  void write(Uint8List chunk) {
    socket.add(chunk);
  }
}

class WebSocketDuplexConnection extends DuplexConnection {
  WebSocket webSocket;
  bool closed = false;

  WebSocketDuplexConnection(this.webSocket);

  @override
  void init() {
    webSocket.listen((message) {
      var data = message as List<int>;
      var frameLenBytes = i24ToBytes(data.length);
      receiveHandler!(Uint8List.fromList(frameLenBytes + data));
    }, onDone: () {
      close();
    }, onError: (e) {
      close();
    });
  }

  @override
  void close() {
    if (!closed) {
      closed = true;
      _availability = 0.0;
      webSocket.close();
      closeHandler?.call();
    }
  }

  @override
  void write(Uint8List chunk) {
    //remove frame length: 3 bytes
    webSocket.add(chunk.sublist(3));
  }
}

Future<DuplexConnection> connectRSocket(String url, TcpChunkHandler handler) {
  var uri = Uri.parse(url);
  var scheme = uri.scheme;
  if (scheme == 'tcp') {
    var socketFuture = Socket.connect(uri.host, uri.port);
    return socketFuture.then((socket) => TcpDuplexConnection(socket));
  } else if (scheme == 'ws' || scheme == 'wss') {
    var socketFuture = WebSocket.connect(url);
    return socketFuture.then((socket) => WebSocketDuplexConnection(socket));
  } else {
    return Future.error('${scheme} unsupported');
  }
}
