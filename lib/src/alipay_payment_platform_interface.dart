import 'package:alipay_payment/src/alipay_payment_method_channel.dart';
import 'package:alipay_payment/src/models/alipay_environment.dart';
import 'package:alipay_payment/src/models/alipay_result.dart';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class AlipayPaymentPlatform extends PlatformInterface {
  AlipayPaymentPlatform() : super(token: _token);

  static final Object _token = Object();

  static AlipayPaymentPlatform _instance = MethodChannelAlipayPayment();

  static AlipayPaymentPlatform get instance => _instance;

  static set instance(AlipayPaymentPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance.dispose();
    _instance = instance;
  }

  /// 释放资源（Stream、Handler 等），替换 instance 前会自动调用
  void dispose() {}

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> setEnvironment(AlipayEnvironment environment) {
    throw UnimplementedError('setEnvironment() has not been implemented.');
  }

  Future<void> pay({
    required String orderInfo,
    String? urlScheme,
    String? universalLink,
    bool showPayLoading = true,
    AlipayEnvironment? payEnv,
    bool dynamicLaunch = false,
  }) {
    throw UnimplementedError('pay() has not been implemented.');
  }

  Future<void> auth({
    required String authInfo,
    String? urlScheme,
    String? universalLink,
    bool showPayLoading = true,
  }) {
    throw UnimplementedError('auth() has not been implemented.');
  }

  Stream<AlipayResult> payResp() {
    throw UnimplementedError('payResp() has not been implemented.');
  }

  Stream<AlipayResult> authResp() {
    throw UnimplementedError('authResp() has not been implemented.');
  }

  Future<bool> isAlipayInstalled() {
    throw UnimplementedError('isAlipayInstalled() has not been implemented.');
  }
}
