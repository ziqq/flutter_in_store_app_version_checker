#import "include/flutter_in_store_app_version_checker/InStoreAppVersionCheckerPlugin.h"

#if __has_include(<flutter_in_store_app_version_checker/flutter_in_store_app_version_checker-Swift.h>)
#import <flutter_in_store_app_version_checker/flutter_in_store_app_version_checker-Swift.h>
#else
#import "flutter_in_store_app_version_checker-Swift.h"
#endif

@implementation InStoreAppVersionCheckerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftInStoreAppVersionCheckerPlugin registerWithRegistrar:registrar];
}
@end
