import 'package:rsocket/rsocket_server.dart';
import 'package:rsocket/payload.dart';
import 'package:rsocket/rsocket.dart';

void main() async {
  const listenUrl = 'tcp://0.0.0.0:42252';
  var closeable = await RSocketServer.create(requestResponseAcceptor((payload) {
    return Future.value(Payload.fromText('text/plain', 'Hello'));
  })).bind(listenUrl);
  print('RSocket Server started on ${listenUrl}');
}
