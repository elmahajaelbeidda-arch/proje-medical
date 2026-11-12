import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../core/facility_provider.dart';
import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/summons_provider.dart';
import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../models/summons.dart';
import '../../widgets/common.dart';
import 'summons_pdf.dart';

// ---------------------------------------------------------------------------
// PDF: download and print
// ---------------------------------------------------------------------------

SummonsPdfAssets? _assets;

Future<SummonsPdfAssets> loadPdfAssets() async => _assets ??= SummonsPdfAssets(
  regular: await rootBundle.load('assets/fonts/ElMessiri-Regular.ttf'),
  bold: await rootBundle.load('assets/fonts/ElMessiri-Bold.ttf'),
  logo: (await rootBundle.load('assets/images/logo_icon.png')).buffer
      .asUint8List(),
);

Future<Uint8List?> _pdf(BuildContext context, Summons s) async {
  final lang = Localizations.localeOf(context).languageCode;
  final messenger = ScaffoldMessenger.of(context);
  final failed = context.tr('summons_failed');
  try {
    return await buildSummonsPdf(
      s,
      await loadPdfAssets(),
      tr: (k) => AppStrings.of(lang, k),
      rtl: lang == 'ar',
    );
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(failed)));
    return null;
  }
}

String _fileName(Summons s) => 'convocation-${s.code}.pdf';

/// Saves the PDF (browser download on the web, share sheet on phones).
Future<void> downloadSummons(BuildContext context, Summons s) async {
  final bytes = await _pdf(context, s);
  if (bytes == null) return;
  await Printing.sharePdf(bytes: bytes, filename: _fileName(s));
}

/// Opens the system print dialog.
Future<void> printSummons(BuildContext context, Summons s) async {
  final bytes = await _pdf(context, s);
  if (bytes == null) return;
  await Printing.layoutPdf(onLayout: (_) async => bytes, name: _fileName(s));
}

// ---------------------------------------------------------------------------
// On-screen card
// ---------------------------------------------------------------------------

String _two(int n) => n.toString().padLeft(2, '0');

String summonsDate(BuildContext context, DateTime a) =>
    '${context.tr('wd_${a.weekday}')} ${_two(a.day)}/${_two(a.month)}/${a.year}';

String summonsTime(DateTime a) => '${_two(a.hour)}:${_two(a.minute)}';

class SummonsCardView extends StatelessWidget {
  const SummonsCardView({super.key, required this.summons});
  final Summons summons;

  @override
  Widget build(BuildContext context) {
    final s = summons;
    final text = Theme.of(context).textTheme;
    final byDoctor = s.issuer == SummonsIssuer.doctor;

    Widget row(String label, String value, {bool ltr = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, child: Text(label, style: text.bodySmall)),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              textDirection: ltr ? TextDirection.ltr : null,
              textAlign: ltr && Directionality.of(context) == TextDirection.rtl
                  ? TextAlign.right
                  : null,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    Widget block(String title, List<Widget> children) => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset('assets/images/logo_icon.png'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('summons_title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        '${context.tr('summons_number')}: ${s.code}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('summons_appointment'),
                              style: text.bodySmall,
                            ),
                            Text(
                              summonsDate(context, s.appointment),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        summonsTime(s.appointment),
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                block(context.tr('summons_patient'), [
                  row(context.tr('summons_patient_name'), s.patientName),
                  if (s.patientRef.isNotEmpty)
                    row(
                      context.tr('summons_file_number'),
                      s.patientRef,
                      ltr: true,
                    ),
                ]),
                block(
                  context.tr(byDoctor ? 'summons_doctor' : 'summons_facility'),
                  [
                    row(context.tr('summons_name'), s.issuerName),
                    row(
                      context.tr(byDoctor ? 'specialty' : 'facility_type'),
                      context.tr(s.issuerDetailKey),
                    ),
                    row(
                      context.tr('phone'),
                      '+222 ${s.issuerPhone}',
                      ltr: true,
                    ),
                  ],
                ),
                block(context.tr('summons_place'), [
                  row(context.tr('address'), s.place),
                  row(context.tr('city'), s.city),
                ]),
                if (s.instructions.isNotEmpty)
                  block(context.tr('summons_instructions'), [
                    Text(s.instructions),
                  ]),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.qr_code_2, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${context.tr('summons_verification')}: ',
                      style: text.bodySmall,
                    ),
                    Text(
                      s.verificationCode,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card page (patient, issuing doctor or issuing facility)
// ---------------------------------------------------------------------------

class SummonsScreen extends ConsumerWidget {
  const SummonsScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final facility = ref.watch(facilitySessionProvider);
    Summons? s;
    for (final x in ref.watch(summonsProvider)) {
      if (x.id == id) s = x;
    }
    final allowed =
        s != null &&
        ((auth.loggedIn &&
                !auth.isDoctor &&
                !auth.isCommittee &&
                s.patientId == MockData.currentPatientId) ||
            (auth.isDoctor && s.issuerId == auth.doctorId) ||
            (facility != null && s.issuerId == facility));
    if (!allowed) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.lock_outline,
          message: context.tr('summons_none'),
        ),
      );
    }
    final summons = s;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('summons_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SummonsCardView(summons: summons),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
                  onPressed: () => downloadSummons(context, summons),
                  icon: const Icon(Icons.download),
                  label: Text(context.tr('summons_download')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                  ),
                  onPressed: () => printSummons(context, summons),
                  icon: const Icon(Icons.print_outlined),
                  label: Text(context.tr('summons_print')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('summons_print_hint'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Patient: all my cards
// ---------------------------------------------------------------------------

class SummonsTile extends StatelessWidget {
  const SummonsTile({super.key, required this.summons});
  final Summons summons;

  @override
  Widget build(BuildContext context) {
    final s = summons;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => context.push('/summons/${s.id}'),
        leading: CircleAvatar(
          backgroundColor: AppColors.teal,
          child: Icon(
            s.issuer == SummonsIssuer.doctor
                ? Icons.medical_services_outlined
                : Icons.local_hospital_outlined,
            color: Colors.white,
          ),
        ),
        title: Text(
          s.issuerName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${summonsDate(context, s.appointment)} • '
          '\u2066${summonsTime(s.appointment)}\u2069\n${s.place}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class SummonsListScreen extends ConsumerWidget {
  const SummonsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(summonsProvider);
    final all = ref
        .read(summonsProvider.notifier)
        .forPatient(MockData.currentPatientId);
    final upcoming = all.where((s) => s.isUpcoming()).toList();
    final past = all.where((s) => !s.isUpcoming()).toList().reversed.toList();
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('summons_cards'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.tr('summons_print_hint'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (all.isEmpty)
            EmptyState(
              icon: Icons.badge_outlined,
              message: context.tr('summons_none'),
            ),
          if (upcoming.isNotEmpty) ...[
            SectionHeader(context.tr('summons_upcoming')),
            for (final s in upcoming) SummonsTile(summons: s),
          ],
          if (past.isNotEmpty) ...[
            SectionHeader(context.tr('summons_past')),
            for (final s in past) SummonsTile(summons: s),
          ],
        ],
      ),
    );
  }
}

/// Home banner when the patient has an upcoming visit.
class SummonsBanner extends ConsumerWidget {
  const SummonsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(summonsProvider);
    final next = ref
        .read(summonsProvider.notifier)
        .forPatient(MockData.currentPatientId)
        .where((s) => s.isUpcoming())
        .firstOrNull;
    if (next == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        color: AppColors.secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        child: ListTile(
          onTap: () => context.push('/summons/${next.id}'),
          leading: const CircleAvatar(
            backgroundColor: AppColors.teal,
            child: Icon(Icons.badge_outlined, color: Colors.white),
          ),
          title: Text(
            context.tr('summons_new_banner'),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          subtitle: Text(
            '${next.issuerName}\n${summonsDate(context, next.appointment)} • '
            '\u2066${summonsTime(next.appointment)}\u2069',
          ),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Issuing (doctor or facility): date, time, place, instructions
// ---------------------------------------------------------------------------

class SummonsDraft {
  final DateTime appointment;
  final String place;
  final String city;
  final String instructions;
  const SummonsDraft(
    this.appointment,
    this.place,
    this.city,
    this.instructions,
  );
}

Future<SummonsDraft?> showSummonsForm(
  BuildContext context, {
  String place = '',
  String city = '',
  String instructions = '',
  DateTime? appointment,
  String? title,
}) => showModalBottomSheet<SummonsDraft>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _SummonsForm(
    place: place,
    city: city,
    instructions: instructions,
    appointment: appointment,
    title: title,
  ),
);

class _SummonsForm extends StatefulWidget {
  const _SummonsForm({
    required this.place,
    required this.city,
    required this.instructions,
    this.appointment,
    this.title,
  });
  final String place;
  final String city;
  final String instructions;
  final DateTime? appointment;
  final String? title;
  @override
  State<_SummonsForm> createState() => _SummonsFormState();
}

class _SummonsFormState extends State<_SummonsForm> {
  final _form = GlobalKey<FormState>();
  late final _place = TextEditingController(text: widget.place);
  late final _city = TextEditingController(text: widget.city);
  late final _instructions = TextEditingController(text: widget.instructions);
  late DateTime? _date = widget.appointment;
  late TimeOfDay? _time = widget.appointment == null
      ? null
      : TimeOfDay.fromDateTime(widget.appointment!);

  @override
  void dispose() {
    _place.dispose();
    _city.dispose();
    _instructions.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? context.tr('required_field') : null;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 180)),
      initialDate: _date ?? now.add(const Duration(days: 1)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (t != null) setState(() => _time = t);
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    if (_date == null || _time == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('summons_pick_date'))));
      return;
    }
    Navigator.pop(
      context,
      SummonsDraft(
        DateTime(
          _date!.year,
          _date!.month,
          _date!.day,
          _time!.hour,
          _time!.minute,
        ),
        _place.text,
        _city.text,
        _instructions.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title ?? context.tr('summons_issue'),
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              gap,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                      ),
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        _date == null
                            ? context.tr('summons_date')
                            : summonsDate(context, _date!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                      ),
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule),
                      label: Text(
                        _time == null
                            ? context.tr('summons_time')
                            : '${_two(_time!.hour)}:${_two(_time!.minute)}',
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ),
                ],
              ),
              gap,
              TextFormField(
                controller: _place,
                validator: _required,
                decoration: InputDecoration(
                  labelText: context.tr('summons_place'),
                  hintText: context.tr('summons_place_hint'),
                  prefixIcon: const Icon(Icons.place_outlined),
                ),
              ),
              gap,
              TextFormField(
                controller: _city,
                validator: _required,
                decoration: InputDecoration(
                  labelText: context.tr('city'),
                  prefixIcon: const Icon(Icons.location_city_outlined),
                ),
              ),
              gap,
              TextFormField(
                controller: _instructions,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: context.tr('summons_instructions'),
                  hintText: context.tr('summons_instructions_hint'),
                  alignLabelWithHint: true,
                ),
              ),
              gap,
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
                onPressed: _submit,
                icon: const Icon(Icons.badge_outlined),
                label: Text(context.tr('summons_issue')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
