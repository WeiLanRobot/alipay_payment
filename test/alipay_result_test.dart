import 'package:alipay_payment/alipay_payment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlipayResult', () {
    test('resultStatusCode returns int for numeric resultStatus', () {
      expect(
        const AlipayResult(resultStatus: '9000').resultStatusCode,
        9000,
      );
      expect(
        const AlipayResult(resultStatus: '6001').resultStatusCode,
        6001,
      );
      expect(
        const AlipayResult(resultStatus: '8000').resultStatusCode,
        8000,
      );
    });

    test('resultStatusCode returns null for non-numeric resultStatus', () {
      expect(
        const AlipayResult(resultStatus: '').resultStatusCode,
        isNull,
      );
      expect(
        const AlipayResult(resultStatus: 'unknown').resultStatusCode,
        isNull,
      );
    });

    test('parseAuthResult returns null when not success', () {
      const AlipayResult result = AlipayResult(resultStatus: '6001', memo: '取消');
      expect(result.parseAuthResult(), isNull);
    });

    test('parseAuthResult returns null when result is empty', () {
      const AlipayResult result = AlipayResult(resultStatus: '9000', result: null);
      expect(result.parseAuthResult(), isNull);
    });

    test('parseAuthResult parses auth result string', () {
      final AlipayResult result = AlipayResult(
        resultStatus: '9000',
        result: 'success=true&auth_code=xxx123&result_code=200&user_id=2088xxx',
      );
      final AlipayAuthResult? authResult = result.parseAuthResult();
      expect(authResult, isNotNull);
      expect(authResult!.success, true);
      expect(authResult.authCode, 'xxx123');
      expect(authResult.resultCode, 200);
      expect(authResult.userId, '2088xxx');
    });

    test('parseAuthResult handles URL-encoded values', () {
      final AlipayResult result = AlipayResult(
        resultStatus: '9000',
        result: 'success=true&auth_code=xxx%26yyy&result_code=200',
      );
      final AlipayAuthResult? authResult = result.parseAuthResult();
      expect(authResult, isNotNull);
      expect(authResult!.authCode, 'xxx&yyy');
    });
  });

  group('AlipayAuthResult', () {
    test('fromJson parses success=true', () {
      final AlipayAuthResult r = AlipayAuthResult.fromJson(<String, String>{
        'success': 'true',
        'auth_code': 'code123',
        'result_code': '200',
        'user_id': 'uid456',
      });
      expect(r.success, true);
      expect(r.authCode, 'code123');
      expect(r.resultCode, 200);
      expect(r.userId, 'uid456');
    });

    test('fromJson parses success=false', () {
      final AlipayAuthResult r = AlipayAuthResult.fromJson(<String, String>{
        'success': 'false',
        'result_code': '202',
      });
      expect(r.success, false);
      expect(r.resultCode, 202);
    });
  });
}
