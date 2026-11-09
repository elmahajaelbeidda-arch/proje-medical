import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/blood_provider.dart';
import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../models/blood.dart';
import '../../widgets/common.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';

/// Blood types as left-to-right islands inside Arabic text ("O-  O+  A-").
String _typesText(String recipient) =>
    compatibleDonorTypes(recipient).map((t) => '\u2066$t\u2069').join('  ');

String contactKey(ContactMethod m) => switch (m) {
  ContactMethod.call => 'contact_call',
  ContactMethod.whatsapp => 'contact_whatsapp',
  ContactMethod.sms => 'contact_sms',
};

IconData contactIcon(ContactMethod m) => switch (m) {
  ContactMethod.call => Icons.call,
  ContactMethod.whatsapp => Icons.chat,
  ContactMethod.sms => Icons.sms_outlined,
};

/// Opens the phone app, WhatsApp or SMS for [phone].
Future<void> openContact(
  BuildContext context,
  String phone,
  ContactMethod method,
) async {
  final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  // WhatsApp needs the international format; local numbers starting with 0
  // are assumed to be Algerian (+213).
  String international() {
    if (digits.startsWith('+')) return digits.substring(1);
    if (digits.startsWith('00')) return digits.substring(2);
    if (digits.startsWith('0')) return '213${digits.substring(1)}';
    return digits;
  }

  final uri = switch (method) {
    ContactMethod.call => Uri(scheme: 'tel', path: digits),
    ContactMethod.sms => Uri(scheme: 'sms', path: digits),
    ContactMethod.whatsapp => Uri.parse('https://wa.me/${international()}'),
  };
  final messenger = ScaffoldMessenger.of(context);
  final failed = context.tr('pick_failed');
  try {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(failed)));
  }
}

/// Big round blood-type badge.
class BloodTypeBadge extends StatelessWidget {
  const BloodTypeBadge(this.type, {super.key, this.size = 52});
  final String type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        type,
        textDirection: TextDirection.ltr,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * .34,
        ),
      ),
    );
  }
}

/// Call / WhatsApp / SMS buttons; the preferred method is highlighted.
class ContactButtons extends StatelessWidget {
  const ContactButtons({
    super.key,
    required this.phone,
    required this.preferred,
  });
  final String phone;
  final ContactMethod preferred;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          phone,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final m in ContactMethod.values) ...[
              Expanded(child: _contactButton(context, m)),
              if (m != ContactMethod.values.last) const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }

  Widget _contactButton(BuildContext context, ContactMethod m) {
    final label = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        context.tr(m == ContactMethod.sms ? 'sms_short' : contactKey(m)),
        maxLines: 1,
      ),
    );
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 46)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 8),
      ),
    );
    final icon = Icon(contactIcon(m), size: 18);
    void onPressed() => openContact(context, phone, m);
    return m == preferred
        ? FilledButton.icon(
            style: style,
            onPressed: onPressed,
            icon: icon,
            label: label,
          )
        : OutlinedButton.icon(
            style: style,
            onPressed: onPressed,
            icon: icon,
            label: label,
          );
  }
}

// ---------------------------------------------------------------------------
// Home: actions, my donor card, open requests
// ---------------------------------------------------------------------------

class BloodHomeScreen extends ConsumerStatefulWidget {
  const BloodHomeScreen({super.key});
  @override
  ConsumerState<BloodHomeScreen> createState() => _BloodHomeScreenState();
}

class _BloodHomeScreenState extends ConsumerState<BloodHomeScreen> {
  String? _type;

  @override
  Widget build(BuildContext context) {
    final blood = ref.watch(bloodProvider);
    final me = blood.myDonor;
    final text = Theme.of(context).textTheme;
    final requests =
        blood.requests
            .where((r) => _type == null || r.bloodType == _type)
            .toList()
          ..sort((a, b) {
            int score(BloodRequest r) =>
                (r.isOpen ? 2 : 0) + (r.urgent ? 1 : 0);
            final s = score(b).compareTo(score(a));
            return s != 0 ? s : b.createdAt.compareTo(a.createdAt);
          });
    final forMe = me == null
        ? <BloodRequest>[]
        : matchRequests(me, blood.requests);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('blood_donation'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // Intro
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.secondary,
                  child: Icon(
                    Icons.bloodtype,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr('blood_intro'),
                    style: text.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.add_circle_outline,
                  title: context.tr('need_blood'),
                  subtitle: context.tr('need_blood_desc'),
                  onTap: () => context.push('/blood/request'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionCard(
                  icon: Icons.volunteer_activism,
                  title: context.tr(
                    me == null ? 'want_donate' : 'my_donor_card',
                  ),
                  subtitle: context.tr(
                    me == null ? 'want_donate_desc' : 'edit',
                  ),
                  onTap: () => context.push('/blood/donor'),
                ),
              ),
            ],
          ),

          // My donor card + requests I can answer
          if (me != null) ...[
            const SizedBox(height: 12),
            _MyDonorCard(donor: me),
            if (forMe.isNotEmpty) ...[
              SectionHeader(context.tr('requests_for_you')),
              for (final r in forMe.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BloodRequestCard(request: r),
                ),
            ],
          ],

          // All requests
          SectionHeader(context.tr('blood_requests')),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(context.tr('all')),
                    selected: _type == null,
                    onSelected: (_) => setState(() => _type = null),
                  ),
                ),
                for (final t in bloodTypes)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(t, textDirection: TextDirection.ltr),
                      selected: _type == t,
                      onSelected: (_) => setState(() => _type = t),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (requests.isEmpty)
            EmptyState(
              icon: Icons.bloodtype_outlined,
              message: context.tr('no_requests'),
            )
          else
            for (final r in requests)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BloodRequestCard(request: r),
              ),

          const SizedBox(height: 8),
          const _CompatibilityTable(),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.lock_outline, size: 16, color: AppColors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.tr('blood_privacy'),
                  style: text.bodySmall?.copyWith(color: AppColors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary,
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              Text(subtitle, style: text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyDonorCard extends ConsumerWidget {
  const _MyDonorCard({required this.donor});
  final BloodDonor donor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final next = donor.nextEligibleDate;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.primary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                BloodTypeBadge(donor.bloodType, size: 58),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('my_donor_card'),
                        style: text.labelMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        donor.name,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${donor.city} • ${context.tr(contactKey(donor.contact))}',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.tr('edit'),
                  onPressed: () => context.push('/blood/donor'),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: donor.available,
              onChanged: (v) =>
                  ref.read(bloodProvider.notifier).setMyAvailability(v),
              title: Text(
                context.tr('available_to_donate'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                donor.eligibleNow || next == null
                    ? context.tr('eligible_now')
                    : context.tr('next_eligible', args: {'date': _date(next)}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BloodRequestCard extends ConsumerWidget {
  const BloodRequestCard({super.key, required this.request});
  final BloodRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = request;
    final donors = ref.watch(bloodProvider).donors;
    final matches = matchDonors(r, donors).length;
    final text = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/blood/request/${r.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              BloodTypeBadge(r.bloodType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.patientName,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${r.hospital} • ${r.city}',
                      style: text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (!r.isOpen)
                          Pill(
                            label: context.tr('fulfilled'),
                            color: AppColors.success,
                            icon: Icons.check,
                          )
                        else if (r.urgent)
                          Pill(
                            label: context.tr('urgency_urgent'),
                            color: AppColors.emergency,
                            icon: Icons.bolt,
                          ),
                        Pill(
                          label: context.tr('units_n', args: {'n': r.units}),
                          color: AppColors.primary,
                        ),
                        if (r.isOpen)
                          Pill(
                            label: context.tr(
                              'matching_count',
                              args: {'n': matches},
                            ),
                            color: AppColors.info,
                            icon: Icons.people_outline,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                context.timeAgo(r.createdAt),
                style: text.labelSmall?.copyWith(color: AppColors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompatibilityTable extends StatelessWidget {
  const _CompatibilityTable();

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.info_outline, color: AppColors.primary),
        title: Text(
          context.tr('compat_title'),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          for (final t in bloodTypes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  BloodTypeBadge(t, size: 34),
                  const SizedBox(width: 10),
                  Text(
                    '${context.tr('receives_from')}: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Text(
                      _typesText(t),
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
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
// Shared form pieces
// ---------------------------------------------------------------------------

class _BloodTypePicker extends StatelessWidget {
  const _BloodTypePicker({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in bloodTypes)
          ChoiceChip(
            label: Text(
              t,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: value == t ? Colors.white : AppColors.primary,
              ),
            ),
            selected: value == t,
            showCheckmark: false,
            selectedColor: AppColors.primary,
            onSelected: (_) => onChanged(t),
          ),
      ],
    );
  }
}

class _ContactPicker extends StatelessWidget {
  const _ContactPicker({required this.value, required this.onChanged});
  final ContactMethod value;
  final ValueChanged<ContactMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ContactMethod>(
      segments: [
        for (final m in ContactMethod.values)
          ButtonSegment(
            value: m,
            icon: Icon(contactIcon(m)),
            label: Text(context.tr(contactKey(m))),
          ),
      ],
      selected: {value},
      showSelectedIcon: false,
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

String? _phoneValidator(BuildContext context, String? v) {
  final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return context.tr('required_field');
  if (digits.length < 9) return context.tr('phone_invalid');
  return null;
}

Widget _label(BuildContext context, String key) => Padding(
  padding: const EdgeInsets.only(top: 18, bottom: 8),
  child: Text(
    context.tr(key),
    style: Theme.of(context).textTheme.titleSmall
        ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
  ),
);

// ---------------------------------------------------------------------------
// New blood request
// ---------------------------------------------------------------------------

class NewBloodRequestScreen extends ConsumerStatefulWidget {
  const NewBloodRequestScreen({super.key});
  @override
  ConsumerState<NewBloodRequestScreen> createState() =>
      _NewBloodRequestScreenState();
}

class _NewBloodRequestScreenState extends ConsumerState<NewBloodRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: ref.read(authProvider).displayName,
  );
  final _hospital = TextEditingController();
  final _city = TextEditingController();
  late final _phone = TextEditingController(text: ref.read(authProvider).phone);
  final _note = TextEditingController();
  String? _type;
  int _units = 1;
  bool _urgent = false;
  ContactMethod _contact = ContactMethod.call;

  @override
  void dispose() {
    for (final c in [_name, _hospital, _city, _phone, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final typeMissing = _type == null;
    if (!_formKey.currentState!.validate() || typeMissing) {
      if (typeMissing) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('blood_type_needed'))),
        );
      }
      return;
    }
    final id = ref
        .read(bloodProvider.notifier)
        .addRequest(
          patientName: _name.text,
          bloodType: _type!,
          units: _units,
          hospital: _hospital.text,
          city: _city.text,
          urgent: _urgent,
          phone: _phone.text,
          contact: _contact,
          note: _note.text,
        );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr('blood_request_posted'))));
    context.pushReplacement('/blood/request/$id');
  }

  @override
  Widget build(BuildContext context) {
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? context.tr('required_field') : null;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('request_blood'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            _label(context, 'blood_type_needed'),
            _BloodTypePicker(
              value: _type,
              onChanged: (t) => setState(() => _type = t),
            ),
            if (_type != null) ...[
              const SizedBox(height: 8),
              Text(
                '${context.tr('receives_from')}: ${_typesText(_type!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            _label(context, 'units_needed'),
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: _units > 1 ? () => setState(() => _units--) : null,
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Text(
                    context.tr('units_n', args: {'n': _units}),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _units < 10
                      ? () => setState(() => _units++)
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              color: _urgent ? AppColors.emergency : null,
              child: SwitchListTile(
                value: _urgent,
                onChanged: (v) => setState(() => _urgent = v),
                secondary: Icon(
                  Icons.bolt,
                  color: _urgent ? Colors.white : AppColors.emergency,
                ),
                title: Text(
                  context.tr('urgent_request'),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _urgent ? Colors.white : null,
                  ),
                ),
                subtitle: Text(
                  context.tr('urgent_request_desc'),
                  style: TextStyle(color: _urgent ? Colors.white : null),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                labelText: context.tr('patient_name'),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hospital,
              decoration: InputDecoration(
                labelText: context.tr('hospital'),
                prefixIcon: const Icon(Icons.local_hospital_outlined),
              ),
              validator: required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              decoration: InputDecoration(
                labelText: context.tr('city'),
                prefixIcon: const Icon(Icons.location_city_outlined),
              ),
              validator: required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
              ],
              decoration: InputDecoration(
                labelText: context.tr('phone'),
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              validator: (v) => _phoneValidator(context, v),
            ),
            _label(context, 'contact_method'),
            _ContactPicker(
              value: _contact,
              onChanged: (m) => setState(() => _contact = m),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.tr('note_optional'),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send),
              label: Text(context.tr('submit_blood_request')),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Request details: matching donors (for the requester) or volunteering
// (for a donor)
// ---------------------------------------------------------------------------

class BloodRequestDetailsScreen extends ConsumerWidget {
  const BloodRequestDetailsScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blood = ref.watch(bloodProvider);
    final r = blood.request(id);
    if (r == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.search_off,
          message: context.tr('no_requests'),
        ),
      );
    }
    final text = Theme.of(context).textTheme;
    final mine = r.requesterId == MockData.currentPatientId;
    final me = blood.myDonor;
    final matches = matchDonors(r, blood.donors);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(mine ? 'your_request' : 'request_blood')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      BloodTypeBadge(r.bloodType, size: 66),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.patientName,
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text('${r.hospital} • ${r.city}'),
                            Text(
                              context.timeAgo(r.createdAt),
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (!r.isOpen)
                        Pill(
                          label: context.tr('fulfilled'),
                          color: AppColors.success,
                          icon: Icons.check,
                        )
                      else if (r.urgent)
                        Pill(
                          label: context.tr('urgency_urgent'),
                          color: AppColors.emergency,
                          icon: Icons.bolt,
                        ),
                      Pill(
                        label: context.tr('units_n', args: {'n': r.units}),
                        color: AppColors.primary,
                      ),
                      Pill(
                        label:
                            '${context.tr('receives_from')}: ${_typesText(r.bloodType)}',
                        color: AppColors.info,
                      ),
                      if (r.volunteerIds.isNotEmpty)
                        Pill(
                          label: context.tr(
                            'volunteers_count',
                            args: {'n': r.volunteerIds.length},
                          ),
                          color: AppColors.success,
                          icon: Icons.favorite,
                        ),
                    ],
                  ),
                  if (r.note.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(r.note, style: text.bodyLarge),
                  ],
                ],
              ),
            ),
          ),

          if (mine)
            ..._requesterView(context, ref, r, matches)
          else
            ..._donorView(context, ref, r, me),
        ],
      ),
    );
  }

  List<Widget> _requesterView(
    BuildContext context,
    WidgetRef ref,
    BloodRequest r,
    List<BloodDonor> matches,
  ) {
    return [
      SectionHeader('${context.tr('matching_donors')} (${matches.length})'),
      if (matches.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(context.tr('no_matching_donors')),
          ),
        )
      else
        for (final d in matches)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DonorMatchCard(
              donor: d,
              request: r,
              volunteered: r.volunteerIds.contains(d.id),
            ),
          ),
      if (r.isOpen) ...[
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            ref.read(bloodProvider.notifier).markFulfilled(r.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('marked_fulfilled'))),
            );
          },
          icon: const Icon(Icons.check_circle_outline),
          label: Text(context.tr('mark_fulfilled')),
        ),
      ],
    ];
  }

  List<Widget> _donorView(
    BuildContext context,
    WidgetRef ref,
    BloodRequest r,
    BloodDonor? me,
  ) {
    if (!r.isOpen) return const [];
    final volunteered = me != null && r.volunteerIds.contains(me.id);

    if (volunteered) {
      return [
        SectionHeader(context.tr('contact_requester')),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('volunteered'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ContactButtons(phone: r.phone, preferred: r.contact),
              ],
            ),
          ),
        ),
      ];
    }

    final String? blocker;
    if (me == null) {
      blocker = context.tr('must_register_donor');
    } else if (!canDonate(me.bloodType, r.bloodType)) {
      blocker = context.tr('not_compatible', args: {'type': me.bloodType});
    } else {
      blocker = null;
    }

    return [
      const SizedBox(height: 16),
      if (blocker != null) ...[
        Text(blocker, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        if (me == null)
          FilledButton.icon(
            onPressed: () => context.push('/blood/donor'),
            icon: const Icon(Icons.volunteer_activism),
            label: Text(context.tr('register_donor')),
          ),
      ] else
        FilledButton.icon(
          onPressed: () {
            ref.read(bloodProvider.notifier).volunteer(r.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('thanks_volunteer'))),
            );
          },
          icon: const Icon(Icons.favorite),
          label: Text(context.tr('i_can_donate')),
        ),
    ];
  }
}

class _DonorMatchCard extends StatelessWidget {
  const _DonorMatchCard({
    required this.donor,
    required this.request,
    required this.volunteered,
  });
  final BloodDonor donor;
  final BloodRequest request;
  final bool volunteered;

  @override
  Widget build(BuildContext context) {
    final sameCity =
        donor.city.trim().toLowerCase() == request.city.trim().toLowerCase();
    final exact = donor.bloodType == request.bloodType;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                BloodTypeBadge(donor.bloodType, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donor.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(donor.city),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (volunteered)
                  Pill(
                    label: context.tr('volunteered'),
                    color: AppColors.success,
                    icon: Icons.favorite,
                  ),
                if (sameCity)
                  Pill(
                    label: context.tr('same_city'),
                    color: AppColors.primary,
                    icon: Icons.place_outlined,
                  ),
                Pill(
                  label: context.tr(exact ? 'exact_type' : 'compatible'),
                  color: AppColors.info,
                  icon: Icons.check,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ContactButtons(phone: donor.phone, preferred: donor.contact),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Donor registration
// ---------------------------------------------------------------------------

class DonorRegisterScreen extends ConsumerStatefulWidget {
  const DonorRegisterScreen({super.key});
  @override
  ConsumerState<DonorRegisterScreen> createState() =>
      _DonorRegisterScreenState();
}

class _DonorRegisterScreenState extends ConsumerState<DonorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final BloodDonor? _existing = ref.read(bloodProvider).myDonor;
  late final _name = TextEditingController(
    text: _existing?.name ?? ref.read(authProvider).displayName,
  );
  late final _city = TextEditingController(text: _existing?.city ?? '');
  late final _phone = TextEditingController(
    text: _existing?.phone ?? ref.read(authProvider).phone,
  );
  late String? _type =
      _existing?.bloodType ?? ref.read(healthProfileProvider).bloodType;
  late ContactMethod _contact = _existing?.contact ?? ContactMethod.whatsapp;
  late bool _available = _existing?.available ?? true;
  late bool _share = _existing?.shareContact ?? false;
  late DateTime? _lastDonation = _existing?.lastDonation;

  @override
  void dispose() {
    for (final c in [_name, _city, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastDonation ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (picked != null) setState(() => _lastDonation = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate() || _type == null) return;
    if (!_share) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('share_contact_required'))),
      );
      return;
    }
    ref
        .read(bloodProvider.notifier)
        .saveMyDonor(
          name: _name.text,
          bloodType: _type!,
          city: _city.text,
          phone: _phone.text,
          contact: _contact,
          available: _available,
          shareContact: _share,
          lastDonation: _lastDonation,
        );
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr('donor_saved'))));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? context.tr('required_field') : null;
    final next = _lastDonation?.add(BloodDonor.minInterval);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('register_donor'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            _label(context, 'blood_type'),
            _BloodTypePicker(
              value: _type,
              onChanged: (t) => setState(() => _type = t),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                labelText: context.tr('full_name'),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              decoration: InputDecoration(
                labelText: context.tr('city'),
                prefixIcon: const Icon(Icons.location_city_outlined),
              ),
              validator: required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
              ],
              decoration: InputDecoration(
                labelText: context.tr('phone'),
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              validator: (v) => _phoneValidator(context, v),
            ),
            _label(context, 'contact_method'),
            _ContactPicker(
              value: _contact,
              onChanged: (m) => setState(() => _contact = m),
            ),
            _label(context, 'last_donation'),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event_outlined),
                    label: Text(
                      _lastDonation == null
                          ? context.tr('never_donated')
                          : _date(_lastDonation!),
                    ),
                  ),
                ),
                if (_lastDonation != null)
                  IconButton(
                    tooltip: context.tr('clear'),
                    onPressed: () => setState(() => _lastDonation = null),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              next == null || !next.isAfter(DateTime.now())
                  ? context.tr('eligible_now')
                  : context.tr('next_eligible', args: {'date': _date(next)}),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    value: _available,
                    onChanged: (v) => setState(() => _available = v),
                    title: Text(context.tr('available_to_donate')),
                  ),
                  CheckboxListTile(
                    value: _share,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (v) => setState(() => _share = v ?? false),
                    title: Text(context.tr('share_contact_consent')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('blood_privacy'),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.volunteer_activism),
              label: Text(context.tr('save_donor')),
            ),
          ],
        ),
      ),
    );
  }
}
