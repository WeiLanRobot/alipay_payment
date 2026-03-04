import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'alipay_payment_method_channel.dart';

abstract class AlipayPaymentPlatform extends PlatformInterface {
  /// Constructs a AlipayPaymentPlatform.
  AlipayPaymentPlatform() : super(token: _token);

  static final Object _token = Object();

  static AlipayPaymentPlatform _instance = MethodChannelAlipayPayment();

  /// The default instance of [AlipayPaymentPlatform] to use.
  ///
  /// Defaults to [MethodChannelAlipayPayment].
  static AlipayPaymentPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AlipayPaymentPlatform] when
  /// they register themselves.
  static set instance(AlipayPaymentPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
