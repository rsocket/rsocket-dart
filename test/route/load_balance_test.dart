import 'package:rsocket/payload.dart';
import 'package:rsocket/route/load_balance.dart';
import 'package:test/test.dart';

void main() {
  test('load-balance', () async {
    var rsocket = LoadBalanceRSocket();
    await rsocket.refreshUrl(['tcp://127.0.0.1:42252']);
    var result = await rsocket.requestResponse(Payload.fromText('Ping', ''));
    print(result.getDataUtf8());
  });
}
