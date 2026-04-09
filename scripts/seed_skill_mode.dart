// Seed script: inserts 50 German cards into skill_mode_cards.
// Run after migration: dart scripts/seed_skill_mode.dart
//
// MANUAL (Dhayan): Run this script after running the migration in Supabase SQL Editor.
// Requires SUPABASE_URL and SUPABASE_ANON_KEY environment variables,
// or modify the constants below.

// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:http/http.dart' as http;

const supabaseUrl = 'https://tipinjxdupfwntmkarkj.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRpcGluanhkdXBmd250bWthcmtqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2MTkwODYsImV4cCI6MjA5MDE5NTA4Nn0.kg2NuAJk1pFEpcXN0bbVma_xqMMjOIxcsNXlcLI8hhY';

Future<void> main() async {
  print('Seeding 50 German cards into skill_mode_cards...');

  final cards = <Map<String, dynamic>>[
    // ---- 20 Vocabulary word cards (A1) ----

    // Greetings
    _word('Hallo', 'Hello', pos: 'interjection', diff: 1, tags: ['greeting', 'a1']),
    _word('Guten Morgen', 'Good morning', pos: 'phrase', diff: 1, tags: ['greeting', 'a1']),
    _word('Gute Nacht', 'Good night', pos: 'phrase', diff: 1, tags: ['greeting', 'a1']),
    _word('Auf Wiedersehen', 'Goodbye', pos: 'phrase', diff: 1, tags: ['greeting', 'a1']),
    _word('Bitte', 'Please', pos: 'particle', diff: 1, tags: ['courtesy', 'a1']),
    _word('Danke', 'Thank you', pos: 'interjection', diff: 1, tags: ['courtesy', 'a1']),

    // Nouns with gender (der/die/das)
    _word('der Hund', 'the dog', pos: 'noun', diff: 1, tags: ['animal', 'a1'],
        grammar: {'pos': 'noun', 'gender': 'masculine', 'article': 'der'}),
    _word('die Katze', 'the cat', pos: 'noun', diff: 1, tags: ['animal', 'a1'],
        grammar: {'pos': 'noun', 'gender': 'feminine', 'article': 'die'}),
    _word('das Buch', 'the book', pos: 'noun', diff: 1, tags: ['object', 'a1'],
        grammar: {'pos': 'noun', 'gender': 'neuter', 'article': 'das'}),
    _word('die Mutter', 'the mother', pos: 'noun', diff: 1, tags: ['family', 'a1'],
        grammar: {'pos': 'noun', 'gender': 'feminine', 'article': 'die'}),
    _word('der Vater', 'the father', pos: 'noun', diff: 1, tags: ['family', 'a1'],
        grammar: {'pos': 'noun', 'gender': 'masculine', 'article': 'der'}),
    _word('der Bruder', 'the brother', pos: 'noun', diff: 1, tags: ['family', 'a1'],
        grammar: {'pos': 'noun', 'gender': 'masculine', 'article': 'der'}),
    _word('die Schwester', 'the sister', pos: 'noun', diff: 1, tags: ['family', 'a1'],
        grammar: {'pos': 'noun', 'gender': 'feminine', 'article': 'die'}),
    _word('das Haus', 'the house', pos: 'noun', diff: 1, tags: ['home', 'a1'],
        grammar: {'pos': 'noun', 'gender': 'neuter', 'article': 'das'}),

    // Colours
    _word('rot', 'red', pos: 'adjective', diff: 1, tags: ['colour', 'a1'],
        grammar: {'pos': 'adjective'}),
    _word('blau', 'blue', pos: 'adjective', diff: 1, tags: ['colour', 'a1'],
        grammar: {'pos': 'adjective'}),
    _word('grün', 'green', pos: 'adjective', diff: 1, tags: ['colour', 'a1'],
        grammar: {'pos': 'adjective'}),
    _word('weiß', 'white', pos: 'adjective', diff: 1, tags: ['colour', 'a1'],
        grammar: {'pos': 'adjective'}),

    // Numbers
    _word('eins', 'one', pos: 'numeral', diff: 1, tags: ['number', 'a1']),
    _word('zwei', 'two', pos: 'numeral', diff: 1, tags: ['number', 'a1']),

    // ---- 15 Sentence cards (4-7 tiles) — showcasing German word order ----

    // V2 rule: verb always second in main clause
    _sentence(
      'Ich habe eine Katze',
      'I have a cat',
      tiles: [
        {'word': 'Ich', 'type': 'standard', 'pos': 'pronoun', 'native': 'I'},
        {'word': 'habe', 'type': 'inflected', 'pos': 'verb', 'native': 'have'},
        {'word': 'eine', 'type': 'standard', 'pos': 'article', 'native': 'a'},
        {'word': 'Katze', 'type': 'standard', 'pos': 'noun', 'native': 'cat'},
      ],
      nativeOrder: [0, 1, 2, 3],
      foreignOrder: [0, 1, 2, 3],
      diff: 1,
      tags: ['present', 'a1'],
    ),
    _sentence(
      'Sie isst Äpfel',
      'She eats apples',
      tiles: [
        {'word': 'Sie', 'type': 'standard', 'pos': 'pronoun', 'native': 'She'},
        {'word': 'isst', 'type': 'inflected', 'pos': 'verb', 'native': 'eats'},
        {'word': 'Äpfel', 'type': 'standard', 'pos': 'noun', 'native': 'apples'},
      ],
      nativeOrder: [0, 1, 2],
      foreignOrder: [0, 1, 2],
      diff: 1,
      tags: ['present', 'a1'],
    ),
    _sentence(
      'Das Buch ist rot',
      'The book is red',
      tiles: [
        {'word': 'Das', 'type': 'standard', 'pos': 'article', 'native': 'The'},
        {'word': 'Buch', 'type': 'standard', 'pos': 'noun', 'native': 'book'},
        {'word': 'ist', 'type': 'inflected', 'pos': 'verb', 'native': 'is'},
        {'word': 'rot', 'type': 'standard', 'pos': 'adjective', 'native': 'red'},
      ],
      nativeOrder: [0, 1, 2, 3],
      foreignOrder: [0, 1, 2, 3],
      diff: 1,
      tags: ['sein', 'adjective', 'a1'],
    ),
    // Adjective before noun in German (same as English here)
    _sentence(
      'Wir wohnen in einem großen Haus',
      'We live in a big house',
      tiles: [
        {'word': 'Wir', 'type': 'standard', 'pos': 'pronoun', 'native': 'We'},
        {'word': 'wohnen', 'type': 'inflected', 'pos': 'verb', 'native': 'live'},
        {'word': 'in', 'type': 'standard', 'pos': 'preposition', 'native': 'in'},
        {'word': 'einem', 'type': 'standard', 'pos': 'article', 'native': 'a'},
        {'word': 'großen', 'type': 'inflected', 'pos': 'adjective', 'native': 'big'},
        {'word': 'Haus', 'type': 'standard', 'pos': 'noun', 'native': 'house'},
      ],
      nativeOrder: [0, 1, 2, 3, 4, 5],
      foreignOrder: [0, 1, 2, 3, 4, 5],
      diff: 2,
      tags: ['dative', 'adjective-declension', 'a1'],
      grammar: {'case': 'dative', 'note': 'in + dative = location'},
    ),
    // Accusative case
    _sentence(
      'Ich sehe den Hund',
      'I see the dog',
      tiles: [
        {'word': 'Ich', 'type': 'standard', 'pos': 'pronoun', 'native': 'I'},
        {'word': 'sehe', 'type': 'inflected', 'pos': 'verb', 'native': 'see'},
        {'word': 'den', 'type': 'standard', 'pos': 'article', 'native': 'the'},
        {'word': 'Hund', 'type': 'standard', 'pos': 'noun', 'native': 'dog'},
      ],
      nativeOrder: [0, 1, 2, 3],
      foreignOrder: [0, 1, 2, 3],
      diff: 2,
      tags: ['accusative', 'a1'],
      grammar: {'case': 'accusative', 'note': 'der → den in accusative'},
    ),
    // Separable verb: anfangen → Ich fange ... an
    _sentence(
      'Ich fange morgen an',
      'I start tomorrow',
      tiles: [
        {'word': 'Ich', 'type': 'standard', 'pos': 'pronoun', 'native': 'I'},
        {'word': 'fange', 'type': 'inflected', 'pos': 'verb', 'native': 'start'},
        {'word': 'morgen', 'type': 'standard', 'pos': 'adverb', 'native': 'tomorrow'},
        {'word': 'an', 'type': 'particle', 'pos': 'particle', 'native': '(prefix)'},
      ],
      nativeOrder: [0, 1, 2],
      foreignOrder: [0, 1, 2, 3],
      diff: 3,
      tags: ['separable-verb', 'particle', 'a2'],
      grammar: {'verb': 'anfangen', 'separable_prefix': 'an'},
    ),
    // Subordinate clause: verb goes to end
    _sentence(
      'Ich weiß, dass er Deutsch spricht',
      'I know that he speaks German',
      tiles: [
        {'word': 'Ich', 'type': 'standard', 'pos': 'pronoun', 'native': 'I'},
        {'word': 'weiß', 'type': 'inflected', 'pos': 'verb', 'native': 'know'},
        {'word': 'dass', 'type': 'particle', 'pos': 'conjunction', 'native': 'that'},
        {'word': 'er', 'type': 'standard', 'pos': 'pronoun', 'native': 'he'},
        {'word': 'Deutsch', 'type': 'standard', 'pos': 'noun', 'native': 'German'},
        {'word': 'spricht', 'type': 'inflected', 'pos': 'verb', 'native': 'speaks'},
      ],
      nativeOrder: [0, 1, 2, 3, 5, 4],
      foreignOrder: [0, 1, 2, 3, 4, 5],
      diff: 3,
      tags: ['subordinate', 'verb-final', 'a2'],
      grammar: {'note': 'dass sends verb to end of clause'},
    ),
    // Modal verb: können (can) — infinitive goes to end
    _sentence(
      'Ich kann Deutsch sprechen',
      'I can speak German',
      tiles: [
        {'word': 'Ich', 'type': 'standard', 'pos': 'pronoun', 'native': 'I'},
        {'word': 'kann', 'type': 'inflected', 'pos': 'verb', 'native': 'can'},
        {'word': 'Deutsch', 'type': 'standard', 'pos': 'noun', 'native': 'German'},
        {'word': 'sprechen', 'type': 'standard', 'pos': 'verb', 'native': 'speak'},
      ],
      nativeOrder: [0, 1, 3, 2],
      foreignOrder: [0, 1, 2, 3],
      diff: 2,
      tags: ['modal', 'infinitive-end', 'a1'],
      grammar: {'note': 'Modal verb second, infinitive at end'},
    ),
    // Dative: Ich gebe dem Mann das Buch
    _sentence(
      'Ich gebe dem Mann das Buch',
      'I give the man the book',
      tiles: [
        {'word': 'Ich', 'type': 'standard', 'pos': 'pronoun', 'native': 'I'},
        {'word': 'gebe', 'type': 'inflected', 'pos': 'verb', 'native': 'give'},
        {'word': 'dem', 'type': 'standard', 'pos': 'article', 'native': 'the'},
        {'word': 'Mann', 'type': 'standard', 'pos': 'noun', 'native': 'man'},
        {'word': 'das', 'type': 'standard', 'pos': 'article', 'native': 'the'},
        {'word': 'Buch', 'type': 'standard', 'pos': 'noun', 'native': 'book'},
      ],
      nativeOrder: [0, 1, 2, 3, 4, 5],
      foreignOrder: [0, 1, 2, 3, 4, 5],
      diff: 2,
      tags: ['dative', 'accusative', 'a2'],
      grammar: {'case': 'dative+accusative', 'note': 'dem = dative der, das = accusative das'},
    ),
    // Question with inversion
    _sentence(
      'Wo ist die Toilette',
      'Where is the toilet',
      tiles: [
        {'word': 'Wo', 'type': 'standard', 'pos': 'adverb', 'native': 'Where'},
        {'word': 'ist', 'type': 'inflected', 'pos': 'verb', 'native': 'is'},
        {'word': 'die', 'type': 'standard', 'pos': 'article', 'native': 'the'},
        {'word': 'Toilette', 'type': 'standard', 'pos': 'noun', 'native': 'toilet'},
      ],
      nativeOrder: [0, 1, 2, 3],
      foreignOrder: [0, 1, 2, 3],
      diff: 1,
      tags: ['question', 'travel', 'a1'],
    ),
    // Negation with nicht (position matters in German)
    _sentence(
      'Ich verstehe die Frage nicht',
      'I don\'t understand the question',
      tiles: [
        {'word': 'Ich', 'type': 'standard', 'pos': 'pronoun', 'native': 'I'},
        {'word': 'verstehe', 'type': 'inflected', 'pos': 'verb', 'native': 'understand'},
        {'word': 'die', 'type': 'standard', 'pos': 'article', 'native': 'the'},
        {'word': 'Frage', 'type': 'standard', 'pos': 'noun', 'native': 'question'},
        {'word': 'nicht', 'type': 'particle', 'pos': 'adverb', 'native': 'not'},
      ],
      nativeOrder: [0, 4, 1, 2, 3],
      foreignOrder: [0, 1, 2, 3, 4],
      diff: 2,
      tags: ['negation', 'particle', 'a1'],
      grammar: {'note': 'nicht goes after the object in German'},
    ),
    // Time-manner-place: Ich fahre heute mit dem Zug nach Berlin
    _sentence(
      'Ich fahre heute mit dem Zug nach Berlin',
      'I travel to Berlin by train today',
      tiles: [
        {'word': 'Ich', 'type': 'standard', 'pos': 'pronoun', 'native': 'I'},
        {'word': 'fahre', 'type': 'inflected', 'pos': 'verb', 'native': 'travel'},
        {'word': 'heute', 'type': 'standard', 'pos': 'adverb', 'native': 'today'},
        {'word': 'mit', 'type': 'standard', 'pos': 'preposition', 'native': 'by'},
        {'word': 'dem', 'type': 'standard', 'pos': 'article', 'native': 'the'},
        {'word': 'Zug', 'type': 'standard', 'pos': 'noun', 'native': 'train'},
        {'word': 'nach', 'type': 'standard', 'pos': 'preposition', 'native': 'to'},
        {'word': 'Berlin', 'type': 'standard', 'pos': 'noun', 'native': 'Berlin'},
      ],
      nativeOrder: [0, 1, 6, 7, 3, 4, 5, 2],
      foreignOrder: [0, 1, 2, 3, 4, 5, 6, 7],
      diff: 3,
      tags: ['time-manner-place', 'dative', 'a2'],
      grammar: {'note': 'German word order: Time-Manner-Place (heute-mit dem Zug-nach Berlin)'},
    ),
    // Separable verb: aufstehen
    _sentence(
      'Er steht um sechs Uhr auf',
      'He gets up at six o\'clock',
      tiles: [
        {'word': 'Er', 'type': 'standard', 'pos': 'pronoun', 'native': 'He'},
        {'word': 'steht', 'type': 'inflected', 'pos': 'verb', 'native': 'gets'},
        {'word': 'um', 'type': 'standard', 'pos': 'preposition', 'native': 'at'},
        {'word': 'sechs', 'type': 'standard', 'pos': 'numeral', 'native': 'six'},
        {'word': 'Uhr', 'type': 'standard', 'pos': 'noun', 'native': 'o\'clock'},
        {'word': 'auf', 'type': 'particle', 'pos': 'particle', 'native': '(prefix)'},
      ],
      nativeOrder: [0, 1, 5, 2, 3, 4],
      foreignOrder: [0, 1, 2, 3, 4, 5],
      diff: 3,
      tags: ['separable-verb', 'particle', 'a2'],
      grammar: {'verb': 'aufstehen', 'separable_prefix': 'auf'},
    ),
    // Perfect tense: haben + past participle at end
    _sentence(
      'Ich habe das Buch gelesen',
      'I have read the book',
      tiles: [
        {'word': 'Ich', 'type': 'standard', 'pos': 'pronoun', 'native': 'I'},
        {'word': 'habe', 'type': 'inflected', 'pos': 'verb', 'native': 'have'},
        {'word': 'das', 'type': 'standard', 'pos': 'article', 'native': 'the'},
        {'word': 'Buch', 'type': 'standard', 'pos': 'noun', 'native': 'book'},
        {'word': 'gelesen', 'type': 'inflected', 'pos': 'verb', 'native': 'read'},
      ],
      nativeOrder: [0, 1, 4, 2, 3],
      foreignOrder: [0, 1, 2, 3, 4],
      diff: 2,
      tags: ['perfect', 'past-participle', 'a2'],
      grammar: {'note': 'Perfect tense: auxiliary (habe) second, participle (gelesen) at end'},
    ),

    // ---- 10 Inflected verb card sets (present tense, 6 forms — for conjugation dial) ----

    _inflected('sprechen', 'to speak', forms: [
      'spreche', 'sprichst', 'spricht', 'sprechen', 'sprecht', 'sprechen',
    ], tags: ['strong-verb', 'present', 'a1']),
    _inflected('essen', 'to eat', forms: [
      'esse', 'isst', 'isst', 'essen', 'esst', 'essen',
    ], tags: ['strong-verb', 'present', 'a1']),
    _inflected('wohnen', 'to live', forms: [
      'wohne', 'wohnst', 'wohnt', 'wohnen', 'wohnt', 'wohnen',
    ], tags: ['weak-verb', 'present', 'a1']),
    _inflected('sein', 'to be', forms: [
      'bin', 'bist', 'ist', 'sind', 'seid', 'sind',
    ], tags: ['irregular', 'present', 'a1']),
    _inflected('haben', 'to have', forms: [
      'habe', 'hast', 'hat', 'haben', 'habt', 'haben',
    ], tags: ['irregular', 'present', 'a1']),
    _inflected('werden', 'to become', forms: [
      'werde', 'wirst', 'wird', 'werden', 'werdet', 'werden',
    ], tags: ['irregular', 'present', 'a1']),
    _inflected('gehen', 'to go', forms: [
      'gehe', 'gehst', 'geht', 'gehen', 'geht', 'gehen',
    ], tags: ['strong-verb', 'present', 'a1']),
    _inflected('machen', 'to do/make', forms: [
      'mache', 'machst', 'macht', 'machen', 'macht', 'machen',
    ], tags: ['weak-verb', 'present', 'a1']),
    _inflected('können', 'to be able to', forms: [
      'kann', 'kannst', 'kann', 'können', 'könnt', 'können',
    ], tags: ['modal', 'present', 'a2']),
    _inflected('wollen', 'to want', forms: [
      'will', 'willst', 'will', 'wollen', 'wollt', 'wollen',
    ], tags: ['modal', 'present', 'a2']),

    // ---- 5 Sentences with ghost/particle tiles ----

    // Impersonal "es" (ghost subject)
    _sentence(
      'Es regnet viel in London',
      'It rains a lot in London',
      tiles: [
        {'word': 'Es', 'type': 'ghost', 'pos': 'pronoun', 'native': 'It', 'is_ghost': true},
        {'word': 'regnet', 'type': 'inflected', 'pos': 'verb', 'native': 'rains'},
        {'word': 'viel', 'type': 'standard', 'pos': 'adverb', 'native': 'a lot'},
        {'word': 'in', 'type': 'standard', 'pos': 'preposition', 'native': 'in'},
        {'word': 'London', 'type': 'standard', 'pos': 'noun', 'native': 'London'},
      ],
      nativeOrder: [0, 1, 2, 3, 4],
      foreignOrder: [0, 1, 2, 3, 4],
      diff: 2,
      tags: ['weather', 'ghost', 'impersonal', 'a1'],
    ),
    // "Man" (impersonal pronoun — ghost-like)
    _sentence(
      'Hier spricht man Deutsch',
      'German is spoken here',
      tiles: [
        {'word': 'Hier', 'type': 'standard', 'pos': 'adverb', 'native': 'Here'},
        {'word': 'spricht', 'type': 'inflected', 'pos': 'verb', 'native': 'speaks'},
        {'word': 'man', 'type': 'ghost', 'pos': 'pronoun', 'native': 'one', 'is_ghost': true},
        {'word': 'Deutsch', 'type': 'standard', 'pos': 'noun', 'native': 'German'},
      ],
      nativeOrder: [3, 1, 0],
      foreignOrder: [0, 1, 2, 3],
      diff: 3,
      tags: ['impersonal', 'ghost', 'a2'],
      grammar: {'note': 'man = impersonal one/people; verb in V2 position'},
    ),
    // "Es gibt" (there is/are — idiomatic)
    _sentence(
      'Es gibt viele Studenten in der Klasse',
      'There are many students in the class',
      tiles: [
        {'word': 'Es', 'type': 'ghost', 'pos': 'pronoun', 'native': 'There', 'is_ghost': true},
        {'word': 'gibt', 'type': 'inflected', 'pos': 'verb', 'native': 'are'},
        {'word': 'viele', 'type': 'standard', 'pos': 'adjective', 'native': 'many'},
        {'word': 'Studenten', 'type': 'standard', 'pos': 'noun', 'native': 'students'},
        {'word': 'in', 'type': 'standard', 'pos': 'preposition', 'native': 'in'},
        {'word': 'der', 'type': 'standard', 'pos': 'article', 'native': 'the'},
        {'word': 'Klasse', 'type': 'standard', 'pos': 'noun', 'native': 'class'},
      ],
      nativeOrder: [0, 1, 2, 3, 4, 5, 6],
      foreignOrder: [0, 1, 2, 3, 4, 5, 6],
      diff: 2,
      tags: ['es-gibt', 'ghost', 'a1'],
    ),
    // Reflexive with sich
    _sentence(
      'Ich freue mich auf den Urlaub',
      'I look forward to the holiday',
      tiles: [
        {'word': 'Ich', 'type': 'standard', 'pos': 'pronoun', 'native': 'I'},
        {'word': 'freue', 'type': 'inflected', 'pos': 'verb', 'native': 'look forward'},
        {'word': 'mich', 'type': 'particle', 'pos': 'pronoun', 'native': 'myself'},
        {'word': 'auf', 'type': 'particle', 'pos': 'preposition', 'native': 'to'},
        {'word': 'den', 'type': 'standard', 'pos': 'article', 'native': 'the'},
        {'word': 'Urlaub', 'type': 'standard', 'pos': 'noun', 'native': 'holiday'},
      ],
      nativeOrder: [0, 1, 3, 4, 5],
      foreignOrder: [0, 1, 2, 3, 4, 5],
      diff: 3,
      tags: ['reflexive', 'particle', 'accusative', 'a2'],
      grammar: {'note': 'sich freuen auf + accusative = to look forward to'},
    ),
    // Separable verb in perfect tense: hat ... aufgemacht
    _sentence(
      'Er hat die Tür aufgemacht',
      'He opened the door',
      tiles: [
        {'word': 'Er', 'type': 'standard', 'pos': 'pronoun', 'native': 'He'},
        {'word': 'hat', 'type': 'inflected', 'pos': 'verb', 'native': 'has'},
        {'word': 'die', 'type': 'standard', 'pos': 'article', 'native': 'the'},
        {'word': 'Tür', 'type': 'standard', 'pos': 'noun', 'native': 'door'},
        {'word': 'aufgemacht', 'type': 'compound', 'pos': 'verb', 'native': 'opened'},
      ],
      nativeOrder: [0, 4, 2, 3],
      foreignOrder: [0, 1, 2, 3, 4],
      diff: 3,
      tags: ['perfect', 'separable-verb', 'compound', 'a2'],
      grammar: {'verb': 'aufmachen', 'note': 'Separable verbs rejoin in past participle: auf+ge+macht'},
    ),
  ];

  // Insert in batches of 10
  for (var i = 0; i < cards.length; i += 10) {
    final batch = cards.sublist(i, i + 10 > cards.length ? cards.length : i + 10);
    final response = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/skill_mode_cards'),
      headers: {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $supabaseAnonKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
      body: jsonEncode(batch),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('  Inserted batch ${(i ~/ 10) + 1} (${batch.length} cards)');
    } else {
      print('  ERROR batch ${(i ~/ 10) + 1}: ${response.statusCode} ${response.body}');
    }
  }

  print('Done! Seeded ${cards.length} German cards.');
}

// ---- Helpers ----

Map<String, dynamic> _word(
  String foreign,
  String native, {
  String? pos,
  int diff = 1,
  List<String> tags = const [],
  Map<String, dynamic>? grammar,
}) {
  return {
    'language': 'de',
    'foreign_text': foreign,
    'native_text': native,
    'tile_type': 'standard',
    'card_type': 'word',
    'difficulty': diff,
    'part_of_speech': pos,
    'grammar_metadata': grammar ?? {},
    'tile_config': {},
    'sentence_tiles': null,
    'native_word_order': null,
    'foreign_word_order': null,
    'tags': tags,
  };
}

Map<String, dynamic> _sentence(
  String foreign,
  String native, {
  required List<Map<String, dynamic>> tiles,
  required List<int> nativeOrder,
  required List<int> foreignOrder,
  int diff = 1,
  List<String> tags = const [],
  Map<String, dynamic>? grammar,
}) {
  return {
    'language': 'de',
    'foreign_text': foreign,
    'native_text': native,
    'tile_type': 'standard',
    'card_type': 'sentence',
    'difficulty': diff,
    'part_of_speech': null,
    'grammar_metadata': grammar ?? {},
    'tile_config': {},
    'sentence_tiles': tiles,
    'native_word_order': nativeOrder,
    'foreign_word_order': foreignOrder,
    'tags': tags,
  };
}

Map<String, dynamic> _inflected(
  String foreign,
  String native, {
  required List<String> forms,
  List<String> tags = const [],
}) {
  return {
    'language': 'de',
    'foreign_text': foreign,
    'native_text': native,
    'tile_type': 'inflected',
    'card_type': 'word',
    'difficulty': 2,
    'part_of_speech': 'verb',
    'grammar_metadata': {
      'pos': 'verb',
      'tense': 'present',
      'inflection_forms': forms,
      'form_labels': ['ich', 'du', 'er/sie/es', 'wir', 'ihr', 'sie/Sie'],
    },
    'tile_config': {
      'root': foreign,
      'suffix': '',
      'suffix_color': '#10B981',
    },
    'sentence_tiles': null,
    'native_word_order': null,
    'foreign_word_order': null,
    'tags': tags,
  };
}
