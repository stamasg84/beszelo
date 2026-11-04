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
  String get speak => 'Mondom';

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
  String languageSelectorLabel(String name) {
    return 'Nyelv: $name';
  }

  @override
  String installedVoicesCount(int count) {
    return '$count letöltve';
  }

  @override
  String get systemVoiceMissing => 'A hang nincs letöltve a telefonon.';

  @override
  String get downloadInAndroidSettings => 'Letöltés az Android beállításaiban';

  @override
  String get systemVoiceUnsupported =>
      'A telefon nem tud ezen a nyelven beszélni.';

  @override
  String get systemVoice => 'Android alapértelmezett';

  @override
  String get systemVoiceInfo => 'Azonnal működik, internet nélkül is';

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
  String get emptyListHint =>
      'Ez a lista üres. Szerkesztés: ⚙ Beállítások → Listák';

  @override
  String get settingsTooltip => 'Beállítások';

  @override
  String get settingsVoiceTitle => 'Hang és nyelv';

  @override
  String settingsVoiceSubtitle(String voice, String language) {
    return '$voice · $language';
  }

  @override
  String get settingsListsTitle => 'Listák';

  @override
  String get settingsListsSubtitle => 'Listák és mondatok szerkesztése';

  @override
  String get pinnedLabel => 'Kitűzve';

  @override
  String sentenceCount(int count) {
    return '$count mondat';
  }

  @override
  String get currentlyOpen => 'Most megnyitva';

  @override
  String get reorderHandle => 'Mozgatás';

  @override
  String get moreActions => 'További műveletek';

  @override
  String get renameList => 'Átnevezés';

  @override
  String get pinList => 'Kitűzés';

  @override
  String get unpinList => 'Kitűzés megszüntetése';

  @override
  String get deleteList => 'Törlés';

  @override
  String deleteListQuestion(String title, int count) {
    return 'Törlöd a(z) „$title” listát és a $count mondatát?';
  }

  @override
  String get deleteAction => 'Törlés';

  @override
  String get saveAction => 'Mentés';

  @override
  String get newList => 'Új lista';

  @override
  String get listNameLabel => 'A lista neve';

  @override
  String get kindEveryday => 'Mondatlista';

  @override
  String get kindConversation => 'Beszélgetés';

  @override
  String get kindConversationInfo => 'Előre megírt mondatok, Következő gombbal';

  @override
  String get createAction => 'Létrehozás';

  @override
  String get restoreDefaultLists => 'Alapértelmezett listák visszaállítása';

  @override
  String addSeedListsQuestion(String language) {
    return 'Hozzáadjam a(z) $language alapértelmezett listákat?';
  }

  @override
  String get addAction => 'Hozzáadás';

  @override
  String get noAction => 'Nem';

  @override
  String get newLinesLabel => 'Új sor(ok)';

  @override
  String get newLinesHint => 'Soronként egy mondat';

  @override
  String get copyToList => 'Másolás listába…';

  @override
  String get moveToList => 'Áthelyezés listába…';

  @override
  String get chooseListTitle => 'Melyik listába?';

  @override
  String get editSentenceTitle => 'Mondat szerkesztése';

  @override
  String get sentenceDeleted => 'Mondat törölve';

  @override
  String get undoAction => 'Visszavonás';

  @override
  String get restoreDefaultSentences =>
      'Alapértelmezett mondatok visszaállítása';

  @override
  String get resetSaid => 'Újrakezdés';

  @override
  String get emptyEditorList => 'Még nincs mondat. Írj alább, soronként egyet.';
}
