import Flutter
import UIKit

public final class SwiftInStoreAppVersionCheckerPlugin: NSObject, FlutterPlugin {
  private static let channelName = "github.com/ziqq/instoreappversionchecker/app_metadata"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    let instance = SwiftInStoreAppVersionCheckerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getAppMetadata":
      result([
        "packageName": Bundle.main.bundleIdentifier,
        "version": Bundle.main.object(
          forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String,
      ])
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
