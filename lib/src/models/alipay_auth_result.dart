/// 支付宝授权解析结果
///
/// 从 [AlipayResult.parseAuthResult] 解析得到。
library;

/// 授权成功时 result 中的结构化数据
class AlipayAuthResult {
  const AlipayAuthResult({
    required this.success,
    this.resultCode,
    this.authCode,
    this.userId,
  });

  /// 是否成功
  final bool success;

  /// 200 业务处理成功，会返回 authCode
  /// 1005 账户已冻结
  /// 202 系统异常
  final int? resultCode;

  /// 授权码，用于后续登录
  final String? authCode;

  /// 支付宝用户 ID
  final String? userId;

  /// 从 query 格式的 Map 解析
  factory AlipayAuthResult.fromJson(Map<String, String> json) {
    final String? successStr = json['success'];
    final bool success = successStr?.toLowerCase() == 'true';

    final String? resultCodeStr = json['result_code'];
    final int? resultCode = resultCodeStr != null ? int.tryParse(resultCodeStr) : null;

    return AlipayAuthResult(
      success: success,
      resultCode: resultCode,
      authCode: json['auth_code'],
      userId: json['user_id'],
    );
  }

  @override
  String toString() =>
      'AlipayAuthResult(success: $success, resultCode: $resultCode, authCode: $authCode, userId: $userId)';
}
