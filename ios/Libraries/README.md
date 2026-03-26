# AlipaySDK Libraries

## 放置 SDK

将 AlipaySDK.framework 和 AlipaySDK.bundle 放入 `noutdid/` 或 `utdid/`：

- **utdid**：默认，标准 AlipaySDK
- **noutdid**：无 UTDID，避免与阿里系其他 SDK 冲突（pubspec: `alipay_payment.ios: noutdid`）

从 [支付宝开放平台](https://opendocs.alipay.com/open/204/105296) 获取 SDK。

## Info.plist

**推荐**：在 `pubspec.yaml` 配置 `alipay_payment.scheme`，`pod install` 时 podspec 会生成 Swift 配置并运行脚本：用 **xcodeproj** 定位主工程的 Info.plist，**仅**把 `CFBundleURLTypes` 里 **`CFBundleURLName` 为 `alipay`** 的那一项里，`CFBundleURLSchemes` 的首个 scheme 改成与 pubspec 一致；**不会**新建 URL Type，**不会**自动改 `LSApplicationQueriesSchemes`（你已有 `<string>alipay</string>` 即可用于 `canOpenURL`；若官方文档要求再补 `alipays`，请自行在 Xcode 里加）。

---

### 何时需要手动配置

- 无法或不想依赖 `pod install` 时的脚本（例如 CI 未跑完整、先改 plist 再装依赖等）。
- 首次集成时 Info.plist 里**还没有**「Identifier 为 `alipay`」的 URL Type：`alipay_setup.rb` **只会替换**已有块，不会自动插入；此时需先在 Xcode / plist 中**手动添加下面结构**，之后再跑 `pod install` 时脚本才能把 scheme 与 `pubspec.yaml` 对齐。

---

### 手动添加步骤（与自动脚本一致）

1. **与 Dart / 原生约定一致**  
   `pubspec.yaml` 里 `alipay_payment.scheme` 的值（例如 `alipay2021000000000000`）必须与 Info.plist 里该 URL Type 的 scheme **字符串完全一致**。插件在编译期从 pubspec 注入 `AlipayPaymentConfig.scheme`，支付完成回调依赖同一字符串。

2. **用 Xcode 添加 URL Types（推荐）**  
   - 打开 `ios/Runner.xcworkspace`，选中 **Runner** Target → **Info**。  
   - 展开 **URL Types**，点击 **+**。  
   - **Identifier**：填 `alipay`（对应 plist 中的 `CFBundleURLName`，**必须为 `alipay`**，插件脚本只识别这一项）。  
   - **URL Schemes**：填与 `alipay_payment.scheme` 相同的值（通常为 `alipay` + 支付宝 AppID，不能为纯数字）。  
   - 若工程使用多个 Info.plist（多配置），对每个实际参与打包的 plist 重复检查。

3. **或直接编辑 Info.plist（XML）**  
   在 `CFBundleURLTypes` 的 `<array>` 中增加（或合并进已有数组）如下字典；**注意键顺序可与示例不同，但 `CFBundleURLName` 必须为 `alipay`**：

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

   将 `alipay你的AppID` 换成与 `pubspec.yaml` 中 `scheme` **完全一致** 的字符串。

4. **LSApplicationQueriesSchemes（检测是否安装支付宝）**  
   至少包含 `alipay`，否则 `canOpenURL` 可能受限。部分官方说明还会提到 `alipays`，按需追加。

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>alipay</string>
</array>
```

5. **验证**  
   - 安装包内 Info.plist 中 URL Scheme 与 `pubspec` 一致。  
   - 真机安装支付宝客户端后，`isAlipayInstalled()` 行为符合预期。

---

### 与自动脚本的关系（小结）

| 方式 | 行为 |
|------|------|
| 仅 `pod install` | 需在 plist 中**已存在** `CFBundleURLName=alipay` 的 URL Type，脚本只更新其 scheme 字符串。 |
| 仅手动 | 按上文在 Xcode/plist 中配好 URL Types 与 Queries Schemes，**务必**与 `alipay_payment.scheme` 一致。 |
| 两者兼有 | 先手动建好 `alipay` 这一项，之后每次 `pod install` 会把 scheme 同步成 pubspec 中的值。 |
