import 'payload.dart';

typedef RequestResponse = Future<Payload> Function(Payload? payload);
typedef FireAndForget = Future<void> Function(Payload? payload);
typedef RequestStream = Stream<Payload?> Function(Payload? payload);
typedef RequestChannel = Stream<Payload> Function(Stream<Payload> payloads);
typedef MetadataPush = Future<void> Function(Payload? payload);
typedef RSocketClose = void Function();

abstract class Closeable {
  void close();
}

abstract class Availability {
  double availability();
}

class RSocket implements Closeable, Availability {
  RequestResponse? requestResponse =
      (Payload? payload) => Future.error(Exception('Unsupported'));
  FireAndForget? fireAndForget =
      (Payload? payload) => Future.error(Exception('Unsupported'));
  RequestStream? requestStream =
      (Payload? payload) => Stream.error(Exception('Unsupported'));
  RequestChannel? requestChannel =
      (Stream<Payload> payloads) => Stream.error(Exception('Unsupported'));
  MetadataPush? metadataPush =
      (Payload? payload) => Future.error(Exception('Unsupported'));

  @override
  void close() {}

  @override
  double availability() {
    return 1.0;
  }

  RSocket();

  RSocket.requestResponse(RequestResponse requestResponse) {
    this.requestResponse = requestResponse;
  }

  RSocket.fireAndForget(FireAndForget fireAndForget) {
    this.fireAndForget = fireAndForget;
  }

  RSocket.requestStream(RequestStream requestStream) {
    this.requestStream = requestStream;
  }

  RSocket.requestChannel(RequestChannel requestChannel) {
    this.requestChannel = requestChannel;
  }
}

typedef SocketAcceptor = RSocket? Function(
    ConnectionSetupPayload setup, RSocket sendingSocket);

SocketAcceptor requestResponseAcceptor(RequestResponse requestResponse) {
  return (setup, sendingSocket) {
    return RSocket()..requestResponse = requestResponse;
  };
}

SocketAcceptor fireAndForgetAcceptor(FireAndForget fireAndForget) {
  return (setup, sendingSocket) {
    return RSocket()..fireAndForget = fireAndForget;
  };
}

SocketAcceptor requestStreamAcceptor(RequestStream requestStream) {
  return (setup, sendingSocket) {
    return RSocket()..requestStream = requestStream;
  };
}

class RSocketService {
  final String? group;
  final String name;
  final String? version;

  const RSocketService(this.name, [this.version, this.group]);
}
