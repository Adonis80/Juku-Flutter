import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';
import '../../features/auth/auth_state.dart';

/// Song upload screen (SM-5.1).
///
/// Upload audio file, set metadata, store in R2 + Supabase.
class SmSongUploadScreen extends ConsumerStatefulWidget {
  const SmSongUploadScreen({super.key});

  @override
  ConsumerState<SmSongUploadScreen> createState() => _SmSongUploadScreenState();
}

class _SmSongUploadScreenState extends ConsumerState<SmSongUploadScreen> {
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  String _language = 'de';
  String? _audioPath;
  bool _uploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    // TODO: Use file_picker to select audio file.
    // For now, stub the path.
    setState(() => _audioPath = 'selected_audio.mp3');
  }

  Future<void> _upload() async {
    final user = ref.read(currentUserProvider);
    if (user == null ||
        _titleController.text.isEmpty ||
        _artistController.text.isEmpty) {
      return;
    }

    setState(() => _uploading = true);

    try {
      // Insert song record.
      await supabase.from('skill_mode_songs').insert({
        'uploaded_by': user.id,
        'title': _titleController.text,
        'artist': _artistController.text,
        'language': _language,
        'audio_url': '', // Updated after R2 upload.
        'play_count': 0,
        'line_count': 0,
      });

      // TODO(SM-5): Upload audio to R2 and update audio_url.

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Song uploaded!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Song')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Song Title',
                hintText: 'e.g. 99 Luftballons',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _artistController,
              decoration: const InputDecoration(
                labelText: 'Artist',
                hintText: 'e.g. Nena',
              ),
            ),
            const SizedBox(height: 16),

            // Language selector.
            DropdownButtonFormField<String>(
              initialValue: _language,
              decoration: const InputDecoration(labelText: 'Language'),
              items: const [
                DropdownMenuItem(value: 'de', child: Text('German')),
                DropdownMenuItem(value: 'es', child: Text('Spanish')),
                DropdownMenuItem(value: 'fr', child: Text('French')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (v) => setState(() => _language = v ?? 'de'),
            ),
            const SizedBox(height: 24),

            // Audio file picker.
            OutlinedButton.icon(
              onPressed: _pickAudio,
              icon: Icon(
                _audioPath != null ? Icons.check_circle : Icons.audio_file,
                color: _audioPath != null ? const Color(0xFF10B981) : null,
              ),
              label: Text(
                _audioPath != null ? 'Audio selected' : 'Select Audio File',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Supported: mp3, m4a, wav (max 15MB)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const Spacer(),

            // Upload button.
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    _uploading ||
                        _titleController.text.isEmpty ||
                        _artistController.text.isEmpty ||
                        _audioPath == null
                    ? null
                    : _upload,
                icon: _uploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload),
                label: const Text('Upload Song'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
