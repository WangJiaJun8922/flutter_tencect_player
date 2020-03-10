#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_tc_player.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_tc_player'
  s.version          = '0.0.5'
  s.summary          = 'A new Flutter plugin.'
  s.description      = <<-DESC
A new Flutter plugin.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  # s.platform = :ios, '8.0'
  s.dependency 'TXLiteAVSDK_Player', '= 6.9.8341'
  s.user_target_xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES' }
  s.static_framework = true
  s.ios.deployment_target = '8.0'
  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  # s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
end
