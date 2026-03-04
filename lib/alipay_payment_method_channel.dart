import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'alipay_payment_platform_interface.dart';

/// An implementation of [AlipayPaymentPlatform] that uses method channels.
class MethodChannelAlipayPayment extends AlipayPaymentPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('alipay_payment');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
