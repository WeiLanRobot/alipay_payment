# alipay_kit 源码解读

> 本文档对 [RxReader/alipay_kit](https://github.com/RxReader/alipay_kit) 进行深度解析，适合技术分享与内部学习。

---

## 一、项目概览

### 1.1 基本信息

- **仓库**：https://github.com/RxReader/alipay_kit
- **版本**：6.0.0
- **SDK**：Dart >=3.0.2，Flutter >=3.3.0
- **功能**：Flutter 版支付宝登录、支付，基于原生 Android / iOS SDK

### 1.2 架构设计：Federated Plugin

alipay_kit 采用 **Federated Plugin（联邦插件）** 架构：

```
alipay_kit/                    # 主包（Dart 接口 + 默认实现）
├── alipay_kit_android/        # Android 平台实现
└── alipay_kit_ios/            # iOS 平台实现（可选）
```

**特点**：

- 主包默认只依赖 `alipay_kit_android`，不包含 iOS 支付
- 需要 iOS 支付时，显式添加 `alipay_kit_ios` 依赖
- 平台实现按需引入，减小包体积

---

## 二、项目结构

### 2.1 目录树

```
alipay_kit/
├── alipay_kit/                 # 主包
│   ├── lib/
│   │   ├── alipay_kit.dart      # 入口，导出
│   │   └── src/
│   │       ├── alipay_kit_platform_interface.dart   # 平台接口
│   │       ├── alipay_kit_method_channel.dart       # MethodChannel 实现
│   │       ├── constant.dart                        # 常量（环境枚举）
│   │       ├── model/
│   │       │   ├── resp.dart                       # 支付/授权结果
│   │       │   └── auth_result.dart                # 授权解析结果
│   │       └── json/                               # JSON 转换
│   └── pubspec.yaml
├── alipay_kit_android/         # Android 实现
│   ├── android/                # 原生代码
│   └── pubspec.yaml
├── alipay_kit_ios/             # iOS 实现
│   ├── ios/                    # 原生代码、podspec、Libraries
│   └── pubspec.yaml
└── example/
    └── lib/
        ├── main.dart           # 示例
        ├── unsafe_alipay_kit.dart   # 客户端签名扩展（重要）
        └── crypto/rsa.dart     # RSA 签名工具
```

### 2.2 依赖关系

```
alipay_kit (主包)
  ├── plugin_platform_interface: ^2.0.2
  ├── alipay_kit_android: ^6.0.0   # 默认
  ├── alipay_kit_ios: ^6.0.0       # 可选，注释掉
  └── json_annotation
```

---

## 三、核心模块解读

### 3.1 平台接口：AlipayKitPlatform

**文件**：`alipay_kit/lib/src/alipay_kit_platform_interface.dart`

```dart
abstract class AlipayKitPlatform extends PlatformInterface {
  static AlipayKitPlatform _instance = MethodChannelAlipayKit();
  static AlipayKitPlatform get instance => _instance;
  static set instance(AlipayKitPlatform instance) { ... }

  // 核心 API
  Stream payResp();           // 支付结果流
  Stream authResp();          // 授权结果流
  Future isInstalled();       // 检测是否安装支付宝
  Future setEnv({required AlipayEnv env});  // 设置环境（仅 Android）
  Future pay({required String orderInfo, bool dynamicLaunch, bool isShowLoading});
  Future auth({required String authInfo, bool isShowLoading});
}
```

**设计要点**：

1. **单例**：`instance` 提供全局实例，默认 `MethodChannelAlipayKit`
2. **可替换**：`instance` 可被 setter 替换，便于测试和 Mock
3. **PlatformInterface**：使用 `plugin_platform_interface` 做 token 校验，防止随意替换
4. **setEnv 仅 Android**：沙箱环境由 Android 原生实现，iOS 无此方法

---

### 3.2 MethodChannel 实现：MethodChannelAlipayKit

**文件**：`alipay_kit/lib/src/alipay_kit_method_channel.dart`

#### 3.2.1 Channel 配置

```dart
const MethodChannel('v7lin.github.io/alipay_kit')
  ..setMethodCallHandler(_handleMethod);
```

- Channel 名：`v7lin.github.io/alipay_kit`（域名风格，避免冲突）
- 使用 `setMethodCallHandler` 接收**原生主动回调**（`onPayResp`、`onAuthResp`）

#### 3.2.2 结果流：Broadcast Stream

```dart
final StreamController _payRespStreamController = StreamController.broadcast();
final StreamController _authRespStreamController = StreamController.broadcast();
```

- 使用 `broadcast()`，支持多监听
- 支付/授权为异步，结果通过 Stream 返回，而非 `pay`/`auth` 的 Future

#### 3.2.3 回调处理

```dart
Future _handleMethod(MethodCall call) async {
  switch (call.method) {
    case 'onPayResp':
      _payRespStreamController.add(AlipayResp.fromJson((call.arguments as Map).cast()));
      break;
    case 'onAuthResp':
      _authRespStreamController.add(AlipayResp.fromJson((call.arguments as Map).cast()));
      break;
  }
}
```

- 原生通过 `invokeMethod("onPayResp", map)` 回调
- Dart 解析为 `AlipayResp` 并加入 Stream

#### 3.2.4 调用原生

```dart
Future pay({required String orderInfo, bool dynamicLaunch = false, bool isShowLoading = true}) {
  return methodChannel.invokeMethod('pay', {
    'orderInfo': orderInfo,
    'dynamicLaunch': dynamicLaunch,
    'isShowLoading': isShowLoading,
  });
}
```

- `pay`/`auth` 只负责传参，不等待结果
- 结果通过 `payResp`/`authResp` 的 Stream 返回

---

### 3.3 数据模型

#### 3.3.1 AlipayResp（支付/授权通用结果）

**文件**：`alipay_kit/lib/src/model/resp.dart`

```dart
@JsonSerializable(explicitToJson: true)
class AlipayResp {
  final int? resultStatus;   // 状态码（9000 成功、6001 取消等）
  final String? result;     // 结果详情
  final String? memo;        // 提示信息

  bool get isSuccessful => resultStatus == 9000;
  bool get isCancelled => resultStatus == 6001;

  AlipayAuthResult? parseAuthResult() {
    if (isSuccessful && result?.isNotEmpty == true) {
      final Map params = Uri.parse('alipay://alipay?$result').queryParameters;
      return AlipayAuthResult.fromJson(params);
    }
    return null;
  }
}
```

- `resultStatus` 为 `int`，与支付宝文档一致
- `parseAuthResult()` 用 `Uri.parse` 解析 `result` 中的 query 字符串

#### 3.3.2 AlipayAuthResult（授权解析结果）

**文件**：`alipay_kit/lib/src/model/auth_result.dart`

```dart
@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class AlipayAuthResult {
  final bool success;
  final int? resultCode;   // 200 成功
  final String? authCode;  // 授权码
  final String? userId;
}
```

- 用于授权成功后的结构化解析

---

### 3.4 客户端签名：unsafePay / unsafeAuth

**文件**：`example/lib/unsafe_alipay_kit.dart`（在 example 中，不在主包）

这是 alipay_kit 的**重要扩展**：在 Dart 端完成 RSA 签名，再调用 `pay`/`auth`。

#### 3.4.1 扩展方式

```dart
extension UnsafeAlipayKitPlatform on AlipayKitPlatform {
  static const String SIGNTYPE_RSA = 'RSA';
  static const String SIGNTYPE_RSA2 = 'RSA2';
  static const String AUTHTYPE_AUTHACCOUNT = 'AUTHACCOUNT';
  static const String AUTHTYPE_LOGIN = 'LOGIN';

  Future unsafePay({ required Map orderInfo, String signType, required String privateKey, ... });
  Future unsafeAuth({ required String appId, required String pid, required String targetId, ... });
}
```

- 使用 **Extension** 扩展 `AlipayKitPlatform`，不修改主包
- 主包只提供 `pay(orderInfo: String)`，签名逻辑在 example 中

#### 3.4.2 签名流程（unsafePay）

1. **补全 sign_type**：`clone['sign_type'] = signType`
2. **生成参数字符串**：`_param(clone, encoding)` → `key1=value1&key2=value2`（value 做 URL 编码）
3. **生成待签名字符串**：按 key 排序，`key1=value1&key2=value2`（value 原始值，不编码）
4. **RSA 签名**：RSA2 用 SHA256，RSA 用 SHA1，再 Base64
5. **拼接**：`param + '&sign=' + Uri.encodeQueryComponent(sign)`
6. **调用**：`AlipayKitPlatform.instance.pay(orderInfo: 最终字符串)`

#### 3.4.3 签名流程（unsafeAuth）

- 固定 authInfo 结构：`apiname`、`method`、`app_id`、`pid`、`target_id` 等
- 签名逻辑与 `unsafePay` 相同

#### 3.4.4 RSA 签名工具

**文件**：`example/lib/crypto/rsa.dart`

- 使用 `pointycastle` 做 RSA 签名
- 支持 PKCS#1、PKCS#8 私钥
- `RsaSigner.sha1Rsa()` / `sha256Rsa()` 对应 RSA / RSA2

---

### 3.5 常量：AlipayEnv

**文件**：`alipay_kit/lib/src/constant.dart`

```dart
enum AlipayEnv {
  online,   // 正式环境
  sandbox,  // 沙箱环境
}
```

- 仅 Android 使用，用于 `setEnv`

---

## 四、平台实现

### 4.1 Android（alipay_kit_android）

- 通过 `default_package: alipay_kit_android` 注册
- 依赖 `com.alipay.sdk:alipaysdk-android`
- 混淆规则已内置
- 使用 `PayTask`、`AuthTask` 调用支付和授权

### 4.2 iOS（alipay_kit_ios）

- 可选依赖，需显式添加
- 使用 `alipay_kit_ios.podspec` 配置 AlipaySDK
- 支持 utdid / noutdid：`alipay_kit: ios: noutdid`
- `alipay_setup.rb` 从 pubspec 读取 scheme 并写入 Info.plist
- `Libraries/` 下放置 AlipaySDK.framework 和 AlipaySDK.bundle

---

## 五、调用流程

### 5.1 支付流程

```
Flutter                          Native
   |                               |
   | pay(orderInfo)                |
   |------------------------------>| PayTask.pay()
   |                               | (跳转支付宝 App)
   |                               |
   | payResp().listen()            |
   |<------------------------------| onPayResp(resultMap)
   |                               |
```

### 5.2 客户端签名流程（unsafePay）

```
Flutter
   |
   | 1. 构建 orderInfo Map
   | 2. 添加 sign_type
   | 3. 生成待签名字符串（排序、拼接）
   | 4. RSA 签名 + Base64
   | 5. 拼接 param&sign=...
   | 6. pay(orderInfo: 最终字符串)
   | 7. payResp().listen() 等待结果
```

---

## 六、设计亮点

### 6.1 Federated Plugin

- 平台实现按需引入，减小包体积
- iOS 支付可选，适合仅 Android 的场景

### 6.2 结果流 vs Future

- 支付/授权为异步，结果通过 Stream 返回
- 支持多监听，适合复杂 UI 场景

### 6.3 客户端签名放在 Example

- 主包不包含签名逻辑，保持接口简洁
- 签名在 example 中，用户可自行拷贝或封装
- 命名为 "unsafe" 提醒私钥风险

### 6.4 UTDID 可选

- iOS 支持 utdid / noutdid，避免与阿里系其他 SDK 冲突

---

## 七、与 alipay_payment 的差异

| 项目 | alipay_kit | alipay_payment |
|------|------------|----------------|
| 架构 | Federated（3 包） | 单包 |
| 结果类型 | AlipayResp（int resultStatus） | AlipayResult（String resultStatus） |
| 平台入口 | AlipayKitPlatform | AlipayPaymentPlatform |
| 检测安装 | isInstalled() | isAlipayInstalled() |
| 客户端签名 | 在 example 扩展中 | 在主包扩展中 |
| Channel 名 | v7lin.github.io/alipay_kit | com.weilan.alipay_payment |

---

## 八、参考链接

- [alipay_kit GitHub](https://github.com/RxReader/alipay_kit)
- [alipay_kit pub.dev](https://pub.dev/packages/alipay_kit)
- [支付宝 App 支付](https://docs.open.alipay.com/204/105051/)
- [支付宝登录](https://docs.open.alipay.com/218/105329/)
