package com.otterdays.soundpax

import android.content.ClipData
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "soundpax/share",
        ).setMethodCallHandler { call, result ->
            if (call.method != "shareWavs") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val paths = call.argument<List<String>>("paths").orEmpty()
            val subject = call.argument<String>("subject")
            val text = call.argument<String>("text")

            try {
                shareWavs(paths, subject, text)
                result.success(null)
            } catch (e: Exception) {
                result.error("SHARE_FAILED", e.message, null)
            }
        }
    }

    private fun shareWavs(paths: List<String>, subject: String?, text: String?) {
        require(paths.isNotEmpty()) { "No files to share" }

        val uris = ArrayList<Uri>()
        paths.forEach { path ->
            val file = File(path)
            require(file.exists()) { "Missing export file: $path" }
            uris.add(
                FileProvider.getUriForFile(
                    this,
                    "${applicationContext.packageName}.fileprovider",
                    file,
                ),
            )
        }

        val sendIntent = Intent(
            if (uris.size == 1) Intent.ACTION_SEND else Intent.ACTION_SEND_MULTIPLE,
        ).apply {
            type = "audio/wav"
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            subject?.let { putExtra(Intent.EXTRA_SUBJECT, it) }
            text?.let { putExtra(Intent.EXTRA_TEXT, it) }

            if (uris.size == 1) {
                putExtra(Intent.EXTRA_STREAM, uris.first())
            } else {
                putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
            }

            clipData = ClipData.newUri(contentResolver, "SoundPax export", uris.first()).also {
                uris.drop(1).forEach { uri -> it.addItem(ClipData.Item(uri)) }
            }
        }

        startActivity(Intent.createChooser(sendIntent, subject ?: "Share SoundPax WAV"))
    }
}
