// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'Mondom';

  @override
  String get textHint => 'Írj ide…';

  @override
  String get loading => 'Betöltés…';

  @override
  String get speak => 'Beszélj';

  @override
  String get repeat => 'Ismétlés';

  @override
  String modelLoadTime(int ms) {
    return 'Modell betöltés: $ms ms';
  }

  @override
  String synthesisStats(int synthMs, int audioMs, String rtf) {
    return 'Szintézis: $synthMs ms, hang: $audioMs ms, RTF: $rtf';
  }

  @override
  String get tuning => 'Hangolás';

  @override
  String get tuningLength => 'Hossz';

  @override
  String get tuningNoise => 'Zaj';

  @override
  String get tuningNoiseW => 'Zaj W';

  @override
  String get tuningApply => 'Alkalmaz (újratöltés)';

  @override
  String get tuningReset => 'Alapértelmezett';
}
