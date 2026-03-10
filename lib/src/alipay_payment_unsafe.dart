import 'package:alipay_payment/src/alipay_payment_platform_interface.dart';
import 'package:alipay_payment/src/models/alipay_environment.dart';
import 'package:alipay_payment/src/sign/alipay_sign.dart';

/// 客户端签名扩展，与 alipay_kit unsafePay/unsafeAuth 一致
///
/// ⚠️ **安全警告**：私钥存放在客户端存在泄露风险，仅适合开发测试或与 alipay_kit 迁移。
/// 生产环境强烈建议由服务端生成并签名订单，使用 [pay]/[auth] 传入已签名字符串。
extension AlipayPaymentUnsafe on AlipayPaymentPlatform {
  /// 客户端签名支付
  ///
  /// ⚠️ 私钥仅用于开发测试，生产环境请使用服务端签名。
  Future<void> unsafePay({
    required Map<String, dynamic> orderInfo,
    String signType = AlipaySign.signTypeRsa2,
    required String privateKey,
    bool isShowLoading = true,
    String? urlScheme,
    String? universalLink,
    AlipayEnvironment? payEnv,
    bool dynamicLaunch = false,
  }) async {
    final String orderInfoStr = AlipaySign.buildOrderInfo(
      orderInfo: orderInfo,
      signType: signType,
      privateKey: privateKey,
    );
    return pay(
      orderInfo: orderInfoStr,
      urlScheme: urlScheme,
      universalLink: universalLink,
      showPayLoading: isShowLoading,
      payEnv: payEnv,
      dynamicLaunch: dynamicLaunch,
    );
  }

  /// 客户端签名授权
  ///
  /// ⚠️ 私钥仅用于开发测试，生产环境请使用服务端签名。
  Future<void> unsafeAuth({
    required String appId,
    required String pid,
    required String targetId,
    String authType = AlipaySign.authTypeAuthAccount,
    String signType = AlipaySign.signTypeRsa2,
    required String privateKey,
    bool isShowLoading = true,
    String? urlScheme,
    String? universalLink,
  }) async {
    final String authInfoStr = AlipaySign.buildAuthInfo(
      appId: appId,
      pid: pid,
      targetId: targetId,
      authType: authType,
      signType: signType,
      privateKey: privateKey,
    );
    return auth(
      authInfo: authInfoStr,
      urlScheme: urlScheme,
      universalLink: universalLink,
      showPayLoading: isShowLoading,
    );
  }
}
