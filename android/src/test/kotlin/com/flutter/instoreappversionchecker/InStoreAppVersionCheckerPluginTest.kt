package com.flutter.instoreappversionchecker

import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Looper
import com.huawei.hms.jos.AppUpdateClient
import com.huawei.hms.jos.JosApps
import com.huawei.updatesdk.service.appmgr.bean.ApkUpgradeInfo
import com.huawei.updatesdk.service.otaupdate.CheckUpdateCallBack
import com.huawei.updatesdk.service.otaupdate.UpdateKey
import com.huawei.updatesdk.service.otaupdate.UpdateStatusCode
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.io.Serializable
import java.time.Duration
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.ArgumentCaptor
import org.mockito.MockedStatic
import org.mockito.Mockito.*
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.LooperMode

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], manifest = Config.NONE)
@LooperMode(LooperMode.Mode.PAUSED)
class InStoreAppVersionCheckerPluginTest {
    private lateinit var plugin: InStoreAppVersionCheckerPlugin
    private lateinit var context: Context
    private lateinit var binding: FlutterPlugin.FlutterPluginBinding
    private lateinit var messenger: BinaryMessenger
    private lateinit var client: AppUpdateClient
    private lateinit var sdk: MockedStatic<JosApps>
    private lateinit var callback: CheckUpdateCallBack

    @Before
    fun setUp() {
        context = mock(Context::class.java)
        messenger = mock(BinaryMessenger::class.java)
        binding = mock(FlutterPlugin.FlutterPluginBinding::class.java)
        `when`(binding.applicationContext).thenReturn(context)
        `when`(binding.binaryMessenger).thenReturn(messenger)
        `when`(context.packageName).thenReturn("installed.app")
        val packageManager = mock(PackageManager::class.java)
        val packageInfo = PackageInfo().apply { versionName = "1.0.0" }
        `when`(context.packageManager).thenReturn(packageManager)
        `when`(packageManager.getPackageInfo("installed.app", 0)).thenReturn(packageInfo)
        client = mock(AppUpdateClient::class.java)
        sdk = mockStatic(JosApps::class.java)
        sdk.`when`<AppUpdateClient> { JosApps.getAppUpdateClient(context) }.thenReturn(client)
        doAnswer {
                callback = it.getArgument(1)
                null
            }
            .`when`(client)
            .checkAppUpdate(eq(context), any(CheckUpdateCallBack::class.java))
        plugin = InStoreAppVersionCheckerPlugin()
        plugin.onAttachedToEngine(binding)
    }

    @After
    fun tearDown() {
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(16))
        if (::plugin.isInitialized) plugin.onDetachedFromEngine(binding)
        if (::sdk.isInitialized) sdk.close()
    }

    @Test
    fun metadataUsesInstalledPackageAndVersion() {
        val result = call("getAppMetadata")
        assertEquals(mapOf("packageName" to "installed.app", "version" to "1.0.0"), result.value)
        assertEquals(1, result.replies)
        verifyNoInteractions(client)
    }

    @Test
    fun registrationRoutesEncodedMethodCallAndResponse() {
        val handler = ArgumentCaptor.forClass(BinaryMessenger.BinaryMessageHandler::class.java)
        verify(messenger).setMessageHandler(eq(CHANNEL), handler.capture())
        val codec = StandardMethodCodec.INSTANCE
        val message = codec.encodeMethodCall(MethodCall("getAppMetadata", null))
        message.flip()
        var replies = 0
        var value: Any? = null
        handler.value.onMessage(message) {
            replies++
            val envelope = requireNotNull(it)
            envelope.flip()
            value = codec.decodeEnvelope(envelope)
        }
        assertEquals(1, replies)
        assertEquals(mapOf("packageName" to "installed.app", "version" to "1.0.0"), value)
    }

    @Test
    fun metadataPreservesMissingVersion() {
        `when`(context.packageManager.getPackageInfo("installed.app", 0)).thenReturn(PackageInfo())
        val result = call("getAppMetadata")
        assertEquals(mapOf("packageName" to "installed.app", "version" to null), result.value)
    }

    @Test
    fun platformVersionUsesAndroidRelease() {
        assertEquals("Android ${Build.VERSION.RELEASE}", call("getPlatformVersion").value)
    }

    @Test
    fun unknownMethodIsNotImplemented() {
        val result = call("unknown")
        assertTrue(result.notImplemented)
        assertEquals(1, result.replies)
    }

    @Test
    fun detachUnregistersMethodChannel() {
        plugin.onDetachedFromEngine(binding)
        verify(messenger).setMessageHandler(CHANNEL, null)
    }

    @Test
    fun upgradeMapsStoreIDPackageAndTrimmedVersion() {
        val result = check()
        respond(upgrade(version = " 2.0.0 "))
        assertEquals(
            mapOf(
                "storeID" to "C107631977",
                "packageName" to "installed.app",
                "version" to "2.0.0",
            ),
            result.value,
        )
        assertCompleted(result)
    }

    @Test
    fun equalVersionIsReturnedWithoutAvailabilityOverride() {
        val result = check()
        respond(upgrade(version = "1.0.0"))
        assertEquals("1.0.0", (result.value as Map<*, *>)["version"])
        assertFalse((result.value as Map<*, *>).containsKey("canUpdate"))
        assertCompleted(result)
    }

    @Test
    fun noUpgradeReturnsExplicitNullFields() {
        val result = check()
        respond(Intent().putExtra(UpdateKey.STATUS, UpdateStatusCode.NO_UPGRADE_INFO))
        assertEquals(
            mapOf("storeID" to null, "packageName" to null, "version" to null),
            result.value,
        )
        assertCompleted(result)
    }

    @Test
    fun nullIntentIsAnError() {
        val result = check()
        respond(null)
        assertError(result, "app_gallery_invalid_response")
    }

    @Test
    fun missingAndUnknownStatusesAreErrors() {
        for (status in
            listOf(
                null,
                -1,
                UpdateStatusCode.CONNECT_ERROR,
                UpdateStatusCode.CHECK_FAILED,
                UpdateStatusCode.CANCEL,
                999,
            )) {
            val result = check()
            val intent = Intent()
            if (status != null) intent.putExtra(UpdateKey.STATUS, status)
            respond(intent)
            assertError(result, "app_gallery_update_failed")
            assertEquals(status ?: -1, (result.details as Map<*, *>)["status"])
        }
        verify(client, times(6)).releaseCallBack()
    }

    @Test
    fun failureCodeOverridesBothSuccessfulStatusesAndKeepsReason() {
        for (status in
            listOf(UpdateStatusCode.HAS_UPGRADE_INFO, UpdateStatusCode.NO_UPGRADE_INFO)) {
            val result = check()
            respond(
                Intent()
                    .putExtra(UpdateKey.STATUS, status)
                    .putExtra(UpdateKey.FAIL_CODE, 42)
                    .putExtra(UpdateKey.FAIL_REASON, "network failed")
            )
            assertError(result, "app_gallery_update_failed")
            assertEquals("network failed", result.message)
            assertEquals(mapOf("status" to status, "failureCode" to 42), result.details)
        }
        verify(client, times(2)).releaseCallBack()
    }

    @Test
    fun upgradeRequiresCorrectInfoType() {
        for (info in listOf<Serializable?>(null, "wrong type")) {
            val result = check()
            val intent = Intent().putExtra(UpdateKey.STATUS, UpdateStatusCode.HAS_UPGRADE_INFO)
            if (info != null) intent.putExtra(UpdateKey.INFO, info)
            respond(intent)
            assertError(result, "app_gallery_invalid_response")
        }
    }

    @Test
    fun upgradeRequiresNonBlankVersionAndPackage() {
        for ((version, packageName) in
            listOf(
                null to "installed.app",
                "" to "installed.app",
                "   " to "installed.app",
                "2.0.0" to null,
                "2.0.0" to "",
                "2.0.0" to "   ",
            )) {
            val result = check()
            respond(upgrade(version, packageName))
            assertError(result, "app_gallery_invalid_response")
        }
        verify(client, times(6)).releaseCallBack()
    }

    @Test
    fun marketAndUpdateErrorsAreDistinct() {
        val market = check()
        callback.onMarketStoreError(12)
        idle()
        assertError(market, "app_gallery_market_error")
        assertEquals(12, market.details)
        val update = check()
        callback.onUpdateStoreError(34)
        idle()
        assertError(update, "app_gallery_update_error")
        assertEquals(34, update.details)
    }

    @Test
    fun marketInstallNotificationDoesNotCompleteCheck() {
        val result = check()
        callback.onMarketInstallInfo(Intent())
        idle()
        assertEquals(0, result.replies)
        respond(upgrade())
        assertCompleted(result)
    }

    @Test
    fun sdkInitializationExceptionIsAnErrorAndAllowsRetry() {
        sdk.`when`<AppUpdateClient> { JosApps.getAppUpdateClient(context) }
            .thenThrow(IllegalStateException("init failed"))
        val result = check()
        assertError(result, "app_gallery_update_exception")
        assertEquals("init failed", result.message)
        verifyNoInteractions(client)
        sdk.`when`<AppUpdateClient> { JosApps.getAppUpdateClient(context) }.thenReturn(client)
        val retry = check()
        respond(upgrade())
        assertCompleted(retry)
    }

    @Test
    fun sdkExceptionsWithoutMessagesUseFallbackDiagnostics() {
        sdk.`when`<AppUpdateClient> { JosApps.getAppUpdateClient(context) }
            .thenThrow(IllegalStateException())
        val initialization = check()
        assertError(initialization, "app_gallery_update_exception")
        assertEquals("Huawei AppUpdateClient failed.", initialization.message)
        sdk.`when`<AppUpdateClient> { JosApps.getAppUpdateClient(context) }.thenReturn(client)
        doThrow(IllegalStateException())
            .`when`(client)
            .checkAppUpdate(eq(context), any(CheckUpdateCallBack::class.java))
        val checking = check()
        idle()
        assertError(checking, "app_gallery_update_exception")
        assertEquals("Huawei AppUpdateClient failed.", checking.message)
        verify(client).releaseCallBack()
    }

    @Test
    fun sdkCheckExceptionReleasesCallbackAndAllowsRetry() {
        doThrow(IllegalStateException("check failed"))
            .`when`(client)
            .checkAppUpdate(eq(context), any(CheckUpdateCallBack::class.java))
        val result = check()
        idle()
        assertError(result, "app_gallery_update_exception")
        assertEquals("check failed", result.message)
        verify(client).releaseCallBack()
        doAnswer {
                callback = it.getArgument(1)
                null
            }
            .`when`(client)
            .checkAppUpdate(eq(context), any(CheckUpdateCallBack::class.java))
        val retry = check()
        respond(upgrade())
        assertEquals(1, retry.replies)
        verify(client, times(2)).releaseCallBack()
    }

    @Test
    fun concurrentChecksAcrossPluginInstancesShareOneSdkCall() {
        val first = check()
        val otherPlugin = InStoreAppVersionCheckerPlugin()
        otherPlugin.onAttachedToEngine(binding)
        val second = RecordingResult()
        otherPlugin.onMethodCall(MethodCall("checkAppGalleryUpdate", null), second)
        verify(client).checkAppUpdate(eq(context), any(CheckUpdateCallBack::class.java))
        respond(upgrade())
        assertEquals(first.value, second.value)
        assertEquals(1, first.replies)
        assertEquals(1, second.replies)
        verify(client).releaseCallBack()
        otherPlugin.onDetachedFromEngine(binding)
    }

    @Test
    fun concurrentChecksShareFailureAndNextCheckStartsFresh() {
        val first = check()
        val second = check()
        callback.onUpdateStoreError(1)
        idle()
        assertError(first, "app_gallery_update_error")
        assertError(second, "app_gallery_update_error")
        val retry = check()
        respond(upgrade())
        assertEquals(1, retry.replies)
        verify(client, times(2)).checkAppUpdate(eq(context), any(CheckUpdateCallBack::class.java))
        verify(client, times(2)).releaseCallBack()
    }

    @Test
    fun timeoutCompletesAllWaitersAndLateCallbackCannotFinishRetry() {
        val first = check()
        val second = check()
        val oldCallback = callback
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(14_999))
        assertEquals(0, first.replies)
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(1))
        assertError(first, "app_gallery_update_timeout")
        assertError(second, "app_gallery_update_timeout")
        verify(client).releaseCallBack()
        val retry = check()
        oldCallback.onUpdateInfo(upgrade(version = "9.0.0"))
        oldCallback.onUpdateStoreError(99)
        idle()
        assertEquals(0, retry.replies)
        respond(upgrade())
        assertEquals("2.0.0", (retry.value as Map<*, *>)["version"])
        assertEquals(1, first.replies)
        assertEquals(1, second.replies)
        verify(client, times(2)).releaseCallBack()
    }

    @Test
    fun repeatedCallbacksAndOldTimeoutDoNotReplyTwice() {
        val result = check()
        respond(upgrade())
        callback.onUpdateInfo(upgrade(version = "9.0.0"))
        callback.onMarketStoreError(10)
        callback.onUpdateStoreError(11)
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(16))
        assertCompleted(result)
        assertEquals("2.0.0", (result.value as Map<*, *>)["version"])
    }

    private fun call(method: String): RecordingResult =
        RecordingResult().also {
            plugin.onMethodCall(MethodCall(method, null), it)
        }

    private fun check() = call("checkAppGalleryUpdate")

    private fun respond(intent: Intent?) {
        callback.onUpdateInfo(intent)
        idle()
    }

    private fun idle() = shadowOf(Looper.getMainLooper()).idle()

    private fun assertCompleted(result: RecordingResult) {
        assertEquals(1, result.replies)
        assertNull(result.code)
        verify(client).releaseCallBack()
    }

    private fun assertError(result: RecordingResult, code: String) {
        assertEquals(1, result.replies)
        assertEquals(code, result.code)
        assertFalse(result.message.isNullOrBlank())
    }

    private fun upgrade(
        version: String? = "2.0.0",
        packageName: String? = "installed.app",
    ): Intent {
        val info =
            ApkUpgradeInfo().apply {
                setId_("C107631977")
                setVersion_(version)
                setPackage_(packageName)
            }
        return Intent()
            .putExtra(UpdateKey.STATUS, UpdateStatusCode.HAS_UPGRADE_INFO)
            .putExtra(UpdateKey.INFO, info as Serializable)
    }

    private class RecordingResult : MethodChannel.Result {
        var replies = 0
        var value: Any? = null
        var code: String? = null
        var message: String? = null
        var details: Any? = null
        var notImplemented = false

        override fun success(result: Any?) {
            replies++
            value = result
        }

        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
            replies++
            code = errorCode
            message = errorMessage
            details = errorDetails
        }

        override fun notImplemented() {
            replies++
            notImplemented = true
        }
    }

    companion object {
        private const val CHANNEL = "github.com/ziqq/instoreappversionchecker/app_metadata"
    }
}
