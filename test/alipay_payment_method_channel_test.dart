import 'package:alipay_payment/alipay_payment.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannelAlipayPayment platform = MethodChannelAlipayPayment();
  final MethodChannel channel =
      MethodChannel(MethodChannelAlipayPayment.channelName);

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
        case 'getPlatformVersion':
          return '42';
        case 'setEnvironment':
          return null;
        case 'pay':
          return <String, Object?>{
            'resultStatus': '9000',
            'result': null,
            'memo': null,
          };
        case 'auth':
          return <String, Object?>{
            'resultStatus': '9000',
            'result': null,
            'memo': null,
          };
        case 'isAlipayInstalled':
          return true;
        default:
          return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('isAlipayInstalled', () async {
    expect(await platform.isAlipayInstalled(), true);
  });

  test('pay emits AlipayResult via payResp', () async {
    final List<AlipayResult> results = <AlipayResult>[];
    platform.payResp().listen(results.add);
    await platform.pay(orderInfo: 'test');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(results, hasLength(1));
    expect(results.first.resultStatus, '9000');
    expect(results.first.isSuccess, true);
  });

  test('auth emits AlipayResult via authResp', () async {
    final List<AlipayResult> results = <AlipayResult>[];
    platform.authResp().listen(results.add);
    await platform.auth(authInfo: 'test');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(results, hasLength(1));
    expect(results.first.resultStatus, '9000');
    expect(results.first.isSuccess, true);
  });

  test('payAndWait returns AlipayResult', () async {
    final AlipayResult result = await platform.payAndWait(orderInfo: 'test');
    expect(result.resultStatus, '9000');
    expect(result.isSuccess, true);
    expect(result.resultStatusCode, 9000);
  });

  test('authAndWait returns AlipayResult', () async {
    final AlipayResult result = await platform.authAndWait(authInfo: 'test');
    expect(result.resultStatus, '9000');
    expect(result.isSuccess, true);
  });

  test('pay with empty orderInfo throws ArgumentError', () async {
    expect(
      () => platform.pay(orderInfo: ''),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => platform.pay(orderInfo: '   '),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('auth with empty authInfo throws ArgumentError', () async {
    expect(
      () => platform.auth(authInfo: ''),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => platform.auth(authInfo: '   '),
      throwsA(isA<ArgumentError>()),
    );
  });
}
