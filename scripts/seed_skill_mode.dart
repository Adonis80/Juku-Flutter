// Seed script: inserts 50 Spanish cards into skill_mode_cards.
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
  print('Seeding 50 Spanish cards into skill_mode_cards...');

  final cards = <Map<String, dynamic>>[
    // ---- 20 Vocabulary word cards (A1) ----

    // Greetings
    _word('Hola', 'Hello', pos: 'interjection', diff: 1, tags: ['greeting', 'a1']),
    _word('Buenos días', 'Good morning', pos: 'phrase', diff: 1, tags: ['greeting', 'a1']),
    _word('Buenas noches', 'Good night', pos: 'phrase', diff: 1, tags: ['greeting', 'a1']),
    _word('Adiós', 'Goodbye', pos: 'interjection', diff: 1, tags: ['greeting', 'a1']),
    _word('Por favor', 'Please', pos: 'phrase', diff: 1, tags: ['courtesy', 'a1']),
    _word('Gracias', 'Thank you', pos: 'interjection', diff: 1, tags: ['courtesy', 'a1']),

    // Numbers
    _word('Uno', 'One', pos: 'numeral', diff: 1, tags: ['number', 'a1']),
    _word('Dos', 'Two', pos: 'numeral', diff: 1, tags: ['number', 'a1']),
    _word('Tres', 'Three', pos: 'numeral', diff: 1, tags: ['number', 'a1']),
    _word('Diez', 'Ten', pos: 'numeral', diff: 1, tags: ['number', 'a1']),

    // Colours
    _word('Rojo', 'Red', pos: 'adjective', diff: 1, tags: ['colour', 'a1'],
        grammar: {'pos': 'adjective', 'gender': 'masculine'}),
    _word('Azul', 'Blue', pos: 'adjective', diff: 1, tags: ['colour', 'a1']),
    _word('Verde', 'Green', pos: 'adjective', diff: 1, tags: ['colour', 'a1']),
    _word('Blanco', 'White', pos: 'adjective', diff: 1, tags: ['colour', 'a1'],
        grammar: {'pos': 'adjective', 'gender': 'masculine'}),

    // Family
    _word('Madre', 'Mother', pos: 'noun', diff: 1, tags: ['family', 'a1'],
        grammar: {'pos': 'noun', 'gender': 'feminine'}),
    _word('Padre', 'Father', pos: 'noun', diff: 1, tags: ['family', 'a1'],
        grammar: {'pos': 'noun', 'gender': 'masculine'}),
    _word('Hermano', 'Brother', pos: 'noun', diff: 1, tags: ['family', 'a1'],
        grammar: {'pos': 'noun', 'gender': 'masculine'}),
    _word('Hermana', 'Sister', pos: 'noun', diff: 1, tags: ['family', 'a1'],
        grammar: {'pos': 'noun', 'gender': 'feminine'}),
    _word('Amigo', 'Friend', pos: 'noun', diff: 1, tags: ['social', 'a1'],
        grammar: {'pos': 'noun', 'gender': 'masculine'}),
    _word('Casa', 'House', pos: 'noun', diff: 1, tags: ['home', 'a1'],
        grammar: {'pos': 'noun', 'gender': 'feminine'}),

    // ---- 15 Sentence cards (4-6 tiles) ----

    _sentence(
      'Yo tengo un gato',
      'I have a cat',
      tiles: [
        {'word': 'Yo', 'type': 'standard', 'pos': 'pronoun', 'native': 'I'},
        {'word': 'tengo', 'type': 'inflected', 'pos': 'verb', 'native': 'have'},
        {'word': 'un', 'type': 'standard', 'pos': 'article', 'native': 'a'},
        {'word': 'gato', 'type': 'standard', 'pos': 'noun', 'native': 'cat'},
      ],
      nativeOrder: [0, 1, 2, 3],
      foreignOrder: [0, 1, 2, 3],
      diff: 1,
      tags: ['present', 'a1'],
    ),
    _sentence(
      'Ella come manzanas',
      'She eats apples',
      tiles: [
        {'word': 'Ella', 'type': 'standard', 'pos': 'pronoun', 'native': 'She'},
        {'word': 'come', 'type': 'inflected', 'pos': 'verb', 'native': 'eats'},
        {'word': 'manzanas', 'type': 'standard', 'pos': 'noun', 'native': 'apples'},
      ],
      nativeOrder: [0, 1, 2],
      foreignOrder: [0, 1, 2],
      diff: 1,
      tags: ['present', 'a1'],
    ),
    _sentence(
      'El libro es rojo',
      'The book is red',
      tiles: [
        {'word': 'El', 'type': 'standard', 'pos': 'article', 'native': 'The'},
        {'word': 'libro', 'type': 'standard', 'pos': 'noun', 'native': 'book'},
        {'word': 'es', 'type': 'inflected', 'pos': 'verb', 'native': 'is'},
        {'word': 'rojo', 'type': 'standard', 'pos': 'adjective', 'native': 'red'},
      ],
      nativeOrder: [0, 1, 2, 3],
      foreignOrder: [0, 1, 2, 3],
      diff: 1,
      tags: ['ser', 'adjective', 'a1'],
    ),
    _sentence(
      'Nosotros vivimos en una casa grande',
      'We live in a big house',
      tiles: [
        {'word': 'Nosotros', 'type': 'standard', 'pos': 'pronoun', 'native': 'We'},
        {'word': 'vivimos', 'type': 'inflected', 'pos': 'verb', 'native': 'live'},
        {'word': 'en', 'type': 'standard', 'pos': 'preposition', 'native': 'in'},
        {'word': 'una', 'type': 'standard', 'pos': 'article', 'native': 'a'},
        {'word': 'casa', 'type': 'standard', 'pos': 'noun', 'native': 'house'},
        {'word': 'grande', 'type': 'standard', 'pos': 'adjective', 'native': 'big'},
      ],
      nativeOrder: [0, 1, 2, 3, 5, 4],  // "a big house" → "una casa grande"
      foreignOrder: [0, 1, 2, 3, 4, 5],
      diff: 2,
      tags: ['present', 'adjective-position', 'a1'],
    ),
    _sentence(
      'Me gusta el café',
      'I like coffee',
      tiles: [
        {'word': 'Me', 'type': 'particle', 'pos': 'pronoun', 'native': 'to me', 'is_ghost': false},
        {'word': 'gusta', 'type': 'inflected', 'pos': 'verb', 'native': 'is pleasing'},
        {'word': 'el', 'type': 'ghost', 'pos': 'article', 'native': '', 'is_ghost': true},
        {'word': 'café', 'type': 'standard', 'pos': 'noun', 'native': 'coffee'},
      ],
      nativeOrder: [3, 1, 0],
      foreignOrder: [0, 1, 2, 3],
      diff: 2,
      tags: ['gustar', 'ghost', 'a1'],
    ),
    _sentence(
      'Ellos tienen dos perros',
      'They have two dogs',
      tiles: [
        {'word': 'Ellos', 'type': 'standard', 'pos': 'pronoun', 'native': 'They'},
        {'word': 'tienen', 'type': 'inflected', 'pos': 'verb', 'native': 'have'},
        {'word': 'dos', 'type': 'standard', 'pos': 'numeral', 'native': 'two'},
        {'word': 'perros', 'type': 'standard', 'pos': 'noun', 'native': 'dogs'},
      ],
      nativeOrder: [0, 1, 2, 3],
      foreignOrder: [0, 1, 2, 3],
      diff: 1,
      tags: ['present', 'tener', 'a1'],
    ),
    _sentence(
      'Quiero aprender español',
      'I want to learn Spanish',
      tiles: [
        {'word': 'Quiero', 'type': 'inflected', 'pos': 'verb', 'native': 'I want'},
        {'word': 'aprender', 'type': 'standard', 'pos': 'verb', 'native': 'to learn'},
        {'word': 'español', 'type': 'standard', 'pos': 'noun', 'native': 'Spanish'},
      ],
      nativeOrder: [0, 1, 2],
      foreignOrder: [0, 1, 2],
      diff: 2,
      tags: ['infinitive', 'a1'],
    ),
    _sentence(
      'La niña está contenta',
      'The girl is happy',
      tiles: [
        {'word': 'La', 'type': 'standard', 'pos': 'article', 'native': 'The'},
        {'word': 'niña', 'type': 'standard', 'pos': 'noun', 'native': 'girl'},
        {'word': 'está', 'type': 'inflected', 'pos': 'verb', 'native': 'is'},
        {'word': 'contenta', 'type': 'inflected', 'pos': 'adjective', 'native': 'happy'},
      ],
      nativeOrder: [0, 1, 2, 3],
      foreignOrder: [0, 1, 2, 3],
      diff: 2,
      tags: ['estar', 'adjective-agreement', 'a1'],
    ),
    _sentence(
      'Voy al supermercado',
      'I go to the supermarket',
      tiles: [
        {'word': 'Voy', 'type': 'inflected', 'pos': 'verb', 'native': 'I go'},
        {'word': 'al', 'type': 'compound', 'pos': 'preposition', 'native': 'to the'},
        {'word': 'supermercado', 'type': 'standard', 'pos': 'noun', 'native': 'supermarket'},
      ],
      nativeOrder: [0, 1, 2],
      foreignOrder: [0, 1, 2],
      diff: 2,
      tags: ['ir', 'contraction', 'a1'],
    ),
    _sentence(
      'Mi hermano es más alto que yo',
      'My brother is taller than me',
      tiles: [
        {'word': 'Mi', 'type': 'standard', 'pos': 'determiner', 'native': 'My'},
        {'word': 'hermano', 'type': 'standard', 'pos': 'noun', 'native': 'brother'},
        {'word': 'es', 'type': 'inflected', 'pos': 'verb', 'native': 'is'},
        {'word': 'más', 'type': 'particle', 'pos': 'adverb', 'native': 'more'},
        {'word': 'alto', 'type': 'standard', 'pos': 'adjective', 'native': 'tall'},
        {'word': 'que', 'type': 'particle', 'pos': 'conjunction', 'native': 'than'},
        {'word': 'yo', 'type': 'standard', 'pos': 'pronoun', 'native': 'me'},
      ],
      nativeOrder: [0, 1, 2, 4, 5, 6],
      foreignOrder: [0, 1, 2, 3, 4, 5, 6],
      diff: 3,
      tags: ['comparatives', 'particle', 'a2'],
    ),
    _sentence(
      'Puedes hablar más despacio',
      'Can you speak more slowly',
      tiles: [
        {'word': 'Puedes', 'type': 'inflected', 'pos': 'verb', 'native': 'Can you'},
        {'word': 'hablar', 'type': 'standard', 'pos': 'verb', 'native': 'speak'},
        {'word': 'más', 'type': 'particle', 'pos': 'adverb', 'native': 'more'},
        {'word': 'despacio', 'type': 'standard', 'pos': 'adverb', 'native': 'slowly'},
      ],
      nativeOrder: [0, 1, 2, 3],
      foreignOrder: [0, 1, 2, 3],
      diff: 2,
      tags: ['poder', 'travel', 'a1'],
    ),
    _sentence(
      'Dónde está el baño',
      'Where is the bathroom',
      tiles: [
        {'word': 'Dónde', 'type': 'standard', 'pos': 'adverb', 'native': 'Where'},
        {'word': 'está', 'type': 'inflected', 'pos': 'verb', 'native': 'is'},
        {'word': 'el', 'type': 'standard', 'pos': 'article', 'native': 'the'},
        {'word': 'baño', 'type': 'standard', 'pos': 'noun', 'native': 'bathroom'},
      ],
      nativeOrder: [0, 1, 2, 3],
      foreignOrder: [0, 1, 2, 3],
      diff: 1,
      tags: ['question', 'travel', 'a1'],
    ),
    _sentence(
      'No entiendo la pregunta',
      'I don\'t understand the question',
      tiles: [
        {'word': 'No', 'type': 'particle', 'pos': 'adverb', 'native': 'don\'t'},
        {'word': 'entiendo', 'type': 'inflected', 'pos': 'verb', 'native': 'I understand'},
        {'word': 'la', 'type': 'standard', 'pos': 'article', 'native': 'the'},
        {'word': 'pregunta', 'type': 'standard', 'pos': 'noun', 'native': 'question'},
      ],
      nativeOrder: [1, 0, 2, 3],
      foreignOrder: [0, 1, 2, 3],
      diff: 2,
      tags: ['negation', 'particle', 'a1'],
    ),
    _sentence(
      'Hace buen tiempo hoy',
      'The weather is nice today',
      tiles: [
        {'word': 'Hace', 'type': 'inflected', 'pos': 'verb', 'native': 'It makes'},
        {'word': 'buen', 'type': 'standard', 'pos': 'adjective', 'native': 'good'},
        {'word': 'tiempo', 'type': 'standard', 'pos': 'noun', 'native': 'weather'},
        {'word': 'hoy', 'type': 'standard', 'pos': 'adverb', 'native': 'today'},
      ],
      nativeOrder: [2, 0, 1, 3],
      foreignOrder: [0, 1, 2, 3],
      diff: 2,
      tags: ['hacer', 'weather', 'a1'],
    ),

    // ---- 10 Inflected verb card sets (present tense, 6 forms — for conjugation dial) ----

    _inflected('hablar', 'to speak', forms: [
      'hablo', 'hablas', 'habla', 'hablamos', 'habláis', 'hablan',
    ], tags: ['ar-verb', 'present', 'a1']),
    _inflected('comer', 'to eat', forms: [
      'como', 'comes', 'come', 'comemos', 'coméis', 'comen',
    ], tags: ['er-verb', 'present', 'a1']),
    _inflected('vivir', 'to live', forms: [
      'vivo', 'vives', 'vive', 'vivimos', 'vivís', 'viven',
    ], tags: ['ir-verb', 'present', 'a1']),
    _inflected('ser', 'to be (permanent)', forms: [
      'soy', 'eres', 'es', 'somos', 'sois', 'son',
    ], tags: ['irregular', 'present', 'a1']),
    _inflected('estar', 'to be (temporary)', forms: [
      'estoy', 'estás', 'está', 'estamos', 'estáis', 'están',
    ], tags: ['irregular', 'present', 'a1']),
    _inflected('tener', 'to have', forms: [
      'tengo', 'tienes', 'tiene', 'tenemos', 'tenéis', 'tienen',
    ], tags: ['irregular', 'present', 'a1']),
    _inflected('ir', 'to go', forms: [
      'voy', 'vas', 'va', 'vamos', 'vais', 'van',
    ], tags: ['irregular', 'present', 'a1']),
    _inflected('hacer', 'to do/make', forms: [
      'hago', 'haces', 'hace', 'hacemos', 'hacéis', 'hacen',
    ], tags: ['irregular', 'present', 'a1']),
    _inflected('poder', 'to be able to', forms: [
      'puedo', 'puedes', 'puede', 'podemos', 'podéis', 'pueden',
    ], tags: ['stem-change', 'present', 'a2']),
    _inflected('querer', 'to want', forms: [
      'quiero', 'quieres', 'quiere', 'queremos', 'queréis', 'quieren',
    ], tags: ['stem-change', 'present', 'a2']),

    // ---- 5 Sentences with ghost/particle tiles ----

    _sentence(
      'Llueve mucho en Londres',
      'It rains a lot in London',
      tiles: [
        {'word': 'Llueve', 'type': 'inflected', 'pos': 'verb', 'native': 'It rains'},
        {'word': 'mucho', 'type': 'standard', 'pos': 'adverb', 'native': 'a lot'},
        {'word': 'en', 'type': 'standard', 'pos': 'preposition', 'native': 'in'},
        {'word': 'Londres', 'type': 'standard', 'pos': 'noun', 'native': 'London'},
      ],
      nativeOrder: [0, 1, 2, 3],
      foreignOrder: [0, 1, 2, 3],
      diff: 2,
      tags: ['weather', 'null-subject', 'ghost', 'a1'],
    ),
    _sentence(
      'Se habla español aquí',
      'Spanish is spoken here',
      tiles: [
        {'word': 'Se', 'type': 'ghost', 'pos': 'pronoun', 'native': '', 'is_ghost': true},
        {'word': 'habla', 'type': 'inflected', 'pos': 'verb', 'native': 'is spoken'},
        {'word': 'español', 'type': 'standard', 'pos': 'noun', 'native': 'Spanish'},
        {'word': 'aquí', 'type': 'standard', 'pos': 'adverb', 'native': 'here'},
      ],
      nativeOrder: [2, 1, 3],
      foreignOrder: [0, 1, 2, 3],
      diff: 3,
      tags: ['passive-se', 'ghost', 'a2'],
    ),
    _sentence(
      'Hay muchos estudiantes en la clase',
      'There are many students in the class',
      tiles: [
        {'word': 'Hay', 'type': 'ghost', 'pos': 'verb', 'native': 'There are', 'is_ghost': true},
        {'word': 'muchos', 'type': 'standard', 'pos': 'adjective', 'native': 'many'},
        {'word': 'estudiantes', 'type': 'standard', 'pos': 'noun', 'native': 'students'},
        {'word': 'en', 'type': 'standard', 'pos': 'preposition', 'native': 'in'},
        {'word': 'la', 'type': 'standard', 'pos': 'article', 'native': 'the'},
        {'word': 'clase', 'type': 'standard', 'pos': 'noun', 'native': 'class'},
      ],
      nativeOrder: [0, 1, 2, 3, 4, 5],
      foreignOrder: [0, 1, 2, 3, 4, 5],
      diff: 2,
      tags: ['hay', 'ghost', 'a1'],
    ),
    _sentence(
      'A mí no me gustan las verduras',
      'I don\'t like vegetables',
      tiles: [
        {'word': 'A mí', 'type': 'particle', 'pos': 'pronoun', 'native': 'As for me', 'is_ghost': false},
        {'word': 'no', 'type': 'particle', 'pos': 'adverb', 'native': 'not'},
        {'word': 'me', 'type': 'particle', 'pos': 'pronoun', 'native': 'to me'},
        {'word': 'gustan', 'type': 'inflected', 'pos': 'verb', 'native': 'are pleasing'},
        {'word': 'las', 'type': 'ghost', 'pos': 'article', 'native': '', 'is_ghost': true},
        {'word': 'verduras', 'type': 'standard', 'pos': 'noun', 'native': 'vegetables'},
      ],
      nativeOrder: [5, 3, 2, 1, 0],
      foreignOrder: [0, 1, 2, 3, 4, 5],
      diff: 3,
      tags: ['gustar', 'negation', 'ghost', 'particle', 'a2'],
    ),
    _sentence(
      'Tengo que irme ahora',
      'I have to leave now',
      tiles: [
        {'word': 'Tengo', 'type': 'inflected', 'pos': 'verb', 'native': 'I have'},
        {'word': 'que', 'type': 'particle', 'pos': 'conjunction', 'native': 'to'},
        {'word': 'irme', 'type': 'compound', 'pos': 'verb', 'native': 'leave'},
        {'word': 'ahora', 'type': 'standard', 'pos': 'adverb', 'native': 'now'},
      ],
      nativeOrder: [0, 1, 2, 3],
      foreignOrder: [0, 1, 2, 3],
      diff: 2,
      tags: ['tener-que', 'reflexive', 'particle', 'a2'],
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

  print('Done! Seeded ${cards.length} Spanish cards.');
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
    'language': 'es',
    'foreign_text': foreign,
    'native_text': native,
    'tile_type': 'standard',
    'card_type': 'word',
    'difficulty': diff,
    'part_of_speech': pos,
    'grammar_metadata': grammar ?? {},
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
}) {
  return {
    'language': 'es',
    'foreign_text': foreign,
    'native_text': native,
    'tile_type': 'standard',
    'card_type': 'sentence',
    'difficulty': diff,
    'sentence_tiles': tiles,
    'native_word_order': nativeOrder,
    'foreign_word_order': foreignOrder,
    'grammar_metadata': {},
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
    'language': 'es',
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
      'form_labels': ['yo', 'tú', 'él/ella', 'nosotros', 'vosotros', 'ellos'],
    },
    'tile_config': {
      'root': foreign,
      'suffix': '',
      'suffix_color': '#10B981',
    },
    'tags': tags,
  };
}
