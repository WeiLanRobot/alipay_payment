package com.weilan.alipay_payment

import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import com.alipay.sdk.app.AuthTask
import com.alipay.sdk.app.PayTask
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.Executors

class AlipayPaymentPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel: MethodChannel
  private var applicationContext: Context? = null
  private var activity: Activity? = null
  private val mainHandler = Handler(Looper.getMainLooper())
  private val executor = Executors.newSingleThreadExecutor()

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    applicationContext = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "io.github.weilanwl.alipay_payment")
    channel.setMethodCallHandler(this)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "setEnvironment" -> {
        val args = call.arguments as? Map<*, *>
        val environment = args?.get("environment") as? String
        if (environment != null) {
          applicationContext?.getSharedPreferences("alipay_payment", Context.MODE_PRIVATE)
            ?.edit()
            ?.putString("environment", environment)
            ?.apply()
          result.success(null)
        } else {
          result.error("INVALID_ARGS", "缺少 environment 参数", null)
        }
      }
      "pay" -> {
        handlePay(call, result)
      }
      "auth" -> {
        handleAuth(call, result)
      }
      "isAlipayInstalled" -> {
        result.success(isAlipayInstalled())
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun handlePay(call: MethodCall, result: Result) {
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "缺少参数", null)
      return
    }
    val orderInfo = args["orderInfo"] as? String ?: run {
      result.error("INVALID_ARGS", "缺少 orderInfo 参数", null)
      return
    }
    val showPayLoading = args["showPayLoading"] as? Boolean ?: true
    val dynamicLaunch = args["dynamicLaunch"] as? Boolean ?: false
    val payEnvIndex = args["payEnv"] as? Int

    if (payEnvIndex != null && payEnvIndex in 0..1) {
      val env = if (payEnvIndex == 0) "production" else "sandbox"
      applicationContext?.getSharedPreferences("alipay_payment", Context.MODE_PRIVATE)
        ?.edit()
        ?.putString("environment", env)
        ?.apply()
    }

    val act = activity
    if (act == null) {
      result.error("NO_ACTIVITY", "无法获取 Activity", null)
      return
    }

    if (!isAlipayInstalled()) {
      result.success(mapOf(
        "resultStatus" to "6002",
        "result" to null,
        "memo" to "未安装支付宝"
      ))
      return
    }

    result.success(null)

    executor.execute {
      try {
        val payTask = PayTask(act)
        val resultStr = payTask.pay(orderInfo, showPayLoading)
        val resultMap = parsePayResult(resultStr)
        mainHandler.post {
          channel.invokeMethod("onPayResp", resultMap)
        }
      } catch (e: Exception) {
        mainHandler.post {
          channel.invokeMethod("onPayResp", mapOf(
            "resultStatus" to "4000",
            "result" to null,
            "memo" to (e.message ?: "支付异常")
          ))
        }
      }
    }
  }

  private fun handleAuth(call: MethodCall, result: Result) {
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("INVALID_ARGS", "缺少参数", null)
      return
    }
    val authInfo = args["authInfo"] as? String ?: run {
      result.error("INVALID_ARGS", "缺少 authInfo 参数", null)
      return
    }
    val showPayLoading = args["showPayLoading"] as? Boolean ?: true

    val act = activity
    if (act == null) {
      result.error("NO_ACTIVITY", "无法获取 Activity", null)
      return
    }

    if (!isAlipayInstalled()) {
      result.success(mapOf(
        "resultStatus" to "6002",
        "result" to null,
        "memo" to "未安装支付宝"
      ))
      return
    }

    result.success(null)

    executor.execute {
      try {
        val authTask = AuthTask(act)
        val resultMap = authTask.authV2(authInfo, showPayLoading)
        val formatted = mapOf(
          "resultStatus" to (resultMap["resultStatus"] ?: ""),
          "result" to resultMap["result"],
          "memo" to (resultMap["memo"] ?: "")
        )
        mainHandler.post {
          channel.invokeMethod("onAuthResp", formatted)
        }
      } catch (e: Exception) {
        mainHandler.post {
          channel.invokeMethod("onAuthResp", mapOf(
            "resultStatus" to "4000",
            "result" to null,
            "memo" to (e.message ?: "授权异常")
          ))
        }
      }
    }
  }

  private fun parsePayResult(resultStr: String?): Map<String, Any?> {
    if (resultStr.isNullOrEmpty()) {
      return mapOf("resultStatus" to "6004", "result" to null, "memo" to "无返回数据")
    }
    val map = mutableMapOf<String, String?>()
    for (pair in resultStr.split(";")) {
      val idx = pair.indexOf("=")
      if (idx > 0) {
        val key = pair.substring(0, idx).trim()
        val value = pair.substring(idx + 1).trim()
        map[key] = value.ifEmpty { null }
      }
    }
    return mapOf(
      "resultStatus" to (map["resultStatus"] ?: ""),
      "result" to map["result"],
      "memo" to (map["memo"] ?: "")
    )
  }

  private fun isAlipayInstalled(): Boolean {
    val ctx = applicationContext ?: return false
    val packageManager = ctx.packageManager
    val alipayPackages = listOf(
      "com.eg.android.AlipayGphone",
      "com.alipay.mobile"
    )
    return alipayPackages.any { pkg ->
      try {
        packageManager.getPackageInfo(pkg, 0)
        true
      } catch (e: PackageManager.NameNotFoundException) {
        false
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    applicationContext = null
    activity = null
    executor.shutdown()
  }
}
