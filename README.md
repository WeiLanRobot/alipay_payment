# alipay_payment

Flutter 支付宝支付插件，支持 iOS、Android 平台。

## 功能

- **支付**：发起支付宝 App 支付
- **授权（登录）**：支付宝账号授权，支持 `parseAuthResult()` 解析
- **沙箱环境**：iOS/Android 均支持 `AlipayEnvironment.sandbox`
- **检测安装**：`isAlipayInstalled()`
- **结果返回**：`payResp()` / `authResp()` 返回 Stream，支持多监听
- **客户端签名**：`unsafePay` / `unsafeAuth`（⚠️ 仅开发测试，生产请用服务端签名）
- **iOS utdid/noutdid**：可配置避免与阿里系 SDK 冲突

## 安装

```yaml
dependencies:
  alipay_payment: ^0.0.1

# 配置（可选）
alipay_payment:
  scheme: alipay${yourAppId}  # iOS 必填，支付完成后跳回 App
  ios: noutdid  # 可选，默认 utdid；noutdid 可避免与阿里系其他 SDK 的 UTDID 冲突
```

**iOS utdid/noutdid**：在 `ios/Podfile` 顶部添加（供 podspec 读取 pubspec 配置）：
```ruby
ENV['ALIPAY_PAYMENT_APP_ROOT'] ||= File.dirname(File.dirname(File.expand_path(__FILE__)))
```

## 使用

```dart
import 'package:alipay_payment/alipay_payment.dart';

// 设置环境（测试/正式）
await AlipayPaymentPlatform.instance.setEnvironment(AlipayEnvironment.sandbox);

// 检查是否安装支付宝
final installed = await AlipayPaymentPlatform.instance.isAlipayInstalled();

// 先监听结果流，再发起支付/授权
AlipayPaymentPlatform.instance.payResp().listen((result) {
  if (result.isSuccess) {
    // 支付成功
  } else if (result.isCancel) {
    // 用户取消
  } else if (result.isFailure) {
    // 失败
  }
});
AlipayPaymentPlatform.instance.authResp().listen((result) { /* 同上 */ });

// 发起支付（会跳转支付宝 App，结果通过 payResp 返回）
await AlipayPaymentPlatform.instance.pay(
  orderInfo: orderInfoFromServer,
  urlScheme: 'alipay${yourAppId}',  // iOS URL Scheme
  universalLink: 'https://yourdomain.com/alipay',  // iOS Universal Links（可选）
  showPayLoading: true,  // 是否显示支付中 loading
  payEnv: AlipayEnvironment.sandbox,  // 本次支付环境（可选，不传则用 setEnvironment）
);

// 发起授权
await AlipayPaymentPlatform.instance.auth(
  authInfo: authInfoFromServer,
  urlScheme: 'alipay${yourAppId}',
  universalLink: 'https://yourdomain.com/alipay',
  showPayLoading: true,
);

// 客户端签名支付（与 alipay_kit unsafePay 一致，私钥仅用于开发测试）
await AlipayPaymentPlatform.instance.unsafePay(
  orderInfo: {
    'app_id': yourAppId,
    'biz_content': json.encode(bizContent),
    'charset': 'utf-8',
    'method': 'alipay.trade.app.pay',
    'timestamp': 'yyyy-MM-dd HH:mm:ss',
    'version': '1.0',
  },
  signType: AlipaySign.signTypeRsa2,
  privateKey: yourRsaPrivateKey,
  urlScheme: 'alipay${yourAppId}',
);

// 客户端签名授权（与 alipay_kit unsafeAuth 一致）
await AlipayPaymentPlatform.instance.unsafeAuth(
  appId: yourAppId,
  pid: yourPid,
  targetId: targetId,
  signType: AlipaySign.signTypeRsa2,
  privateKey: yourRsaPrivateKey,
  urlScheme: 'alipay${yourAppId}',
);
```

## 平台配置

### iOS

1. **pubspec 配置**（推荐）：在项目根目录 `pubspec.yaml` 添加：
```yaml
alipay_payment:
  scheme: alipay${yourAppId}
  ios: noutdid  # 可选
```
在 `ios/Podfile` 的 `post_install` 中调用 `alipay_setup.rb` 可自动写入 scheme（见 example）。

2. **或手动**在 `Info.plist` 中添加 URL Scheme：
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>alipay你的AppID</string>
    </array>
    <key>CFBundleURLName</key>
    <string>alipay</string>
  </dict>
</array>
```

2. 添加 `LSApplicationQueriesSchemes`（检测支付宝是否安装）：
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>alipay</string>
  <string>alipays</string>
</array>
```

3. **AlipaySDK**：将 `AlipaySDK.framework` 和 `AlipaySDK.bundle` 放入插件目录 `ios/Libraries/noutdid/` 或 `utdid/`（与 pubspec 的 `ios: noutdid` 对应）。详见 [AlipaySDK-iOS](https://opendocs.alipay.com/open/204/105296)

### Android

1. 在 `AndroidManifest.xml` 中已配置 `queries` 用于检测支付宝安装
2. **Android SDK**：二选一
   - **Maven**（默认）：无需配置，自动拉取 `com.alipay.sdk:alipaysdk-android:15.8.35`
   - **本地 AAR**：将 `alipaySdk-xxx.aar` 放入 `android/libs/` 后优先使用，详见 [支付宝 Android SDK](https://opendocs.alipay.com/open/204/105297)

## 结果状态码

| 状态码 | 含义     |
|--------|----------|
| 9000   | 成功     |
| 8000   | 处理中   |
| 6001   | 用户取消 |
| 6002   | 网络错误 |
| 4000   | 支付失败 |

## 测试与 Mock

业务代码只需导入 `package:alipay_payment/alipay_payment.dart` 使用 [AlipayPaymentPlatform.instance]。  
单元测试如需 mock 平台实现，实现 [AlipayPaymentPlatform] 并替换实例：

```dart
import 'package:alipay_payment/alipay_payment.dart';

// 实现 MockAlipayPaymentPlatform 继承 AlipayPaymentPlatform
// 测试前：AlipayPaymentPlatform.instance = mockPlatform;
// 测试后：AlipayPaymentPlatform.instance = 原实例;
```

## 注意事项

1. **安全性**：生产环境强烈建议由服务端生成并签名订单，使用 `pay`/`auth` 传入已签名字符串。`unsafePay`/`unsafeAuth` 仅在客户端签名，私钥存在泄露风险，仅适合开发测试或与 alipay_kit 平替迁移
2. **iOS URL Scheme**：格式通常为 `alipay${AppID}`，不能为纯数字
3. **测试**：开发阶段使用 `AlipayEnvironment.sandbox` 沙箱环境
