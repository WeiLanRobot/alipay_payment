# alipay_payment 源码解读

> 本文档对本项目 alipay_payment 进行深度解析，包含架构、实现细节及优缺点分析，适合技术分享与内部学习。

---

## 一、项目概览

### 1.1 基本信息

- **架构**：单包（非 Federated）
- **版本**：0.0.1
- **SDK**：Dart ^3.8.0，Flutter >=3.3.0
- **功能**：Flutter 支付宝支付、授权，支持 iOS、Android

### 1.2 架构设计：单包

```
alipay_payment/
├── lib/                          # Dart 层
│   ├── alipay_payment.dart       # 入口
│   └── src/
│       ├── alipay_payment_platform_interface.dart
│       ├── alipay_payment_method_channel.dart
│       ├── alipay_payment_unsafe.dart    # 客户端签名扩展
│       ├── models/
│       │   ├── alipay_environment.dart
│       │   └── alipay_result.dart
│       └── sign/
│           ├── alipay_sign.dart
│           └── rsa_signer.dart
├── android/                      # Android 原生
└── ios/                          # iOS 原生
```

---

## 二、核心模块解读

### 2.1 平台接口：AlipayPaymentPlatform

**文件**：`lib/src/alipay_payment_platform_interface.dart`

```dart
abstract class AlipayPaymentPlatform extends PlatformInterface {
  static AlipayPaymentPlatform _instance = MethodChannelAlipayPayment();
  static AlipayPaymentPlatform get instance => _instance;
  static set instance(AlipayPaymentPlatform instance) { ... }

  Future<String?> getPlatformVersion();
  Future<void> setEnvironment(AlipayEnvironment environment);
  Future<void> pay({ required String orderInfo, String? urlScheme, String? universalLink, ... });
  Future<void> auth({ required String authInfo, String? urlScheme, String? universalLink, ... });
  Stream<AlipayResult> payResp();
  Stream<AlipayResult> authResp();
  Future<bool> isAlipayInstalled();
}
```

**设计要点**：

- 接口**只定义契约**，不包含业务实现
- `pay`/`auth` 支持 `urlScheme`、`universalLink`，iOS 配置更完整
- `setEnvironment` 双端支持（Android 用 SharedPreferences，iOS 用 UserDefaults）

---

### 2.2 MethodChannel 实现：MethodChannelAlipayPayment

**文件**：`lib/src/alipay_payment_method_channel.dart`

#### 2.2.1 Channel 配置

```dart
static const String channelName = 'com.weilan.alipay_payment';
MethodChannel get methodChannel => const MethodChannel(channelName);
```

- 使用**包名风格** Channel 名，降低与其他插件冲突概率
- `channelName` 为 `@visibleForTesting` 静态常量，便于测试 Mock

#### 2.2.2 延迟注册 Handler

```dart
bool _handlerSetup = false;

void _ensureMethodCallHandler() {
  if (_handlerSetup) return;
  _handlerSetup = true;
  methodChannel.setMethodCallHandler((MethodCall call) async {
    switch (call.method) {
      case 'onPayResp': ...
      case 'onAuthResp': ...
    }
  });
}
```

- **首次调用 pay/auth 时才注册** Handler，避免过早占用 Channel
- 避免与测试中的 `setMockMethodCallHandler` 冲突

#### 2.2.3 双路径结果处理

```dart
// 路径 1：原生异步回调 onPayResp
_ensureMethodCallHandler() 后，原生 invokeMethod("onPayResp", map)

// 路径 2：原生同步返回（如未安装、立即错误）
final dynamic result = await methodChannel.invokeMethod('pay', ...);
if (result is Map) {
  _payRespStreamController.add(AlipayResult.fromMap(result));
}
```

- 支持**同步错误**（如未安装）和**异步回调**两种结果来源
- 统一通过 `payResp()` Stream 输出

#### 2.2.4 异常处理

```dart
} on PlatformException catch (e) {
  _payRespStreamController.add(AlipayResult.networkError(e.message ?? e.code));
}
```

- 捕获 `PlatformException`，转为 `AlipayResult.networkError`，不直接抛异常

---

### 2.3 数据模型：AlipayResult

**文件**：`lib/src/models/alipay_result.dart`

```dart
@JsonSerializable()
class AlipayResult {
  final String resultStatus;   // 字符串，兼容原生 int/string
  final String? result;
  final String? memo;

  factory AlipayResult.fromMap(Map<dynamic, dynamic>? map);  // 容错解析
  factory AlipayResult.networkError(String message);
  factory AlipayResult.cancelled();
  factory AlipayResult.unknown(String message);

  bool get isSuccess => resultStatus == '9000';
  bool get isCancel => resultStatus == '6001';
  bool get isProcessing => resultStatus == '8000';
  bool get isFailure => ...;
}
```

**设计要点**：

- `resultStatus` 用 **String**，兼容 Android `int` 与 iOS 返回
- `fromMap` 做空值、类型转换等容错
- 提供 `networkError`、`cancelled`、`unknown` 等工厂方法
- `isSuccess`、`isCancel`、`isFailure` 等便捷 getter

---

### 2.4 客户端签名扩展：AlipayPaymentUnsafe

**文件**：`lib/src/alipay_payment_unsafe.dart`

```dart
extension AlipayPaymentUnsafe on AlipayPaymentPlatform {
  Future<void> unsafePay({ required Map<String, dynamic> orderInfo, ... });
  Future<void> unsafeAuth({ required String appId, required String pid, ... });
}
```

- 使用 **Extension**，不污染平台接口
- Mock 只需实现 `pay`/`auth`，无需实现 `unsafePay`/`unsafeAuth`
- 与 alipay_kit 签名逻辑一致，便于迁移

---

### 2.5 签名模块：AlipaySign + RsaSigner

**文件**：`lib/src/sign/alipay_sign.dart`、`lib/src/sign/rsa_signer.dart`

- `AlipaySign.buildOrderInfo()` / `buildAuthInfo()`：参数排序、拼接、签名
- `RsaSigner`：PKCS#1 / PKCS#8 解析，SHA1 / SHA256 签名
- 依赖 `pointycastle`，与 alipay_kit 一致

---

### 2.6 Android 实现

**文件**：`android/.../AlipayPaymentPlugin.kt`

- 实现 `ActivityAware`，获取 `Activity` 供 `PayTask`/`AuthTask` 使用
- 支付/授权在**子线程**执行，结果通过 `Handler` 回主线程再 `invokeMethod`
- 支持 `setEnvironment`（SharedPreferences）
- 依赖 `com.alipay.sdk:alipaysdk-android:15.8.35`

---

### 2.7 iOS 实现

**文件**：`ios/Classes/AlipayPaymentPlugin.swift`

- 实现 `FlutterApplicationLifeCycleDelegate`，处理 URL 回调和 Universal Link
- 支持 `payEnv` 单次支付环境覆盖
- 支持 `universalLink` 参数
- utdid/noutdid 通过 podspec 读取 pubspec 配置

---

## 三、优点

### 3.1 架构与职责

| 优点 | 说明 |
|------|------|
| **接口纯净** | `AlipayPaymentPlatform` 只定义 pay/auth 等核心方法，无业务逻辑 |
| **扩展分离** | `unsafePay`/`unsafeAuth` 用 Extension，Mock 简单，职责清晰 |
| **单包结构** | 一个包包含双端实现，依赖简单，无 Federated 心智负担 |

### 3.2 健壮性与兼容

| 优点 | 说明 |
|------|------|
| **结果容错** | `AlipayResult.fromMap` 处理 null、空 Map、int/string 混用 |
| **双路径结果** | 同步错误（未安装等）和异步回调统一走 Stream |
| **异常封装** | `PlatformException` 转为 `AlipayResult.networkError`，不直接抛给业务 |
| **String resultStatus** | 兼容 Android int 与 iOS 返回，避免类型转换问题 |

### 3.3 可测试性

| 优点 | 说明 |
|------|------|
| **channelName 可测** | `@visibleForTesting` 静态常量，测试可复用 |
| **延迟 Handler** | 首次 pay/auth 才注册，避免与 Mock 冲突 |
| **Extension Mock 友好** | Mock 只需实现 pay/auth，自动获得 unsafePay/unsafeAuth |

### 3.4 功能与配置

| 优点 | 说明 |
|------|------|
| **iOS 配置完整** | 支持 urlScheme、universalLink、payEnv |
| **双端环境切换** | `setEnvironment` 在 Android、iOS 均支持 |
| **客户端签名内置** | 主包提供 unsafePay/unsafeAuth，无需从 example 拷贝 |
| **Channel 名唯一** | `com.weilan.alipay_payment` 降低与其他插件冲突 |

### 3.5 工程实践

| 优点 | 说明 |
|------|------|
| **类型安全** | 使用 `Map<String, Object?>`、显式类型转换 |
| **严格 Lint** | 遵循 `flutter_lints`、`strict-casts` 等规则 |
| **build_runner** | `AlipayResult` 使用 `@JsonSerializable` 生成代码 |

---

## 四、缺点与改进点

### 4.1 架构与依赖

| 缺点 | 说明 | 改进建议 |
|------|------|----------|
| **单包体积** | 同时包含 Android、iOS 实现，无法按平台裁剪 | 若需极致体积，可考虑 Federated 拆分 |
| **pointycastle 依赖** | 客户端签名引入加解密库，增加包体积 | 可拆成 `alipay_payment`（核心）+ `alipay_payment_unsafe`（可选） |

### 4.2 实现细节

| 缺点 | 说明 | 改进建议 |
|------|------|----------|
| **Handler 单次注册** | `_handlerSetup` 为 true 后不再更新，若测试中多次替换 instance 可能残留 | 在 `dispose` 或替换 instance 时清理 Handler |
| **Stream 无 dispose** | `StreamController` 未在插件销毁时关闭 | 若插件有明确生命周期，可增加 `dispose` 关闭流 |
| **Android 包名固定** | `com.weilan.alipay_payment` 写死，不适合多团队复用 | 可考虑通过 pubspec 或构建参数配置 |

### 4.3 功能与文档

| 缺点 | 说明 | 改进建议 |
|------|------|----------|
| **iOS SDK 手动放置** | 需手动将 AlipaySDK 放入 Libraries/ | 在 README 中强调步骤，或提供脚本辅助 |
| **ProGuard 需手动配置** | Android 混淆规则需用户自行添加 | 在 README 中给出完整规则，或通过 consumer-rules 自动合并 |
| **沙箱环境说明不足** | 沙箱在服务端配置，客户端 `setEnvironment` 作用未详细说明 | 在文档中补充客户端/服务端职责划分 |

### 4.4 与 alipay_kit 的差异

| 差异点 | alipay_payment | alipay_kit | 影响 |
|--------|----------------|------------|------|
| **resultStatus 类型** | String | int | 迁移时需注意类型转换 |
| **客户端签名位置** | 主包扩展 | example 中 | alipay_payment 开箱即用，但增加依赖 |
| **iOS 默认包含** | 是 | 否（需单独依赖） | alipay_payment 更简单，但无法按需排除 |

---

## 五、优缺点总结

### 5.1 优点汇总

1. **架构清晰**：接口与实现分离，Extension 扩展，Mock 简单
2. **健壮性好**：结果容错、双路径处理、异常封装完善
3. **可测试性强**：channelName 可测、延迟 Handler、Extension 友好
4. **功能完整**：双端环境、Universal Link、客户端签名内置
5. **工程规范**：类型安全、Lint 严格、代码生成规范

### 5.2 缺点汇总

1. **单包体积**：无法按平台裁剪，且 pointycastle 增加体积
2. **生命周期**：Stream、Handler 未做完整 dispose 设计
3. **配置成本**：iOS SDK 手动放置、ProGuard 需用户配置
4. **包名固定**：`com.weilan` 不利于多团队直接复用

### 5.3 适用场景

- **适合**：需要双端支付、希望开箱即用、重视可测试性的项目
- **需权衡**：对包体积极度敏感、仅单端使用的场景

---

## 六、与 alipay_kit 对比

| 维度 | alipay_payment | alipay_kit |
|------|----------------|------------|
| 架构 | 单包 | Federated（3 包） |
| 接口职责 | 纯接口，Extension 扩展 | 接口 + 部分逻辑在 example |
| 客户端签名 | 主包内置 | example 中，需拷贝 |
| 结果类型 | AlipayResult（String） | AlipayResp（int） |
| 结果容错 | fromMap 容错强 | 依赖原生返回格式 |
| 双路径结果 | 支持同步错误 + 异步回调 | 主要依赖异步回调 |
| Mock 成本 | 低（Extension 自动生效） | 需实现 unsafePay/unsafeAuth |
| 包体积 | 单包较大 | 可按平台裁剪 |
| iOS 配置 | 需手动放 SDK | 集成更自动化 |

---

## 七、参考

- [alipay_kit 源码解读](./alipay_kit_source_analysis.md)
- [支付宝 App 支付](https://docs.open.alipay.com/204/105051/)
- [支付宝登录](https://docs.open.alipay.com/218/105329/)
