#import "InStoreAppVersionCheckerPlugin.h"
#if __has_include(<flutter_in_store_app_version_checker/flutter_in_store_app_version_checker-Swift.h>)
#import <flutter_in_store_app_version_checker/flutter_in_store_app_version_checker-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_in_store_app_version_checker-Swift.h"
#endif

@implementation InStoreAppVersionCheckerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftInStoreAppVersionCheckerPlugin registerWithRegistrar:registrar];
}
@end