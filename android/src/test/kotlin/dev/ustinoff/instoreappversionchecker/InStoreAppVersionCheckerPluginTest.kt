package dev.ustinoff.instoreappversionchecker

import android.content.Context
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.ArgumentCaptor
import org.mockito.Mockito.*
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], manifest = Config.NONE)
class InStoreAppVersionCheckerPluginTest {
    private lateinit var plugin: InStoreAppVersionCheckerPlugin
    private lateinit var context: Context
    private lateinit var binding: FlutterPlugin.FlutterPluginBinding
    private lateinit var messenger: BinaryMessenger

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
        plugin = InStoreAppVersionCheckerPlugin()
        plugin.onAttachedToEngine(binding)
    }

    @After
    fun tearDown() {
        if (::plugin.isInitialized) plugin.onDetachedFromEngine(binding)
    }

    @Test
    fun metadataUsesInstalledPackageAndVersion() {
        val result = call("getAppMetadata")
        assertEquals(mapOf("packageName" to "installed.app", "version" to "1.0.0"), result.value)
        assertEquals(1, result.replies)
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
    fun unknownMethodsIncludingHashCollisionsAreNotImplemented() {
        val collisions =
            mapOf(
                "getAppMetadata" to "hFtAppMetadata",
                "getPlatformVersion" to "hFtPlatformVersion",
            )
        for ((known, unknown) in collisions) {
            assertNotEquals(known, unknown)
            assertEquals(known.hashCode(), unknown.hashCode())
        }
        // The AppGallery SDK bridge was removed with the Huawei dependency.
        for (method in listOf("unknown", "", "checkAppGalleryUpdate") + collisions.values) {
            val result = call(method)
            assertTrue(method, result.notImplemented)
            assertEquals(1, result.replies)
        }
    }

    @Test
    fun malformedNativeCallWithNullMethodIsNotImplemented() {
        // MethodCall's constructor rejects null; model a malformed native input.
        val malformedCall = mock(MethodCall::class.java)
        assertNull(malformedCall.method)
        val result = RecordingResult()
        plugin.onMethodCall(malformedCall, result)
        assertTrue(result.notImplemented)
        assertEquals(1, result.replies)
    }

    @Test
    fun detachUnregistersMethodChannel() {
        plugin.onDetachedFromEngine(binding)
        verify(messenger).setMessageHandler(CHANNEL, null)
    }

    private fun call(method: String): RecordingResult =
        RecordingResult().also {
            plugin.onMethodCall(MethodCall(method, null), it)
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
