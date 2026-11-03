package io.github.stamasg84.mondom

import android.content.ActivityNotFoundException
import android.content.Intent
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "io.github.stamasg84.mondom/tts"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openInstallVoiceData" -> result.success(openInstallVoiceData())
                "availability" -> availability(call.arguments.toString(), result)
                else -> result.notImplemented()
            }
        }
    }

    /**
     * "installed" | "missingData" | "unsupported" for a language code ("hu").
     * Matches voices by language only: flutter_tts compares whole locales
     * ("hu" != "hu_HU"), which never matches real voices.
     */
    private fun availability(language: String, result: MethodChannel.Result) {
        var tts: TextToSpeech? = null
        tts = TextToSpeech(applicationContext) { status ->
            val engine = tts
            if (status != TextToSpeech.SUCCESS || engine == null) {
                result.error("init", "TTS init failed: $status", null)
                engine?.shutdown()
                return@TextToSpeech
            }
            try {
                val avail = engine.isLanguageAvailable(Locale(language))
                val voices = (engine.voices ?: emptySet()).filter {
                    it.locale.language == language
                }
                val usable = voices.any {
                    !it.isNetworkConnectionRequired &&
                        !it.features.contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED)
                }
                val answer = when {
                    usable -> "installed"
                    // Engine lists no voices at all: trust isLanguageAvailable.
                    (engine.voices ?: emptySet()).isEmpty() ->
                        if (avail >= TextToSpeech.LANG_AVAILABLE) "installed" else "unsupported"
                    voices.isNotEmpty() || avail == TextToSpeech.LANG_MISSING_DATA ||
                        avail >= TextToSpeech.LANG_AVAILABLE -> "missingData"
                    else -> "unsupported"
                }
                result.success(answer)
            } catch (e: Exception) {
                result.error("query", e.message, null)
            } finally {
                engine.shutdown()
            }
        }
    }

    /** Engine's voice-data install screen; falls back to the TTS settings. */
    private fun openInstallVoiceData(): Boolean {
        val intents = listOf(
            Intent(TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA),
            Intent("com.android.settings.TTS_SETTINGS"),
        )
        for (intent in intents) {
            try {
                startActivity(intent)
                return true
            } catch (e: ActivityNotFoundException) {
                // Try the next one.
            } catch (e: SecurityException) {
                // Try the next one.
            }
        }
        return false
    }
}
