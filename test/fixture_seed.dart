import 'package:mondom/storage/database.dart' show ListKind;
import 'package:mondom/storage/seed.dart';

/// Small in-code seed for tests, so they don't depend on the shipped
/// `assets/seed/*.json` (those get edited freely). Languages: hu, en, sv;
/// anything else throws, like a missing seed file.
Future<Seed> fixtureSeed(String lang) async {
  final seed = _seeds[lang];
  if (seed == null) throw Exception('no seed $lang');
  return seed;
}

SeedList _everyday(String title, List<String> texts) => SeedList(
  seedKey: 'everyday',
  title: title,
  kind: ListKind.everyday,
  pinned: true,
  color: 'blue',
  sentences: [
    for (var i = 0; i < texts.length; i++)
      SeedSentence(_everydayKeys[i], texts[i]),
  ],
);

SeedList _conversation(String title, List<String> texts) => SeedList(
  seedKey: 'example-conversation',
  title: title,
  kind: ListKind.conversation,
  pinned: false,
  color: 'orange',
  sentences: [
    for (var i = 0; i < texts.length; i++)
      SeedSentence(_conversationKeys[i], texts[i]),
  ],
);

const _everydayKeys = ['water', 'food', 'drink', 'stand', 'wait', 'yes'];
const _conversationKeys = ['bulb', 'cheese', 'school'];

final _seeds = <String, Seed>{
  'hu': Seed(historyTitle: 'Előzmények', [
    _everyday('Alap', [
      'Kérek vizet!',
      'Éhes vagyok.',
      'Szomjas vagyok.',
      'Segíts felállni!',
      'Várj, gépelek.',
      'Igen.',
    ]),
    _conversation('Példa beszélgetés', [
      'Ki kéne cserélni a villanykörtét.',
      'Légyszi vegyetek a boltban trappistát!',
      'Mi újság a suliban?',
    ]),
  ]),
  'en': Seed(historyTitle: 'History', [
    _everyday('Basics', [
      "I'd like some water, please!",
      "I'm hungry.",
      "I'm thirsty.",
      'Help me stand up!',
      "Wait, I'm typing.",
      'Yes.',
    ]),
    _conversation('Example conversation', [
      'The light bulb needs changing.',
      'Please pick up some cheddar at the shop!',
      "How's school going?",
    ]),
  ]),
  'sv': Seed(historyTitle: 'Historik', [
    _everyday('Grunder', [
      'Jag vill ha vatten, tack!',
      'Jag är hungrig.',
      'Jag är törstig.',
      'Hjälp mig att resa mig!',
      'Vänta, jag skriver.',
      'Ja.',
    ]),
    _conversation('Exempelsamtal', [
      'Glödlampan behöver bytas.',
      'Köp lite ost i affären, tack!',
      'Hur går det i skolan?',
    ]),
  ]),
};
