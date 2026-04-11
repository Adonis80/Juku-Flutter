import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'ai_generator.dart';
import 'branding_editor.dart';
import 'content_editor.dart';
import 'studio_state.dart';

class ModuleBuilderScreen extends ConsumerStatefulWidget {
  final String templateTypeParam;

  const ModuleBuilderScreen({super.key, required this.templateTypeParam});

  @override
  ConsumerState<ModuleBuilderScreen> createState() =>
      _ModuleBuilderScreenState();
}

class _ModuleBuilderScreenState extends ConsumerState<ModuleBuilderScreen> {
  late StudioTemplate _template;
  int _currentStep = 0;
  bool _generating = false;
  String? _error;

  // Wizard state
  final _topicCtrl = TextEditingController();
  String _level = 'Beginner';
  int _itemCount = 10;
  int _timeLimitSecs = 20;
  int _passScorePct = 70;
  String _languagePair = 'de-en';
  final _calcDescCtrl = TextEditingController();

  // Generated config
  Map<String, dynamic>? _config;

  // Branding
  ModuleBranding _branding = const ModuleBranding();

  // Publish fields
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _domain = 'Languages';
  bool _isPublic = true;

  @override
  void initState() {
    super.initState();
    _template = templateFromDb(widget.templateTypeParam);
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    _calcDescCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  List<String> get _stepLabels {
    final steps = ['Topic', 'Audience', 'Size'];

    switch (_template) {
      case StudioTemplate.quiz:
        steps.add('Quiz Settings');
      case StudioTemplate.flashcard:
        steps.add('Language Pair');
      case StudioTemplate.calculator:
        steps[2] = 'Describe Pricing';
      case StudioTemplate.conditionalCalculator:
        steps[2] = 'Describe Pricing';
    }

    steps.addAll(['Generate', 'Review & Edit', 'Branding', 'Publish']);
    return steps;
  }

  int get _totalSteps => _stepLabels.length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Build ${_template.label}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
      body: _generating ? _buildGenerating(theme) : _buildStep(theme),
      bottomNavigationBar: _generating
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        child: const Text('Back'),
                      ),
                    const Spacer(),
                    if (_currentStep < _totalSteps - 1)
                      FilledButton(
                        onPressed: _canProceed() ? _onNext : null,
                        child: Text(
                          _currentStep == _stepLabels.indexOf('Generate')
                              ? 'Generate'
                              : 'Next',
                        ),
                      )
                    else
                      FilledButton(
                        onPressed: _canPublish() ? _onPublish : null,
                        child: const Text('Publish'),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGenerating(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Brewing your module...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few seconds',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(ThemeData theme) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => setState(() {
                    _error = null;
                    _currentStep = _stepLabels.indexOf('Generate');
                  }),
                  child: const Text('Try Again'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => setState(() {
                    _error = null;
                    _config = _buildEmptyConfig();
                    _currentStep = _stepLabels.indexOf('Review & Edit');
                  }),
                  child: const Text('Enter Manually'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final stepLabel = _stepLabels[_currentStep];

    switch (stepLabel) {
      case 'Topic':
        return _buildTopicStep(theme);
      case 'Audience':
        return _buildAudienceStep(theme);
      case 'Size':
        return _buildSizeStep(theme);
      case 'Describe Pricing':
        return _buildCalcDescStep(theme);
      case 'Quiz Settings':
        return _buildQuizSettingsStep(theme);
      case 'Language Pair':
        return _buildLanguagePairStep(theme);
      case 'Generate':
        return _buildGenerateStep(theme);
      case 'Review & Edit':
        return _buildReviewStep(theme);
      case 'Branding':
        return BrandingEditor(
          branding: _branding,
          onChanged: (b) => setState(() => _branding = b),
        );
      case 'Publish':
        return _buildPublishStep(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTopicStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What is your module about?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _topicCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. German A1 vocabulary',
              labelText: 'Topic',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who is this for?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: ['Beginner', 'Intermediate', 'Advanced'].map((l) {
              final selected = _level == l;
              return ChoiceChip(
                label: Text(l),
                selected: selected,
                onSelected: (_) => setState(() => _level = l),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How many items?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 5, label: Text('5')),
              ButtonSegment(value: 10, label: Text('10')),
              ButtonSegment(value: 20, label: Text('20')),
            ],
            selected: {_itemCount},
            onSelectionChanged: (v) => setState(() => _itemCount = v.first),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcDescStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Describe your pricing or calculation',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explain how you calculate your prices. AI will turn this into a calculator.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _calcDescCtrl,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText:
                  'e.g. I charge £15/hour for basic alterations, £25/hour for complex work. Add £5 for express service.',
              alignLabelWithHint: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizSettingsStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiz Settings',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text('Time limit per question', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 10, label: Text('10s')),
              ButtonSegment(value: 20, label: Text('20s')),
              ButtonSegment(value: 30, label: Text('30s')),
              ButtonSegment(value: 0, label: Text('None')),
            ],
            selected: {_timeLimitSecs},
            onSelectionChanged: (v) => setState(() => _timeLimitSecs = v.first),
          ),
          const SizedBox(height: 20),
          Text('Pass score', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 50, label: Text('50%')),
              ButtonSegment(value: 70, label: Text('70%')),
              ButtonSegment(value: 90, label: Text('90%')),
            ],
            selected: {_passScorePct},
            onSelectionChanged: (v) => setState(() => _passScorePct = v.first),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagePairStep(ThemeData theme) {
    final pairs = ['de-en', 'ru-en', 'ar-en', 'zh-en', 'other'];
    final labels = {
      'de-en': 'DE ↔ EN',
      'ru-en': 'RU ↔ EN',
      'ar-en': 'AR ↔ EN',
      'zh-en': 'ZH ↔ EN',
      'other': 'Other',
    };

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Language Pair',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pairs.map((p) {
              final selected = _languagePair == p;
              return ChoiceChip(
                label: Text(labels[p]!),
                selected: selected,
                onSelected: (_) => setState(() => _languagePair = p),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate Content',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use your AI key to auto-generate ${_template.label.toLowerCase()} content, or enter it manually.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _onGenerate,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Generate with AI'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _config = _buildEmptyConfig();
                  _currentStep = _stepLabels.indexOf('Review & Edit');
                });
              },
              child: const Text('Enter manually'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add your AI key in Settings to unlock AI generation.',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.outline,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep(ThemeData theme) {
    if (_config == null) {
      return const Center(child: Text('No content generated yet.'));
    }

    return ContentEditor(
      templateType: _template,
      config: _config!,
      onConfigChanged: (c) => setState(() => _config = c),
      onRegenerate: _onGenerate,
    );
  }

  Widget _buildPublishStep(ThemeData theme) {
    final domains = ['Languages', 'Skincare', 'Fitness', 'Tailoring', 'Other'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Almost there!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Module Title'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Text('Domain', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: domains.map((d) {
              return ChoiceChip(
                label: Text(d),
                selected: _domain == d,
                onSelected: (_) => setState(() => _domain = d),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Public'),
            subtitle: Text(
              _isPublic
                  ? 'Anyone can discover and play'
                  : 'Only playable via direct link',
            ),
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    final stepLabel = _stepLabels[_currentStep];
    switch (stepLabel) {
      case 'Topic':
        return _topicCtrl.text.trim().isNotEmpty;
      case 'Describe Pricing':
        return _calcDescCtrl.text.trim().isNotEmpty;
      default:
        return true;
    }
  }

  bool _canPublish() {
    return _titleCtrl.text.trim().isNotEmpty && _config != null;
  }

  void _onNext() {
    if (_stepLabels[_currentStep] == 'Generate') {
      // Skip to next if already have config
      if (_config != null) {
        setState(() => _currentStep++);
      }
      return;
    }

    // Auto-fill title from topic if entering publish step
    if (_stepLabels[_currentStep + 1] == 'Publish' && _titleCtrl.text.isEmpty) {
      _titleCtrl.text = _topicCtrl.text.trim();
    }

    setState(() => _currentStep++);
  }

  Future<void> _onGenerate() async {
    setState(() {
      _generating = true;
      _error = null;
    });

    try {
      final config = await AiGenerator.generate(
        templateType: _template,
        topic: _topicCtrl.text.trim(),
        level: _level,
        itemCount: _itemCount,
        calculatorDescription: _calcDescCtrl.text.trim(),
        timeLimitSecs: _template == StudioTemplate.quiz ? _timeLimitSecs : null,
        passScorePct: _template == StudioTemplate.quiz ? _passScorePct : null,
        languagePair: _template == StudioTemplate.flashcard
            ? _languagePair
            : null,
      );

      if (mounted) {
        setState(() {
          _config = config;
          _generating = false;
          _currentStep = _stepLabels.indexOf('Review & Edit');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generating = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _onPublish() async {
    if (_config == null) return;

    try {
      final moduleId = await publishModule(
        templateType: _template,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        config: _config!,
        domain: _domain.toLowerCase(),
        branding: _branding.toJson(),
      );

      if (mounted) {
        // Navigate to success screen
        context.go('/studio/published/$moduleId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error publishing: $e')));
      }
    }
  }

  Map<String, dynamic> _buildEmptyConfig() {
    switch (_template) {
      case StudioTemplate.quiz:
        return {
          'questions': [
            {
              'q': '',
              'options': ['', '', '', ''],
              'answer': 0,
              'hint': '',
            },
          ],
          'time_limit_secs': _timeLimitSecs > 0 ? _timeLimitSecs : null,
          'pass_score_pct': _passScorePct,
        };
      case StudioTemplate.flashcard:
        return {
          'cards': [
            {'front': '', 'back': '', 'example': ''},
          ],
          'language_pair': _languagePair,
        };
      case StudioTemplate.calculator:
        return {
          'inputs': [
            {'label': '', 'key': 'input_1', 'unit': '', 'type': 'number'},
          ],
          'formula': '',
          'output_label': 'Result',
          'output_unit': '',
        };
      case StudioTemplate.conditionalCalculator:
        return {
          'steps': [
            {
              'id': 'step_1',
              'question': '',
              'type': 'choice',
              'options': [
                {'label': '', 'next': 'result', 'value': ''},
              ],
            },
          ],
          'result_template': '',
          'currency': '',
        };
    }
  }
}
