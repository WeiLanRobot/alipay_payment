import 'dart:convert';

import 'package:alipay_payment/src/sign/rsa_signer.dart';

/// 支付宝客户端签名，与 alipay_kit 逻辑一致
class AlipaySign {
  AlipaySign._();

  /// 签名类型常量
  static const String signTypeRsa = 'RSA';
  static const String signTypeRsa2 = 'RSA2';

  /// 授权类型常量
  static const String authTypeAuthAccount = 'AUTHACCOUNT';
  static const String authTypeLogin = 'LOGIN';

  /// 构建支付 orderInfo 字符串（客户端签名）
  static String buildOrderInfo({
    required Map<String, dynamic> orderInfo,
    String signType = signTypeRsa2,
    required String privateKey,
  }) {
    final String? charset = orderInfo['charset'] as String?;
    final Encoding encoding = Encoding.getByName(charset ?? 'utf-8') ?? utf8;
    final Map<String, dynamic> clone = Map<String, dynamic>.from(orderInfo)
      ..['sign_type'] = signType;
    final String param = _param(clone, encoding);
    final String sign = _sign(clone, signType, privateKey);
    return '$param&sign=${Uri.encodeQueryComponent(sign, encoding: encoding)}';
  }

  /// 构建授权 authInfo 字符串（客户端签名）
  static String buildAuthInfo({
    required String appId,
    required String pid,
    required String targetId,
    String authType = authTypeAuthAccount,
    String signType = signTypeRsa2,
    required String privateKey,
  }) {
    assert(
      authType == authTypeAuthAccount || authType == authTypeLogin,
      'authType must be AUTHACCOUNT or LOGIN',
    );
    final Map<String, String> authInfo = <String, String>{
      'apiname': 'com.alipay.account.auth',
      'method': 'alipay.open.auth.sdk.code.get',
      'app_id': appId,
      'app_name': 'mc',
      'biz_type': 'openservice',
      'pid': pid,
      'product_id': 'APP_FAST_LOGIN',
      'scope': 'kuaijie',
      'target_id': targetId,
      'auth_type': authType,
      'sign_type': signType,
    };
    const Encoding encoding = utf8;
    final String param = _param(authInfo, encoding);
    final String sign = _sign(authInfo, signType, privateKey);
    return '$param&sign=${Uri.encodeQueryComponent(sign, encoding: encoding)}';
  }

  static String _param(Map<String, dynamic> map, Encoding encoding) {
    return map.entries
        .map((MapEntry<String, dynamic> e) =>
            '${e.key}=${Uri.encodeQueryComponent('${e.value}', encoding: encoding)}')
        .join('&');
  }

  static String _sign(Map<String, dynamic> map, String signType, String privateKey) {
    final List<String> keys = map.keys.toList()..sort();
    final String content = keys.map((String e) => '$e=${map[e]}').join('&');
    final List<int> signBytes;
    if (signType == signTypeRsa) {
      signBytes = RsaSigner.sha1Rsa(privateKey).sign(utf8.encode(content));
    } else if (signType == signTypeRsa2) {
      signBytes = RsaSigner.sha256Rsa(privateKey).sign(utf8.encode(content));
    } else {
      throw UnsupportedError('Alipay sign_type($signType) is not supported!');
    }
    return base64.encode(signBytes);
  }
}
