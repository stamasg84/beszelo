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
  String get speak => 'Mondd';

  @override
  String get clearText => 'Szöveg törlése';

  @override
  String get replayed => 'Újrajátszva (szintézis nélkül)';

  @override
  String modelLoadTime(int ms) {
    return 'Modell betöltés: $ms ms';
  }

  @override
  String synthesisStats(int synthMs, int audioMs, String rtf) {
    return 'Szintézis: $synthMs ms, hang: $audioMs ms, RTF: $rtf';
  }

  @override
  String get cancel => 'Mégse';

  @override
  String get voicePickerTitle => 'Hang kiválasztása';

  @override
  String get voiceSettingsTooltip => 'Hang kiválasztása';

  @override
  String get moreLanguages => 'Más nyelvek';

  @override
  String get systemVoice => 'Android alapértelmezett';

  @override
  String get systemVoiceInfo => 'Azonnal működik, internet nélkül is';

  @override
  String get skip => 'Kihagyás';

  @override
  String get download => 'Letöltés';

  @override
  String get select => 'Kiválasztás';

  @override
  String get selected => 'Kiválasztva';

  @override
  String get deleteVoice => 'Hang törlése';

  @override
  String get playSample => 'Minta meghallgatása';

  @override
  String get sampleUnavailable => 'A minta nem érhető el';

  @override
  String get downloadsNeedInternet =>
      'A hangok letöltéséhez internet kell. Az Android alapértelmezett hang internet nélkül is működik.';

  @override
  String get downloadFailed =>
      'A letöltés nem sikerült. Ellenőrizd az internetkapcsolatot.';

  @override
  String get genderMale => 'férfi';

  @override
  String get genderFemale => 'női';

  @override
  String voiceSizeMb(int mb) {
    return '$mb MB';
  }

  @override
  String get installing => 'Telepítés… (ez eltarthat egy ideig)';

  @override
  String get historyTitle => 'Előzmények';

  @override
  String get allLists => 'Összes lista';

  @override
  String get editTooltip => 'Szerkesztés';

  @override
  String get editComingSoon => 'A szerkesztés hamarosan elérhető.';

  @override
  String get emptyListHint => 'Ez a lista üres. Szerkesztés: ✎';
}
