import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hu'),
  ];

  /// App name, shown in the app bar and task switcher.
  ///
  /// In hu, this message translates to:
  /// **'Mondom'**
  String get appTitle;

  /// Placeholder in the free-text field.
  ///
  /// In hu, this message translates to:
  /// **'Írj ide…'**
  String get textHint;

  /// Shown instead of the speak button while the voice model is loading.
  ///
  /// In hu, this message translates to:
  /// **'Betöltés…'**
  String get loading;

  /// Button that speaks the typed text.
  ///
  /// In hu, this message translates to:
  /// **'Mondom'**
  String get speak;

  /// Tooltip of the ✕ button that clears the text field.
  ///
  /// In hu, this message translates to:
  /// **'Szöveg törlése'**
  String get clearText;

  /// Timing line shown when the last phrase was replayed instead of synthesized.
  ///
  /// In hu, this message translates to:
  /// **'Újrajátszva (szintézis nélkül)'**
  String get replayed;

  /// Timing info: how long loading the voice model took.
  ///
  /// In hu, this message translates to:
  /// **'Modell betöltés: {ms} ms'**
  String modelLoadTime(int ms);

  /// Timing info for the last synthesis (real-time factor, RTF).
  ///
  /// In hu, this message translates to:
  /// **'Szintézis: {synthMs} ms, hang: {audioMs} ms, RTF: {rtf}'**
  String synthesisStats(int synthMs, int audioMs, String rtf);

  /// Cancels a running voice download.
  ///
  /// In hu, this message translates to:
  /// **'Mégse'**
  String get cancel;

  /// Title of the voice picker screen.
  ///
  /// In hu, this message translates to:
  /// **'Hang kiválasztása'**
  String get voicePickerTitle;

  /// Tooltip of the app bar icon that opens the voice picker.
  ///
  /// In hu, this message translates to:
  /// **'Hang kiválasztása'**
  String get voiceSettingsTooltip;

  /// Button at the top of the voice picker showing the chosen language.
  ///
  /// In hu, this message translates to:
  /// **'Nyelv: {name}'**
  String languageSelectorLabel(String name);

  /// Marker on a language in the language list: downloaded voices.
  ///
  /// In hu, this message translates to:
  /// **'{count} letöltve'**
  String installedVoicesCount(int count);

  /// System voice row: the engine knows the language but has no voice data.
  ///
  /// In hu, this message translates to:
  /// **'A hang nincs letöltve a telefonon.'**
  String get systemVoiceMissing;

  /// Button opening Android's voice data install screen.
  ///
  /// In hu, this message translates to:
  /// **'Letöltés az Android beállításaiban'**
  String get downloadInAndroidSettings;

  /// System voice row: the engine can't speak this language.
  ///
  /// In hu, this message translates to:
  /// **'A telefon nem tud ezen a nyelven beszélni.'**
  String get systemVoiceUnsupported;

  /// Name of the Android system TTS voice.
  ///
  /// In hu, this message translates to:
  /// **'Android alapértelmezett'**
  String get systemVoice;

  /// Subtitle of the system voice row.
  ///
  /// In hu, this message translates to:
  /// **'Azonnal működik, internet nélkül is'**
  String get systemVoiceInfo;

  /// Button that downloads a voice.
  ///
  /// In hu, this message translates to:
  /// **'Letöltés'**
  String get download;

  /// Button that selects an installed voice.
  ///
  /// In hu, this message translates to:
  /// **'Kiválasztás'**
  String get select;

  /// State label of the currently selected voice.
  ///
  /// In hu, this message translates to:
  /// **'Kiválasztva'**
  String get selected;

  /// Tooltip of the button that deletes a downloaded voice.
  ///
  /// In hu, this message translates to:
  /// **'Hang törlése'**
  String get deleteVoice;

  /// Tooltip of the sample play button.
  ///
  /// In hu, this message translates to:
  /// **'Minta meghallgatása'**
  String get playSample;

  /// Shown when a voice sample cannot be loaded.
  ///
  /// In hu, this message translates to:
  /// **'A minta nem érhető el'**
  String get sampleUnavailable;

  /// Shown when the voice catalog could not be fetched.
  ///
  /// In hu, this message translates to:
  /// **'A hangok letöltéséhez internet kell. Az Android alapértelmezett hang internet nélkül is működik.'**
  String get downloadsNeedInternet;

  /// Shown when a voice download fails.
  ///
  /// In hu, this message translates to:
  /// **'A letöltés nem sikerült. Ellenőrizd az internetkapcsolatot.'**
  String get downloadFailed;

  /// Voice gender.
  ///
  /// In hu, this message translates to:
  /// **'férfi'**
  String get genderMale;

  /// Voice gender.
  ///
  /// In hu, this message translates to:
  /// **'női'**
  String get genderFemale;

  /// Download size.
  ///
  /// In hu, this message translates to:
  /// **'{mb} MB'**
  String voiceSizeMb(int mb);

  /// Shown while a downloaded voice is verified and unpacked.
  ///
  /// In hu, this message translates to:
  /// **'Telepítés… (ez eltarthat egy ideig)'**
  String get installing;

  /// Title of the automatic history list (chip and list grid).
  ///
  /// In hu, this message translates to:
  /// **'Előzmények'**
  String get historyTitle;

  /// Tooltip of the ▾ button that shows all lists.
  ///
  /// In hu, this message translates to:
  /// **'Összes lista'**
  String get allLists;

  /// Tooltip of the app bar icon that opens the list editor.
  ///
  /// In hu, this message translates to:
  /// **'Szerkesztés'**
  String get editTooltip;

  /// Temporary message until the editing screen exists.
  ///
  /// In hu, this message translates to:
  /// **'A szerkesztés hamarosan elérhető.'**
  String get editComingSoon;

  /// Hint shown in an empty sentence list.
  ///
  /// In hu, this message translates to:
  /// **'Ez a lista üres. Szerkesztés: ✎'**
  String get emptyListHint;

  /// Dialog asking whether to add the default sentence lists of another language. The language name is lowercase in Hungarian.
  ///
  /// In hu, this message translates to:
  /// **'Hozzáadjam a(z) {language} alapértelmezett listákat?'**
  String addSeedListsQuestion(String language);

  /// Confirm button of the add-default-lists dialog.
  ///
  /// In hu, this message translates to:
  /// **'Hozzáadás'**
  String get addAction;

  /// Decline button of the add-default-lists dialog.
  ///
  /// In hu, this message translates to:
  /// **'Nem'**
  String get noAction;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hu':
      return AppLocalizationsHu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
