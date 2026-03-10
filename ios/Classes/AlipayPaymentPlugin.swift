import Flutter
import UIKit
import AlipaySDK

public class AlipayPaymentPlugin: NSObject, FlutterPlugin, FlutterApplicationLifeCycleDelegate {
  private var channel: FlutterMethodChannel?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.weilan.alipay_payment",
      binaryMessenger: registrar.messenger()
    )
    let instance = AlipayPaymentPlugin()
    instance.channel = channel
    registrar.addApplicationDelegate(instance)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)

    case "setEnvironment":
      if let args = call.arguments as? [String: Any],
         let environment = args["environment"] as? String
      {
        UserDefaults.standard.set(environment, forKey: "alipay_environment")
        applyEnvironment(environment)
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGS", message: "缺少 environment 参数", details: nil))
      }

    case "pay":
      handlePay(call: call, result: result)

    case "auth":
      handleLogin(call: call, result: result)

    case "isAlipayInstalled":
      result(isAlipayInstalled())

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func applyEnvironment(_ env: String) {
    if env == "sandbox" {
      AlipaySDK.defaultService().setUrl("https://openapi-sandbox.dl.alipaydev.com/gateway.do")
    } else {
      AlipaySDK.defaultService().setUrl(nil)
    }
  }

  private func handlePay(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let orderInfo = args["orderInfo"] as? String
    else {
      result(FlutterError(code: "INVALID_ARGS", message: "缺少 orderInfo 参数", details: nil))
      return
    }
    let urlScheme = args["urlScheme"] as? String ?? "alipay"
    let universalLink = args["universalLink"] as? String
    let dynamicLaunch = args["dynamicLaunch"] as? Bool ?? false
    let payEnvIndex = args["payEnv"] as? Int

    if let idx = payEnvIndex, idx >= 0, idx <= 1 {
      let env = idx == 0 ? "production" : "sandbox"
      UserDefaults.standard.set(env, forKey: "alipay_environment")
      applyEnvironment(env)
    } else if let env = UserDefaults.standard.string(forKey: "alipay_environment") {
      applyEnvironment(env)
    }

    if !isAlipayInstalled() {
      result([
        "resultStatus": "6002",
        "result": nil,
        "memo": "未安装支付宝",
      ])
      return
    }

    let callback: (([AnyHashable: Any]?) -> Void) = { [weak self] resultDic in
      guard let self = self else { return }
      self.channel?.invokeMethod("onPayResp", arguments: self.toResultMap(resultDic))
    }

    if let link = universalLink, !link.isEmpty {
      AlipaySDK.defaultService().payOrder(
        orderInfo,
        fromScheme: urlScheme,
        fromUniversalLink: link,
        callback: callback
      )
    } else {
      AlipaySDK.defaultService().payOrder(
        orderInfo,
        fromScheme: urlScheme,
        callback: callback
      )
    }
    result(nil)
  }

  private func handleLogin(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let authInfo = args["authInfo"] as? String
    else {
      result(FlutterError(code: "INVALID_ARGS", message: "缺少 authInfo 参数", details: nil))
      return
    }
    let urlScheme = args["urlScheme"] as? String ?? "alipay"

    if !isAlipayInstalled() {
      result([
        "resultStatus": "6002",
        "result": nil,
        "memo": "未安装支付宝",
      ])
      return
    }

    AlipaySDK.defaultService().auth_V2(
      withInfo: authInfo,
      fromScheme: urlScheme,
      callback: { [weak self] resultDic in
        guard let self = self else { return }
        self.channel?.invokeMethod("onAuthResp", arguments: self.toResultMap(resultDic))
      }
    )
    result(nil)
  }

  private func toResultMap(_ dict: [AnyHashable: Any]?) -> [String: Any?]? {
    guard let d = dict else { return nil }
    return [
      "resultStatus": d["resultStatus"],
      "result": d["result"],
      "memo": d["memo"],
    ]
  }

  private func isAlipayInstalled() -> Bool {
    guard let url = URL(string: "alipay://") else { return false }
    return UIApplication.shared.canOpenURL(url)
  }

  public func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return handleOpenURL(url)
  }

  public func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([Any]) -> Void
  ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
      AlipaySDK.defaultService().handleOpenUniversalLink(
        userActivity,
        standbyCallback: { [weak self] (resultDic: [AnyHashable: Any]?) in
          guard let self = self else { return }
          self.channel?.invokeMethod("onPayResp", arguments: self.toResultMap(resultDic))
        }
      )
      return true
    }
    return false
  }

  private func handleOpenURL(_ url: URL) -> Bool {
    guard url.host == "safepay" else { return false }

    AlipaySDK.defaultService().processOrder(
      withPaymentResult: url,
      standbyCallback: { [weak self] (resultDic: [AnyHashable: Any]?) in
        guard let self = self else { return }
        self.channel?.invokeMethod("onPayResp", arguments: self.toResultMap(resultDic))
      }
    )

    AlipaySDK.defaultService().processAuth_V2Result(
      url,
      standbyCallback: { [weak self] (resultDic: [AnyHashable: Any]?) in
        guard let self = self else { return }
        self.channel?.invokeMethod("onAuthResp", arguments: self.toResultMap(resultDic))
      }
    )
    return true
  }
}
