import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

/// Static make-up gain (dB) applied after peak normalization, before limiting.
const speechGainDb = 6.0;

/// Output ceiling (dBFS) of the soft limiter.
const speechCeilingDb = -1.0;

/// Where the soft limiter starts to bend the signal (linear below).
const _kneeLinear = 0.5; // about -6 dBFS

/// `shared_preferences` key of the speech boost switch (default on).
const speechBoostKey = 'speechBoost';

Future<bool> speechBoostEnabled() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(speechBoostKey) ?? true;
  } catch (_) {
    return true;
  }
}

double _fromDb(double db) => math.pow(10, db / 20).toDouble();

/// Makes [samples] (−1..1) louder: normalizes the peak to full scale, adds
/// [gainDb] of make-up gain, then soft-limits to [ceilingDb]. Static, so no
/// per-sentence pumping. Quiet parts are raised as much as loud ones; the
/// peaks are bent by a smooth tanh knee instead of being clipped.
/// Silence stays silence. Returns a new list.
Float32List boostLoudness(
  Float32List samples, {
  double gainDb = speechGainDb,
  double ceilingDb = speechCeilingDb,
}) {
  var peak = 0.0;
  for (final s in samples) {
    final a = s.abs();
    if (a > peak) peak = a;
  }
  final out = Float32List(samples.length);
  if (peak < 1e-6) return out; // silence (or near-silence): leave it alone
  final gain = _fromDb(gainDb) / peak;
  final ceiling = _fromDb(ceilingDb);
  final range = ceiling - _kneeLinear;
  for (var i = 0; i < samples.length; i++) {
    final x = samples[i] * gain;
    final a = x.abs();
    final y = a <= _kneeLinear
        ? a
        : _kneeLinear + range * _tanh((a - _kneeLinear) / range);
    out[i] = x < 0 ? -y : y;
  }
  return out;
}

double _tanh(double x) {
  if (x > 20) return 1;
  final e = math.exp(2 * x);
  return (e - 1) / (e + 1);
}

/// 16-bit PCM WAV contents.
class PcmWav {
  PcmWav(this.samples, this.sampleRate, this.channels);
  final Float32List samples;
  final int sampleRate;
  final int channels;
}

/// Parses a 16-bit PCM WAV, or returns null if it is anything else.
PcmWav? readPcm16Wav(Uint8List bytes) {
  if (bytes.length < 12) return null;
  final d = ByteData.sublistView(bytes);
  String tag(int o) => String.fromCharCodes(bytes.sublist(o, o + 4));
  if (tag(0) != 'RIFF' || tag(8) != 'WAVE') return null;
  int? rate, channels;
  var pos = 12;
  while (pos + 8 <= bytes.length) {
    final id = tag(pos);
    var size = d.getUint32(pos + 4, Endian.little);
    final body = pos + 8;
    if (id == 'fmt ') {
      if (body + 16 > bytes.length) return null;
      final format = d.getUint16(body, Endian.little);
      final bits = d.getUint16(body + 14, Endian.little);
      if (format != 1 || bits != 16) return null;
      channels = d.getUint16(body + 2, Endian.little);
      rate = d.getUint32(body + 4, Endian.little);
    } else if (id == 'data') {
      if (rate == null || channels == null || channels < 1) return null;
      // Streamed files may carry a bogus size: clamp to what is there.
      if (size > bytes.length - body) size = bytes.length - body;
      final n = size ~/ 2;
      final s = Float32List(n);
      for (var i = 0; i < n; i++) {
        s[i] = d.getInt16(body + i * 2, Endian.little) / 32768;
      }
      return PcmWav(s, rate, channels);
    }
    pos = body + size + (size.isOdd ? 1 : 0);
  }
  return null;
}

/// Encodes [wav] as a canonical 44-byte-header 16-bit PCM WAV.
Uint8List writePcm16Wav(PcmWav wav) {
  final n = wav.samples.length;
  final out = Uint8List(44 + n * 2);
  final d = ByteData.sublistView(out);
  void tag(int o, String t) => out.setRange(o, o + 4, t.codeUnits);
  tag(0, 'RIFF');
  d.setUint32(4, 36 + n * 2, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  d.setUint32(16, 16, Endian.little);
  d.setUint16(20, 1, Endian.little);
  d.setUint16(22, wav.channels, Endian.little);
  d.setUint32(24, wav.sampleRate, Endian.little);
  d.setUint32(28, wav.sampleRate * wav.channels * 2, Endian.little);
  d.setUint16(32, wav.channels * 2, Endian.little);
  d.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  d.setUint32(40, n * 2, Endian.little);
  for (var i = 0; i < n; i++) {
    final v = (wav.samples[i] * 32767).round().clamp(-32768, 32767);
    d.setInt16(44 + i * 2, v, Endian.little);
  }
  return out;
}

/// Boosts the WAV file at [path] in place. A file that isn't 16-bit PCM WAV
/// is left unchanged. Returns whether the file was changed.
bool boostWavFile(String path) {
  try {
    final file = File(path);
    final wav = readPcm16Wav(file.readAsBytesSync());
    if (wav == null) return false;
    file.writeAsBytesSync(
      writePcm16Wav(
        PcmWav(boostLoudness(wav.samples), wav.sampleRate, wav.channels),
      ),
    );
    return true;
  } catch (_) {
    return false;
  }
}
