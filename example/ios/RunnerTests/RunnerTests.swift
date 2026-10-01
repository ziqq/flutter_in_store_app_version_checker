import Flutter
import UIKit
import XCTest
import flutter_in_store_app_version_checker

final class RunnerTests: XCTestCase {
  private let channelName = "github.com/ziqq/instoreappversionchecker/app_metadata"

  func testRegistrationInstallsDelegateOnMetadataChannel() {
    let registrar = RecordingRegistrar()
    SwiftInStoreAppVersionCheckerPlugin.register(with: registrar)
    XCTAssertTrue(registrar.delegate is SwiftInStoreAppVersionCheckerPlugin)
    XCTAssertEqual(Array(registrar.binaryMessenger.handlers.keys), [channelName])
  }

  func testMetadataUsesHostApplicationBundle() throws {
    let value = try invoke("getAppMetadata") as? [String: Any]
    XCTAssertNotNil(value)
    XCTAssertEqual(value?["packageName"] as? String, Bundle.main.bundleIdentifier)
    XCTAssertEqual(
      value?["version"] as? String,
      Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    )
    XCTAssertEqual(Set(value?.keys.map { $0 } ?? []), ["packageName", "version"])
  }

  func testMetadataIgnoresCallerOverrides() throws {
    let value = try invoke("getAppMetadata", arguments: [
      "packageName": "another.app", "version": "99.0.0",
    ]) as? [String: Any]
    XCTAssertEqual(value?["packageName"] as? String, Bundle.main.bundleIdentifier)
    XCTAssertEqual(
      value?["version"] as? String,
      Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    )
  }

  func testPlatformVersionUsesSystemVersion() throws {
    XCTAssertEqual(try invoke("getPlatformVersion") as? String, "iOS " + UIDevice.current.systemVersion)
  }

  func testUnknownMethodIsNotImplemented() throws {
    XCTAssertNil(try invoke("unknown"))
  }

  func testAppGalleryNativeIsNotImplementedOnIOS() throws {
    XCTAssertNil(try invoke("checkAppGalleryUpdate"))
  }

  private func invoke(_ method: String, arguments: Any? = nil) throws -> Any? {
    let registrar = RecordingRegistrar()
    SwiftInStoreAppVersionCheckerPlugin.register(with: registrar)
    let handler = try XCTUnwrap(registrar.binaryMessenger.handlers[channelName])
    let codec = FlutterStandardMethodCodec.sharedInstance()
    var replies = 0
    var envelope: Data?
    handler(codec.encode(FlutterMethodCall(methodName: method, arguments: arguments))) {
      replies += 1
      envelope = $0
    }
    XCTAssertEqual(replies, 1, "The native handler must complete exactly once")
    guard let envelope else { return nil }
    return codec.decodeEnvelope(envelope)
  }
}

private final class RecordingMessenger: NSObject, FlutterBinaryMessenger {
  var handlers = [String: FlutterBinaryMessageHandler]()

  func send(onChannel channel: String, message: Data?) {}
  func send(onChannel channel: String, message: Data?, binaryReply callback: FlutterBinaryReply?) {
    callback?(nil)
  }
  func setMessageHandlerOnChannel(
    _ channel: String, binaryMessageHandler handler: FlutterBinaryMessageHandler?
  ) -> FlutterBinaryMessengerConnection {
    handlers[channel] = handler
    return 1
  }
  func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) {
    handlers.removeAll()
  }
}

private final class RecordingRegistrar: NSObject, FlutterPluginRegistrar {
  let binaryMessenger = RecordingMessenger()
  var delegate: FlutterPlugin?
  var viewController: UIViewController? { nil }

  func messenger() -> FlutterBinaryMessenger { binaryMessenger }
  func addMethodCallDelegate(_ delegate: FlutterPlugin, channel: FlutterMethodChannel) {
    self.delegate = delegate
    channel.setMethodCallHandler { call, result in delegate.handle?(call, result: result) }
  }
  func publish(_ value: NSObject) {}
  func valuePublished(byPlugin pluginKey: String) -> NSObject? { nil }
  func addApplicationDelegate(_ delegate: FlutterPlugin) {}
  func addSceneDelegate(_ delegate: FlutterSceneLifeCycleDelegate) {}
  func lookupKey(forAsset asset: String) -> String { asset }
  func lookupKey(forAsset asset: String, fromPackage package: String) -> String { asset }
  func register(_ factory: FlutterPlatformViewFactory, withId factoryId: String) {}
  func register(
    _ factory: FlutterPlatformViewFactory, withId factoryId: String,
    gestureRecognizersBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicy
  ) {}
  func textures() -> FlutterTextureRegistry {
    fatalError("The metadata plugin must not register textures")
  }
}
