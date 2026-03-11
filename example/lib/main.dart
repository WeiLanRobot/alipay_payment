import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alipay_payment/alipay_payment.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '支付宝插件示例',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AlipayDemoPage(),
    );
  }
}

class AlipayDemoPage extends StatefulWidget {
  const AlipayDemoPage({super.key});

  @override
  State<AlipayDemoPage> createState() => _AlipayDemoPageState();
}

class _AlipayDemoPageState extends State<AlipayDemoPage> {
  String _platformVersion = 'Unknown';
  bool _isAlipayInstalled = false;
  AlipayEnvironment _environment = AlipayEnvironment.sandbox;
  String _lastResult = '';

  StreamSubscription<AlipayResult>? _paySubscription;
  StreamSubscription<AlipayResult>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initPlatform();
    _paySubscription =
        AlipayPaymentPlatform.instance.payResp().listen(_onPayResult);
    _authSubscription =
        AlipayPaymentPlatform.instance.authResp().listen(_onAuthResult);
  }

  @override
  void dispose() {
    _paySubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  void _onPayResult(AlipayResult result) {
    if (mounted) {
      setState(() => _lastResult =
          '支付结果: ${result.resultStatus}\n${result.memo ?? ""}');
    }
  }

  void _onAuthResult(AlipayResult result) {
    if (mounted) {
      setState(() => _lastResult =
          '授权结果: ${result.resultStatus}\n${result.memo ?? ""}');
    }
  }

  Future<void> _initPlatform() async {
    try {
      final version =
          await AlipayPaymentPlatform.instance.getPlatformVersion();
      final installed =
          await AlipayPaymentPlatform.instance.isAlipayInstalled();
      if (mounted) {
        setState(() {
          _platformVersion = version ?? 'Unknown';
          _isAlipayInstalled = installed;
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _platformVersion = 'Error: ${e.message}';
        });
      }
    }
  }

  Future<void> _setEnvironment(AlipayEnvironment env) async {
    try {
      await AlipayPaymentPlatform.instance.setEnvironment(env);
      if (mounted) {
        setState(() {
          _environment = env;
          _lastResult = '环境已设置为: ${env == AlipayEnvironment.production ? "正式" : "测试"}';
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() => _lastResult = '设置失败: ${e.message}');
      }
    }
  }

  Future<void> _pay() async {
    // 实际使用时 orderInfo 应由服务端生成
    const orderInfo = 'test_order_info_from_server';
    await AlipayPaymentPlatform.instance.pay(
      orderInfo: orderInfo,
      urlScheme: 'alipay2021000000000000', // iOS 需配置你的 AppID
    );
    // 结果通过 payResp 流返回，已在 initState 中监听
  }

  Future<void> _auth() async {
    const authInfo = 'test_auth_info_from_server';
    await AlipayPaymentPlatform.instance.auth(
      authInfo: authInfo,
      urlScheme: 'alipay2021000000000000',
    );
    // 结果通过 authResp 流返回，已在 initState 中监听
  }

  /// 验证 {9000} 格式解析：模拟原生返回带花括号的 resultStatus
  void _verifyBracesParsing() {
    final result = AlipayResult.fromMap(<String, dynamic>{
      'resultStatus': '{9000}',
      'result': null,
      'memo': '测试解析',
    });
    setState(() => _lastResult =
        '【{9000} 解析验证】\n'
        'resultStatus: ${result.resultStatus}\n'
        'isSuccess: ${result.isSuccess}\n'
        'resultStatusCode: ${result.resultStatusCode}\n'
        'memo: ${result.memo}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('支付宝插件示例'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildEnvironmentCard(),
            const SizedBox(height: 16),
            _buildActionCard(),
            const SizedBox(height: 16),
            _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('平台: $_platformVersion', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              '支付宝已安装: ${_isAlipayInstalled ? "是" : "否"}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('支付环境', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<AlipayEnvironment>(
                    title: const Text('测试'),
                    value: AlipayEnvironment.sandbox,
                    groupValue: _environment,
                    onChanged: (v) => v != null ? _setEnvironment(v) : null,
                  ),
                ),
                Expanded(
                  child: RadioListTile<AlipayEnvironment>(
                    title: const Text('正式'),
                    value: AlipayEnvironment.production,
                    groupValue: _environment,
                    onChanged: (v) => v != null ? _setEnvironment(v) : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('操作', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _pay,
              icon: const Icon(Icons.payment),
              label: const Text('发起支付'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: _auth,
              icon: const Icon(Icons.login),
              label: const Text('支付宝授权'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _initPlatform,
              icon: const Icon(Icons.refresh),
              label: const Text('刷新安装状态'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _verifyBracesParsing,
              icon: const Icon(Icons.bug_report),
              label: const Text('验证 {9000} 解析'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('结果', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _lastResult.isEmpty ? '暂无结果' : _lastResult,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
