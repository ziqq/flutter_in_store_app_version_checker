package com.flutter.instoreappversionchecker

import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull
import com.huawei.hms.jos.JosApps
import com.huawei.updatesdk.service.appmgr.bean.ApkUpgradeInfo
import com.huawei.updatesdk.service.otaupdate.CheckUpdateCallBack
import com.huawei.updatesdk.service.otaupdate.UpdateKey

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.atomic.AtomicBoolean

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
      "checkAppGalleryUpdate" -> checkAppGalleryUpdate(result)
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

  private fun checkAppGalleryUpdate(result: Result) {
    try {
      val client = JosApps.getAppUpdateClient(applicationContext)
      val completed = AtomicBoolean(false)

      fun complete(block: () -> Unit) {
        if (completed.compareAndSet(false, true)) {
          client.releaseCallBack()
          block()
        }
      }

      client.checkAppUpdate(
        applicationContext,
        object : CheckUpdateCallBack {
          override fun onUpdateInfo(intent: Intent?) {
            if (intent == null) {
              complete {
                result.error(
                  "app_gallery_invalid_response",
                  "Huawei AppUpdateClient returned no update result.",
                  null,
                )
              }
              return
            }

            val info = getUpgradeInfo(intent)
            if (info != null) {
              complete {
                result.success(
                  mapOf(
                    "storeID" to info.id_,
                    "packageName" to info.package_,
                    "version" to info.version_,
                  ),
                )
              }
              return
            }

            val failureCode = intent.getIntExtra(UpdateKey.FAIL_CODE, 0)
            val failureReason = intent.getStringExtra(UpdateKey.FAIL_REASON)
            if (failureCode != 0) {
              complete {
                result.error(
                  "app_gallery_update_failed",
                  failureReason ?: "Huawei AppUpdateClient failed with code $failureCode.",
                  failureCode,
                )
              }
              return
            }

            complete {
              result.success(
                mapOf<String, String?>(
                  "storeID" to null,
                  "packageName" to null,
                  "version" to null,
                ),
              )
            }
          }

          override fun onMarketInstallInfo(intent: Intent?) = Unit

          override fun onMarketStoreError(errorCode: Int) {
            complete {
              result.error(
                "app_gallery_market_error",
                "Huawei AppGallery reported market error $errorCode.",
                errorCode,
              )
            }
          }

          override fun onUpdateStoreError(errorCode: Int) {
            complete {
              result.error(
                "app_gallery_update_error",
                "Huawei AppUpdateClient reported update error $errorCode.",
                errorCode,
              )
            }
          }
        },
      )
    } catch (error: Exception) {
      result.error(
        "app_gallery_update_exception",
        error.message ?: "Huawei AppUpdateClient failed.",
        error.toString(),
      )
    }
  }

  @Suppress("DEPRECATION")
  private fun getUpgradeInfo(intent: Intent): ApkUpgradeInfo? =
    intent.getSerializableExtra(UpdateKey.INFO) as? ApkUpgradeInfo

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
