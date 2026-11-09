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
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/media.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

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
// Blood donation section: donor registration only
// ---------------------------------------------------------------------------

String donorStatusKey(DonorStatus s) => 'donor_status_${s.name}';

Color donorStatusColor(DonorStatus s) => switch (s) {
  DonorStatus.pending => AppColors.warning,
  DonorStatus.approved => AppColors.success,
  DonorStatus.rejected => AppColors.grey,
};

class DonorStatusPill extends StatelessWidget {
  const DonorStatusPill(this.status, {super.key});
  final DonorStatus status;
  @override
  Widget build(BuildContext context) => Pill(
    label: context.tr(donorStatusKey(status)),
    color: donorStatusColor(status),
    icon: switch (status) {
      DonorStatus.pending => Icons.hourglass_top,
      DonorStatus.approved => Icons.verified,
      DonorStatus.rejected => Icons.block,
    },
  );
}

/// "تبرع بالدم": registered patients and volunteer doctors register as
/// blood donors; the committee reviews the registrations.
class BloodHomeScreen extends ConsumerWidget {
  const BloodHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(bloodProvider).myDonor;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('blood_donation'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
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
                    context.tr('donor_section_intro'),
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
          const SizedBox(height: 16),
          if (me == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.volunteer_activism,
                      size: 52,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.tr('become_donor_title'),
                      textAlign: TextAlign.center,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('become_donor_desc'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.push('/blood/donor'),
                      icon: const Icon(Icons.how_to_reg),
                      label: Text(context.tr('register_donor')),
                    ),
                  ],
                ),
              ),
            )
          else
            _MyDonorCard(donor: me),
          const SizedBox(height: 16),
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

class _MyDonorCard extends ConsumerWidget {
  const _MyDonorCard({required this.donor});
  final BloodDonor donor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final note = switch (donor.status) {
      DonorStatus.pending => 'donor_pending_note',
      DonorStatus.approved => 'donor_approved_note',
      DonorStatus.rejected => 'donor_rejected_note',
    };
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.primary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                BloodTypeBadge(donor.bloodType, size: 60),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${context.tr('my_donor_card')} • ${donor.code}',
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
                        '${donor.city} • ${donor.phone}',
                        textDirection: TextDirection.rtl,
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
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: DonorStatusPill(donor.status),
            ),
            const SizedBox(height: 8),
            Text(context.tr(note)),
            if (donor.isApproved)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: donor.available,
                onChanged: (v) =>
                    ref.read(bloodProvider.notifier).setMyAvailability(v),
                title: Text(
                  context.tr('available_to_donate'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String bloodStatusKey(BloodRequestStatus s) => 'status_${s.name}';

Color bloodStatusColor(BloodRequestStatus s) => switch (s) {
  BloodRequestStatus.submitted => AppColors.warning,
  BloodRequestStatus.inProgress => AppColors.info,
  BloodRequestStatus.matched => AppColors.primary,
  BloodRequestStatus.fulfilled => AppColors.success,
  BloodRequestStatus.cancelled => AppColors.grey,
};

class BloodStatusPill extends StatelessWidget {
  const BloodStatusPill(this.status, {super.key});
  final BloodRequestStatus status;
  @override
  Widget build(BuildContext context) => Pill(
    label: context.tr(bloodStatusKey(status)),
    color: bloodStatusColor(status),
    icon: status == BloodRequestStatus.fulfilled ? Icons.check : null,
  );
}

/// Request summary. Outside the committee the patient's name is replaced by
/// the request code and initials (except for the requester's own request).
class BloodRequestCard extends ConsumerWidget {
  const BloodRequestCard({
    super.key,
    required this.request,
    this.forCommittee = false,
  });
  final BloodRequest request;
  final bool forCommittee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = request;
    final donors = ref.watch(bloodProvider).donors;
    final matches = matchDonors(r, donors).length;
    final text = Theme.of(context).textTheme;
    final showName = forCommittee || r.requesterId == MockData.currentPatientId;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          forCommittee
              ? '/committee/request/${r.id}'
              : '/patient/blood/${r.id}',
        ),
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
                      showName
                          ? '${r.code} • ${r.patientName}'
                          : '${r.code} • ${maskName(r.patientName)}',
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
                        if (r.isOpen && r.urgent)
                          Pill(
                            label: context.tr('urgency_urgent'),
                            color: AppColors.emergency,
                            icon: Icons.bolt,
                          ),
                        BloodStatusPill(r.status),
                        Pill(
                          label: context.tr('units_n', args: {'n': r.units}),
                          color: AppColors.primary,
                        ),
                        if (r.isOpen && forCommittee)
                          Pill(
                            label: context.tr(
                              'matching_count',
                              args: {'n': matches},
                            ),
                            color: AppColors.info,
                            icon: Icons.people_outline,
                          ),
                        if (forCommittee && r.assignedDonorIds.isNotEmpty)
                          Pill(
                            label: context.tr(
                              'linked_n',
                              args: {'n': r.assignedDonorIds.length},
                            ),
                            color: AppColors.success,
                            icon: Icons.link,
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
// Blood requests: only from the patient's own profile
// ---------------------------------------------------------------------------

/// The patient's blood requests (Profile > Blood requests).
class MyBloodRequestsScreen extends ConsumerWidget {
  const MyBloodRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine =
        ref
            .watch(bloodProvider)
            .requests
            .where((r) => r.requesterId == MockData.currentPatientId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('my_blood_requests'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/patient/blood/new'),
        icon: const Icon(Icons.add),
        label: Text(context.tr('new_blood_request')),
      ),
      body: mine.isEmpty
          ? EmptyState(
              icon: Icons.bloodtype_outlined,
              message: context.tr('no_blood_requests'),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                Text(context.tr('committee_reviews_request')),
                const SizedBox(height: 12),
                for (final r in mine)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: BloodRequestCard(request: r),
                  ),
              ],
            ),
    );
  }
}

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
  // Guests (no account) start with empty fields.
  late final _auth = ref.read(authProvider);
  late final _name = TextEditingController(
    text: _auth.loggedIn ? _auth.displayName : '',
  );
  final _requester = TextEditingController();
  RequesterRelation _relation = RequesterRelation.self;
  final _hospital = TextEditingController();
  final _city = TextEditingController();
  late final _phone = TextEditingController(text: _auth.phone);
  final _note = TextEditingController();
  final List<Attachment> _docs = [];
  String? _type;
  int _units = 1;
  bool _urgent = false;
  ContactMethod _contact = ContactMethod.call;

  @override
  void dispose() {
    for (final c in [_name, _requester, _hospital, _city, _phone, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _addDocs(PickSource source) async {
    final files = await pickAttachments(
      context,
      source,
      category: AttachmentCategory.prescription,
    );
    if (mounted && files.isNotEmpty) setState(() => _docs.addAll(files));
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
          requesterName: _relation == RequesterRelation.self
              ? _name.text
              : _requester.text,
          relation: _relation,
          bloodType: _type!,
          units: _units,
          hospital: _hospital.text,
          city: _city.text,
          urgent: _urgent,
          phone: _phone.text,
          contact: _contact,
          note: _note.text,
          documents: List.of(_docs),
        );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr('blood_request_posted'))));
    context.pushReplacement('/patient/blood/$id');
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
            _label(context, 'quantity'),
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
            _label(context, 'relation'),
            SegmentedButton<RequesterRelation>(
              segments: [
                for (final rel in RequesterRelation.values)
                  ButtonSegment(
                    value: rel,
                    label: Text(context.tr('relation_${rel.name}')),
                  ),
              ],
              selected: {_relation},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _relation = v.first),
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
            if (_relation != RequesterRelation.self) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _requester,
                decoration: InputDecoration(
                  labelText: context.tr('requester_name'),
                  prefixIcon: const Icon(Icons.family_restroom),
                ),
                validator: required,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _hospital,
              decoration: InputDecoration(
                labelText: context.tr('location_hospital'),
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
                labelText: context.tr('contact_number'),
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
            _label(context, 'medical_document'),
            Text(
              context.tr('medical_document_hint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _docs.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AttachmentTile(
                  _docs[i],
                  onRemove: () => setState(() => _docs.removeAt(i)),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addDocs(PickSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(context.tr('camera')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addDocs(PickSource.files),
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Text(context.tr('pdf_file')),
                  ),
                ),
              ],
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
// Request details (the requester follows the committee's progress)
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

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('your_request'))),
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
                              mine
                                  ? '${r.code} • ${r.patientName}'
                                  : '${r.code} • ${maskName(r.patientName)}',
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
                      if (r.isOpen && r.urgent)
                        Pill(
                          label: context.tr('urgency_urgent'),
                          color: AppColors.emergency,
                          icon: Icons.bolt,
                        ),
                      BloodStatusPill(r.status),
                      Pill(
                        label: context.tr('units_n', args: {'n': r.units}),
                        color: AppColors.primary,
                      ),
                      Pill(
                        label:
                            '${context.tr('receives_from')}: ${_typesText(r.bloodType)}',
                        color: AppColors.info,
                      ),
                    ],
                  ),
                  // The note may contain personal details: requester only.
                  if (mine && r.note.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(r.note, style: text.bodyLarge),
                  ],
                  if (mine && r.documents.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final d in r.documents)
                          InkWell(
                            onTap: () => showAttachmentPreview(context, d),
                            child: AttachmentThumb(d, size: 60),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          ..._requesterView(context, ref, r),
        ],
      ),
    );
  }

  /// The requester follows the progress; donors' data stay with the
  /// committee.
  List<Widget> _requesterView(
    BuildContext context,
    WidgetRef ref,
    BloodRequest r,
  ) {
    return [
      SectionHeader(context.tr('request_status')),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BloodStatusTimeline(status: r.status),
              const SizedBox(height: 14),
              if (r.assignedDonorIds.isNotEmpty)
                Text(
                  context.tr(
                    'linked_n',
                    args: {'n': r.assignedDonorIds.length},
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              Text(context.tr('committee_reviews_request')),
            ],
          ),
        ),
      ),
      if (r.isOpen) ...[
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            ref.read(bloodProvider.notifier).markFulfilled(r.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('marked_fulfilled'))),
            );
          },
          icon: const Icon(Icons.check_circle_outline),
          label: Text(context.tr('mark_fulfilled')),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => ref
              .read(bloodProvider.notifier)
              .setStatus(r.id, BloodRequestStatus.cancelled),
          icon: const Icon(Icons.close),
          label: Text(context.tr('cancel_request')),
        ),
      ],
    ];
  }
}

/// submitted -> in progress -> matched -> fulfilled.
class BloodStatusTimeline extends StatelessWidget {
  const BloodStatusTimeline({super.key, required this.status});
  final BloodRequestStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == BloodRequestStatus.cancelled) {
      return const Align(
        alignment: AlignmentDirectional.centerStart,
        child: BloodStatusPill(BloodRequestStatus.cancelled),
      );
    }
    const steps = [
      (BloodRequestStatus.submitted, Icons.send_rounded),
      (BloodRequestStatus.inProgress, Icons.manage_search),
      (BloodRequestStatus.matched, Icons.link),
      (BloodRequestStatus.fulfilled, Icons.check),
    ];
    final reached = steps.indexWhere((s) => s.$1 == status);
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: i <= reached
                      ? AppColors.primary
                      : AppColors.border,
                  child: Icon(
                    steps[i].$2,
                    size: 17,
                    color: i <= reached ? Colors.white : AppColors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(bloodStatusKey(steps[i].$1)),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: i == reached ? FontWeight.w800 : null,
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

// ---------------------------------------------------------------------------
// Donor registration (name, blood type, city, phone)
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
  late final _auth = ref.read(authProvider);
  late final _name = TextEditingController(
    text: _existing?.name ?? (_auth.loggedIn ? _auth.displayName : ''),
  );
  late final _city = TextEditingController(text: _existing?.city ?? '');
  late final _phone = TextEditingController(
    text: _existing?.phone ?? _auth.phone,
  );
  late String? _type =
      _existing?.bloodType ??
      (_auth.loggedIn && !_auth.isDoctor
          ? ref.read(healthProfileProvider).bloodType
          : null);
  late bool _share = _existing?.shareContact ?? false;

  @override
  void dispose() {
    for (final c in [_name, _city, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_type == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr('blood_type'))));
      return;
    }
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
          shareContact: _share,
          kind: !_auth.loggedIn
              ? DonorKind.other
              : _auth.isDoctor
              ? DonorKind.doctor
              : DonorKind.patient,
          userId: _auth.userId,
        );
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr('donor_saved'))));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? context.tr('required_field') : null;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('register_donor'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                labelText: context.tr('full_name'),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: required,
            ),
            _label(context, 'blood_type'),
            _BloodTypePicker(
              value: _type,
              onChanged: (t) => setState(() => _type = t),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 12),
            Card(
              child: CheckboxListTile(
                value: _share,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) => setState(() => _share = v ?? false),
                title: Text(context.tr('share_contact_consent')),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.tr('donor_review_info'),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.grey),
                  ),
                ),
              ],
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
