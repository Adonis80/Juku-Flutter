import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';

/// Reusable image upload widget for Studio builder.
/// Shows an "Add image" button that opens a bottom sheet (gallery/URL).
/// Uploads to Supabase Storage `studio-images/[userId]/[uuid].jpg`.
/// Returns the public URL of the uploaded image.
class StudioImageUpload extends StatefulWidget {
  final String? currentImageUrl;
  final ValueChanged<String?> onImageChanged;
  final double height;

  const StudioImageUpload({
    super.key,
    this.currentImageUrl,
    required this.onImageChanged,
    this.height = 120,
  });

  @override
  State<StudioImageUpload> createState() => _StudioImageUploadState();
}

class _StudioImageUploadState extends State<StudioImageUpload> {
  bool _uploading = false;
  String? _imageUrl;
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.currentImageUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (picked == null) return;
    await _upload(File(picked.path));
  }

  Future<void> _upload(File file) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _uploading = true);

    try {
      final ext = file.path.split('.').last;
      final fileName =
          '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await supabase.storage.from('studio-images').upload(
            fileName,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      final url = supabase.storage
          .from('studio-images')
          .getPublicUrl(fileName);

      setState(() {
        _imageUrl = url;
        _uploading = false;
      });
      widget.onImageChanged(url);
    } catch (e) {
      setState(() => _uploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  void _showUrlInput() {
    _urlController.text = _imageUrl ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paste Image URL'),
        content: TextField(
          controller: _urlController,
          decoration: const InputDecoration(
            hintText: 'https://...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final url = _urlController.text.trim();
              if (url.isNotEmpty) {
                setState(() => _imageUrl = url);
                widget.onImageChanged(url);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Use URL'),
          ),
        ],
      ),
    );
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Paste URL'),
              onTap: () {
                Navigator.pop(ctx);
                _showUrlInput();
              },
            ),
            if (_imageUrl != null)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove Image',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _imageUrl = null);
                  widget.onImageChanged(null);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_uploading) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return GestureDetector(
        onTap: _showPicker,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Image.network(
                _imageUrl!,
                height: widget.height,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: widget.height,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 32),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.edit,
                      size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _showPicker,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surfaceContainerLowest,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_photo_alternate,
                  size: 32, color: theme.colorScheme.outline),
              const SizedBox(height: 4),
              Text(
                'Add image',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
