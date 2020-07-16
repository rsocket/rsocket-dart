import 'package:rsocket/rsocket_connector.dart';
import 'package:rsocket/payload.dart';

void main() async {
  var rsocket = await RSocketConnector.create().connect('tcp://127.0.0.1:42252');
  var result = await rsocket.requestResponse(Payload.fromText('Ping', ''));
  print(result.getDataUtf8());
}
