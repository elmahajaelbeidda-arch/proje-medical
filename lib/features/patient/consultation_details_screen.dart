import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/summons_provider.dart';
import '../summons/summons_screens.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/media.dart';

class ConsultationDetailsScreen extends ConsumerWidget {
  const ConsultationDetailsScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(consultationProvider(id));
    if (c == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.search_off,
          message: context.tr('no_consultations'),
        ),
      );
    }
    final sp = Specialty.byId(c.specialtyId);
    final doctor = MockData.doctorById(c.doctorId);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('consultation_details'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        child: Icon(sp.icon),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(sp.key),
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${context.tr(typeKey(c.type))} • ${context.timeAgo(c.createdAt)}',
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      UrgencyPill(c.urgency),
                    ],
                  ),
                  const SizedBox(height: 20),
                  StatusTimeline(status: c.status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (c.status == ConsultationStatus.pending)
            Card(
              color: AppColors.warning,
              child: ListTile(
                leading: const Icon(
                  Icons.hourglass_top_rounded,
                  color: AppColors.ink,
                ),
                title: Text(
                  context.tr('waiting_doctor'),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          if (doctor != null) ...[
            SectionHeader(context.tr('assigned_doctor')),
            DoctorCard(
              doctor: doctor,
              onTap: () => showDoctorSheet(context, doctor),
            ),
          ],

          if (ref.watch(summonsProvider.notifier).bySource(c.id)
              case final summons?) ...[
            const SizedBox(height: 12),
            SummonsTile(summons: summons),
          ],
          if (c.reply != null) ...[
            SectionHeader(context.tr('doctor_reply')),
            ReplyView(reply: c.reply!),
          ],

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
                    '${context.tr('symptoms_duration')} ${context.tr(c.durationKey)}',
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

          const SizedBox(height: 16),
          if (c.status == ConsultationStatus.accepted ||
              c.status == ConsultationStatus.answered)
            FilledButton.icon(
              onPressed: () => context.push('/chat/${c.id}'),
              icon: const Icon(Icons.chat_outlined),
              label: Text(context.tr('open_chat')),
            ),
          if (c.status == ConsultationStatus.answered) ...[
            const SizedBox(height: 10),
            if (c.rating == null)
              OutlinedButton.icon(
                onPressed: () => _rate(context, ref, c.id),
                icon: const Icon(Icons.star_outline),
                label: Text(context.tr('rate_doctor')),
              )
            else
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${context.tr('your_rating')}: '),
                    for (var i = 0; i < 5; i++)
                      Icon(
                        i < c.rating!
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppColors.accent,
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _rate(BuildContext context, WidgetRef ref, String id) {
    var stars = 5;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(ctx.tr('rate_title'), textAlign: TextAlign.center),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setState(() => stars = i),
                  icon: Icon(
                    i <= stars
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.accent,
                    size: 36,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr('cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
              onPressed: () {
                ref.read(consultationsProvider.notifier).rate(id, stars);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('thanks_rating'))),
                );
              },
              child: Text(ctx.tr('send')),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.status});
  final ConsultationStatus status;

  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.send_rounded, 'tl_sent'),
      (Icons.how_to_reg_rounded, 'tl_accepted'),
      (Icons.task_alt_rounded, 'tl_answered'),
    ];
    final reached = switch (status) {
      ConsultationStatus.pending => 0,
      ConsultationStatus.accepted => 1,
      _ => 2,
    };
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Column(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: i <= reached
                    ? scheme.primary
                    : scheme.surfaceContainerHighest,
                child: Icon(
                  steps[i].$1,
                  size: 18,
                  color: i <= reached ? scheme.onPrimary : scheme.outline,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(steps[i].$2),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: i == reached ? FontWeight.w800 : null,
                ),
              ),
            ],
          ),
          if (i < steps.length - 1)
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.only(bottom: 22),
                color: i < reached ? scheme.primary : scheme.outlineVariant,
              ),
            ),
        ],
      ],
    );
  }
}

class ReplyView extends StatelessWidget {
  const ReplyView({super.key, required this.reply});
  final DoctorReply reply;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InfoCard(
          title: context.tr('findings'),
          icon: Icons.biotech_outlined,
          child: Text(reply.findings),
        ),
        const SizedBox(height: 10),
        InfoCard(
          title: context.tr('diagnosis'),
          icon: Icons.medical_information_outlined,
          color: AppColors.info,
          child: Text(reply.diagnosis),
        ),
        const SizedBox(height: 10),
        InfoCard(
          title: context.tr('recommendations'),
          icon: Icons.checklist_rounded,
          color: AppColors.success,
          child: Text(reply.recommendations),
        ),
        if (reply.needsVisit) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_hospital_outlined, color: AppColors.ink),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('needs_visit'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
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
}
