import 'package:flutter_test/flutter_test.dart';
import 'package:alipay_payment/alipay_payment.dart';
import 'package:alipay_payment/alipay_payment_platform_interface.dart';
import 'package:alipay_payment/alipay_payment_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAlipayPaymentPlatform
    with MockPlatformInterfaceMixin
    implements AlipayPaymentPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AlipayPaymentPlatform initialPlatform = AlipayPaymentPlatform.instance;

  test('$MethodChannelAlipayPayment is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAlipayPayment>());
  });

  test('getPlatformVersion', () async {
    AlipayPayment alipayPaymentPlugin = AlipayPayment();
    MockAlipayPaymentPlatform fakePlatform = MockAlipayPaymentPlatform();
    AlipayPaymentPlatform.instance = fakePlatform;

    expect(await alipayPaymentPlugin.getPlatformVersion(), '42');
  });
}
