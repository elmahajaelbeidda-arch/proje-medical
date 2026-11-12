import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin_provider.dart';
import '../../core/l10n.dart';
import '../../models/admin.dart';
import '../summons/summons_screens.dart';
import '../../models/summons.dart';
import '../../core/summons_provider.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../models/registration.dart';
import '../../widgets/common.dart';
import '../../widgets/media.dart';
import '../patient/consultation_details_screen.dart';

class RequestDetailsScreen extends ConsumerWidget {
  const RequestDetailsScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(consultationProvider(id));
    if (c == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.search_off,
          message: context.tr('no_requests'),
        ),
      );
    }
    final sp = Specialty.byId(c.specialtyId);
    final isMine = c.doctorId == MockData.currentDoctorId;
    final takenByOther = c.doctorId != null && !isMine;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('request_details'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Patient card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: scheme.secondaryContainer,
                        child: Icon(
                          c.patientMale ? Icons.man : Icons.woman,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.displayPatientName,
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${c.patientAge} ${context.tr('years')} • ${context.tr(c.patientMale ? 'male' : 'female')}',
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      StatusPill(c.status),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Pill(
                        label: context.tr(sp.key),
                        color: scheme.primary,
                        icon: sp.icon,
                      ),
                      Pill(
                        label: context.tr(typeKey(c.type)),
                        color: AppColors.info,
                        icon: typeIcon(c.type),
                      ),
                      UrgencyPill(c.urgency),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.tr('chronic_diseases'),
                    style: text.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.chronicDiseases.isEmpty
                        ? context.tr('none')
                        : c.chronicDiseases.map(context.tr).join('، '),
                  ),
                ],
              ),
            ),
          ),

          SectionHeader(context.tr('symptoms')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (c.symptoms.isNotEmpty) ...[
                    Text(c.symptoms, style: text.bodyLarge),
                    const SizedBox(height: 8),
                  ],
                  if (c.voiceNote != null) ...[
                    VoiceNotePlayer(note: c.voiceNote!),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    '${context.tr('symptoms_duration')} ${context.tr(c.durationKey)} • ${context.timeAgo(c.createdAt)}',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          if (c.attachments.isNotEmpty) ...[
            SectionHeader(context.tr('attachments')),
            for (final a in c.attachments)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AttachmentTile(a),
              ),
          ],

          if (c.reply != null) ...[
            SectionHeader(context.tr('doctor_reply')),
            ReplyView(reply: c.reply!),
          ],

          const SizedBox(height: 20),
          if (c.status == ConsultationStatus.pending &&
              ref.watch(myAccountStatusProvider) != ReviewStatus.approved)
            // New doctors accept cases only after the committee's approval.
            Text(context.tr('doctor_not_approved'), textAlign: TextAlign.center)
          else if (c.status == ConsultationStatus.pending)
            FilledButton.icon(
              onPressed: () {
                ref
                    .read(consultationsProvider.notifier)
                    .accept(c.id, MockData.currentDoctorId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('case_accepted'))),
                );
              },
              icon: const Icon(Icons.how_to_reg),
              label: Text(context.tr('accept_case')),
            )
          else if (takenByOther)
            Center(child: Text(context.tr('accepted_by_other')))
          else ...[
            if (c.status == ConsultationStatus.accepted)
              FilledButton.icon(
                onPressed: () => context.push('/doctor/reply/${c.id}'),
                icon: const Icon(Icons.edit_note),
                label: Text(context.tr('write_reply')),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push('/chat/${c.id}'),
              icon: const Icon(Icons.chat_outlined),
              label: Text(context.tr('chat')),
            ),
            if (ref.watch(appSettingsProvider).enabled(AppSection.summons)) ...[
              const SizedBox(height: 10),
              _SummonsAction(consultation: c),
            ],
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reply form
// ---------------------------------------------------------------------------

class ReplyScreen extends ConsumerStatefulWidget {
  const ReplyScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<ReplyScreen> createState() => _ReplyScreenState();
}

class _ReplyScreenState extends ConsumerState<ReplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _findings = TextEditingController();
  final _diagnosis = TextEditingController();
  final _recommendations = TextEditingController();
  bool _needsVisit = false;

  @override
  void dispose() {
    _findings.dispose();
    _diagnosis.dispose();
    _recommendations.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(consultationsProvider.notifier)
        .reply(
          widget.id,
          DoctorReply(
            findings: _findings.text.trim(),
            diagnosis: _diagnosis.text.trim(),
            recommendations: _recommendations.text.trim(),
            needsVisit: _needsVisit,
            date: DateTime.now(),
          ),
        );
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr('reply_sent'))));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(consultationProvider(widget.id));
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? context.tr('required_field') : null;

    Widget field(
      TextEditingController ctrl,
      String label,
      String hint,
      IconData icon,
    ) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        maxLines: 4,
        minLines: 2,
        validator: required,
        decoration: InputDecoration(
          labelText: context.tr(label),
          hintText: context.tr(hint),
          alignLabelWithHint: true,
          prefixIcon: Icon(icon),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('write_reply'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (c != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(
                    '${context.tr('patient_label')}: ${c.displayPatientName}',
                  ),
                  subtitle: Text(
                    c.symptoms,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            field(
              _findings,
              'findings',
              'findings_hint',
              Icons.biotech_outlined,
            ),
            field(
              _diagnosis,
              'diagnosis',
              'diagnosis_hint',
              Icons.medical_information_outlined,
            ),
            field(
              _recommendations,
              'recommendations',
              'recommendations_hint',
              Icons.checklist_rounded,
            ),
            Card(
              child: SwitchListTile(
                value: _needsVisit,
                onChanged: (v) => setState(() => _needsVisit = v),
                secondary: const Icon(Icons.local_hospital_outlined),
                title: Text(context.tr('needs_visit')),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send),
              label: Text(context.tr('send')),
            ),
          ],
        ),
      ),
    );
  }
}

/// In-person visit: the doctor issues a summons card to the patient.
class _SummonsAction extends ConsumerWidget {
  const _SummonsAction({required this.consultation});
  final Consultation consultation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = consultation;
    ref.watch(summonsProvider);
    final existing = ref.read(summonsProvider.notifier).bySource(c.id);
    final me = MockData.doctorById(MockData.currentDoctorId)!;

    Future<void> issue() async {
      final draft = await showSummonsForm(
        context,
        place: existing?.place ?? '',
        city: existing?.city ?? me.city,
        instructions: existing?.instructions ?? '',
        appointment: existing?.appointment,
        title: context.tr(
          existing == null ? 'summons_issue' : 'summons_update',
        ),
      );
      if (draft == null || !context.mounted) return;
      final phone = ref.read(authProvider).phone;
      final id = ref
          .read(summonsProvider.notifier)
          .issue(
            patientId: c.patientId,
            patientName: c.patientName,
            issuer: SummonsIssuer.doctor,
            issuerId: me.id,
            issuerName: me.name,
            issuerDetailKey: Specialty.byId(me.specialtyId).key,
            issuerPhone: phone.isEmpty ? '22 12 34 56' : phone,
            place: draft.place,
            city: draft.city,
            appointment: draft.appointment,
            instructions: draft.instructions,
            sourceId: c.id,
          );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('summons_issued_msg'))));
      context.push('/summons/$id');
    }

    if (existing != null) {
      return Row(
        children: [
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: () => context.push('/summons/${existing.id}'),
              icon: const Icon(Icons.badge_outlined),
              label: Text(context.tr('summons_view')),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: issue,
              icon: const Icon(Icons.edit_calendar),
              label: Text(context.tr('summons_update')),
            ),
          ),
        ],
      );
    }
    return Card(
      color: AppColors.secondary,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.tr('summons_visit_needed')),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: issue,
              icon: const Icon(Icons.badge_outlined),
              label: Text(context.tr('summons_issue')),
            ),
          ],
        ),
      ),
    );
  }
}
