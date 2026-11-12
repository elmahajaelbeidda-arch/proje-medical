import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/psych_provider.dart';
import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../models/psych.dart';
import '../../widgets/common.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<Doctor> get psychDoctors =>
    MockData.doctors.where((d) => d.specialtyId == 'psych').toList();

String topicKey(PsychTopic t) => 'pt_${t.name}';
String modeKey(SessionMode m) => 'sm_${m.name}';
String psychStatusKey(PsychStatus s) => 'ps_${s.name}';

IconData modeIcon(SessionMode m) => switch (m) {
  SessionMode.chat => Icons.chat_bubble_outline,
  SessionMode.voice => Icons.call_outlined,
  SessionMode.video => Icons.videocam_outlined,
};

Color psychStatusColor(PsychStatus s) => switch (s) {
  PsychStatus.requested => AppColors.warning,
  PsychStatus.confirmed => AppColors.primary,
  PsychStatus.completed => AppColors.success,
  PsychStatus.declined => AppColors.grey,
  PsychStatus.cancelled => AppColors.grey,
};

String _two(int n) => n.toString().padLeft(2, '0');

/// "السبت 15/11 • 18:00" (time kept left-to-right).
String formatSlot(BuildContext context, DateTime d) =>
    '${context.tr('wd_${d.weekday}')} ${d.day}/${d.month} • '
    '\u2066${_two(d.hour)}:${_two(d.minute)}\u2069';

class PsychStatusPill extends StatelessWidget {
  const PsychStatusPill(this.status, {super.key});
  final PsychStatus status;
  @override
  Widget build(BuildContext context) => Pill(
    label: context.tr(psychStatusKey(status)),
    color: psychStatusColor(status),
  );
}

/// Red box: thoughts of self-harm → urgent help, not an appointment.
class CrisisCard extends StatelessWidget {
  const CrisisCard({super.key, this.lead});
  final String? lead;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.emergency,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.health_and_safety, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('psych_crisis_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                if (lead != null)
                  Text(lead!, style: const TextStyle(color: Colors.white)),
                Text(
                  context.tr('psych_crisis_body'),
                  style: const TextStyle(color: Colors.white, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();
  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.secondary,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('psych_privacy_title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('psych_privacy_points'),
                  style: const TextStyle(height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class PsychSessionCard extends StatelessWidget {
  const PsychSessionCard({
    super.key,
    required this.session,
    required this.forDoctor,
    this.onTap,
  });
  final PsychSession session;
  final bool forDoctor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final text = Theme.of(context).textTheme;
    final doctor = MockData.doctorById(s.doctorId);
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
                  CircleAvatar(
                    backgroundColor: AppColors.secondary,
                    child: Icon(modeIcon(s.mode), color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          forDoctor ? s.nameForDoctor : (doctor?.name ?? ''),
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          formatSlot(context, s.slot),
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  PsychStatusPill(s.status),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (forDoctor && s.riskFlag)
                    Pill(
                      label: context.tr('psych_risk_badge'),
                      color: AppColors.emergency,
                      icon: Icons.priority_high,
                    ),
                  if (s.followUpOf != null)
                    Pill(
                      label: context.tr('psych_follow_up'),
                      color: AppColors.info,
                      icon: Icons.repeat,
                    ),
                  for (final t in s.topics)
                    Pill(label: context.tr(topicKey(t)), color: AppColors.mint),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Patient: home of the section
// ---------------------------------------------------------------------------

class PsychHomeScreen extends ConsumerWidget {
  const PsychHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine =
        ref
            .watch(psychProvider)
            .where((s) => s.patientId == MockData.currentPatientId)
            .toList()
          ..sort((a, b) => b.slot.compareTo(a.slot));
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('psych_title'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/patient/psych/new'),
        icon: const Icon(Icons.event_available),
        label: Text(context.tr('psych_book')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.secondary,
              child: Icon(
                Icons.psychology_outlined,
                size: 46,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('psych_intro'),
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(height: 1.7),
          ),
          const SizedBox(height: 14),
          const _PrivacyCard(),
          const SizedBox(height: 10),
          const CrisisCard(),
          SectionHeader(context.tr('psych_my_sessions')),
          if (mine.isEmpty)
            EmptyState(
              icon: Icons.event_note_outlined,
              message: context.tr('psych_no_sessions'),
            ),
          for (final s in mine)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PsychSessionCard(
                session: s,
                forDoctor: false,
                onTap: () => context.push('/patient/psych/${s.id}'),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Patient: booking (need → doctor → time → privacy)
// ---------------------------------------------------------------------------

class PsychBookingScreen extends ConsumerStatefulWidget {
  const PsychBookingScreen({super.key, this.doctorId});
  final String? doctorId;
  @override
  ConsumerState<PsychBookingScreen> createState() => _PsychBookingScreenState();
}

class _PsychBookingScreenState extends ConsumerState<PsychBookingScreen> {
  int _step = 0;
  final Set<PsychTopic> _topics = {};
  final _description = TextEditingController();
  bool? _risk;
  late String? _doctorId = widget.doctorId;
  DateTime? _slot;
  SessionMode _mode = SessionMode.chat;
  late final _alias = TextEditingController(
    text: _initials(ref.read(authProvider).displayName),
  );
  bool _shareName = false;
  bool _consent = false;

  static String _initials(String name) => name
      .split(' ')
      .where((p) => p.isNotEmpty)
      .map((p) => '${p.characters.first}.')
      .join(' ');

  @override
  void dispose() {
    _description.dispose();
    _alias.dispose();
    super.dispose();
  }

  bool get _canContinue => switch (_step) {
    0 => _topics.isNotEmpty && _risk != null,
    1 => _doctorId != null,
    2 => _slot != null,
    _ => _consent,
  };

  void _submit() {
    final auth = ref.read(authProvider);
    final profile = ref.read(healthProfileProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final id = ref
          .read(psychProvider.notifier)
          .book(
            patientId: MockData.currentPatientId,
            patientName: auth.displayName,
            alias: _alias.text,
            shareName: _shareName,
            age: profile.age,
            male: profile.male,
            topics: {..._topics},
            description: _description.text,
            riskFlag: _risk ?? false,
            doctorId: _doctorId!,
            slot: _slot!,
            mode: _mode,
          );
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('psych_booked'))),
      );
      context.pushReplacement('/patient/psych/$id');
    } on StateError {
      // Someone took the slot meanwhile: pick another one.
      setState(() {
        _slot = null;
        _step = 2;
      });
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('psych_no_slots'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const steps = ['pstep_need', 'pstep_doctor', 'pstep_time', 'pstep_privacy'];
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('psych_book'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                for (var i = 0; i < steps.length; i++)
                  Expanded(
                    child: Column(
                      children: [
                        Container(
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
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                switch (_step) {
                  0 => _needStep(),
                  1 => _doctorStep(),
                  2 => _timeStep(),
                  _ => _privacyStep(),
                },
              ],
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
                          : _step == 3
                          ? _submit
                          : () => setState(() => _step++),
                      child: Text(
                        context.tr(
                          _step == 3 ? 'psych_confirm_booking' : 'next',
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
    padding: const EdgeInsets.only(bottom: 10, top: 6),
    child: Text(
      context.tr(key),
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w800),
    ),
  );

  Widget _needStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title('psych_topics'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final t in PsychTopic.values)
            FilterChip(
              label: Text(context.tr(topicKey(t))),
              selected: _topics.contains(t),
              onSelected: (v) =>
                  setState(() => v ? _topics.add(t) : _topics.remove(t)),
            ),
        ],
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _description,
        maxLines: 4,
        maxLength: 600,
        decoration: InputDecoration(
          labelText: context.tr('psych_describe'),
          alignLabelWithHint: true,
        ),
      ),
      _title('psych_risk_question'),
      Row(
        children: [
          for (final v in [false, true]) ...[
            Expanded(
              child: ChoiceChip(
                label: SizedBox(
                  width: double.infinity,
                  child: Text(
                    context.tr(v ? 'psych_risk_yes' : 'psych_risk_no'),
                    textAlign: TextAlign.center,
                  ),
                ),
                selected: _risk == v,
                onSelected: (_) => setState(() => _risk = v),
              ),
            ),
            if (!v) const SizedBox(width: 10),
          ],
        ],
      ),
      if (_risk == true) ...[
        const SizedBox(height: 14),
        CrisisCard(lead: context.tr('psych_risk_note')),
      ],
    ],
  );

  Widget _doctorStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title('psych_choose_doctor'),
      for (final d in psychDoctors)
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _doctorId == d.id ? AppColors.primary : AppColors.border,
              width: _doctorId == d.id ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() {
              if (_doctorId != d.id) _slot = null;
              _doctorId = d.id;
            }),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DoctorAvatar(d),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${context.tr('sp_psych')} • ${d.cityFor(Localizations.localeOf(context).languageCode)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(d.bio),
                        const SizedBox(height: 4),
                        Text(
                          d.availability.join(' | '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _doctorId == d.id
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );

  Widget _timeStep() {
    final slots = freeSlots(_doctorId!, ref.watch(psychProvider));
    // Group by day.
    final days = <DateTime, List<DateTime>>{};
    for (final s in slots) {
      days.putIfAbsent(DateTime(s.year, s.month, s.day), () => []).add(s);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title('psych_session_mode'),
        SegmentedButton<SessionMode>(
          showSelectedIcon: false,
          segments: [
            for (final m in SessionMode.values)
              ButtonSegment(
                value: m,
                icon: Icon(modeIcon(m)),
                label: Text(context.tr(modeKey(m))),
              ),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() => _mode = s.first),
        ),
        const SizedBox(height: 10),
        _title('psych_choose_slot'),
        if (slots.isEmpty)
          EmptyState(
            icon: Icons.event_busy,
            message: context.tr('psych_no_slots'),
          ),
        for (final e in days.entries) ...[
          Text(
            '${context.tr('wd_${e.key.weekday}')} ${e.key.day}/${e.key.month}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in e.value)
                ChoiceChip(
                  label: Text(
                    '${_two(s.hour)}:${_two(s.minute)}',
                    textDirection: TextDirection.ltr,
                  ),
                  selected: _slot == s,
                  onSelected: (_) => setState(() => _slot = s),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _privacyStep() {
    final doctor = MockData.doctorById(_doctorId)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InfoCard(
          title: context.tr('psych_appointment'),
          icon: Icons.event_available,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(formatSlot(context, _slot!)),
              Text(context.tr(modeKey(_mode))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in _topics)
                    Pill(label: context.tr(topicKey(t)), color: AppColors.mint),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _PrivacyCard(),
        const SizedBox(height: 12),
        TextField(
          controller: _alias,
          enabled: !_shareName,
          decoration: InputDecoration(
            labelText: context.tr('psych_alias'),
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _shareName,
          onChanged: (v) => setState(() => _shareName = v),
          title: Text(context.tr('psych_share_name')),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _consent,
          onChanged: (v) => setState(() => _consent = v ?? false),
          title: Text(
            context.tr('psych_consent'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Session page (patient or assigned doctor only)
// ---------------------------------------------------------------------------

class PsychSessionScreen extends ConsumerStatefulWidget {
  const PsychSessionScreen({
    super.key,
    required this.id,
    required this.asDoctor,
  });
  final String id;
  final bool asDoctor;
  @override
  ConsumerState<PsychSessionScreen> createState() => _PsychSessionScreenState();
}

class _PsychSessionScreenState extends ConsumerState<PsychSessionScreen> {
  final _message = TextEditingController();
  TextEditingController? _notes;

  @override
  void dispose() {
    _message.dispose();
    _notes?.dispose();
    super.dispose();
  }

  void _snack(String key) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr(key))));

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    PsychSession? s;
    for (final x in ref.watch(psychProvider)) {
      if (x.id == widget.id) s = x;
    }
    // Confidentiality: only the patient and the assigned doctor.
    final allowed =
        s != null &&
        (widget.asDoctor
            ? auth.isPsychDoctor && s.doctorId == auth.doctorId
            : !auth.isDoctor &&
                  !auth.isCommittee &&
                  s.patientId == MockData.currentPatientId);
    if (!allowed) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.lock_outline,
          message: context.tr('psych_no_items'),
        ),
      );
    }
    final session = s;
    final notifier = ref.read(psychProvider.notifier);
    final text = Theme.of(context).textTheme;
    final doctor = MockData.doctorById(session.doctorId)!;
    _notes ??= TextEditingController(text: session.privateNotes);
    final history = widget.asDoctor
        ? (ref
              .watch(psychProvider)
              .where(
                (x) =>
                    x.patientId == session.patientId &&
                    x.doctorId == session.doctorId &&
                    x.status == PsychStatus.completed &&
                    x.id != session.id,
              )
              .toList()
            ..sort((a, b) => b.slot.compareTo(a.slot)))
        : const <PsychSession>[];

    Future<void> cancel() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.tr('psych_cancel_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.tr('back')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.tr('confirm')),
            ),
          ],
        ),
      );
      if (ok == true) {
        notifier.cancel(session.id);
        _snack('psych_cancelled_msg');
      }
    }

    Future<void> complete() async {
      final c = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.tr('psych_complete')),
          content: TextField(
            controller: c,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: ctx.tr('psych_complete_hint'),
              alignLabelWithHint: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.tr('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.tr('confirm')),
            ),
          ],
        ),
      );
      final value = c.text;
      c.dispose();
      if (ok == true) {
        notifier.complete(session.id, recommendations: value);
        _snack('psych_completed_msg');
      }
    }

    Future<void> followUp() async {
      final slots = freeSlots(session.doctorId, ref.read(psychProvider));
      final slot = await showModalBottomSheet<DateTime>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(
                  ctx.tr('psych_schedule_follow_up'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (slots.isEmpty)
                ListTile(title: Text(ctx.tr('psych_no_slots'))),
              for (final x in slots.take(12))
                ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(formatSlot(ctx, x)),
                  onTap: () => Navigator.pop(ctx, x),
                ),
            ],
          ),
        ),
      );
      if (slot == null || !mounted) return;
      final id = notifier.scheduleFollowUp(session.id, slot);
      _snack('psych_follow_up_booked');
      if (mounted) this.context.pushReplacement('/psych/doctor/session/$id');
    }

    final canChat =
        session.status == PsychStatus.confirmed ||
        session.status == PsychStatus.completed;

    return Scaffold(
      appBar: AppBar(
        title: Text('${context.tr('psych_session')} ${session.code}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.asDoctor ? session.nameForDoctor : doctor.name,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      PsychStatusPill(session.status),
                    ],
                  ),
                  if (widget.asDoctor)
                    Text(
                      '${context.tr('psych_age_sex', args: {'age': session.age, 'sex': context.tr(session.male ? 'male' : 'female')})}'
                      '${session.shareName ? '' : ' • ${context.tr('psych_name_hidden')}'}',
                      style: text.bodySmall,
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.event, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(formatSlot(context, session.slot)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(modeIcon(session.mode), color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(context.tr(modeKey(session.mode))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (session.followUpOf != null)
                        Pill(
                          label: context.tr('psych_follow_up'),
                          color: AppColors.info,
                          icon: Icons.repeat,
                        ),
                      for (final t in session.topics)
                        Pill(
                          label: context.tr(topicKey(t)),
                          color: AppColors.mint,
                        ),
                    ],
                  ),
                  if (session.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(session.description),
                  ],
                  if (session.mode != SessionMode.chat &&
                      session.status == PsychStatus.confirmed) ...[
                    const SizedBox(height: 10),
                    Text(context.tr('psych_call_note'), style: text.bodySmall),
                  ],
                ],
              ),
            ),
          ),
          if (session.riskFlag && widget.asDoctor) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.emergency,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                context.tr('psych_risk_doctor_hint'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (!widget.asDoctor && session.riskFlag && session.isUpcoming) ...[
            const SizedBox(height: 10),
            const CrisisCard(),
          ],

          // ----- Actions -----
          const SizedBox(height: 12),
          if (widget.asDoctor && session.status == PsychStatus.requested)
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: () {
                      notifier.confirm(session.id);
                      _snack('psych_confirmed_msg');
                    },
                    icon: const Icon(Icons.check),
                    label: Text(context.tr('psych_confirm')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: AppColors.grey,
                    ),
                    onPressed: () {
                      notifier.decline(session.id);
                      _snack('psych_declined_msg');
                    },
                    icon: const Icon(Icons.close),
                    label: Text(context.tr('psych_decline')),
                  ),
                ),
              ],
            ),
          if (widget.asDoctor && session.status == PsychStatus.confirmed)
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: complete,
              icon: const Icon(Icons.task_alt),
              label: Text(context.tr('psych_complete')),
            ),
          if (widget.asDoctor && session.status == PsychStatus.completed)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: followUp,
              icon: const Icon(Icons.event_repeat),
              label: Text(context.tr('psych_schedule_follow_up')),
            ),
          if (!widget.asDoctor && session.isUpcoming)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                foregroundColor: AppColors.grey,
              ),
              onPressed: cancel,
              icon: const Icon(Icons.event_busy),
              label: Text(context.tr('psych_cancel')),
            ),
          if (!widget.asDoctor &&
              (session.status == PsychStatus.declined ||
                  session.status == PsychStatus.cancelled)) ...[
            Text(
              context.tr('psych_declined_hint'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: () => context.pushReplacement('/patient/psych/new'),
              icon: const Icon(Icons.event_available),
              label: Text(context.tr('psych_book_again')),
            ),
          ],

          if (session.recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            InfoCard(
              title: context.tr('psych_recommendations'),
              icon: Icons.tips_and_updates_outlined,
              child: Text(
                session.recommendations,
                style: const TextStyle(height: 1.6),
              ),
            ),
          ],

          // ----- Doctor's confidential notes -----
          if (widget.asDoctor) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.tr('psych_private_notes'),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      context.tr('psych_private_notes_hint'),
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: _notes, maxLines: 4),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: FilledButton.tonal(
                        onPressed: () {
                          notifier.saveNotes(session.id, _notes!.text);
                          _snack('psych_notes_saved');
                        },
                        child: Text(context.tr('save')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (history.isNotEmpty) ...[
              SectionHeader(context.tr('psych_tab_followup')),
              for (final h in history)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PsychSessionCard(
                    session: h,
                    forDoctor: true,
                    onTap: () => context.push('/psych/doctor/session/${h.id}'),
                  ),
                ),
            ],
          ],

          // ----- Private messages -----
          SectionHeader(context.tr('psych_messages')),
          if (!canChat)
            Text(context.tr('psych_messages_locked'), style: text.bodySmall)
          else ...[
            for (final m in session.messages)
              Align(
                alignment: m.fromDoctor == widget.asDoctor
                    ? AlignmentDirectional.centerStart
                    : AlignmentDirectional.centerEnd,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  constraints: const BoxConstraints(maxWidth: 300),
                  decoration: BoxDecoration(
                    color: m.fromDoctor == widget.asDoctor
                        ? AppColors.primary
                        : AppColors.secondary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    m.text,
                    style: TextStyle(
                      color: m.fromDoctor == widget.asDoctor
                          ? Colors.white
                          : AppColors.text,
                    ),
                  ),
                ),
              ),
            if (session.status == PsychStatus.confirmed)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _message,
                      decoration: InputDecoration(
                        hintText: context.tr('psych_message_hint'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      notifier.sendMessage(
                        session.id,
                        fromDoctor: widget.asDoctor,
                        text: _message.text,
                      );
                      _message.clear();
                    },
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Volunteer psychiatrist workspace
// ---------------------------------------------------------------------------

class _PledgeNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void accept() => state = true;
}

/// Confidentiality pledge accepted in this session.
final psychPledgeProvider = NotifierProvider<_PledgeNotifier, bool>(
  _PledgeNotifier.new,
);

class PsychDoctorShell extends ConsumerStatefulWidget {
  const PsychDoctorShell({super.key});
  @override
  ConsumerState<PsychDoctorShell> createState() => _PsychDoctorShellState();
}

class _PsychDoctorShellState extends ConsumerState<PsychDoctorShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final me = MockData.doctorById(auth.doctorId)!;
    // Registered psychiatrists accepted the pledge at sign-up.
    final pledged =
        ref.watch(psychPledgeProvider) || auth.registrationId != null;
    if (!pledged) return const _PledgeGate();

    final all = ref
        .watch(psychProvider)
        .where((s) => s.doctorId == me.id)
        .toList();
    final requests =
        all.where((s) => s.status == PsychStatus.requested).toList()..sort(
          (a, b) => a.riskFlag != b.riskFlag
              ? (a.riskFlag ? -1 : 1)
              : a.slot.compareTo(b.slot),
        );
    final upcoming =
        all.where((s) => s.status == PsychStatus.confirmed).toList()
          ..sort((a, b) => a.slot.compareTo(b.slot));
    final done = all.where((s) => s.status == PsychStatus.completed).toList()
      ..sort((a, b) => b.slot.compareTo(a.slot));

    Widget list(List<PsychSession> items) => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (items.isEmpty)
          EmptyState(
            icon: Icons.event_note_outlined,
            message: context.tr('psych_no_items'),
          ),
        for (final s in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PsychSessionCard(
              session: s,
              forDoctor: true,
              onTap: () => context.push('/psych/doctor/session/${s.id}'),
            ),
          ),
      ],
    );

    final profile = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DoctorAvatar(me, radius: 36),
                const SizedBox(height: 8),
                Text(
                  me.name,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(context.tr('sp_psych')),
                const SizedBox(height: 8),
                Text(
                  context.tr('psych_sessions_count', args: {'n': done.length}),
                ),
              ],
            ),
          ),
        ),
        InfoCard(
          title: context.tr('psych_hours'),
          icon: Icons.schedule,
          child: Text(me.availability.join('\n')),
        ),
        const SizedBox(height: 10),
        InfoCard(
          title: context.tr('psych_pledge_title'),
          icon: Icons.verified_user_outlined,
          child: Text(
            context.tr('psych_pledge'),
            style: const TextStyle(height: 1.6),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            ref.read(authProvider.notifier).logout();
            context.go('/role');
          },
          icon: const Icon(Icons.logout),
          label: Text(context.tr('logout')),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('psych_doctor_space'))),
      body: [list(requests), list(upcoming), list(done), profile][_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: requests.isNotEmpty,
              label: Text('${requests.length}'),
              child: const Icon(Icons.inbox_outlined),
            ),
            label: context.tr('psych_tab_requests'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_available_outlined),
            label: context.tr('psych_tab_upcoming'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history),
            label: context.tr('psych_tab_followup'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            label: context.tr('psych_tab_profile'),
          ),
        ],
      ),
    );
  }
}

class _PledgeGate extends ConsumerStatefulWidget {
  const _PledgeGate();
  @override
  ConsumerState<_PledgeGate> createState() => _PledgeGateState();
}

class _PledgeGateState extends ConsumerState<_PledgeGate> {
  bool _checked = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('psych_doctor_space'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.secondary,
              child: Icon(
                Icons.verified_user_outlined,
                size: 44,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.tr('psych_pledge_title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(context.tr('psych_pledge'), style: const TextStyle(height: 1.7)),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _checked,
            onChanged: (v) => setState(() => _checked = v ?? false),
            title: Text(context.tr('psych_pledge_accept')),
          ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
            onPressed: _checked
                ? () => ref.read(psychPledgeProvider.notifier).accept()
                : null,
            child: Text(context.tr('psych_pledge_accept')),
          ),
        ],
      ),
    );
  }
}
