import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

class NewConsultationScreen extends ConsumerStatefulWidget {
  const NewConsultationScreen({super.key, this.initialType});
  final ConsultationType? initialType;

  @override
  ConsumerState<NewConsultationScreen> createState() =>
      _NewConsultationScreenState();
}

class _NewConsultationScreenState extends ConsumerState<NewConsultationScreen> {
  int _step = 0;
  String? _specialty;
  late ConsultationType _type = widget.initialType ?? ConsultationType.lab;
  final _symptoms = TextEditingController();
  String _duration = 'dur_days';
  Urgency _urgency = Urgency.normal;
  final List<Attachment> _files = [];
  bool _hideName = false;

  static const _durations = [
    'dur_days',
    'dur_weeks',
    'dur_months',
    'dur_years',
  ];

  @override
  void dispose() {
    _symptoms.dispose();
    super.dispose();
  }

  bool get _canContinue => switch (_step) {
    0 => _specialty != null,
    1 => _symptoms.text.trim().length >= 10,
    _ => true,
  };

  void _addFile(AttachmentKind kind, String prefix) {
    setState(() {
      final n = _files.length + 1;
      _files.add(
        Attachment(
          '${prefix}_$n.${kind == AttachmentKind.pdf ? 'pdf' : 'jpg'}',
          kind,
        ),
      );
    });
  }

  void _submit() {
    final auth = ref.read(authProvider);
    final id = ref
        .read(consultationsProvider.notifier)
        .create(
          specialtyId: _specialty!,
          type: _type,
          urgency: _urgency,
          symptoms: _symptoms.text.trim(),
          durationKey: _duration,
          attachments: List.of(_files),
          hideName: _hideName,
          patientName: auth.displayName,
          profile: ref.read(healthProfileProvider),
        );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 64,
        ),
        title: Text(ctx.tr('request_sent')),
        content: Text(ctx.tr('request_sent_body'), textAlign: TextAlign.center),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pushReplacement('/patient/consultation/$id');
            },
            child: Text(ctx.tr('view_request')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      'step_specialty',
      'step_symptoms',
      'step_files',
      'step_review',
    ];
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('new_consultation'))),
      body: Column(
        children: [
          // Progress header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                for (var i = 0; i < steps.length; i++)
                  Expanded(
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i <= _step
                                ? scheme.primary
                                : scheme.outlineVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr(steps[i]),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: i == _step
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: i <= _step
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: switch (_step) {
                0 => _specialtyStep(context),
                1 => _symptomsStep(context),
                2 => _filesStep(context),
                _ => _reviewStep(context),
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  if (_step > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step--),
                        child: Text(context.tr('back')),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: !_canContinue
                          ? null
                          : _step == steps.length - 1
                          ? _submit
                          : () => setState(() => _step++),
                      child: Text(
                        context.tr(
                          _step == steps.length - 1 ? 'submit_request' : 'next',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(String key) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      context.tr(key),
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w800),
    ),
  );

  Widget _specialtyStep(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('consultation_type'),
        SegmentedButton<ConsultationType>(
          segments: [
            for (final t in ConsultationType.values)
              ButtonSegment(
                value: t,
                icon: Icon(typeIcon(t)),
                label: Text(context.tr(typeKey(t))),
              ),
          ],
          selected: {_type},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _type = s.first),
        ),
        const SizedBox(height: 24),
        _title('choose_specialty'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: .95,
          children: [
            for (final s in Specialty.all)
              Material(
                color: _specialty == s.id
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _specialty == s.id
                        ? scheme.primary
                        : scheme.outlineVariant,
                    width: _specialty == s.id ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => setState(() => _specialty = s.id),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(s.icon, size: 32, color: scheme.primary),
                        const SizedBox(height: 8),
                        Text(
                          context.tr(s.key),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _symptomsStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('describe_symptoms'),
        TextField(
          controller: _symptoms,
          maxLines: 6,
          maxLength: 1000,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(hintText: context.tr('symptoms_hint')),
        ),
        const SizedBox(height: 12),
        _title('symptoms_duration'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in _durations)
              ChoiceChip(
                label: Text(context.tr(d)),
                selected: _duration == d,
                onSelected: (_) => setState(() => _duration = d),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _title('urgency'),
        Row(
          children: [
            for (final u in Urgency.values) ...[
              Expanded(
                child: _UrgencyOption(
                  urgency: u,
                  selected: _urgency == u,
                  onTap: () => setState(() => _urgency = u),
                ),
              ),
              if (u != Urgency.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
        if (_urgency == Urgency.urgent) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('urgent_warning'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _filesStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('attach_files'),
        Text(context.tr('attach_hint')),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _UploadButton(
                icon: Icons.photo_camera_outlined,
                label: context.tr('camera'),
                onTap: () => _addFile(AttachmentKind.image, 'photo'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _UploadButton(
                icon: Icons.photo_library_outlined,
                label: context.tr('gallery'),
                onTap: () => _addFile(AttachmentKind.image, 'image'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _UploadButton(
                icon: Icons.picture_as_pdf_outlined,
                label: context.tr('pdf_file'),
                onTap: () => _addFile(AttachmentKind.pdf, 'document'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_files.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text(context.tr('no_files'))),
          )
        else
          for (var i = 0; i < _files.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AttachmentTile(
                _files[i],
                onRemove: () => setState(() => _files.removeAt(i)),
              ),
            ),
      ],
    );
  }

  Widget _reviewStep(BuildContext context) {
    final sp = Specialty.byId(_specialty!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoCard(
          title: context.tr('step_specialty'),
          icon: sp.icon,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Pill(
                label: context.tr(sp.key),
                color: Theme.of(context).colorScheme.primary,
              ),
              Pill(label: context.tr(typeKey(_type)), color: AppColors.info),
              UrgencyPill(_urgency),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InfoCard(
          title: context.tr('symptoms'),
          icon: Icons.notes,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_symptoms.text.trim()),
              const SizedBox(height: 8),
              Text(
                '${context.tr('symptoms_duration')} ${context.tr(_duration)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InfoCard(
          title: context.tr('attachments'),
          icon: Icons.attach_file,
          child: Text(
            _files.isEmpty
                ? context.tr('no_files')
                : _files.map((f) => f.name).join('\n'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            value: _hideName,
            onChanged: (v) => setState(() => _hideName = v),
            secondary: const Icon(Icons.visibility_off_outlined),
            title: Text(context.tr('hide_name')),
            subtitle: Text(context.tr('hide_name_desc')),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr('emergency_body'),
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.danger),
        ),
      ],
    );
  }
}

class _UrgencyOption extends StatelessWidget {
  const _UrgencyOption({
    required this.urgency,
    required this.selected,
    required this.onTap,
  });
  final Urgency urgency;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = urgencyColor(urgency);
    return Material(
      color: selected
          ? color
          : Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected
              ? color
              : Theme.of(context).colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle,
                color: selected ? AppColors.on(color) : color,
                size: selected ? 18 : 14,
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(urgencyKey(urgency)),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.on(color) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  const _UploadButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: AppColors.mint,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Icon(icon, size: 30, color: scheme.primary),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
