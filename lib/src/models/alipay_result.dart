/// 支付宝支付/授权结果
///
/// 支付和授权都会跳转支付宝 App，完成后返回此结果。
/// 状态码说明：
/// - 9000: 成功
/// - 8000: 正在处理中
/// - 4000: 订单支付失败
/// - 5000: 重复请求
/// - 6001: 用户中途取消
/// - 6002: 网络连接出错
/// - 6004: 支付结果未知
library;

import 'package:alipay_payment/src/models/alipay_auth_result.dart';
import 'package:json_annotation/json_annotation.dart';

part 'alipay_result.g.dart';

@JsonSerializable()
class AlipayResult {
  const AlipayResult({
    required this.resultStatus,
    this.result,
    this.memo,
  });

  factory AlipayResult.fromJson(Map<String, dynamic> json) =>
      _$AlipayResultFromJson(json);

  factory AlipayResult.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return AlipayResult.unknown('无返回数据');
    }
    String resultStatus = map['resultStatus']?.toString().trim() ?? '';
    resultStatus = resultStatus.replaceAll(RegExp(r'^\{|\}$'), '').trim();
    if (resultStatus.isEmpty) {
      return AlipayResult.unknown('结果格式异常');
    }
    return AlipayResult.fromJson(<String, dynamic>{
      'resultStatus': resultStatus,
      'result': map['result']?.toString(),
      'memo': map['memo']?.toString(),
    });
  }

  factory AlipayResult.networkError(String message) => AlipayResult(
        resultStatus: '6002',
        memo: message,
      );

  factory AlipayResult.cancelled() => const AlipayResult(
        resultStatus: '6001',
        memo: '用户取消',
      );

  factory AlipayResult.unknown(String message) => AlipayResult(
        resultStatus: '6004',
        memo: message,
      );

  final String resultStatus;

  final String? result;

  final String? memo;

  Map<String, dynamic> toJson() => _$AlipayResultToJson(this);

  Map<String, dynamic> toMap() => toJson();

  /// 状态码 int 形式（与 alipay_kit 的 resultStatus 兼容）
  int? get resultStatusCode => int.tryParse(resultStatus);

  bool get isSuccess => resultStatus == '9000';

  bool get isCancel => resultStatus == '6001';

  bool get isProcessing => resultStatus == '8000';

  bool get isFailure =>
      resultStatus != '9000' &&
      resultStatus != '8000' &&
      resultStatus.isNotEmpty;

  /// 解析授权结果（成功时 result 为 success=true&auth_code=xxx&... 格式）
  AlipayAuthResult? parseAuthResult() {
    if (isSuccess && result != null && result!.isNotEmpty) {
      final Map<String, String> params = <String, String>{};
      for (final String pair in result!.split('&')) {
        final int idx = pair.indexOf('=');
        if (idx > 0) {
          params[Uri.decodeComponent(pair.substring(0, idx))] =
              Uri.decodeComponent(pair.substring(idx + 1));
        }
      }
      return AlipayAuthResult.fromJson(params);
    }
    return null;
  }

  @override
  String toString() =>
      'AlipayResult(resultStatus: $resultStatus, result: $result, memo: $memo)';
}
