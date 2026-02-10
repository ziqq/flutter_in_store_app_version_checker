#import "InStoreAppVersionCheckerPlugin.h"
#import <UIKit/UIKit.h>

@implementation InStoreAppVersionCheckerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel =
      [FlutterMethodChannel methodChannelWithName:@"github.com/ziqq/flutter_in_store_app_version_checker"
                            binaryMessenger:[registrar messenger]];
  InStoreAppVersionCheckerPlugin* instance = [[InStoreAppVersionCheckerPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  result([@"iOS " stringByAppendingString:UIDevice.currentDevice.systemVersion]);
}
@end