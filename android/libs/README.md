# 支付宝 Android SDK 本地 AAR

将下载的 `alipaySdk-xxx.aar` 或 `alipaysdk-android-xxx.aar` 放入此目录后，插件会优先使用本地 AAR，不再从 Maven 拉取。

**获取方式**：[支付宝开放平台 - App 支付客户端 DEMO&SDK](https://opendocs.alipay.com/open/204/105297)

若此目录为空，则自动使用 Maven 依赖 `com.alipay.sdk:alipaysdk-android:15.8.35`。
