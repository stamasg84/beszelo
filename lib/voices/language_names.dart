/// Language names for the catalog languages (and a few likely ones), in the
/// UI languages. Unknown codes fall back to the code itself.
const _names = <String, Map<String, String>>{
  'hu': {'hu': 'Magyar', 'en': 'Hungarian'},
  'en': {'hu': 'Angol', 'en': 'English'},
  'sv': {'hu': 'Svéd', 'en': 'Swedish'},
  'de': {'hu': 'Német', 'en': 'German'},
  'fr': {'hu': 'Francia', 'en': 'French'},
  'es': {'hu': 'Spanyol', 'en': 'Spanish'},
  'it': {'hu': 'Olasz', 'en': 'Italian'},
  'ro': {'hu': 'Román', 'en': 'Romanian'},
  'sk': {'hu': 'Szlovák', 'en': 'Slovak'},
  'sr': {'hu': 'Szerb', 'en': 'Serbian'},
  'fi': {'hu': 'Finn', 'en': 'Finnish'},
  'uk': {'hu': 'Ukrán', 'en': 'Ukrainian'},
};

/// Each language's own name, so a user who can't read the UI language can
/// still find theirs.
const _nativeNames = <String, String>{
  'hu': 'Magyar',
  'en': 'English',
  'sv': 'Svenska',
  'de': 'Deutsch',
  'fr': 'Français',
  'es': 'Español',
  'it': 'Italiano',
  'ro': 'Română',
  'sk': 'Slovenčina',
  'sr': 'Српски',
  'fi': 'Suomi',
  'uk': 'Українська',
};

/// Name of language [code] in that language itself; unknown → the code.
String nativeLanguageName(String code) => _nativeNames[code] ?? code;

/// Name of language [code] in [uiLang] (`hu` or `en`; anything else is
/// treated as `en`), capitalized. With [midSentence], Hungarian names are
/// lowercased ("a svéd listák"); English names stay capitalized.
String languageName(String code, String uiLang, {bool midSentence = false}) {
  final names = _names[code];
  if (names == null) return code;
  final name = names[uiLang] ?? names['en']!;
  return midSentence && uiLang == 'hu' ? name.toLowerCase() : name;
}
