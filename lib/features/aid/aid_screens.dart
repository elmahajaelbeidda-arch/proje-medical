import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../models/blood.dart' show ContactMethod;
import '../../widgets/common.dart';
import '../blood/blood_screens.dart' show ContactButtons;
import 'aid_models.dart';
import 'aid_providers.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _nouakchott = LatLng(nouakchottLat, nouakchottLng);

String _date(DateTime d) =>
    '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String urgencyLabelKey(AidUrgency u) => 'aid_urg_${u.name}';
String aidStatusKey(AidStatus s) => 'aid_st_${s.name}';

Color urgencyColorOf(AidUrgency u) => switch (u) {
  AidUrgency.urgent => AppColors.emergency,
  AidUrgency.medium => AppColors.warning,
  AidUrgency.normal => AppColors.success,
};

Color aidStatusColor(AidStatus s) => switch (s) {
  AidStatus.newRequest => AppColors.warning,
  AidStatus.verifying => AppColors.info,
  AidStatus.verified => AppColors.primary,
  AidStatus.helped => AppColors.success,
  AidStatus.closed => AppColors.grey,
};

/// OpenStreetMap tiles (free; identify the app as the tile policy asks).
TileLayer _osmTiles() => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'org.shifa.shifa',
  maxZoom: 19,
);

Widget _osmCredit(BuildContext context) => Positioned(
  left: 6,
  bottom: 4,
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    color: Colors.white,
    child: Text(
      context.tr('aid_osm_credit'),
      style: const TextStyle(fontSize: 10, color: AppColors.text),
    ),
  ),
);

void _snack(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

class _DemoBanner extends ConsumerWidget {
  const _DemoBanner();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(aidRepositoryProvider).isDemo) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(context.tr('aid_demo_mode'))),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Supabase sign in (patients and committee members)
// ---------------------------------------------------------------------------

class AidSignIn extends ConsumerStatefulWidget {
  const AidSignIn({super.key});
  @override
  ConsumerState<AidSignIn> createState() => _AidSignInState();
}

class _AidSignInState extends ConsumerState<AidSignIn> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final repo = ref.read(aidRepositoryProvider);
    setState(() => _busy = true);
    try {
      if (_signUp) {
        await repo.signUp(_email.text, _password.text);
        if (mounted) _snack(context, context.tr('aid_check_email'));
      } else {
        await repo.signIn(_email.text, _password.text);
      }
      ref.read(aidSessionProvider.notifier).changed();
    } catch (e) {
      if (mounted) _snack(context, context.tr('aid_error', args: {'e': e}));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(
          Icons.lock_person_outlined,
          size: 56,
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        Text(
          context.tr('aid_sign_in_title'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: context.tr('email'),
            prefixIcon: const Icon(Icons.alternate_email),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: InputDecoration(
            labelText: context.tr('password'),
            prefixIcon: const Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(context.tr(_signUp ? 'aid_sign_up' : 'login')),
        ),
        TextButton(
          onPressed: () => setState(() => _signUp = !_signUp),
          child: Text(context.tr(_signUp ? 'aid_have_account' : 'aid_sign_up')),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Patient: my requests
// ---------------------------------------------------------------------------

class MyAidRequestsScreen extends ConsumerWidget {
  const MyAidRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(aidSessionProvider);
    final repo = ref.watch(aidRepositoryProvider);
    if (!repo.signedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('aid_my_requests'))),
        body: const AidSignIn(),
      );
    }
    final mine = ref.watch(aidMineProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('aid_my_requests'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/aid/new'),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text(context.tr('aid_new')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          const _DemoBanner(),
          Text(context.tr('aid_intro')),
          const SizedBox(height: 12),
          ...mine.when(
            data: (list) => list.isEmpty
                ? [
                    EmptyState(
                      icon: Icons.location_off_outlined,
                      message: context.tr('aid_none'),
                    ),
                  ]
                : [
                    for (final r in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MyRequestCard(request: r),
                      ),
                  ],
            loading: () => [const Center(child: CircularProgressIndicator())],
            error: (e, _) => [
              Text(context.tr('aid_error', args: {'e': e})),
            ],
          ),
        ],
      ),
    );
  }
}

class _MyRequestCard extends StatelessWidget {
  const _MyRequestCard({required this.request});
  final AidRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    const steps = [
      AidStatus.newRequest,
      AidStatus.verifying,
      AidStatus.verified,
      AidStatus.helped,
    ];
    final reached = steps.indexOf(r.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.conditionDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 8),
                Pill(
                  label: context.tr(urgencyLabelKey(r.urgency)),
                  color: urgencyColorOf(r.urgency),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${r.addressNote} • ${context.timeAgo(r.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (r.status == AidStatus.closed)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Pill(
                  label: context.tr(aidStatusKey(r.status)),
                  color: aidStatusColor(r.status),
                ),
              )
            else
              Row(
                children: [
                  for (var i = 0; i < steps.length; i++)
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: i <= reached
                                ? AppColors.primary
                                : AppColors.border,
                            child: Icon(
                              i < reached ? Icons.check : Icons.circle,
                              size: i < reached ? 14 : 8,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr(aidStatusKey(steps[i])),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontWeight: i == reached
                                      ? FontWeight.w900
                                      : null,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Patient: request form with location picker and consent
// ---------------------------------------------------------------------------

class AidRequestFormScreen extends ConsumerStatefulWidget {
  const AidRequestFormScreen({super.key});
  @override
  ConsumerState<AidRequestFormScreen> createState() =>
      _AidRequestFormScreenState();
}

class _AidRequestFormScreenState extends ConsumerState<AidRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _condition = TextEditingController();
  final _address = TextEditingController();
  AidUrgency _urgency = AidUrgency.normal;
  LatLng? _location;
  bool _consent = false;
  bool _sending = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _condition, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_location == null) {
      _snack(context, context.tr('aid_location_required'));
      return;
    }
    if (!_consent) {
      _snack(context, context.tr('aid_consent_required'));
      return;
    }
    setState(() => _sending = true);
    try {
      await ref
          .read(aidRepositoryProvider)
          .submit(
            AidRequestDraft(
              patientName: _name.text,
              phone: _phone.text,
              latitude: _location!.latitude,
              longitude: _location!.longitude,
              addressNote: _address.text,
              conditionDescription: _condition.text,
              urgency: _urgency,
              consentGiven: _consent,
            ),
          );
      if (!mounted) return;
      _snack(context, context.tr('aid_sent'));
      context.pop();
    } catch (e) {
      if (mounted) _snack(context, context.tr('aid_error', args: {'e': e}));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? context.tr('required_field') : null;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('aid_title'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            const _DemoBanner(),
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
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
              ],
              decoration: InputDecoration(
                labelText: context.tr('phone'),
                hintText: 'XX XX XX XX',
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if (digits.isEmpty) return context.tr('required_field');
                if (digits.length < 8) return context.tr('phone_invalid');
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _condition,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: context.tr('aid_condition'),
                hintText: context.tr('aid_condition_hint'),
                alignLabelWithHint: true,
              ),
              validator: required,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('aid_urgency'),
              style: text.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<AidUrgency>(
              segments: [
                for (final u in AidUrgency.values)
                  ButtonSegment(
                    value: u,
                    label: Text(context.tr(urgencyLabelKey(u))),
                    icon: Icon(
                      Icons.circle,
                      size: 12,
                      color: urgencyColorOf(u),
                    ),
                  ),
              ],
              selected: {_urgency},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _urgency = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _address,
              decoration: InputDecoration(
                labelText: context.tr('aid_address_note'),
                prefixIcon: const Icon(Icons.signpost_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('aid_location'),
              style: text.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            LocationPicker(onChanged: (p) => setState(() => _location = p)),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _consent ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: CheckboxListTile(
                value: _consent,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) => setState(() => _consent = v ?? false),
                title: Text(context.tr('aid_consent')),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _sending ? null : _submit,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(context.tr('aid_submit')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Map with a pin fixed in the centre: "Locate me" uses the device position,
/// then the user moves the map to put the pin exactly on the house.
class LocationPicker extends StatefulWidget {
  const LocationPicker({super.key, required this.onChanged});
  final ValueChanged<LatLng?> onChanged;

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final _map = MapController();
  LatLng? _picked;
  bool _locating = false;

  void _set(LatLng p) {
    setState(() => _picked = p);
    widget.onChanged(p);
  }

  Future<void> _locate() async {
    final off = context.tr('aid_location_off');
    final denied = context.tr('aid_location_denied');
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) _snack(context, off);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) _snack(context, denied);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final p = LatLng(pos.latitude, pos.longitude);
      _map.move(p, 17);
      _set(p);
    } catch (e) {
      if (mounted) _snack(context, denied);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 280,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _nouakchott,
                    initialZoom: 13,
                    onPositionChanged: (camera, hasGesture) {
                      if (hasGesture) _set(camera.center);
                    },
                  ),
                  children: [_osmTiles()],
                ),
                // Pin fixed in the centre; its tip marks the location.
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 44),
                      child: Icon(
                        Icons.location_pin,
                        size: 48,
                        color: AppColors.emergency,
                      ),
                    ),
                  ),
                ),
                _osmCredit(context),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _locating ? null : _locate,
          icon: _locating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          label: Text(context.tr(_locating ? 'aid_locating' : 'aid_locate_me')),
        ),
        const SizedBox(height: 6),
        Text(
          _picked == null
              ? context.tr('aid_move_map_hint')
              : '${context.tr('aid_location_set')}: '
                    // Keep "lat, lng" in left-to-right order inside Arabic.
                    '\u2066${_picked!.latitude.toStringAsFixed(5)}, '
                    '${_picked!.longitude.toStringAsFixed(5)}\u2069',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _picked == null ? AppColors.grey : AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Committee: map of all requests
// ---------------------------------------------------------------------------

class AidMapScreen extends ConsumerStatefulWidget {
  const AidMapScreen({super.key});
  @override
  ConsumerState<AidMapScreen> createState() => _AidMapScreenState();
}

class _AidMapScreenState extends ConsumerState<AidMapScreen> {
  final _map = MapController();
  bool _openOnly = true;
  AidUrgency? _urgency;
  AidStatus? _status;
  bool _listView = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(aidSessionProvider);
    final repo = ref.watch(aidRepositoryProvider);
    if (!repo.signedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('aid_map'))),
        body: const AidSignIn(),
      );
    }
    final role = ref.watch(aidRoleProvider);
    return role.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(context.tr('aid_error', args: {'e': e}))),
      ),
      data: (role) => role == null
          ? Scaffold(
              appBar: AppBar(title: Text(context.tr('aid_map'))),
              body: EmptyState(
                icon: Icons.lock_outline,
                message: context.tr('aid_committee_only'),
              ),
            )
          : _buildMap(context, role),
    );
  }

  Widget _buildMap(BuildContext context, CommitteeRole role) {
    final all = ref.watch(aidAllProvider).value ?? const <AidRequest>[];
    final items =
        all
            .where((r) => !_openOnly || r.isOpen)
            .where((r) => _urgency == null || r.urgency == _urgency)
            .where((r) => _status == null || r.status == _status)
            .toList()
          ..sort((a, b) {
            final u = a.urgency.index.compareTo(b.urgency.index);
            return u != 0 ? u : b.createdAt.compareTo(a.createdAt);
          });

    Widget chip(
      String label,
      bool selected,
      VoidCallback onTap, {
      Color? dot,
    }) => Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: FilterChip(
        avatar: dot == null ? null : Icon(Icons.circle, size: 12, color: dot),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('aid_map')),
        actions: [
          IconButton(
            tooltip: context.tr('aid_list'),
            onPressed: () => setState(() => _listView = !_listView),
            icon: Icon(_listView ? Icons.map_outlined : Icons.list_alt),
          ),
          if (role == CommitteeRole.supervisor)
            IconButton(
              tooltip: context.tr('aid_members'),
              onPressed: () => context.push('/aid/members'),
              icon: const Icon(Icons.manage_accounts_outlined),
            ),
          if (!ref.read(aidRepositoryProvider).isDemo)
            IconButton(
              tooltip: context.tr('aid_sign_out'),
              onPressed: () async {
                await ref.read(aidRepositoryProvider).signOut();
                ref.read(aidSessionProvider.notifier).changed();
              },
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                chip(
                  context.tr('aid_open_only'),
                  _openOnly,
                  () => setState(() => _openOnly = !_openOnly),
                ),
                for (final u in AidUrgency.values)
                  chip(
                    context.tr(urgencyLabelKey(u)),
                    _urgency == u,
                    () => setState(() => _urgency = _urgency == u ? null : u),
                    dot: urgencyColorOf(u),
                  ),
                for (final s in AidStatus.values)
                  chip(
                    context.tr(aidStatusKey(s)),
                    _status == s,
                    () => setState(() => _status = _status == s ? null : s),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _listView
                ? ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      for (final r in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            child: ListTile(
                              onTap: () => _openSheet(context, r, role),
                              leading: CircleAvatar(
                                backgroundColor: urgencyColorOf(r.urgency),
                                child: const Icon(
                                  Icons.person_pin_circle,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                r.patientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                '${r.conditionDescription}\n${r.addressNote}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Pill(
                                label: context.tr(aidStatusKey(r.status)),
                                color: aidStatusColor(r.status),
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : Stack(
                    children: [
                      FlutterMap(
                        mapController: _map,
                        options: const MapOptions(
                          initialCenter: _nouakchott,
                          initialZoom: 12,
                        ),
                        children: [
                          _osmTiles(),
                          MarkerLayer(
                            markers: [
                              for (final r in items.reversed)
                                Marker(
                                  point: LatLng(r.latitude, r.longitude),
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.topCenter,
                                  child: GestureDetector(
                                    onTap: () => _openSheet(context, r, role),
                                    child: _AidPin(request: r),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      PositionedDirectional(
                        top: 8,
                        start: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            context.tr(
                              'aid_n_requests',
                              args: {'n': items.length},
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      _osmCredit(context),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _openSheet(BuildContext context, AidRequest r, CommitteeRole role) {
    _map.move(LatLng(r.latitude, r.longitude), 15);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AidRequestSheet(requestId: r.id, role: role),
    );
  }
}

class _AidPin extends StatelessWidget {
  const _AidPin({required this.request});
  final AidRequest request;

  @override
  Widget build(BuildContext context) {
    final done =
        request.status == AidStatus.helped ||
        request.status == AidStatus.closed;
    return Icon(
      done ? Icons.check_circle : Icons.location_pin,
      size: 44,
      color: done ? AppColors.grey : urgencyColorOf(request.urgency),
      shadows: const [Shadow(blurRadius: 4, color: Colors.black38)],
    );
  }
}

/// Details of a request for the committee, with contact, directions and
/// status actions (closing / deleting: supervisor only).
class AidRequestSheet extends ConsumerWidget {
  const AidRequestSheet({
    super.key,
    required this.requestId,
    required this.role,
  });
  final String requestId;
  final CommitteeRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(aidAllProvider).value ?? const <AidRequest>[];
    final r = list.where((e) => e.id == requestId).firstOrNull;
    if (r == null) return const SizedBox(height: 120);
    final repo = ref.read(aidRepositoryProvider);
    final supervisor = role == CommitteeRole.supervisor;
    final text = Theme.of(context).textTheme;

    Future<void> run(Future<void> Function() action, String okKey) async {
      try {
        await action();
        if (context.mounted) _snack(context, context.tr(okKey));
      } catch (e) {
        if (context.mounted) {
          _snack(context, context.tr('aid_error', args: {'e': e}));
        }
      }
    }

    final statuses = [
      AidStatus.newRequest,
      AidStatus.verifying,
      AidStatus.verified,
      AidStatus.helped,
      if (supervisor) AidStatus.closed,
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: urgencyColorOf(r.urgency),
                  child: const Icon(
                    Icons.person_pin_circle,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.patientName,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(context.timeAgo(r.createdAt), style: text.bodySmall),
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
                  label: context.tr(urgencyLabelKey(r.urgency)),
                  color: urgencyColorOf(r.urgency),
                ),
                Pill(
                  label: context.tr(aidStatusKey(r.status)),
                  color: aidStatusColor(r.status),
                ),
                if (r.verifiedAt != null)
                  Pill(
                    label: context.tr(
                      'aid_verified_on',
                      args: {'date': _date(r.verifiedAt!)},
                    ),
                    color: AppColors.primary,
                    icon: Icons.verified,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(r.conditionDescription, style: text.bodyLarge),
            if (r.addressNote.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.signpost_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(r.addressNote)),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '${r.latitude.toStringAsFixed(5)}, ${r.longitude.toStringAsFixed(5)}',
              textDirection: TextDirection.ltr,
              style: text.bodySmall,
            ),
            const SizedBox(height: 12),
            ContactButtons(phone: r.phone, preferred: ContactMethod.call),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(
                  'https://www.google.com/maps/dir/?api=1&destination=${r.latitude},${r.longitude}',
                ),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.directions),
              label: Text(context.tr('aid_directions')),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('aid_change_status'),
              style: text.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in statuses)
                  ChoiceChip(
                    label: Text(context.tr(aidStatusKey(s))),
                    selected: r.status == s,
                    showCheckmark: false,
                    selectedColor: aidStatusColor(s),
                    labelStyle: TextStyle(
                      color: r.status == s
                          ? AppColors.on(aidStatusColor(s))
                          : null,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (r.status == AidStatus.closed && !supervisor)
                        ? null
                        : (_) => run(
                            () => repo.setStatus(r.id, s),
                            'aid_status_updated',
                          ),
                  ),
              ],
            ),
            if (supervisor) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.emergency,
                ),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      content: Text(ctx.tr('aid_delete_confirm')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(ctx.tr('cancel')),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(ctx.tr('delete')),
                        ),
                      ],
                    ),
                  );
                  if (ok != true || !context.mounted) return;
                  await run(() => repo.delete(r.id), 'aid_deleted');
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline),
                label: Text(context.tr('aid_delete')),
              ),
            ] else ...[
              const SizedBox(height: 10),
              Text(
                context.tr('aid_supervisor_only'),
                style: text.bodySmall?.copyWith(color: AppColors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Supervisor: committee members
// ---------------------------------------------------------------------------

class AidMembersScreen extends ConsumerStatefulWidget {
  const AidMembersScreen({super.key});
  @override
  ConsumerState<AidMembersScreen> createState() => _AidMembersScreenState();
}

class _AidMembersScreenState extends ConsumerState<AidMembersScreen> {
  final _userId = TextEditingController();
  final _name = TextEditingController();
  CommitteeRole _role = CommitteeRole.member;

  @override
  void dispose() {
    _userId.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      if (mounted) _snack(context, context.tr('aid_error', args: {'e': e}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(aidRepositoryProvider);
    final role = ref.watch(aidRoleProvider).value;
    final members = ref.watch(aidMembersProvider).value ?? const [];
    final supervisor = role == CommitteeRole.supervisor;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('aid_members'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text(context.tr('aid_my_user_id')),
              subtitle: SelectableText(repo.currentUserId ?? '—'),
            ),
          ),
          const SizedBox(height: 12),
          for (final m in members)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: m.role == CommitteeRole.supervisor
                      ? AppColors.primary
                      : AppColors.secondary,
                  child: Icon(
                    m.role == CommitteeRole.supervisor
                        ? Icons.admin_panel_settings
                        : Icons.person,
                    color: m.role == CommitteeRole.supervisor
                        ? Colors.white
                        : AppColors.primary,
                  ),
                ),
                title: Text(
                  m.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${context.tr('aid_role_${m.role.name}')} • ${m.userId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: supervisor && m.userId != repo.currentUserId
                    ? TextButton(
                        onPressed: () =>
                            _run(() => repo.removeMember(m.userId)),
                        child: Text(context.tr('aid_remove')),
                      )
                    : null,
              ),
            ),
          if (supervisor) ...[
            SectionHeader(context.tr('aid_add_member')),
            TextField(
              controller: _userId,
              decoration: InputDecoration(
                labelText: context.tr('aid_member_user_id'),
                prefixIcon: const Icon(Icons.key_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: context.tr('full_name'),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<CommitteeRole>(
              segments: [
                for (final r in CommitteeRole.values)
                  ButtonSegment(
                    value: r,
                    label: Text(context.tr('aid_role_${r.name}')),
                  ),
              ],
              selected: {_role},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _role = s.first),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                if (_userId.text.trim().isEmpty || _name.text.trim().isEmpty) {
                  _snack(context, context.tr('required_field'));
                  return;
                }
                _run(() async {
                  await repo.addMember(_userId.text, _name.text, _role);
                  _userId.clear();
                  _name.clear();
                });
              },
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(context.tr('aid_add_member')),
            ),
          ],
        ],
      ),
    );
  }
}
