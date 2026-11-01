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

  /// The system voice ("Android alapértelmezett") for [languageCode].
  static const systemHu = Voice(
    id: 'system-hu',
    languageCode: 'hu',
    gender: VoiceGender.unknown,
    label: 'Android alapértelmezett',
    kind: VoiceKind.system,
  );

  static const imre = Voice(
    id: 'hu_HU-imre-medium',
    languageCode: 'hu',
    gender: VoiceGender.male,
    label: 'Imre',
    kind: VoiceKind.piper,
  );

  /// Temporary hardcoded list; T10/T11 replace it with the catalog.
  static const temporary = [imre, systemHu];

  static Voice byId(String? id) =>
      temporary.firstWhere((v) => v.id == id, orElse: () => imre);
}
