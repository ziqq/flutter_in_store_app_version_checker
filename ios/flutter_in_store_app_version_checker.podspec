#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_app_version_checker.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_in_store_app_version_checker'
  s.version          = '2.0.0'
  s.summary          = 'Lightweight flutter plugin to check if your app is up-to-date on GooglePlay or AppStore.'
  s.description      = 'Lightweight flutter plugin to check if your app is up-to-date on GooglePlay or AppStore.'
  s.homepage         = 'https://github.com/ziqq/flutter_in_store_app_version_checker'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Anton Ustinoff' => 'a.a.ustinoff@gmail.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'flutter_in_store_app_version_checker/Sources/flutter_in_store_app_version_checker/**/*.swift'
  s.requires_arc     = true

  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
  s.dependency 'Flutter'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end