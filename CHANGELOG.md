## 1.1.2

* **alipay_setup.rb**：**不再**自动追加 `alipays`；`LSApplicationQueriesSchemes` 仅保留业务自行维护（已有 `alipay` 即可满足常见 `canOpenURL` 检测）

## 1.1.1

* **alipay_setup.rb**：移除「兜底」替换逻辑；仅当 Info.plist 中已存在 `alipay` 前缀的 URL Scheme 时才更新，**不再误改微信、微博等**；无匹配时不写回 plist

## 1.1.0

* **podspec 路径推断**：从 `ios/.symlinks` 自动解析主工程根目录，**无需在 Podfile 配置 `ENV['ALIPAY_PAYMENT_APP_ROOT']`**
* **Info.plist 写入**：`alipay_setup.rb` 在 `pod install` 时由 podspec 调用，**无需在 Podfile `post_install` 中手动调用**
* **文档**：主 README 精简 iOS 说明，详情移至 `ios/Libraries/README.md`

## 1.0.0

* 正式稳定版
* **scheme 从 pubspec 读取**（与 alipay_kit 一致）：`pod install` 时 podspec 自动读取 `alipay_payment.scheme` 并注入，**无需执行脚本**
* **移除 urlScheme 参数**：pay/auth/unsafePay/unsafeAuth 等接口不再接受 urlScheme
* 兼容 resultStatus `{9000}` 格式解析（iOS 等平台可能返回带花括号）
* example：新增「验证 {9000} 解析」按钮

## 0.0.2

* 新增 `payAndWait()` / `authAndWait()` Future 风格 API
* 新增 `orderInfo` / `authInfo` 非空校验
* 完善平台接口文档注释
* 补充 `parseAuthResult`、`resultStatusCode`、`AlipayAuthResult` 单元测试

## 0.0.1

* 初始版本：支持支付宝 App 支付、账号授权
* 支持 iOS、Android 平台
* 支持沙箱/正式环境切换
