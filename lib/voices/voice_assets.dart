import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Copies a bundled voice folder from Flutter assets to app support storage,
/// because native code (sherpa-onnx / espeak-ng) needs real file paths.
class VoiceAssets {
  VoiceAssets._();

  static const _assetRoot = 'assets/voices';

  /// Bump to force a re-copy after the voice files change.
  static const _version = '2';

  /// Returns the directory on disk containing the voice files.
  static Future<String> prepare(String voiceDir) async {
    final support = await getApplicationSupportDirectory();
    final target = Directory('${support.path}/voices/$voiceDir');
    final marker = File('${target.path}/.copied');

    if (marker.existsSync() && marker.readAsStringSync() == _version) {
      return target.path;
    }

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final prefix = '$_assetRoot/$voiceDir/';
    final assets = manifest.listAssets().where((a) => a.startsWith(prefix));

    for (final asset in assets) {
      final rel = Uri.decodeFull(asset.substring(prefix.length));
      final file = File('${target.path}/$rel');
      await file.parent.create(recursive: true);
      final data = await rootBundle.load(asset);
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }

    await marker.writeAsString(_version);
    return target.path;
  }
}
