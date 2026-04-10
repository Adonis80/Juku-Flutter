import 'package:flutter/material.dart';

/// Branding configuration for a Studio module.
class ModuleBranding {
  final String primaryColor;
  final String accentColor;
  final String bgType; // 'solid' | 'gradient' | 'image'
  final String bgColor;
  final String? bgGradientStart;
  final String? bgGradientEnd;
  final String? bgImageUrl;
  final String fontFamily;
  final String soundPack; // 'arcade' | 'minimal' | 'nature' | 'silent'
  final String? coverUrl;

  const ModuleBranding({
    this.primaryColor = '#8B5CF6',
    this.accentColor = '#F59E0B',
    this.bgType = 'solid',
    this.bgColor = '#FFFFFF',
    this.bgGradientStart,
    this.bgGradientEnd,
    this.bgImageUrl,
    this.fontFamily = 'Inter',
    this.soundPack = 'arcade',
    this.coverUrl,
  });

  Map<String, dynamic> toJson() => {
        'primary_color': primaryColor,
        'accent_color': accentColor,
        'bg_type': bgType,
        'bg_color': bgColor,
        if (bgGradientStart != null) 'bg_gradient_start': bgGradientStart,
        if (bgGradientEnd != null) 'bg_gradient_end': bgGradientEnd,
        if (bgImageUrl != null) 'bg_image_url': bgImageUrl,
        'font_family': fontFamily,
        'sound_pack': soundPack,
        if (coverUrl != null) 'cover_url': coverUrl,
      };

  factory ModuleBranding.fromJson(Map<String, dynamic> json) {
    return ModuleBranding(
      primaryColor: json['primary_color'] as String? ?? '#8B5CF6',
      accentColor: json['accent_color'] as String? ?? '#F59E0B',
      bgType: json['bg_type'] as String? ?? 'solid',
      bgColor: json['bg_color'] as String? ?? '#FFFFFF',
      bgGradientStart: json['bg_gradient_start'] as String?,
      bgGradientEnd: json['bg_gradient_end'] as String?,
      bgImageUrl: json['bg_image_url'] as String?,
      fontFamily: json['font_family'] as String? ?? 'Inter',
      soundPack: json['sound_pack'] as String? ?? 'arcade',
      coverUrl: json['cover_url'] as String?,
    );
  }

  ModuleBranding copyWith({
    String? primaryColor,
    String? accentColor,
    String? bgType,
    String? bgColor,
    String? bgGradientStart,
    String? bgGradientEnd,
    String? bgImageUrl,
    String? fontFamily,
    String? soundPack,
    String? coverUrl,
  }) {
    return ModuleBranding(
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      bgType: bgType ?? this.bgType,
      bgColor: bgColor ?? this.bgColor,
      bgGradientStart: bgGradientStart ?? this.bgGradientStart,
      bgGradientEnd: bgGradientEnd ?? this.bgGradientEnd,
      bgImageUrl: bgImageUrl ?? this.bgImageUrl,
      fontFamily: fontFamily ?? this.fontFamily,
      soundPack: soundPack ?? this.soundPack,
      coverUrl: coverUrl ?? this.coverUrl,
    );
  }
}

/// Branding step in the builder wizard.
class BrandingEditor extends StatelessWidget {
  final ModuleBranding branding;
  final ValueChanged<ModuleBranding> onChanged;

  const BrandingEditor({
    super.key,
    required this.branding,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Brand Your Module',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make it look like yours.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),

          // Preview card.
          _PreviewCard(branding: branding),
          const SizedBox(height: 24),

          // Primary colour.
          Text('Primary Colour', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _ColorPicker(
            currentColor: branding.primaryColor,
            onChanged: (c) => onChanged(branding.copyWith(primaryColor: c)),
          ),
          const SizedBox(height: 20),

          // Accent colour.
          Text('Accent Colour', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _ColorPicker(
            currentColor: branding.accentColor,
            onChanged: (c) => onChanged(branding.copyWith(accentColor: c)),
          ),
          const SizedBox(height: 20),

          // Background type.
          Text('Background', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'solid', label: Text('Solid')),
              ButtonSegment(value: 'gradient', label: Text('Gradient')),
            ],
            selected: {branding.bgType},
            onSelectionChanged: (v) =>
                onChanged(branding.copyWith(bgType: v.first)),
          ),
          const SizedBox(height: 12),

          if (branding.bgType == 'solid')
            _ColorPicker(
              currentColor: branding.bgColor,
              onChanged: (c) => onChanged(branding.copyWith(bgColor: c)),
            ),

          if (branding.bgType == 'gradient') ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start', style: theme.textTheme.labelSmall),
                      const SizedBox(height: 4),
                      _ColorPicker(
                        currentColor:
                            branding.bgGradientStart ?? branding.primaryColor,
                        onChanged: (c) =>
                            onChanged(branding.copyWith(bgGradientStart: c)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('End', style: theme.textTheme.labelSmall),
                      const SizedBox(height: 4),
                      _ColorPicker(
                        currentColor:
                            branding.bgGradientEnd ?? branding.accentColor,
                        onChanged: (c) =>
                            onChanged(branding.copyWith(bgGradientEnd: c)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // Sound pack.
          Text('Sound Pack', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ('arcade', 'Arcade'),
              ('minimal', 'Minimal'),
              ('nature', 'Nature'),
              ('silent', 'Silent'),
            ].map((pack) {
              return ChoiceChip(
                label: Text(pack.$2),
                selected: branding.soundPack == pack.$1,
                onSelected: (_) =>
                    onChanged(branding.copyWith(soundPack: pack.$1)),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final ModuleBranding branding;
  const _PreviewCard({required this.branding});

  Color _parseColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final primary = _parseColor(branding.primaryColor);
    final accent = _parseColor(branding.accentColor);

    BoxDecoration bg;
    if (branding.bgType == 'gradient') {
      bg = BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            _parseColor(branding.bgGradientStart ?? branding.primaryColor),
            _parseColor(branding.bgGradientEnd ?? branding.accentColor),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else {
      bg = BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _parseColor(branding.bgColor),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      );
    }

    return Container(
      height: 160,
      decoration: bg,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Preview',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 60,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 8,
                decoration: BoxDecoration(
                  color: accent.withAlpha(100),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final String currentColor;
  final ValueChanged<String> onChanged;

  const _ColorPicker({
    required this.currentColor,
    required this.onChanged,
  });

  static const _presets = [
    '#8B5CF6', '#3B82F6', '#10B981', '#F59E0B',
    '#EF4444', '#EC4899', '#06B6D4', '#84CC16',
    '#F97316', '#6366F1', '#0F172A', '#FFFFFF',
  ];

  Color _parseColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _presets.map((hex) {
        final isSelected =
            hex.toUpperCase() == currentColor.toUpperCase();
        final color = _parseColor(hex);

        return GestureDetector(
          onTap: () => onChanged(hex),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: isSelected
                ? Icon(Icons.check,
                    size: 16,
                    color: color.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
