package com.flutter.instoreappversionchecker

import android.content.Context
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** InStoreAppVersionCheckerPlugin */
class InStoreAppVersionCheckerPlugin: FlutterPlugin, MethodCallHandler {
  companion object {
    private const val CHANNEL_NAME = "github.com/ziqq/instoreappversionchecker/app_metadata"
  }

  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var applicationContext: Context

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    applicationContext = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getAppMetadata" -> result.success(getAppMetadata())
      "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
      else -> result.notImplemented()
    }
  }

  @Suppress("DEPRECATION")
  private fun getAppMetadata(): Map<String, String?> {
    val packageManager = applicationContext.packageManager
    val packageName = applicationContext.packageName
    val packageInfo = packageManager.getPackageInfo(packageName, 0)

    return mapOf(
      "packageName" to packageName,
      "version" to packageInfo.versionName,
    )
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
