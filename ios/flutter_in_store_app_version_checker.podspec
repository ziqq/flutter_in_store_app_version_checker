#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_in_store_app_version_checker.podspec` to validate before publishing.
#
# Pod::Spec.new do |s|
#   s.name             = 'flutter_in_store_app_version_checker'
#   s.version          = '1.4.0'
#   s.license          = { :type => 'MIT', :file => './../LICENSE' }
#   s.homepage         = 'https://github.com/ziqq/flutter_in_store_app_version_checker'
#   s.authors           = { 'Anton Ustinoff' => 'a.a.ustinoff@gmail.com' }
#   s.summary          = ' lightweight flutter plugin to check if your app is up-to-date on Google Play Store or Apple App Store'
#   s.source           = { :git => 'https://github.com/ziqq/flutter_in_store_app_version_checker.git', :tag => s.version.to_s }
#   s.module_name      = 'flutter_in_store_app_version_checker'
#   s.swift_version = '5.0'

#   s.ios.deployment_target  = '12.0'

#   s.source_files = 'Classes/**/*'
#   s.platforms = { :ios => '12.0' }
#   s.dependency 'Flutter'

#   s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64, i386' }
#   s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
# end


#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_app_version_checker.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_in_store_app_version_checker'
  s.version          = '1.4.0'
  s.summary          = 'Lightweight flutter plugin to check if your app is up-to-date on GooglePlay or AppStore.'
  s.description      = <<-DESC
  Lightweight flutter plugin to check if your app is up-to-date on GooglePlay or AppStore.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Anton Ustinoff' => 'a.a.ustinoff@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end