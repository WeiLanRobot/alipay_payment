# 仅做一处「就地」字符串替换：CFBundleURLName=alipay 的 dict 内，只改 CFBundleURLSchemes 下首个 <string>。
# 不修改 LSApplicationQueriesSchemes（已有 alipay 即可用于 canOpenURL；alipays 为可选，由业务自行维护）。
#
# CLI: ruby alipay_setup.rb -s <scheme> -a <app_root>

require 'xcodeproj'
require 'optparse'

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

# 只替换：CFBundleURLName=alipay 的 dict 内，CFBundleURLSchemes 下第一个 <string>
def patch_alipay_scheme_string(content, scheme)
  pattern = %r{(<key>CFBundleURLName</key>\s*<string>alipay</string>\s*<key>CFBundleURLSchemes</key>\s*<array>\s*)<string>[^<]*</string>}m
  content.gsub(pattern) { "#{Regexp.last_match(1)}<string>#{scheme}</string>" }
end

def apply_alipay_edits_to_plist_file(path, scheme)
  raw = File.read(path)
  new_content = patch_alipay_scheme_string(raw, scheme)
  File.write(path, new_content) if new_content != raw
end

def apply_scheme_to_runner_plist(project_dir, scheme)
  project_path = File.join(project_dir, 'Runner.xcodeproj')
  return unless File.exist?(project_path)

  project = Xcodeproj::Project.open(project_path)
  target = project.targets.find { |t| t.name == 'Runner' }
  return unless target

  plist_paths = []
  target.build_configurations.each do |config|
    rel = config.build_settings['INFOPLIST_FILE']
    next if rel.nil? || rel.empty?
    abs = File.expand_path(rel, project_dir)
    plist_paths << abs if File.exist?(abs)
  end
  plist_paths.uniq!

  if plist_paths.empty?
    default_plist = File.join(project_dir, 'Runner', 'Info.plist')
    plist_paths << default_plist if File.exist?(default_plist)
  end

  plist_paths.each do |infoplist_file|
    apply_alipay_edits_to_plist_file(infoplist_file, scheme)
  end
end

def alipay_setup_scheme(app_root)
  pubspec_path = File.join(app_root, 'pubspec.yaml')
  return unless File.exist?(pubspec_path)

  scheme = read_scheme_from_pubspec(pubspec_path)
  return if scheme.nil? || scheme.empty?

  project_dir = File.join(app_root, 'ios')
  return unless File.directory?(project_dir)

  apply_scheme_to_runner_plist(project_dir, scheme)
end

if __FILE__ == $0
  options = {}
  OptionParser.new do |opts|
    opts.on('-s', '--scheme=SCHEME') { |v| options[:scheme] = v }
    opts.on('-a', '--app-root=DIR') { |v| options[:app_root] = v }
  end.parse!

  if options[:scheme] && options[:app_root]
    project_dir = File.join(options[:app_root], 'ios')
    apply_scheme_to_runner_plist(project_dir, options[:scheme]) if File.directory?(project_dir)
  end
end
