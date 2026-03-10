import 'package:alipay_payment/alipay_payment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAlipayPaymentPlatform extends MockPlatformInterfaceMixin
    implements AlipayPaymentPlatform {
  @override
  Future<String?> getPlatformVersion() => Future<String?>.value('42');

  @override
  Future<void> setEnvironment(AlipayEnvironment environment) =>
      Future<void>.value();

  @override
  Future<void> pay({
    required String orderInfo,
    String? urlScheme,
    String? universalLink,
    bool showPayLoading = true,
    AlipayEnvironment? payEnv,
    bool dynamicLaunch = false,
  }) =>
      Future<void>.value();

  @override
  Future<void> auth({
    required String authInfo,
    String? urlScheme,
    String? universalLink,
    bool showPayLoading = true,
  }) =>
      Future<void>.value();

  @override
  Stream<AlipayResult> payResp() =>
      Stream<AlipayResult>.value(const AlipayResult(resultStatus: '9000'));

  @override
  Stream<AlipayResult> authResp() =>
      Stream<AlipayResult>.value(const AlipayResult(resultStatus: '9000'));

  @override
  Future<bool> isAlipayInstalled() => Future<bool>.value(true);

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final AlipayPaymentPlatform initialPlatform = AlipayPaymentPlatform.instance;

  test('$MethodChannelAlipayPayment is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAlipayPayment>());
  });

  test('getPlatformVersion', () async {
    final MockAlipayPaymentPlatform fakePlatform =
        MockAlipayPaymentPlatform();
    AlipayPaymentPlatform.instance = fakePlatform;

    expect(await AlipayPaymentPlatform.instance.getPlatformVersion(), '42');
  });
}
