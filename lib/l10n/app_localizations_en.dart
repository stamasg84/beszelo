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
  String get clearText => 'Clear text';

  @override
  String get replayed => 'Replayed (no synthesis)';

  @override
  String modelLoadTime(int ms) {
    return 'Model load: $ms ms';
  }

  @override
  String synthesisStats(int synthMs, int audioMs, String rtf) {
    return 'Synthesis: $synthMs ms, audio: $audioMs ms, RTF: $rtf';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get voicePickerTitle => 'Choose a voice';

  @override
  String get voiceSettingsTooltip => 'Choose a voice';

  @override
  String languageSelectorLabel(String name) {
    return 'Language: $name';
  }

  @override
  String installedVoicesCount(int count) {
    return '$count downloaded';
  }

  @override
  String get systemVoiceMissing => 'The voice isn\'t downloaded on this phone.';

  @override
  String get downloadInAndroidSettings => 'Download in Android settings';

  @override
  String get systemVoiceUnsupported => 'This phone can\'t speak this language.';

  @override
  String get systemVoice => 'Android default';

  @override
  String get systemVoiceInfo => 'Works right away, even offline';

  @override
  String get download => 'Download';

  @override
  String get select => 'Select';

  @override
  String get selected => 'Selected';

  @override
  String get deleteVoice => 'Delete voice';

  @override
  String get playSample => 'Play sample';

  @override
  String get sampleUnavailable => 'The sample is not available';

  @override
  String get downloadsNeedInternet =>
      'Downloading voices needs internet. The Android default voice works offline.';

  @override
  String get downloadFailed =>
      'The download failed. Check your internet connection.';

  @override
  String get genderMale => 'male';

  @override
  String get genderFemale => 'female';

  @override
  String voiceSizeMb(int mb) {
    return '$mb MB';
  }

  @override
  String get installing => 'Installing… (this can take a while)';

  @override
  String get historyTitle => 'History';

  @override
  String get allLists => 'All lists';

  @override
  String get editTooltip => 'Edit';

  @override
  String get editComingSoon => 'Editing is coming soon.';

  @override
  String get emptyListHint => 'This list is empty. Edit: ✎';

  @override
  String addSeedListsQuestion(String language) {
    return 'Add the default $language lists?';
  }

  @override
  String get addAction => 'Add';

  @override
  String get noAction => 'No';
}
