#import <Flutter/Flutter.h>

// Re-export the Swift plugin class for Objective-C registrants.
#if __has_include(<flutter_in_store_app_version_checker/flutter_in_store_app_version_checker-Swift.h>)
#import <flutter_in_store_app_version_checker/flutter_in_store_app_version_checker-Swift.h>
#else
#import "flutter_in_store_app_version_checker-Swift.h"
#endif