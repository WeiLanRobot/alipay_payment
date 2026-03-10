import 'dart:async';

import 'package:alipay_payment/src/alipay_payment_platform_interface.dart';
import 'package:alipay_payment/src/models/alipay_environment.dart';
import 'package:alipay_payment/src/models/alipay_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MethodCall, MethodChannel, PlatformException;

class MethodChannelAlipayPayment extends AlipayPaymentPlatform {
  MethodChannelAlipayPayment() {
    _payRespStreamController = StreamController<AlipayResult>.broadcast();
    _authRespStreamController = StreamController<AlipayResult>.broadcast();
  }

  late final StreamController<AlipayResult> _payRespStreamController;
  late final StreamController<AlipayResult> _authRespStreamController;
  bool _handlerSetup = false;
  bool _disposed = false;

  @visibleForTesting
  static const String channelName = 'io.github.weilanwl.alipay_payment';

  MethodChannel get methodChannel => const MethodChannel(channelName);

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _payRespStreamController.close();
    _authRespStreamController.close();
    methodChannel.setMethodCallHandler(null);
    _handlerSetup = false;
  }

  void _ensureMethodCallHandler() {
    if (_handlerSetup || _disposed) {
      return;
    }
    _handlerSetup = true;
    methodChannel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'onPayResp':
          _payRespStreamController.add(
            AlipayResult.fromMap(call.arguments as Map<dynamic, dynamic>?),
          );
          return null;
        case 'onAuthResp':
          _authRespStreamController.add(
            AlipayResult.fromMap(call.arguments as Map<dynamic, dynamic>?),
          );
          return null;
        default:
          return null;
      }
    });
  }

  @override
  Future<String?> getPlatformVersion() async {
    final String? version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> setEnvironment(AlipayEnvironment environment) async {
    await methodChannel.invokeMethod<void>(
      'setEnvironment',
      <String, Object?>{'environment': environment.name},
    );
  }

  @override
  Future<void> pay({
    required String orderInfo,
    String? urlScheme,
    String? universalLink,
    bool showPayLoading = true,
    AlipayEnvironment? payEnv,
    bool dynamicLaunch = false,
  }) async {
    _ensureMethodCallHandler();
    try {
      final dynamic result = await methodChannel.invokeMethod<dynamic>(
        'pay',
        <String, Object?>{
          'orderInfo': orderInfo,
          'urlScheme': urlScheme,
          'universalLink': universalLink,
          'showPayLoading': showPayLoading,
          'payEnv': payEnv?.index,
          'dynamicLaunch': dynamicLaunch,
        },
      );

      if (result is Map) {
        _payRespStreamController.add(AlipayResult.fromMap(result));
      }
    } on PlatformException catch (e) {
      _payRespStreamController.add(AlipayResult.networkError(e.message ?? e.code));
    }
  }

  @override
  Future<void> auth({
    required String authInfo,
    String? urlScheme,
    String? universalLink,
    bool showPayLoading = true,
  }) async {
    _ensureMethodCallHandler();
    try {
      final dynamic result = await methodChannel.invokeMethod<dynamic>(
        'auth',
        <String, Object?>{
          'authInfo': authInfo,
          'urlScheme': urlScheme,
          'universalLink': universalLink,
          'showPayLoading': showPayLoading,
        },
      );
      if (result is Map) {
        _authRespStreamController.add(AlipayResult.fromMap(result));
      }
    } on PlatformException catch (e) {
      _authRespStreamController.add(AlipayResult.networkError(e.message ?? e.code));
    }
  }

  @override
  Stream<AlipayResult> payResp() => _payRespStreamController.stream;

  @override
  Stream<AlipayResult> authResp() => _authRespStreamController.stream;

  @override
  Future<bool> isAlipayInstalled() async {
    final bool? installed =
        await methodChannel.invokeMethod<bool>('isAlipayInstalled');
    return installed ?? false;
  }
}
