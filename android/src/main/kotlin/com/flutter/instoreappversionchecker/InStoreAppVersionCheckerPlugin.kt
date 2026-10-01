package com.flutter.instoreappversionchecker

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.huawei.hms.jos.JosApps
import com.huawei.updatesdk.service.appmgr.bean.ApkUpgradeInfo
import com.huawei.updatesdk.service.otaupdate.CheckUpdateCallBack
import com.huawei.updatesdk.service.otaupdate.UpdateKey
import com.huawei.updatesdk.service.otaupdate.UpdateStatusCode

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
    private const val APP_GALLERY_TIMEOUT_MS = 15_000L
    private val appGalleryHandler = Handler(Looper.getMainLooper())
    private var pendingAppGalleryResults: MutableList<Result>? = null
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
    pendingAppGalleryResults?.let {
      it.add(result)
      return
    }

    try {
      val client = JosApps.getAppUpdateClient(applicationContext)
      val completed = AtomicBoolean(false)
      val results = mutableListOf(result)
      pendingAppGalleryResults = results
      lateinit var timeout: Runnable

      fun complete(block: (Result) -> Unit) {
        appGalleryHandler.post {
          if (completed.compareAndSet(false, true)) {
            appGalleryHandler.removeCallbacks(timeout)
            pendingAppGalleryResults = null
            client.releaseCallBack()
            results.forEach(block)
          }
        }
      }

      timeout = Runnable {
        complete {
          it.error(
            "app_gallery_update_timeout",
            "Huawei AppUpdateClient did not respond within 15 seconds.",
            null,
          )
        }
      }
      appGalleryHandler.postDelayed(timeout, APP_GALLERY_TIMEOUT_MS)

      try {
        client.checkAppUpdate(
          applicationContext,
          object : CheckUpdateCallBack {
            override fun onUpdateInfo(intent: Intent?) {
              if (intent == null) {
                complete {
                  it.error(
                    "app_gallery_invalid_response",
                    "Huawei AppUpdateClient returned no update result.",
                    null,
                  )
                }
                return
              }

              val status = intent.getIntExtra(UpdateKey.STATUS, -1)
              val failureCode = intent.getIntExtra(UpdateKey.FAIL_CODE, 0)
              val failureReason = intent.getStringExtra(UpdateKey.FAIL_REASON)
              if (failureCode != 0 ||
                  (status != UpdateStatusCode.HAS_UPGRADE_INFO &&
                   status != UpdateStatusCode.NO_UPGRADE_INFO)) {
                complete {
                  it.error(
                    "app_gallery_update_failed",
                    failureReason ?: "Huawei AppUpdateClient failed with status $status (code $failureCode).",
                    mapOf(
                      "status" to status,
                      "failureCode" to failureCode,
                    ),
                  )
                }
                return
              }

              if (status == UpdateStatusCode.HAS_UPGRADE_INFO) {
                val info = getUpgradeInfo(intent)
                if (info == null || info.version_.isNullOrBlank() || info.package_.isNullOrBlank()) {
                  complete {
                    it.error(
                      "app_gallery_invalid_response",
                      "Huawei AppUpdateClient returned invalid upgrade information.",
                      status,
                    )
                  }
                  return
                }
                complete {
                  it.success(
                    mapOf(
                      "storeID" to info.id_,
                      "packageName" to info.package_,
                      "version" to info.version_.trim(),
                    ),
                  )
                }
                return
              }

              complete {
                it.success(
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
                it.error(
                  "app_gallery_market_error",
                  "Huawei AppGallery reported market error $errorCode.",
                  errorCode,
                )
              }
            }

            override fun onUpdateStoreError(errorCode: Int) {
              complete {
                it.error(
                  "app_gallery_update_error",
                  "Huawei AppUpdateClient reported update error $errorCode.",
                  errorCode,
                )
              }
            }
          },
        )
      } catch (error: Exception) {
        complete {
          it.error(
            "app_gallery_update_exception",
            error.message ?: "Huawei AppUpdateClient failed.",
            error.toString(),
          )
        }
      }
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
