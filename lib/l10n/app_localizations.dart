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

  /// Hint shown in an empty sentence list.
  ///
  /// In hu, this message translates to:
  /// **'Ez a lista üres. Szerkesztés: ⚙ Beállítások → Listák'**
  String get emptyListHint;

  /// Tooltip of the cog in the speaking screen's app bar, and title of the settings screen.
  ///
  /// In hu, this message translates to:
  /// **'Beállítások'**
  String get settingsTooltip;

  /// Settings row opening the voice picker.
  ///
  /// In hu, this message translates to:
  /// **'Hang és nyelv'**
  String get settingsVoiceTitle;

  /// Subtitle of the voice row: current voice and its language.
  ///
  /// In hu, this message translates to:
  /// **'{voice} · {language}'**
  String settingsVoiceSubtitle(String voice, String language);

  /// Settings row opening the lists overview; also its screen title.
  ///
  /// In hu, this message translates to:
  /// **'Listák'**
  String get settingsListsTitle;

  /// Subtitle of the lists row.
  ///
  /// In hu, this message translates to:
  /// **'Listák és mondatok szerkesztése'**
  String get settingsListsSubtitle;

  /// Marker on a list that has a chip on the speaking screen.
  ///
  /// In hu, this message translates to:
  /// **'Kitűzve'**
  String get pinnedLabel;

  /// Number of sentences in a list.
  ///
  /// In hu, this message translates to:
  /// **'{count} mondat'**
  String sentenceCount(int count);

  /// Marker on the list that is open on the speaking screen.
  ///
  /// In hu, this message translates to:
  /// **'Most megnyitva'**
  String get currentlyOpen;

  /// Semantics label of the drag handle of a list row.
  ///
  /// In hu, this message translates to:
  /// **'Mozgatás'**
  String get reorderHandle;

  /// Tooltip of the ⋮ button of a list row.
  ///
  /// In hu, this message translates to:
  /// **'További műveletek'**
  String get moreActions;

  /// List action: rename.
  ///
  /// In hu, this message translates to:
  /// **'Átnevezés'**
  String get renameList;

  /// List action: pin to the chip row.
  ///
  /// In hu, this message translates to:
  /// **'Kitűzés'**
  String get pinList;

  /// List action: remove from the chip row.
  ///
  /// In hu, this message translates to:
  /// **'Kitűzés megszüntetése'**
  String get unpinList;

  /// List action: delete.
  ///
  /// In hu, this message translates to:
  /// **'Törlés'**
  String get deleteList;

  /// Confirmation before deleting a list.
  ///
  /// In hu, this message translates to:
  /// **'Törlöd a(z) „{title}” listát és a {count} mondatát?'**
  String deleteListQuestion(String title, int count);

  /// Confirm button of a delete dialog.
  ///
  /// In hu, this message translates to:
  /// **'Törlés'**
  String get deleteAction;

  /// Confirm button of the rename dialog.
  ///
  /// In hu, this message translates to:
  /// **'Mentés'**
  String get saveAction;

  /// Button and dialog title for creating a list.
  ///
  /// In hu, this message translates to:
  /// **'Új lista'**
  String get newList;

  /// Name field of the new list / rename dialogs.
  ///
  /// In hu, this message translates to:
  /// **'A lista neve'**
  String get listNameLabel;

  /// List kind: plain sentence list.
  ///
  /// In hu, this message translates to:
  /// **'Mondatlista'**
  String get kindEveryday;

  /// List kind: prepared conversation.
  ///
  /// In hu, this message translates to:
  /// **'Beszélgetés'**
  String get kindConversation;

  /// Explains the conversation list kind.
  ///
  /// In hu, this message translates to:
  /// **'Előre megírt mondatok, Következő gombbal'**
  String get kindConversationInfo;

  /// Confirm button of the new list dialog.
  ///
  /// In hu, this message translates to:
  /// **'Létrehozás'**
  String get createAction;

  /// Row that re-creates deleted default lists.
  ///
  /// In hu, this message translates to:
  /// **'Alapértelmezett listák visszaállítása'**
  String get restoreDefaultLists;

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
