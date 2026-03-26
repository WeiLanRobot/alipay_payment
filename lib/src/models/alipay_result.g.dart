// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alipay_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlipayResult _$AlipayResultFromJson(Map<String, dynamic> json) => AlipayResult(
  resultStatus: json['resultStatus'] as String,
  result: json['result'] as String?,
  memo: json['memo'] as String?,
);

Map<String, dynamic> _$AlipayResultToJson(AlipayResult instance) =>
    <String, dynamic>{
      'resultStatus': instance.resultStatus,
      'result': instance.result,
      'memo': instance.memo,
    };
