import 'package:alipay_payment/alipay_payment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('signType constants match alipay_kit', () {
    expect(AlipaySign.signTypeRsa, 'RSA');
    expect(AlipaySign.signTypeRsa2, 'RSA2');
    expect(AlipaySign.authTypeAuthAccount, 'AUTHACCOUNT');
    expect(AlipaySign.authTypeLogin, 'LOGIN');
  });
}
