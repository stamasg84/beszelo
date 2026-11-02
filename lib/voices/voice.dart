enum VoiceKind { system, piper }

enum VoiceGender { male, female, unknown }

/// One selectable voice (system TTS or a Piper model).
class Voice {
  const Voice({
    required this.id,
    required this.languageCode,
    required this.gender,
    required this.label,
    required this.kind,
  });

  final String id;

  /// Language of the voice, e.g. `hu`.
  final String languageCode;
  final VoiceGender gender;
  final String label;
  final VoiceKind kind;

  @override
  bool operator ==(Object other) => other is Voice && other.id == id;

  @override
  int get hashCode => id.hashCode;

  /// The system voice ("Android alapértelmezett") for [languageCode].
  static const systemHu = Voice(
    id: 'system-hu',
    languageCode: 'hu',
    gender: VoiceGender.unknown,
    label: 'Android alapértelmezett',
    kind: VoiceKind.system,
  );

}
