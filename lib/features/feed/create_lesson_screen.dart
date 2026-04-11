import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';

const _topics = [
  'grammar',
  'vocabulary',
  'culture',
  'pronunciation',
  'idioms',
  'slang',
  'writing',
  'listening',
  'tips',
  'other',
];

const _languagePairs = [
  'en-de',
  'en-ru',
  'en-ar',
  'en-zh',
  'de-en',
  'ru-en',
  'ar-en',
  'zh-en',
];

class CreateLessonScreen extends StatefulWidget {
  const CreateLessonScreen({super.key});

  @override
  State<CreateLessonScreen> createState() => _CreateLessonScreenState();
}

class _CreateLessonScreenState extends State<CreateLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _exampleCtrl = TextEditingController();

  String _topic = _topics.first;
  String _languagePair = _languagePairs.first;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _exampleCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _submitting = false);
      return;
    }

    try {
      await supabase.from('lessons').insert({
        'author_id': user.id,
        'title': _titleCtrl.text.trim(),
        'content': _contentCtrl.text.trim(),
        'example': _exampleCtrl.text.trim().isEmpty
            ? null
            : _exampleCtrl.text.trim(),
        'domain': 'languages',
        'topic': _topic,
        'language_pair': _languagePair,
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lesson created! +10 XP')));
        context.go('/feed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }

    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Lesson')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'A clear, catchy title for your lesson',
                ),
                maxLength: 120,
                validator: (v) {
                  if (v == null || v.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Topic dropdown
              DropdownButtonFormField<String>(
                initialValue: _topic,
                decoration: const InputDecoration(labelText: 'Topic'),
                items: _topics
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t[0].toUpperCase() + t.substring(1)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _topic = v);
                },
              ),
              const SizedBox(height: 12),

              // Language pair dropdown
              DropdownButtonFormField<String>(
                initialValue: _languagePair,
                decoration: const InputDecoration(labelText: 'Language Pair'),
                items: _languagePairs
                    .map(
                      (lp) => DropdownMenuItem(
                        value: lp,
                        child: Text(lp.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _languagePair = v);
                },
              ),
              const SizedBox(height: 12),

              // Content
              TextFormField(
                controller: _contentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText: 'Your lesson content — one idea, clearly explained',
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                maxLength: 2000,
                validator: (v) {
                  if (v == null || v.trim().length < 10) {
                    return 'Content must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Example (optional)
              TextFormField(
                controller: _exampleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Example (optional)',
                  hintText: 'A concrete example to illustrate your lesson',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 24),

              // Submit
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.publish),
                label: Text(_submitting ? 'Publishing...' : 'Publish Lesson'),
              ),

              const SizedBox(height: 8),
              Text(
                'You\'ll earn +10 XP for creating a lesson',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
