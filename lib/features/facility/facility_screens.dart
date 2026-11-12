import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/facility_provider.dart';
import '../../core/l10n.dart';
import '../../core/summons_provider.dart';
import '../../models/summons.dart';
import '../summons/summons_screens.dart';
import '../../core/search.dart';
import '../../core/theme.dart';
import '../../models/blood.dart';
import '../../models/facility.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/media.dart';
import '../blood/blood_screens.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String facilityTypeKey(FacilityType t) => 'ft_${t.name}';

IconData facilityTypeIcon(FacilityType t) => switch (t) {
  FacilityType.hospital => Icons.local_hospital_outlined,
  FacilityType.clinic => Icons.medical_services_outlined,
  FacilityType.lab => Icons.biotech_outlined,
  FacilityType.pharmacy => Icons.local_pharmacy_outlined,
  FacilityType.radiology => Icons.monitor_heart_outlined,
};

String referralStatusKey(ReferralStatus s) => 'rs_${s.name}';

Color referralStatusColor(ReferralStatus s) => switch (s) {
  ReferralStatus.sent => AppColors.info,
  ReferralStatus.accepted => AppColors.primary,
  ReferralStatus.inProgress => AppColors.warning,
  ReferralStatus.completed => AppColors.success,
  ReferralStatus.declined => AppColors.grey,
};

String facilityStatusKey(FacilityStatus s) => 'fs_${s.name}';

Color facilityStatusColor(FacilityStatus s) => switch (s) {
  FacilityStatus.pending => AppColors.warning,
  FacilityStatus.needsInfo => AppColors.info,
  FacilityStatus.approved => AppColors.success,
  FacilityStatus.rejected => AppColors.grey,
};

String coopKey(CooperationType c) => 'coop_${c.name}';

IconData coopIcon(CooperationType c) => switch (c) {
  CooperationType.free => Icons.volunteer_activism_outlined,
  CooperationType.discounted => Icons.percent,
  CooperationType.referrals => Icons.assignment_ind_outlined,
};

String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';

Widget _line(BuildContext context, IconData icon, String label, String value) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
          Expanded(child: Text(value.isEmpty ? '—' : value)),
        ],
      ),
    );

/// Chips describing what the facility offers to the association.
class CooperationChips extends StatelessWidget {
  const CooperationChips({super.key, required this.facility});
  final MedicalFacility facility;

  @override
  Widget build(BuildContext context) {
    final f = facility;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final c in CooperationType.values)
          if (f.cooperation.contains(c))
            Pill(
              icon: coopIcon(c),
              color: AppColors.secondary,
              label:
                  c == CooperationType.discounted && f.discountPercent != null
                  ? context.tr(
                      'discount_value',
                      args: {'n': f.discountPercent!},
                    )
                  : context.tr(coopKey(c)),
            ),
      ],
    );
  }
}

class FacilityAvatar extends StatelessWidget {
  const FacilityAvatar(this.type, {super.key, this.radius = 24});
  final FacilityType type;
  final double radius;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: AppColors.primary,
    child: Icon(facilityTypeIcon(type), color: Colors.white, size: radius),
  );
}

// ---------------------------------------------------------------------------
// Entry: register a new facility or open its account
// ---------------------------------------------------------------------------

class FacilityEntryScreen extends ConsumerWidget {
  const FacilityEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('role_facility'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.secondary,
              child: const Icon(
                Icons.local_hospital_outlined,
                size: 46,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.tr('role_facility'),
            textAlign: TextAlign.center,
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('facility_intro'),
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(height: 1.7),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in FacilityType.values)
                Chip(
                  avatar: Icon(
                    facilityTypeIcon(t),
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: Text(context.tr(facilityTypeKey(t))),
                ),
            ],
          ),
          const SizedBox(height: 18),
          for (final c in CooperationType.values)
            Card(
              child: ListTile(
                leading: Icon(coopIcon(c), color: AppColors.primary),
                title: Text(
                  context.tr(coopKey(c)),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(context.tr('${coopKey(c)}_desc')),
              ),
            ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            onPressed: () => context.push('/facility/register'),
            icon: const Icon(Icons.app_registration),
            label: Text(context.tr('facility_register')),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
            onPressed: () => context.push('/facility/login'),
            icon: const Icon(Icons.login),
            label: Text(context.tr('facility_login')),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Registration form
// ---------------------------------------------------------------------------

/// Registration in 5 steps: basic data, type/specialties/services,
/// manager/contact/address, licence and legal documents, review and send.
class FacilityRegisterScreen extends ConsumerStatefulWidget {
  const FacilityRegisterScreen({super.key});
  @override
  ConsumerState<FacilityRegisterScreen> createState() =>
      _FacilityRegisterScreenState();
}

class _FacilityRegisterScreenState
    extends ConsumerState<FacilityRegisterScreen> {
  final _forms = List.generate(5, (_) => GlobalKey<FormState>());
  int _step = 0;

  FacilityType _type = FacilityType.hospital;
  final _name = TextEditingController();
  final _manager = TextEditingController();
  final _license = TextEditingController();
  final _city = TextEditingController(text: 'نواكشوط');
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _service = TextEditingController();
  final _discount = TextEditingController(text: '30');
  final _capacity = TextEditingController(text: '10');
  final _notes = TextEditingController();
  final Set<String> _specialties = {};
  final List<String> _services = [];
  final Set<CooperationType> _coop = {CooperationType.referrals};
  Attachment? _licenseDoc;
  final List<Attachment> _documents = [];
  bool _consent = false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _manager,
      _license,
      _city,
      _address,
      _phone,
      _email,
      _service,
      _discount,
      _capacity,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? context.tr('required_field') : null;

  void _snack(String key) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr(key))));

  void _addService() {
    final s = _service.text.trim();
    if (s.isEmpty || _services.contains(s)) return;
    setState(() {
      _services.add(s);
      _service.clear();
    });
  }

  Future<void> _pickLicense() async {
    final files = await pickAttachments(
      context,
      PickSource.files,
      category: AttachmentCategory.other,
    );
    if (files.isNotEmpty) setState(() => _licenseDoc = files.first);
  }

  Future<void> _pickDocuments() async {
    final files = await pickAttachments(
      context,
      PickSource.files,
      category: AttachmentCategory.other,
    );
    if (files.isNotEmpty) setState(() => _documents.addAll(files));
  }

  /// Validates the current step before moving on.
  bool _stepValid(int i) {
    if (!(_forms[i].currentState?.validate() ?? true)) return false;
    if (i == 1) {
      _addService();
      if (_coop.isEmpty) {
        _snack('facility_need_coop');
        return false;
      }
    }
    if (i == 3 && _licenseDoc == null) {
      _snack('license_required');
      return false;
    }
    return true;
  }

  void _next() {
    if (!_stepValid(_step)) return;
    if (_step < 4) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _submit() {
    if (!_consent) return;
    final id = ref
        .read(facilityProvider.notifier)
        .register(
          type: _type,
          name: _name.text,
          managerName: _manager.text,
          licenseNumber: _license.text,
          city: _city.text,
          address: _address.text,
          phone: _phone.text,
          email: _email.text,
          specialtyIds: _specialties.toList(),
          services: _services,
          cooperation: {..._coop},
          discountPercent: int.tryParse(_discount.text.trim()),
          monthlyCapacity: int.tryParse(_capacity.text.trim()),
          notes: _notes.text,
          licenseDocument: _licenseDoc,
          documents: [..._documents],
        );
    ref.read(facilitySessionProvider.notifier).signIn(id);
    _snack('facility_submitted');
    context.go('/facility/home');
  }

  Widget _label(String key) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      context.tr(key),
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
  );

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);

    // 1. Basic data
    final basic = Column(
      children: [
        TextFormField(
          controller: _name,
          validator: _required,
          decoration: InputDecoration(
            labelText: context.tr('facility_name'),
            prefixIcon: Icon(facilityTypeIcon(_type)),
          ),
        ),
        gap,
        TextFormField(
          controller: _license,
          validator: _required,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText: context.tr('facility_license'),
            prefixIcon: const Icon(Icons.verified_outlined),
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
      ],
    );

    // 2. Type, specialties, services and cooperation
    final services = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('facility_type'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in FacilityType.values)
              ChoiceChip(
                avatar: Icon(facilityTypeIcon(t), size: 18),
                label: Text(context.tr(facilityTypeKey(t))),
                selected: _type == t,
                onSelected: (_) => setState(() => _type = t),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _label('facility_specialties'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in Specialty.all)
              FilterChip(
                label: Text(context.tr(s.key)),
                selected: _specialties.contains(s.id),
                onSelected: (v) => setState(
                  () => v ? _specialties.add(s.id) : _specialties.remove(s.id),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _label('facility_services'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _service,
                onSubmitted: (_) => _addService(),
                decoration: InputDecoration(
                  hintText: context.tr('facility_services_hint'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _addService,
              child: Text(context.tr('add')),
            ),
          ],
        ),
        if (_services.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in _services)
                InputChip(
                  label: Text(s),
                  onDeleted: () => setState(() => _services.remove(s)),
                ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        _label('facility_section_coop'),
        for (final c in CooperationType.values) ...[
          Card(
            child: CheckboxListTile(
              value: _coop.contains(c),
              onChanged: (v) =>
                  setState(() => v == true ? _coop.add(c) : _coop.remove(c)),
              secondary: Icon(coopIcon(c), color: AppColors.primary),
              title: Text(
                context.tr(coopKey(c)),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(context.tr('${coopKey(c)}_desc')),
            ),
          ),
          if (c == CooperationType.discounted && _coop.contains(c))
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
              child: TextFormField(
                controller: _discount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n < 1 || n > 100)
                      ? context.tr('required_field')
                      : null;
                },
                decoration: InputDecoration(
                  labelText: context.tr('discount_percent'),
                  prefixIcon: const Icon(Icons.percent),
                ),
              ),
            ),
          if (c == CooperationType.referrals && _coop.contains(c))
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
              child: TextFormField(
                controller: _capacity,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: context.tr('monthly_capacity'),
                  prefixIcon: const Icon(Icons.groups_outlined),
                ),
              ),
            ),
        ],
      ],
    );

    // 3. Manager, contact and address
    final contact = Column(
      children: [
        TextFormField(
          controller: _manager,
          validator: _required,
          decoration: InputDecoration(
            labelText: context.tr('facility_manager'),
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ),
        gap,
        TextFormField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9 +]')),
          ],
          validator: (v) {
            final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
            return d.length < 8 ? context.tr('required_field') : null;
          },
          decoration: InputDecoration(
            labelText: context.tr('phone'),
            prefixIcon: const Icon(Icons.phone_outlined),
            prefixText: '+222 ',
          ),
        ),
        gap,
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText: context.tr('email'),
            prefixIcon: const Icon(Icons.alternate_email),
          ),
        ),
        gap,
        TextFormField(
          controller: _address,
          validator: _required,
          decoration: InputDecoration(
            labelText: context.tr('address'),
            prefixIcon: const Icon(Icons.place_outlined),
          ),
        ),
      ],
    );

    // 4. Official licence and legal documents
    final documents = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('facility_license_doc'),
        if (_licenseDoc == null)
          OutlinedButton.icon(
            onPressed: _pickLicense,
            icon: const Icon(Icons.upload_file),
            label: Text(context.tr('facility_license_doc')),
          )
        else
          AttachmentTile(
            _licenseDoc!,
            onRemove: () => setState(() => _licenseDoc = null),
          ),
        const SizedBox(height: 14),
        _label('legal_documents'),
        Text(
          context.tr('legal_documents_hint'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        for (final d in _documents)
          AttachmentTile(
            d,
            onRemove: () => setState(() => _documents.remove(d)),
          ),
        OutlinedButton.icon(
          onPressed: _pickDocuments,
          icon: const Icon(Icons.note_add_outlined),
          label: Text(context.tr('add_document')),
        ),
      ],
    );

    // 5. Review and send
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _line(
          context,
          facilityTypeIcon(_type),
          context.tr('facility_name'),
          '${_name.text} (${context.tr(facilityTypeKey(_type))})',
        ),
        _line(
          context,
          Icons.verified_outlined,
          context.tr('facility_license'),
          _license.text,
        ),
        _line(
          context,
          Icons.person_outline,
          context.tr('facility_manager'),
          _manager.text,
        ),
        _line(context, Icons.phone_outlined, context.tr('phone'), _phone.text),
        _line(
          context,
          Icons.place_outlined,
          context.tr('address'),
          '${_city.text} — ${_address.text}',
        ),
        _line(
          context,
          Icons.handshake_outlined,
          context.tr('facility_section_coop'),
          [
            for (final c in CooperationType.values)
              if (_coop.contains(c)) context.tr(coopKey(c)),
          ].join('، '),
        ),
        _line(
          context,
          Icons.folder_outlined,
          context.tr('documents'),
          '${(_licenseDoc == null ? 0 : 1) + _documents.length}',
        ),
        gap,
        TextFormField(
          controller: _notes,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: context.tr('facility_notes'),
            alignLabelWithHint: true,
          ),
        ),
        CheckboxListTile(
          value: _consent,
          onChanged: (v) => setState(() => _consent = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(
            context.tr('facility_consent'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );

    final contents = [basic, services, contact, documents, summary];
    const titles = [
      'fstep_basic',
      'fstep_services',
      'fstep_contact',
      'fstep_documents',
      'fstep_send',
    ];

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('facility_register'))),
      body: Stepper(
        currentStep: _step,
        onStepTapped: (i) {
          // Going back is free; going forward validates each step.
          if (i < _step) return setState(() => _step = i);
          for (var s = _step; s < i; s++) {
            if (!_stepValid(s)) return setState(() => _step = s);
          }
          setState(() => _step = i);
        },
        onStepContinue: _next,
        onStepCancel: _step == 0 ? null : () => setState(() => _step--),
        controlsBuilder: (context, details) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: _step == 4 && !_consent
                      ? null
                      : details.onStepContinue,
                  icon: Icon(_step == 4 ? Icons.send : Icons.arrow_forward),
                  label: Text(
                    context.tr(_step == 4 ? 'facility_submit' : 'next'),
                  ),
                ),
              ),
              if (_step > 0) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: details.onStepCancel,
                  child: Text(context.tr('back')),
                ),
              ],
            ],
          ),
        ),
        steps: [
          for (var i = 0; i < 5; i++)
            Step(
              title: Text(
                context.tr(titles[i]),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              isActive: _step >= i,
              state: _step > i ? StepState.complete : StepState.indexed,
              content: Form(key: _forms[i], child: contents[i]),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Login (phone + licence number)
// ---------------------------------------------------------------------------

class FacilityLoginScreen extends ConsumerStatefulWidget {
  const FacilityLoginScreen({super.key});
  @override
  ConsumerState<FacilityLoginScreen> createState() =>
      _FacilityLoginScreenState();
}

class _FacilityLoginScreenState extends ConsumerState<FacilityLoginScreen> {
  final _phone = TextEditingController();
  final _license = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _license.dispose();
    super.dispose();
  }

  void _login() {
    final f = findFacilityAccount(
      ref.read(facilityProvider),
      _phone.text,
      _license.text,
    );
    if (f == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('facility_login_failed'))),
      );
      return;
    }
    ref.read(facilitySessionProvider.notifier).signIn(f.id);
    context.go('/facility/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('facility_login'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: FacilityAvatar(FacilityType.hospital, radius: 36),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: context.tr('phone'),
              prefixIcon: const Icon(Icons.phone_outlined),
              prefixText: '+222 ',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _license,
            textDirection: TextDirection.ltr,
            onSubmitted: (_) => _login(),
            decoration: InputDecoration(
              labelText: context.tr('facility_license'),
              prefixIcon: const Icon(Icons.verified_outlined),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            onPressed: _login,
            icon: const Icon(Icons.login),
            label: Text(context.tr('facility_login')),
          ),
          const SizedBox(height: 16),
          Card(
            color: AppColors.secondary,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(context.tr('facility_demo_hint'))),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _phone.text = '45 25 10 10';
              _license.text = 'MS-NKC-2019-114';
              _login();
            },
            child: Text(context.tr('demo_login')),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Facility account: referrals + profile
// ---------------------------------------------------------------------------

class FacilityHomeScreen extends ConsumerStatefulWidget {
  const FacilityHomeScreen({super.key});
  @override
  ConsumerState<FacilityHomeScreen> createState() => _FacilityHomeScreenState();
}

class _FacilityHomeScreenState extends ConsumerState<FacilityHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final id = ref.watch(facilitySessionProvider);
    final state = ref.watch(facilityProvider);
    final f = state.facility(id);
    if (f == null) return const FacilityEntryScreen();

    void logout() {
      ref.read(facilitySessionProvider.notifier).signOut();
      context.go('/role');
    }

    final appBar = AppBar(
      title: Text(f.name, overflow: TextOverflow.ellipsis),
      actions: [
        IconButton(
          tooltip: context.tr('logout'),
          onPressed: logout,
          icon: const Icon(Icons.logout),
        ),
      ],
    );

    if (!f.isApproved) {
      return Scaffold(
        appBar: appBar,
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _RegistrationStatusCard(facility: f),
            const SizedBox(height: 12),
            if (f.status == FacilityStatus.needsInfo) ...[
              _CompleteDocumentsCard(facility: f),
              const SizedBox(height: 12),
            ],
            FacilityHistory(facility: f),
            const SizedBox(height: 12),
            _FacilityProfile(facility: f),
          ],
        ),
      );
    }

    final referrals = state.referralsOf(f.id);
    return Scaffold(
      appBar: appBar,
      body: Column(
        children: [
          // Step 8: the facility is told its account is now active.
          if (!f.approvalSeen)
            MaterialBanner(
              backgroundColor: AppColors.secondary,
              leading: const Icon(
                Icons.verified,
                color: AppColors.success,
                size: 32,
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('approval_notice_title'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(context.tr('approval_notice_body')),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => ref
                      .read(facilityProvider.notifier)
                      .markApprovalSeen(f.id),
                  child: Text(context.tr('got_it')),
                ),
              ],
            ),
          Expanded(
            child: _tab == 0
                ? _ReferralsTab(referrals: referrals)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _FacilityProfile(facility: f),
                      const SizedBox(height: 12),
                      FacilityHistory(facility: f),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: referrals.any(
                (r) => r.status == ReferralStatus.sent,
              ),
              child: const Icon(Icons.assignment_ind_outlined),
            ),
            label: context.tr('facility_tab_referrals'),
          ),
          NavigationDestination(
            icon: Icon(facilityTypeIcon(f.type)),
            label: context.tr('facility_tab_profile'),
          ),
        ],
      ),
    );
  }
}

/// Where the request stands (pending / documents requested / rejected).
class _RegistrationStatusCard extends StatelessWidget {
  const _RegistrationStatusCard({required this.facility});
  final MedicalFacility facility;

  @override
  Widget build(BuildContext context) {
    final f = facility;
    final text = Theme.of(context).textTheme;
    final (icon, title, body) = switch (f.status) {
      FacilityStatus.needsInfo => (
        Icons.upload_file,
        'fs_needsInfo',
        'needs_info_body',
      ),
      FacilityStatus.rejected => (
        Icons.block,
        'facility_rejected_title',
        'facility_rejected_body',
      ),
      _ => (
        Icons.hourglass_top,
        'facility_pending_title',
        'facility_pending_body',
      ),
    };
    final color = facilityStatusColor(f.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: color,
              child: Icon(icon, color: AppColors.on(color), size: 32),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr(title),
              textAlign: TextAlign.center,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(body),
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(height: 1.6),
            ),
            if (f.teamNote.isNotEmpty &&
                f.status != FacilityStatus.pending) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('team_message'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(f.teamNote),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Step 7 (facility side): upload what the association asked for.
class _CompleteDocumentsCard extends ConsumerStatefulWidget {
  const _CompleteDocumentsCard({required this.facility});
  final MedicalFacility facility;
  @override
  ConsumerState<_CompleteDocumentsCard> createState() =>
      _CompleteDocumentsCardState();
}

class _CompleteDocumentsCardState
    extends ConsumerState<_CompleteDocumentsCard> {
  final List<Attachment> _files = [];
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final files = await pickAttachments(
      context,
      PickSource.files,
      category: AttachmentCategory.other,
    );
    if (files.isNotEmpty) setState(() => _files.addAll(files));
  }

  void _send() {
    ref
        .read(facilityProvider.notifier)
        .resubmit(widget.facility.id, documents: [..._files], note: _note.text);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr('resent_msg'))));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('complete_and_resend'),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            for (final d in _files)
              AttachmentTile(
                d,
                onRemove: () => setState(() => _files.remove(d)),
              ),
            OutlinedButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.note_add_outlined),
              label: Text(context.tr('add_document')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: InputDecoration(labelText: context.tr('resend_note')),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: _files.isEmpty ? null : _send,
              icon: const Icon(Icons.send),
              label: Text(context.tr('complete_and_resend')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Timeline of the registration request, seen by both sides.
class FacilityHistory extends StatelessWidget {
  const FacilityHistory({super.key, required this.facility});
  final MedicalFacility facility;

  String _key(FacilityEvent e, int i) => switch (e.status) {
    FacilityStatus.pending => i == 0 ? 'fe_submitted' : 'fe_resubmitted',
    FacilityStatus.needsInfo => 'fe_needsInfo',
    FacilityStatus.approved => 'fe_approved',
    FacilityStatus.rejected => 'fe_rejected',
  };

  @override
  Widget build(BuildContext context) {
    final h = facility.history;
    if (h.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('registration_history'),
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < h.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 14,
                      color: facilityStatusColor(h[i].status),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(_key(h[i], i)),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          if (h[i].note.isNotEmpty) Text(h[i].note),
                          Text(
                            '${_date(h[i].at)} • ${context.timeAgo(h[i].at)}',
                            style: text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReferralsTab extends StatefulWidget {
  const _ReferralsTab({required this.referrals});
  final List<Referral> referrals;
  @override
  State<_ReferralsTab> createState() => _ReferralsTabState();
}

class _ReferralsTabState extends State<_ReferralsTab> {
  int _filter = 0; // 0 new, 1 in follow-up, 2 closed

  @override
  Widget build(BuildContext context) {
    final all = widget.referrals;
    final groups = [
      all.where((r) => r.status == ReferralStatus.sent).toList(),
      all
          .where(
            (r) =>
                r.status == ReferralStatus.accepted ||
                r.status == ReferralStatus.inProgress,
          )
          .toList(),
      all.where((r) => !r.isOpen).toList(),
    ];
    final labels = ['referrals_new', 'referrals_open', 'referrals_closed'];
    final colors = [AppColors.info, AppColors.warning, AppColors.success];
    final list = groups[_filter];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: StatCard(
                    icon: [
                      Icons.fiber_new_outlined,
                      Icons.pending_actions_outlined,
                      Icons.task_alt,
                    ][i],
                    value: '${groups[i].length}',
                    label: context.tr(labels[i]),
                    color: colors[i],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            for (var i = 0; i < 3; i++)
              ButtonSegment(value: i, label: Text(context.tr(labels[i]))),
          ],
          selected: {_filter},
          onSelectionChanged: (s) => setState(() => _filter = s.first),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          EmptyState(
            icon: Icons.inbox_outlined,
            message: context.tr('no_referrals'),
          ),
        for (final r in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ReferralCard(
              referral: r,
              onTap: () => context.push('/facility/referral/${r.id}'),
            ),
          ),
      ],
    );
  }
}

class ReferralCard extends StatelessWidget {
  const ReferralCard({
    super.key,
    required this.referral,
    this.onTap,
    this.subtitle,
  });
  final Referral referral;
  final VoidCallback? onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final r = referral;
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
                  Expanded(
                    child: Text(
                      '${r.code} • ${r.patientName}',
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (r.urgent)
                    Pill(
                      label: context.tr('referral_urgent'),
                      color: AppColors.emergency,
                      icon: Icons.priority_high,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.medical_information_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(r.service)),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: text.bodySmall),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Pill(
                    label: context.tr(referralStatusKey(r.status)),
                    color: referralStatusColor(r.status),
                  ),
                  const Spacer(),
                  Text(context.timeAgo(r.updatedAt), style: text.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FacilityProfile extends StatelessWidget {
  const _FacilityProfile({required this.facility});
  final MedicalFacility facility;

  @override
  Widget build(BuildContext context) {
    final f = facility;
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                FacilityAvatar(f.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.name,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${context.tr(facilityTypeKey(f.type))} • ${f.code}',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Pill(
                  label: f.isApproved
                      ? context.tr('facility_approved_badge')
                      : context.tr(facilityStatusKey(f.status)),
                  color: facilityStatusColor(f.status),
                  icon: f.isApproved ? Icons.verified : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _line(
              context,
              Icons.person_outline,
              context.tr('facility_manager'),
              f.managerName,
            ),
            _line(
              context,
              Icons.verified_outlined,
              context.tr('facility_license'),
              f.licenseNumber,
            ),
            _line(
              context,
              Icons.place_outlined,
              context.tr('address'),
              '${f.city} — ${f.address}',
            ),
            _line(context, Icons.phone_outlined, context.tr('phone'), f.phone),
            if (f.email.isNotEmpty)
              _line(
                context,
                Icons.alternate_email,
                context.tr('email'),
                f.email,
              ),
            if (f.specialtyIds.isNotEmpty)
              _line(
                context,
                Icons.local_hospital_outlined,
                context.tr('facility_specialties'),
                f.specialtyIds
                    .map((s) => context.tr(Specialty.byId(s).key))
                    .join('، '),
              ),
            if (f.services.isNotEmpty)
              _line(
                context,
                Icons.list_alt,
                context.tr('facility_services'),
                f.services.join('، '),
              ),
            if (f.monthlyCapacity != null)
              _line(
                context,
                Icons.groups_outlined,
                context.tr('monthly_capacity'),
                context.tr('capacity_value', args: {'n': f.monthlyCapacity!}),
              ),
            if (f.notes.isNotEmpty)
              _line(
                context,
                Icons.notes,
                context.tr('facility_notes'),
                f.notes,
              ),
            const SizedBox(height: 8),
            Text(
              context.tr('facility_section_coop'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            CooperationChips(facility: f),
            if (f.licenseDocument != null || f.documents.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                context.tr('documents'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in [?f.licenseDocument, ...f.documents])
                    InkWell(
                      onTap: () => showAttachmentPreview(context, d),
                      child: AttachmentThumb(d, size: 64),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Referral details (facility side): move the case forward
// ---------------------------------------------------------------------------

class FacilityReferralScreen extends ConsumerWidget {
  const FacilityReferralScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(facilityProvider);
    final session = ref.watch(facilitySessionProvider);
    Referral? r;
    for (final x in state.referrals) {
      if (x.id == id) r = x;
    }
    // A facility only sees its own referrals.
    if (r == null || r.facilityId != session) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.inbox_outlined,
          message: context.tr('no_referrals'),
        ),
      );
    }
    final referral = r;
    final text = Theme.of(context).textTheme;

    final summons = ref.watch(summonsProvider.notifier).bySource(referral.id);
    ref.watch(summonsProvider);

    /// Accepting a referred patient = giving an appointment: a summons card
    /// is issued to the patient with the facility's details.
    Future<void> issueSummons({required bool accepting}) async {
      final f = state.facility(referral.facilityId)!;
      final draft = await showSummonsForm(
        context,
        place: summons?.place ?? f.address,
        city: summons?.city ?? f.city,
        instructions: summons?.instructions ?? '',
        appointment: summons?.appointment,
        title: context.tr(accepting ? 'ra_accepted' : 'summons_update'),
      );
      if (draft == null || !context.mounted) return;
      if (accepting) {
        ref
            .read(facilityProvider.notifier)
            .updateReferral(
              referral.id,
              ReferralStatus.accepted,
              note:
                  '${summonsDate(context, draft.appointment)} ${summonsTime(draft.appointment)}',
            );
      }
      final id = ref
          .read(summonsProvider.notifier)
          .issue(
            patientId: referral.patientId.isEmpty
                ? 'ref:${referral.patientRef}'
                : referral.patientId,
            patientName: referral.patientName,
            patientRef: referral.patientRef,
            issuer: SummonsIssuer.facility,
            issuerId: f.id,
            issuerName: f.name,
            issuerDetailKey: facilityTypeKey(f.type),
            issuerPhone: f.phone,
            place: draft.place,
            city: draft.city,
            appointment: draft.appointment,
            instructions: draft.instructions,
            sourceId: referral.id,
          );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('summons_issued_msg'))));
      context.push('/summons/$id');
    }

    Future<void> step(ReferralStatus next) async {
      if (next == ReferralStatus.accepted) {
        return issueSummons(accepting: true);
      }
      final note = TextEditingController(text: referral.facilityNote);
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.tr('ra_${next.name}')),
          content: TextField(
            controller: note,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: ctx.tr('referral_update_note'),
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
      final value = note.text.trim();
      note.dispose();
      if (ok != true || !context.mounted) return;
      ref
          .read(facilityProvider.notifier)
          .updateReferral(referral.id, next, note: value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('referral_updated_msg'))),
      );
    }

    final steps = nextReferralSteps(referral.status);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('referral_details'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReferralDetailsCard(referral: referral),
          const SizedBox(height: 12),
          ReferralTimeline(status: referral.status),
          if (summons != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => context.push('/summons/${summons.id}'),
                    icon: const Icon(Icons.badge_outlined),
                    label: Text(context.tr('summons_view')),
                  ),
                ),
                if (referral.isOpen) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => issueSummons(accepting: false),
                      icon: const Icon(Icons.edit_calendar),
                      label: Text(context.tr('summons_update')),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 16),
          for (final s in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: s == ReferralStatus.declined
                  ? OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        foregroundColor: AppColors.grey,
                      ),
                      onPressed: () => step(s),
                      icon: const Icon(Icons.close),
                      label: Text(context.tr('ra_${s.name}')),
                    )
                  : FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 50),
                      ),
                      onPressed: () => step(s),
                      icon: const Icon(Icons.check),
                      label: Text(context.tr('ra_${s.name}')),
                    ),
            ),
          if (steps.isEmpty)
            Text(
              context.tr(referralStatusKey(referral.status)),
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(
                color: referralStatusColor(referral.status),
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class ReferralDetailsCard extends StatelessWidget {
  const ReferralDetailsCard({super.key, required this.referral});
  final Referral referral;

  @override
  Widget build(BuildContext context) {
    final r = referral;
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.code,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Pill(
                  label: context.tr(referralStatusKey(r.status)),
                  color: referralStatusColor(r.status),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${context.tr('referral_from_association')} • ${_date(r.createdAt)}',
              style: text.bodySmall,
            ),
            if (r.urgent) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Pill(
                  label: context.tr('referral_urgent'),
                  color: AppColors.emergency,
                  icon: Icons.priority_high,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _line(
              context,
              Icons.person_outline,
              context.tr('referral_patient_name'),
              r.patientName,
            ),
            _line(
              context,
              Icons.folder_shared_outlined,
              context.tr('referral_patient_ref'),
              r.patientRef,
            ),
            _line(
              context,
              Icons.medical_information_outlined,
              context.tr('referral_service'),
              r.service,
            ),
            if (r.notes.isNotEmpty)
              _line(
                context,
                Icons.notes,
                context.tr('referral_notes'),
                r.notes,
              ),
            if (r.facilityNote.isNotEmpty)
              _line(
                context,
                Icons.comment_outlined,
                context.tr('facility_note'),
                r.facilityNote,
              ),
            Text(
              context.tr(
                'last_update',
                args: {'t': context.timeAgo(r.updatedAt)},
              ),
              style: text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class ReferralTimeline extends StatelessWidget {
  const ReferralTimeline({super.key, required this.status});
  final ReferralStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == ReferralStatus.declined) {
      return Pill(
        label: context.tr('rs_declined'),
        color: AppColors.grey,
        icon: Icons.close,
      );
    }
    const order = [
      ReferralStatus.sent,
      ReferralStatus.accepted,
      ReferralStatus.inProgress,
      ReferralStatus.completed,
    ];
    final reached = order.indexOf(status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < order.length; i++)
              ListTile(
                dense: true,
                leading: Icon(
                  i <= reached
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: i <= reached ? AppColors.success : AppColors.grey,
                ),
                title: Text(
                  context.tr(referralStatusKey(order[i])),
                  style: TextStyle(
                    fontWeight: i == reached
                        ? FontWeight.w900
                        : FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Association side («فريق المتابعة والإدارة»)
// ---------------------------------------------------------------------------

/// Association (steps 6-8): verification checklist and decision.
class FacilityReviewPanel extends ConsumerWidget {
  const FacilityReviewPanel({super.key, required this.facility});
  final MedicalFacility facility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = facility;
    final text = Theme.of(context).textTheme;
    final notifier = ref.read(facilityProvider.notifier);

    Future<void> decide(
      FacilityStatus decision,
      String labelKey,
      String messageKey,
    ) async {
      String note = '';
      if (decision != FacilityStatus.approved) {
        final controller = TextEditingController();
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            var error = false;
            return StatefulBuilder(
              builder: (ctx, setState) => AlertDialog(
                title: Text(
                  ctx.tr(
                    decision == FacilityStatus.rejected
                        ? 'reject'
                        : 'request_completion',
                  ),
                ),
                content: TextField(
                  controller: controller,
                  maxLines: 3,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: ctx.tr(labelKey),
                    alignLabelWithHint: true,
                    errorText: error ? ctx.tr('reason_required') : null,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(ctx.tr('cancel')),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (controller.text.trim().isEmpty) {
                        setState(() => error = true);
                      } else {
                        Navigator.pop(ctx, true);
                      }
                    },
                    child: Text(ctx.tr('confirm')),
                  ),
                ],
              ),
            );
          },
        );
        note = controller.text;
        controller.dispose();
        if (ok != true) return;
      }
      if (!context.mounted) return;
      notifier.review(f.id, decision, note: note);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr(messageKey))));
    }

    final open =
        f.status == FacilityStatus.pending ||
        f.status == FacilityStatus.needsInfo;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('verification'),
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            for (final c in VerificationCheck.values)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: f.checks.contains(c),
                onChanged: open ? (_) => notifier.toggleCheck(f.id, c) : null,
                title: Text(context.tr('vc_${c.name}')),
              ),
            if (open) ...[
              const Divider(height: 24),
              Text(
                context.tr('decision'),
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                onPressed: f.isVerified
                    ? () => decide(
                        FacilityStatus.approved,
                        '',
                        'facility_approved_msg',
                      )
                    : null,
                icon: const Icon(Icons.verified),
                label: Text(context.tr('approve')),
              ),
              if (!f.isVerified)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    context.tr('verify_first'),
                    textAlign: TextAlign.center,
                    style: text.bodySmall,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                      ),
                      onPressed: () => decide(
                        FacilityStatus.needsInfo,
                        'missing_documents',
                        'completion_requested_msg',
                      ),
                      icon: const Icon(Icons.upload_file),
                      label: Text(context.tr('request_completion')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        foregroundColor: AppColors.grey,
                      ),
                      onPressed: () => decide(
                        FacilityStatus.rejected,
                        'reject_reason',
                        'facility_rejected_msg',
                      ),
                      icon: const Icon(Icons.close),
                      label: Text(context.tr('reject')),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Committee dashboard tab: review facility registrations, approve them and
/// refer patients to approved facilities.
class CommitteeFacilitiesTab extends ConsumerStatefulWidget {
  const CommitteeFacilitiesTab({super.key});
  @override
  ConsumerState<CommitteeFacilitiesTab> createState() =>
      _CommitteeFacilitiesTabState();
}

class _CommitteeFacilitiesTabState
    extends ConsumerState<CommitteeFacilitiesTab> {
  FacilityStatus? _status;
  FacilityType? _type;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(facilityProvider);
    final list =
        state.facilities
            .where((f) => _status == null || f.status == _status)
            .where((f) => _type == null || f.type == _type)
            .where(
              (f) => Search.matches(_query, [
                f.name,
                f.city,
                f.code,
                f.managerName,
                ...f.services,
              ]),
            )
            .toList()
          ..sort((a, b) {
            final p = a.status.index.compareTo(b.status.index);
            return p != 0 ? p : b.createdAt.compareTo(a.createdAt);
          });

    Widget chip(String label, bool selected, VoidCallback onTap) => Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: context.tr('facilities'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              chip(
                context.tr('all'),
                _status == null,
                () => setState(() => _status = null),
              ),
              for (final s in FacilityStatus.values)
                chip(
                  context.tr(facilityStatusKey(s)),
                  _status == s,
                  () => setState(() => _status = s),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              chip(
                context.tr('all'),
                _type == null,
                () => setState(() => _type = null),
              ),
              for (final t in FacilityType.values)
                chip(
                  context.tr(facilityTypeKey(t)),
                  _type == t,
                  () => setState(() => _type = t),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (list.isEmpty)
          EmptyState(
            icon: Icons.local_hospital_outlined,
            message: context.tr('no_facilities'),
          ),
        for (final f in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CommitteeFacilityCard(facility: f),
          ),
      ],
    );
  }
}

class CommitteeFacilityCard extends ConsumerWidget {
  const CommitteeFacilityCard({super.key, required this.facility});
  final MedicalFacility facility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = facility;
    final text = Theme.of(context).textTheme;
    final referrals = ref.watch(facilityProvider).referralsOf(f.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/committee/facility/${f.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  FacilityAvatar(f.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.name,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${f.code} • ${context.tr(facilityTypeKey(f.type))} • ${f.city}',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Pill(
                    label: context.tr(facilityStatusKey(f.status)),
                    color: facilityStatusColor(f.status),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CooperationChips(facility: f),
              if (f.services.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  f.services.join('، '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall,
                ),
              ],
              if (f.isApproved && referrals.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  context.tr('referrals_count', args: {'n': referrals.length}),
                  style: text.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
              const SizedBox(height: 10),
              if (!f.isApproved && f.status != FacilityStatus.rejected)
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: () => context.push('/committee/facility/${f.id}'),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(context.tr('review_request')),
                )
              else if (f.isApproved)
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: () => showReferPatientSheet(context, ref, f),
                  icon: const Icon(Icons.assignment_ind_outlined),
                  label: Text(context.tr('refer_patient')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Association: refer a patient to an approved facility.
Future<void> showReferPatientSheet(
  BuildContext context,
  WidgetRef ref,
  MedicalFacility facility,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _ReferPatientForm(facility: facility),
  );
}

class _ReferPatientForm extends ConsumerStatefulWidget {
  const _ReferPatientForm({required this.facility});
  final MedicalFacility facility;
  @override
  ConsumerState<_ReferPatientForm> createState() => _ReferPatientFormState();
}

class _ReferPatientFormState extends ConsumerState<_ReferPatientForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _ref = TextEditingController();
  final _service = TextEditingController();
  final _notes = TextEditingController();
  bool _urgent = false;

  @override
  void dispose() {
    for (final c in [_name, _ref, _service, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? context.tr('required_field') : null;

  void _send() {
    if (!_form.currentState!.validate()) return;
    ref
        .read(facilityProvider.notifier)
        .refer(
          facilityId: widget.facility.id,
          patientName: _name.text,
          patientRef: _ref.text,
          service: _service.text,
          notes: _notes.text,
          urgent: _urgent,
        );
    final messenger = ScaffoldMessenger.of(context);
    final msg = context.tr('referral_sent_msg');
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);
    final f = widget.facility;
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
                '${context.tr('refer_patient')} — ${f.name}',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              if (f.services.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in f.services)
                      ActionChip(
                        label: Text(s),
                        onPressed: () => setState(() => _service.text = s),
                      ),
                  ],
                ),
              ],
              gap,
              TextFormField(
                controller: _name,
                validator: _required,
                decoration: InputDecoration(
                  labelText: context.tr('referral_patient_name'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              gap,
              TextFormField(
                controller: _ref,
                validator: _required,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: context.tr('referral_patient_ref'),
                  prefixIcon: const Icon(Icons.folder_shared_outlined),
                  hintText: 'P-021',
                ),
              ),
              gap,
              TextFormField(
                controller: _service,
                validator: _required,
                decoration: InputDecoration(
                  labelText: context.tr('referral_service'),
                  prefixIcon: const Icon(Icons.medical_information_outlined),
                ),
              ),
              gap,
              TextFormField(
                controller: _notes,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: context.tr('referral_notes'),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _urgent,
                onChanged: (v) => setState(() => _urgent = v),
                title: Text(context.tr('referral_urgent')),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
                onPressed: _send,
                icon: const Icon(Icons.send),
                label: Text(context.tr('referral_send')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Association: a facility's file, contact and its referrals' status.
class CommitteeFacilityScreen extends ConsumerWidget {
  const CommitteeFacilityScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(facilityProvider);
    final f = state.facility(id);
    if (f == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.local_hospital_outlined,
          message: context.tr('no_facilities'),
        ),
      );
    }
    final referrals = state.referralsOf(f.id);
    return Scaffold(
      appBar: AppBar(title: Text(f.name, overflow: TextOverflow.ellipsis)),
      floatingActionButton: f.isApproved
          ? FloatingActionButton.extended(
              onPressed: () => showReferPatientSheet(context, ref, f),
              icon: const Icon(Icons.assignment_ind_outlined),
              label: Text(context.tr('refer_patient')),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _FacilityProfile(facility: f),
          const SizedBox(height: 8),
          ContactButtons(phone: f.phone, preferred: ContactMethod.call),
          const SizedBox(height: 10),
          FacilityReviewPanel(facility: f),
          const SizedBox(height: 10),
          FacilityHistory(facility: f),
          if (f.isApproved) ...[
            SectionHeader(context.tr('referrals_of_facility')),
            if (referrals.isEmpty)
              EmptyState(
                icon: Icons.inbox_outlined,
                message: context.tr('no_referrals'),
              ),
            for (final r in referrals)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ReferralCard(
                  referral: r,
                  subtitle: r.facilityNote.isEmpty
                      ? null
                      : '${context.tr('facility_note')}: ${r.facilityNote}',
                ),
              ),
          ],
        ],
      ),
    );
  }
}
