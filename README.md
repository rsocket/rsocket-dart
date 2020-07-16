RSocket Dart SDK
================

# Examples

### Client

```dart
import 'package:rsocket/rsocket_connector.dart';
import 'package:rsocket/payload.dart';

void main() async {
  var rsocket = await RSocketConnector.create().connect('tcp://127.0.0.1:42252');
  var result = await rsocket.requestResponse(Payload.fromText('Ping', ''));
  print(result.getDataUtf8());
}
```

### Server

```dart
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

```

### RSocket Service Proxy & Routing

Please refer https://github.com/linux-china/rsocket-dart/tree/master/lib/route

# RSocket

- Operations
  - [x] REQUEST_FNF
  - [x] REQUEST_RESPONSE
  - [x] REQUEST_STREAM
  - [ ] REQUEST_CHANNEL
  - [x] METADATA_PUSH
- More Operations
  - [x] Error
  - [ ] Cancel
  - [x] Keepalive
- QoS
  - [ ] RequestN
  - [ ] Lease
- Transport
  - [x] TCP
  - [x] Websocket
- High Level APIs
  - [x] Client
  - [x] Server
- Misc
  - [x] RxDart


# References

* RSocket: https://rsocket.io
* Dart: https://dart.dev/
