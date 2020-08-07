import 'package:rsocket/shelf.dart';

void main() async {
  var rsocket =
      await RSocketConnector.create().connect('tcp://127.0.0.1:42252');
  var result = await rsocket.requestResponse(Payload.fromText('Ping', ''));
  print(result.getDataUtf8());
 /* rsocket.requestStream(Payload.fromText('Ping', '')).listen((payload) {
    print(payload.getDataUtf8());
  }, onDone: () {
    print('done');
  });*/
}
