package com.mamotion.ma_motion_mobile

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.mamotion.ma_motion_mobile/external_links"
        ).setMethodCallHandler { call, result ->
            if (call.method != "openExternalUrl") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val url = call.argument<String>("url")
            if (url.isNullOrBlank()) {
                result.error("invalid_url", "The link is empty.", null)
                return@setMethodCallHandler
            }

            val uri = Uri.parse(url)
            if (uri.scheme != "https" && uri.scheme != "http") {
                result.error("invalid_url", "Only web links are supported.", null)
                return@setMethodCallHandler
            }

            // An implicit VIEW intent lets Android select whichever browser
            // the user installed or chose as their default.
            try {
                val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                    addCategory(Intent.CATEGORY_BROWSABLE)
                }
                startActivity(intent)
                result.success(true)
            } catch (error: ActivityNotFoundException) {
                result.error(
                    "no_browser",
                    "No application is installed to open web links.",
                    null
                )
            } catch (error: Exception) {
                result.error("launch_failed", error.message ?: "Browser launch failed.", null)
            }
        }
    }
}
