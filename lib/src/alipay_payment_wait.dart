import 'dart:async';

import 'package:alipay_payment/src/alipay_payment_platform_interface.dart';
import 'package:alipay_payment/src/models/alipay_environment.dart';
import 'package:alipay_payment/src/models/alipay_result.dart';

extension AlipayPaymentWait on AlipayPaymentPlatform {

  Future<AlipayResult> payAndWait({
    required String orderInfo,
    String? urlScheme,
    String? universalLink,
    bool showPayLoading = true,
    AlipayEnvironment? payEnv,
    bool dynamicLaunch = false,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    if (orderInfo.trim().isEmpty) {
      throw ArgumentError('orderInfo 不能为空');
    }
    final Future<AlipayResult> resultFuture = payResp().first;
    await pay(
      orderInfo: orderInfo,
      urlScheme: urlScheme,
      universalLink: universalLink,
      showPayLoading: showPayLoading,
      payEnv: payEnv,
      dynamicLaunch: dynamicLaunch,
    );
    return resultFuture.timeout(
      timeout,
      onTimeout: () => AlipayResult.unknown('支付超时'),
    );
  }


  Future<AlipayResult> authAndWait({
    required String authInfo,
    String? urlScheme,
    String? universalLink,
    bool showPayLoading = true,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    if (authInfo.trim().isEmpty) {
      throw ArgumentError('authInfo 不能为空');
    }
    final Future<AlipayResult> resultFuture = authResp().first;
    await auth(
      authInfo: authInfo,
      urlScheme: urlScheme,
      universalLink: universalLink,
      showPayLoading: showPayLoading,
    );
    return resultFuture.timeout(
      timeout,
      onTimeout: () => AlipayResult.unknown('授权超时'),
    );
  }
}
