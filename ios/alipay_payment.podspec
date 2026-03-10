#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
# Reads config from app's pubspec.yaml:
#   alipay_payment:
#     scheme: alipay2021000000000000
#     ios: noutdid  # optional, 默认 utdid
#
Pod::Spec.new do |s|
  s.name             = 'alipay_payment'
  s.version          = '0.0.1'
  s.summary          = 'Flutter 支付宝支付插件'
  s.description      = <<-DESC
Flutter 支付宝支付插件，支持 iOS、Android
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # AlipaySDK: 默认 utdid，可配 noutdid（与 alipay_kit 一致）
  # pubspec: alipay_payment: ios: noutdid
  # Podfile 需设置 ENV['ALIPAY_PAYMENT_APP_ROOT'] = app_root
  root = File.dirname(__FILE__)
  noutdid_dir = File.join(root, 'Libraries', 'noutdid')
  utdid_dir = File.join(root, 'Libraries', 'utdid')
  use_noutdid = false
  app_root = ENV['ALIPAY_PAYMENT_APP_ROOT'] || File.expand_path(File.join(Dir.pwd, '..'))
  if app_root
    pubspec_path = File.join(app_root, 'pubspec.yaml')
    if File.exist?(pubspec_path)
      require 'yaml'
      cfg = YAML.load_file(pubspec_path) rescue nil
      use_noutdid = cfg && cfg['alipay_payment'] && cfg['alipay_payment']['ios'].to_s == 'noutdid'
    end
  end
  lib_dir = (use_noutdid && File.directory?(noutdid_dir)) ? 'Libraries/noutdid' : 'Libraries/utdid'

  s.vendored_frameworks = "#{lib_dir}/AlipaySDK.framework"
  s.resources = "#{lib_dir}/AlipaySDK.bundle"
  s.frameworks = 'UIKit', 'Foundation', 'CoreGraphics', 'CoreText', 'QuartzCore', 'CoreTelephony', 'SystemConfiguration', 'CFNetwork', 'WebKit'
  s.libraries = 'z', 'c++'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
