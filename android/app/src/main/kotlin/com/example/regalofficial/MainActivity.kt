package com.example.regalofficial

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.regalofficial/url_launcher"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "launchURL") {
                val url = call.argument<String>("url")
                if (url != null) {
                    launchURL(url)
                    result.success(null)
                } else {
                    result.error("UNAVAILABLE", "URL not available.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun launchURL(url: String) {
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse(url)
        startActivity(intent)
    }
}
