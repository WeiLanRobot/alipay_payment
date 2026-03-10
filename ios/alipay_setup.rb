# Alipay setup script - reads scheme from app pubspec and configures Info.plist
# Called from app's Podfile post_install
#
# pubspec config:
#   alipay_payment:
#     scheme: alipay2021000000000000
#     ios: noutdid  # optional

def alipay_setup_scheme(app_root)
  pubspec_path = File.join(app_root, 'pubspec.yaml')
  info_plist_path = File.join(app_root, 'ios', 'Runner', 'Info.plist')

  return unless File.exist?(pubspec_path)
  return unless File.exist?(info_plist_path)

  scheme = read_scheme_from_pubspec(pubspec_path)
  return if scheme.nil? || scheme.empty?

  update_info_plist_scheme(info_plist_path, scheme)
end

def read_scheme_from_pubspec(pubspec_path)
  content = File.read(pubspec_path)
  in_block = false
  content.each_line do |line|
    if line =~ /^\s*alipay_payment\s*:/
      in_block = true
      next
    end
    if in_block
      break if line =~ /^\s*\w+\s*:/ && line !~ /scheme/
      if line =~ /^\s*scheme\s*:\s*['"]?(\S+)['"]?/
        return $1.strip
      end
    end
  end
  nil
end

def update_info_plist_scheme(plist_path, scheme)
  content = File.read(plist_path)
  new_content = content.gsub(
    /(<key>CFBundleURLSchemes<\/key>\s*<array>\s*)<string>alipay[\w]*<\/string>/m,
    "\\1<string>#{scheme}</string>"
  )
  if new_content == content && content.include?('CFBundleURLTypes')
    new_content = content.gsub(
      /(<key>CFBundleURLSchemes<\/key>\s*<array>\s*)<string>[^<]+<\/string>/m,
      "\\1<string>#{scheme}</string>"
    )
  end
  File.write(plist_path, new_content) if new_content != content
end
