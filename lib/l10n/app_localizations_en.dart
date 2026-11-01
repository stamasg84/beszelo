// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mondom';

  @override
  String get textHint => 'Type here…';

  @override
  String get loading => 'Loading…';

  @override
  String get speak => 'Speak';

  @override
  String get repeat => 'Repeat';

  @override
  String modelLoadTime(int ms) {
    return 'Model load: $ms ms';
  }

  @override
  String synthesisStats(int synthMs, int audioMs, String rtf) {
    return 'Synthesis: $synthMs ms, audio: $audioMs ms, RTF: $rtf';
  }

  @override
  String get tuning => 'Tuning';

  @override
  String get tuningLength => 'Length';

  @override
  String get tuningNoise => 'Noise';

  @override
  String get tuningNoiseW => 'Noise W';

  @override
  String get tuningApply => 'Apply (reload)';

  @override
  String get tuningReset => 'Default';
}
