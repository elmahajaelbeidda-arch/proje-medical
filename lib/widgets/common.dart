import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../data/mock_data.dart';
import '../models/models.dart';

// ---------------------------------------------------------------------------
// Helpers for enums -> label / color
// ---------------------------------------------------------------------------

String statusKey(ConsultationStatus s) => 'status_${s.name}';
String typeKey(ConsultationType t) => 'type_${t.name}';
String urgencyKey(Urgency u) => 'urgency_${u.name}';

Color statusColor(ConsultationStatus s) => switch (s) {
  ConsultationStatus.pending => AppColors.warning,
  ConsultationStatus.accepted => AppColors.info,
  ConsultationStatus.answered => AppColors.success,
  ConsultationStatus.closed => Colors.grey,
};

Color urgencyColor(Urgency u) => switch (u) {
  Urgency.normal => AppColors.success,
  Urgency.soon => AppColors.warning,
  Urgency.urgent => AppColors.danger,
};

IconData typeIcon(ConsultationType t) => switch (t) {
  ConsultationType.lab => Icons.biotech_outlined,
  ConsultationType.imaging => Icons.document_scanner_outlined,
  ConsultationType.general => Icons.chat_outlined,
};

// ---------------------------------------------------------------------------
// Small building blocks
// ---------------------------------------------------------------------------

class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.on(color)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.on(color),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final ConsultationStatus status;
  @override
  Widget build(BuildContext context) =>
      Pill(label: context.tr(statusKey(status)), color: statusColor(status));
}

class UrgencyPill extends StatelessWidget {
  const UrgencyPill(this.urgency, {super.key});
  final Urgency urgency;
  @override
  Widget build(BuildContext context) => Pill(
    label: context.tr(urgencyKey(urgency)),
    color: urgencyColor(urgency),
    icon: urgency == Urgency.urgent ? Icons.bolt : null,
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.peach,
              child: Icon(icon, size: 44, color: AppColors.navy),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.color,
  });
  final String title;
  final Widget child;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: c, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800, color: c),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class DoctorAvatar extends StatelessWidget {
  const DoctorAvatar(this.doctor, {super.key, this.radius = 26});
  final Doctor doctor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: scheme.primaryContainer,
          child: Text(
            doctor.initials,
            style: TextStyle(
              fontSize: radius * .8,
              fontWeight: FontWeight.w800,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
        if (doctor.verified)
          PositionedDirectional(
            end: -2,
            bottom: -2,
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(1.5),
              child: Icon(
                Icons.verified,
                size: radius * .55,
                color: AppColors.info,
              ),
            ),
          ),
      ],
    );
  }
}

class AttachmentTile extends StatelessWidget {
  const AttachmentTile(this.attachment, {super.key, this.onRemove});
  final Attachment attachment;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isPdf = attachment.kind == AttachmentKind.pdf;
    final color = isPdf ? AppColors.danger : AppColors.info;
    return Card(
      child: ListTile(
        onTap: onRemove == null ? () => showPreview(context) : null,
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(
            isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
            color: Colors.white,
          ),
        ),
        title: Text(
          attachment.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: onRemove == null ? Text(context.tr('tap_to_preview')) : null,
        trailing: onRemove != null
            ? IconButton(icon: const Icon(Icons.close), onPressed: onRemove)
            : const Icon(Icons.zoom_in),
      ),
    );
  }

  void showPreview(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(attachment.name),
        content: AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  attachment.kind == AttachmentKind.pdf
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                  size: 64,
                ),
                const SizedBox(height: 12),
                Text(
                  ctx.tr('preview_placeholder'),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.tr('back')),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cards
// ---------------------------------------------------------------------------

class ConsultationCard extends StatelessWidget {
  const ConsultationCard({
    super.key,
    required this.consultation,
    required this.onTap,
    this.showPatient = false,
  });

  final Consultation consultation;
  final VoidCallback onTap;
  final bool showPatient;

  @override
  Widget build(BuildContext context) {
    final c = consultation;
    final sp = Specialty.byId(c.specialtyId);
    final doctor = MockData.doctorById(c.doctorId);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(sp.icon, color: AppColors.peach),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          showPatient
                              ? '${c.displayPatientName} • ${c.patientAge} ${context.tr('years')}'
                              : context.tr(sp.key),
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${context.tr(typeKey(c.type))} • ${context.timeAgo(c.createdAt)}',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(c.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                c.symptoms,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  UrgencyPill(c.urgency),
                  if (showPatient)
                    Pill(
                      label: context.tr(sp.key),
                      color: scheme.primary,
                      icon: sp.icon,
                    ),
                  if (c.attachments.isNotEmpty)
                    Pill(
                      label:
                          '${c.attachments.length} ${context.tr('files_count')}',
                      color: AppColors.navy,
                      icon: Icons.attach_file,
                    ),
                  if (!showPatient && doctor != null)
                    Pill(
                      label: doctor.name,
                      color: AppColors.info,
                      icon: Icons.person_outline,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  const DoctorCard({super.key, required this.doctor, this.onTap});
  final Doctor doctor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              DoctorAvatar(doctor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${context.tr(Specialty.byId(doctor.specialtyId).key)} • ${doctor.city}',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: AppColors.accent,
                        ),
                        Text(' ${doctor.rating}  ', style: text.labelMedium),
                        Icon(
                          Icons.forum_outlined,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        Text(
                          ' ${doctor.consultationsCount}',
                          style: text.labelMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Pill(
                label: context.tr(
                  doctor.available ? 'available_now' : 'unavailable',
                ),
                color: doctor.available ? AppColors.success : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showDoctorSheet(BuildContext context, Doctor doctor) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final text = Theme.of(ctx).textTheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DoctorAvatar(doctor, radius: 42),
            const SizedBox(height: 12),
            Text(
              doctor.name,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              '${ctx.tr(Specialty.byId(doctor.specialtyId).key)} • ${doctor.city}',
            ),
            if (doctor.verified) ...[
              const SizedBox(height: 8),
              Pill(
                label: ctx.tr('verified_doctor'),
                color: AppColors.info,
                icon: Icons.verified,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _Stat(
                  value: '${doctor.yearsOfExperience}',
                  label: '${ctx.tr('experience')} (${ctx.tr('years')})',
                ),
                _Stat(value: '${doctor.rating}', label: ctx.tr('rating')),
                _Stat(
                  value: '${doctor.consultationsCount}',
                  label: ctx.tr('consultations'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(doctor.bio, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final a in doctor.availability)
                  Chip(
                    avatar: const Icon(Icons.schedule, size: 18),
                    label: Text(a),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/patient/new');
              },
              icon: const Icon(Icons.add_comment_outlined),
              label: Text(ctx.tr('request_consultation')),
            ),
          ],
        ),
      );
    },
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: text.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(label, style: text.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color,
              child: Icon(icon, color: AppColors.on(color), size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(label, style: text.bodySmall, maxLines: 2),
          ],
        ),
      ),
    );
  }
}

class MenuTile extends StatelessWidget {
  const MenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.color,
  });
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: c,
        child: Icon(icon, color: AppColors.on(c), size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
