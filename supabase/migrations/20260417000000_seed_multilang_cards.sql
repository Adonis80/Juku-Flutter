-- SM-7: Seed sample cards for French, Russian, Arabic, Mandarin.
-- These are initial cards for testing. Full content will come from deck creators.

-- French (fr) — 10 cards
INSERT INTO skill_mode_cards (language, foreign_text, native_text, tile_type, card_type, difficulty, part_of_speech, grammar_metadata) VALUES
('fr', 'Bonjour', 'Hello', 'standard', 'word', 1, 'interjection', '{"note": "Universal greeting, used in formal and informal contexts"}'),
('fr', 'Merci', 'Thank you', 'standard', 'word', 1, 'interjection', '{"note": "Basic politeness — add beaucoup for emphasis"}'),
('fr', 'le chat', 'the cat', 'standard', 'word', 1, 'noun', '{"gender": "masculine", "note": "le = masculine definite article"}'),
('fr', 'la maison', 'the house', 'standard', 'word', 1, 'noun', '{"gender": "feminine", "note": "la = feminine definite article"}'),
('fr', 'je mange', 'I eat', 'inflected', 'word', 2, 'verb', '{"verb_group": "1st", "tense": "present", "note": "-er verbs: drop -er, add -e for je"}'),
('fr', 'tu parles', 'you speak', 'inflected', 'word', 2, 'verb', '{"verb_group": "1st", "tense": "present", "note": "-er verbs: add -es for tu"}'),
('fr', 'nous avons', 'we have', 'inflected', 'word', 2, 'verb', '{"tense": "present", "note": "avoir — irregular but essential"}'),
('fr', 'l''eau', 'the water', 'standard', 'word', 2, 'noun', '{"gender": "feminine", "elision": true, "note": "Elision: la → l'' before a vowel"}'),
('fr', 'les enfants', 'the children', 'standard', 'word', 2, 'noun', '{"note": "les = plural definite article (all genders)"}'),
('fr', 'il fait beau', 'the weather is nice', 'standard', 'sentence', 3, null, '{"note": "Impersonal il — il fait + adjective for weather"}');

-- Russian (ru) — 10 cards
INSERT INTO skill_mode_cards (language, foreign_text, native_text, tile_type, card_type, difficulty, part_of_speech, grammar_metadata) VALUES
('ru', E'\u041F\u0440\u0438\u0432\u0435\u0442', 'Hello (informal)', 'standard', 'word', 1, 'interjection', '{"note": "Informal greeting — use \u0417\u0434\u0440\u0430\u0432\u0441\u0442\u0432\u0443\u0439\u0442\u0435 for formal"}'),
('ru', E'\u0421\u043F\u0430\u0441\u0438\u0431\u043E', 'Thank you', 'standard', 'word', 1, 'interjection', '{"note": "Most common thanks — \u0411\u043E\u043B\u044C\u0448\u043E\u0435 \u0441\u043F\u0430\u0441\u0438\u0431\u043E for emphasis"}'),
('ru', E'\u043A\u043D\u0438\u0433\u0430', 'book', 'standard', 'word', 1, 'noun', '{"gender": "feminine", "case": "nominative", "note": "Feminine nouns often end in -\u0430 or -\u044F"}'),
('ru', E'\u0434\u043E\u043C', 'house', 'standard', 'word', 1, 'noun', '{"gender": "masculine", "case": "nominative", "note": "Masculine nouns often end in a consonant"}'),
('ru', E'\u043E\u043A\u043D\u043E', 'window', 'standard', 'word', 1, 'noun', '{"gender": "neuter", "case": "nominative", "note": "Neuter nouns often end in -\u043E or -\u0435"}'),
('ru', E'\u044F \u0447\u0438\u0442\u0430\u044E', 'I read', 'inflected', 'word', 2, 'verb', '{"aspect": "imperfective", "tense": "present", "note": "Imperfective — ongoing/habitual action"}'),
('ru', E'\u044F \u043F\u0440\u043E\u0447\u0438\u0442\u0430\u043B', 'I read (completed)', 'inflected', 'word', 2, 'verb', '{"aspect": "perfective", "tense": "past", "note": "Perfective — completed action. \u043F\u0440\u043E- prefix adds completion"}'),
('ru', E'\u043A\u043D\u0438\u0433\u0443', 'book (accusative)', 'standard', 'word', 2, 'noun', '{"gender": "feminine", "case": "accusative", "note": "Accusative: -\u0430 \u2192 -\u0443 for direct objects"}'),
('ru', E'\u0432 \u0434\u043E\u043C\u0435', 'in the house', 'standard', 'word', 2, 'noun', '{"gender": "masculine", "case": "prepositional", "note": "Prepositional case after \u0432 (in)"}'),
('ru', E'\u044F \u0438\u0434\u0443 \u0434\u043E\u043C\u043E\u0439', 'I am going home', 'standard', 'sentence', 3, null, '{"is_motion_verb": true, "note": "Motion verb \u0438\u0434\u0442\u0438 — directional (on foot)"}');

-- Arabic (ar) — 10 cards
INSERT INTO skill_mode_cards (language, foreign_text, native_text, tile_type, card_type, difficulty, part_of_speech, grammar_metadata) VALUES
('ar', E'\u0645\u0631\u062D\u0628\u0627', 'Hello', 'standard', 'word', 1, 'interjection', '{"note": "Universal Arabic greeting"}'),
('ar', E'\u0634\u0643\u0631\u0627', 'Thank you', 'standard', 'word', 1, 'interjection', '{"root": "\u0634-\u0643-\u0631", "note": "From root \u0634-\u0643-\u0631 (gratitude)"}'),
('ar', E'\u0643\u062A\u0627\u0628', 'book', 'standard', 'word', 1, 'noun', '{"root": "\u0643-\u062A-\u0628", "is_definite": false, "note": "Root \u0643-\u062A-\u0628 = writing. Pattern: \u0641\u0650\u0639\u0627\u0644"}'),
('ar', E'\u0627\u0644\u0643\u062A\u0627\u0628', 'the book', 'standard', 'word', 1, 'noun', '{"root": "\u0643-\u062A-\u0628", "is_definite": true, "is_sun_letter": false, "note": "\u0627\u0644 (al-) = definite article. \u0643 is a moon letter"}'),
('ar', E'\u0627\u0644\u0634\u0645\u0633', 'the sun', 'standard', 'word', 1, 'noun', '{"root": "\u0634-\u0645-\u0633", "is_definite": true, "is_sun_letter": true, "note": "Sun letter: \u0627\u0644 assimilates — pronounced ash-shams"}'),
('ar', E'\u0643\u062A\u0628', 'he wrote', 'inflected', 'word', 2, 'verb', '{"root": "\u0643-\u062A-\u0628", "verb_form": "I", "tense": "past", "note": "Form I (base form) past tense, 3rd person masculine"}'),
('ar', E'\u064A\u0643\u062A\u0628', 'he writes', 'inflected', 'word', 2, 'verb', '{"root": "\u0643-\u062A-\u0628", "verb_form": "I", "tense": "present", "note": "Present tense prefix \u064A- for 3rd person masculine"}'),
('ar', E'\u0627\u0633\u062A\u0643\u062A\u0628', 'he dictated', 'inflected', 'word', 3, 'verb', '{"root": "\u0643-\u062A-\u0628", "verb_form": "X", "tense": "past", "note": "Form X (\u0627\u0633\u062A\u0641\u0639\u0644) — to request/seek the action"}'),
('ar', E'\u0643\u0650\u062A\u0627\u0628\u064C', 'a book (nominative)', 'standard', 'word', 2, 'noun', '{"root": "\u0643-\u062A-\u0628", "case": "nominative", "note": "Nominative (marfu'') — tanwin \u064C for indefinite"}'),
('ar', E'\u0641\u064A \u0627\u0644\u0628\u064A\u062A', 'in the house', 'standard', 'sentence', 2, null, '{"case": "genitive", "note": "Preposition \u0641\u064A takes genitive (majrur)"}');

-- Mandarin (zh) — 10 cards
INSERT INTO skill_mode_cards (language, foreign_text, native_text, tile_type, card_type, difficulty, part_of_speech, grammar_metadata) VALUES
('zh', E'\u4F60\u597D', 'Hello', 'standard', 'word', 1, 'interjection', '{"pinyin": "n\u01D0 h\u01CEo", "tone": 3, "note": "Literally: you good. Tone 3 + tone 3 = tone 2 + tone 3 (sandhi)"}'),
('zh', E'\u8C22\u8C22', 'Thank you', 'standard', 'word', 1, 'interjection', '{"pinyin": "xi\u00E8xie", "tone": 4, "note": "Second \u8C22 is neutral tone in speech"}'),
('zh', E'\u4E66', 'book', 'standard', 'word', 1, 'noun', '{"pinyin": "sh\u016B", "tone": 1, "measure_word": "\u672C", "note": "Measure word: \u4E00\u672C\u4E66 (y\u00EC b\u011Bn sh\u016B)"}'),
('zh', E'\u732B', 'cat', 'standard', 'word', 1, 'noun', '{"pinyin": "m\u0101o", "tone": 1, "measure_word": "\u53EA", "note": "Measure word: \u4E00\u53EA\u732B (y\u00EC zh\u012B m\u0101o) — \u53EA for animals"}'),
('zh', E'\u5403', 'to eat', 'standard', 'word', 1, 'verb', '{"pinyin": "ch\u012B", "tone": 1, "note": "No conjugation in Chinese — context determines tense"}'),
('zh', E'\u6211\u5403\u4E86', 'I ate', 'standard', 'sentence', 2, null, '{"pinyin": "w\u01D2 ch\u012B le", "aspect_particle": "\u4E86", "note": "\u4E86 (le) = completed action particle"}'),
('zh', E'\u6211\u5728\u5403', 'I am eating', 'standard', 'sentence', 2, null, '{"pinyin": "w\u01D2 z\u00E0i ch\u012B", "note": "\u5728 (z\u00E0i) before verb = ongoing action (like -ing)"}'),
('zh', E'\u6211\u5403\u8FC7', 'I have eaten (before)', 'standard', 'sentence', 2, null, '{"pinyin": "w\u01D2 ch\u012B guo", "aspect_particle": "\u8FC7", "note": "\u8FC7 (guo) = experiential aspect — have done before"}'),
('zh', E'\u4E09\u672C\u4E66', 'three books', 'standard', 'sentence', 2, null, '{"pinyin": "s\u0101n b\u011Bn sh\u016B", "measure_word": "\u672C", "note": "Number + measure word + noun. \u672C for books/volumes"}'),
('zh', E'\u4ED6\u662F\u8001\u5E08', 'He is a teacher', 'standard', 'sentence', 2, null, '{"pinyin": "t\u0101 sh\u00EC l\u01CEosh\u012B", "note": "\u662F (sh\u00EC) = to be. No articles in Chinese"}');
