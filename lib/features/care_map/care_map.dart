import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/admin_provider.dart';
import '../../core/facility_provider.dart';
import '../../core/health_directory.dart';
import '../../core/l10n.dart';
import '../../core/search.dart';
import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../models/blood.dart' show ContactMethod;
import '../../models/facility.dart';
import '../../models/models.dart';
import '../blood/blood_screens.dart' show ContactButtons;

// ---------------------------------------------------------------------------
// Data: partners (approved doctors and facilities) and every other health
// facility of the public directory (OpenStreetMap)
// ---------------------------------------------------------------------------

enum PlaceKind { doctor, facility }

CareCategory categoryOf(FacilityType t) => switch (t) {
  FacilityType.hospital => CareCategory.hospital,
  FacilityType.clinic => CareCategory.clinic,
  FacilityType.lab => CareCategory.lab,
  FacilityType.pharmacy => CareCategory.pharmacy,
  FacilityType.radiology => CareCategory.radiology,
};

String categoryKey(CareCategory c) => 'ft_${c.name}';

IconData categoryIcon(CareCategory c) => switch (c) {
  CareCategory.hospital => LucideIcons.hospital,
  CareCategory.clinic => LucideIcons.stethoscope,
  CareCategory.lab => LucideIcons.microscope,
  CareCategory.centre => LucideIcons.housePlus,
  CareCategory.pharmacy => LucideIcons.pill,
  CareCategory.radiology => LucideIcons.scanLine,
};

class CarePlace {
  final String id;
  final PlaceKind kind;

  /// null for volunteer doctors.
  final CareCategory? category;

  /// Approved by the association and taking part in the app.
  final bool partner;
  final String name;

  /// Name in another language (French...), from the public directory.
  final String altName;

  /// Specialty or facility type (translation key).
  final String detailKey;

  /// Extra line: services or specialties.
  final String extra;
  final String address;
  final String city;
  final String phone;
  final String website;
  final String openingHours;
  final LatLng point;

  const CarePlace({
    required this.id,
    required this.kind,
    required this.name,
    required this.detailKey,
    required this.address,
    required this.city,
    required this.point,
    this.category,
    this.partner = true,
    this.altName = '',
    this.extra = '',
    this.phone = '',
    this.website = '',
    this.openingHours = '',
  });
}

/// Updated live: a facility appears once approved and disappears if it is
/// suspended or its approval is withdrawn.
final carePlacesProvider = Provider<List<CarePlace>>((ref) {
  final facilities = ref.watch(facilityProvider).facilities;
  final suspended = ref.watch(adminProvider.select((s) => s.suspendedAccounts));
  return [
    for (final d in MockData.doctors)
      if (d.verified && d.latitude != null && d.longitude != null)
        CarePlace(
          id: d.id,
          kind: PlaceKind.doctor,
          name: d.name,
          detailKey: Specialty.byId(d.specialtyId).key,
          extra: d.availability.join(' • '),
          address: d.clinicAddress,
          city: d.city,
          point: LatLng(d.latitude!, d.longitude!),
        ),
    for (final f in facilities)
      if (f.isApproved &&
          !suspended.containsKey(f.id) &&
          f.latitude != null &&
          f.longitude != null)
        CarePlace(
          id: f.id,
          kind: PlaceKind.facility,
          category: categoryOf(f.type),
          name: f.name,
          detailKey: categoryKey(categoryOf(f.type)),
          extra: f.services.join('، '),
          address: f.address,
          city: f.city,
          phone: f.phone,
          point: LatLng(f.latitude!, f.longitude!),
        ),
  ];
});

/// Partners first, then every other facility of the public directory. A
/// directory entry within 150 m of a partner of the same kind is taken to be
/// that partner and is not shown twice.
final allCarePlacesProvider = Provider<List<CarePlace>>((ref) {
  final partners = ref.watch(carePlacesProvider);
  final directory = ref.watch(healthDirectoryProvider).places;
  bool known(DirectoryPlace d) {
    final at = LatLng(d.lat, d.lon);
    for (final p in partners) {
      if (p.category == d.category && kmBetween(at, p.point) < .15) {
        return true;
      }
    }
    return false;
  }

  return [
    ...partners,
    for (final d in directory)
      if (!known(d))
        CarePlace(
          id: d.id,
          kind: PlaceKind.facility,
          category: d.category,
          partner: false,
          name: d.name,
          altName: d.nameFr == d.name ? '' : d.nameFr,
          detailKey: categoryKey(d.category),
          address: d.address,
          city: d.city,
          phone: d.phone,
          website: d.website,
          openingHours: d.openingHours,
          point: LatLng(d.lat, d.lon),
        ),
  ];
});

const _distance = Distance();

/// Kilometres between two points.
double kmBetween(LatLng a, LatLng b) =>
    _distance.as(LengthUnit.Meter, a, b) / 1000;

/// Places sorted from the nearest.
List<(CarePlace, double)> nearest(Iterable<CarePlace> places, LatLng from) =>
    [for (final p in places) (p, kmBetween(from, p.point))]
      ..sort((a, b) => a.$2.compareTo(b.$2));

String formatKm(double km) => km < 1
    ? '${(km * 1000).round()} m'
    : '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';

/// Opens the phone's map app with directions to [p].
Future<void> openDirections(BuildContext context, LatLng p) async {
  final messenger = ScaffoldMessenger.of(context);
  final failed = context.tr('pick_failed');
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=${p.latitude},${p.longitude}',
  );
  try {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(failed)));
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Filter chips: all, doctors, then each kind of facility.
enum PlaceFilter { all, doctors, hospital, clinic, lab, centre, pharmacy }

bool _matches(CarePlace p, PlaceFilter f) => switch (f) {
  PlaceFilter.all => true,
  PlaceFilter.doctors => p.kind == PlaceKind.doctor,
  PlaceFilter.clinic =>
    p.category == CareCategory.clinic || p.category == CareCategory.radiology,
  _ => p.category?.name == f.name,
};

String _filterKey(PlaceFilter f) => switch (f) {
  PlaceFilter.all => 'all',
  PlaceFilter.doctors => 'doctors',
  _ => 'ft_${f.name}',
};

IconData placeIcon(CarePlace p) => p.kind == PlaceKind.doctor
    ? LucideIcons.briefcaseMedical
    : categoryIcon(p.category!);

Color placeColor(CarePlace p) => !p.partner
    ? AppColors.grey
    : p.kind == PlaceKind.doctor
    ? AppColors.vivid
    : AppColors.primary;

/// Name to show: the other-language name outside Arabic when known, and the
/// kind of facility when the place has no name at all.
String placeName(BuildContext context, CarePlace p) {
  final ar = Localizations.localeOf(context).languageCode == 'ar';
  final n = !ar && p.altName.isNotEmpty ? p.altName : p.name;
  return n.isNotEmpty ? n : context.tr(p.detailKey);
}

const _mauritania = LatLng(18.0735, -15.9582); // Nouakchott

class CareMapScreen extends ConsumerStatefulWidget {
  const CareMapScreen({super.key});
  @override
  ConsumerState<CareMapScreen> createState() => _CareMapScreenState();
}

class _CareMapScreenState extends ConsumerState<CareMapScreen> {
  final _map = MapController();
  PlaceFilter _filter = PlaceFilter.all;
  bool _partnersOnly = false;
  String _q = '';
  LatLng? _me;
  bool _locating = false;

  List<CarePlace> _visible(List<CarePlace> all) => [
    for (final p in all)
      if ((!_partnersOnly || p.partner) &&
          _matches(p, _filter) &&
          Search.matches(_q, [
            p.name,
            p.altName,
            context.tr(p.detailKey),
            p.city,
            p.address,
            p.extra,
          ]))
        p,
  ];

  void _snack(String key) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr(key))));

  /// Asks for the location (with the phone's permission).
  Future<LatLng?> _locate() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _snack('aid_location_off');
        return null;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _snack('aid_location_denied');
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final me = LatLng(pos.latitude, pos.longitude);
      if (mounted) setState(() => _me = me);
      return me;
    } catch (_) {
      if (mounted) _snack('aid_location_denied');
      return null;
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _nearestToMe() async {
    final me = _me ?? await _locate();
    if (me == null || !mounted) return;
    final places = _visible(ref.read(allCarePlacesProvider));
    if (places.isEmpty) return _snack('cm_none');
    final list = nearest(places, me);
    _map.move(list.first.$1.point, 14);
    _showList(list.take(60).toList());
  }

  void _showList(List<(CarePlace, double?)> list) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .55,
        maxChildSize: .9,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              ctx.tr(_me == null ? 'cm_list' : 'cm_nearest'),
              style: Theme.of(ctx).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(ctx.tr('cm_none'), textAlign: TextAlign.center),
              ),
            for (final (p, km) in list)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: _PlaceAvatar(p, radius: 20),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          placeName(ctx, p),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (p.partner) ...[
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.badgeCheck,
                          size: 16,
                          color: AppColors.vivid,
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    [
                      ctx.tr(p.detailKey),
                      if (p.city.isNotEmpty) p.city,
                    ].join(' • '),
                  ),
                  trailing: km == null
                      ? const Icon(LucideIcons.chevronLeftDir)
                      : Text(
                          formatKm(km),
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.vivid,
                          ),
                        ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _map.move(p.point, 16);
                    _showPlace(p);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPlace(CarePlace p) {
    final km = _me == null ? null : kmBetween(_me!, p.point);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _PlaceAvatar(p, radius: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          placeName(ctx, p),
                          style: Theme.of(ctx).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          ctx.tr(p.detailKey),
                          style: TextStyle(
                            color: AppColors.turquoiseText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: PartnerBadge(partner: p.partner),
              ),
              const SizedBox(height: 12),
              if (p.city.isNotEmpty || p.address.isNotEmpty)
                _line(
                  LucideIcons.mapPin,
                  [p.city, p.address].where((e) => e.isNotEmpty).join(' — '),
                ),
              if (km != null)
                _line(
                  LucideIcons.navigation,
                  '${ctx.tr('cm_distance')}: ${formatKm(km)}',
                ),
              if (p.openingHours.isNotEmpty)
                _line(
                  LucideIcons.clock,
                  '${ctx.tr('cm_hours')}: ${p.openingHours}',
                  ltr: true,
                ),
              if (p.extra.isNotEmpty) _line(LucideIcons.list, p.extra),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => openDirections(ctx, p.point),
                icon: const Icon(LucideIcons.navigation),
                label: Text(ctx.tr('cm_directions')),
              ),
              const SizedBox(height: 8),
              if (p.phone.isNotEmpty)
                ContactButtons(phone: p.phone, preferred: ContactMethod.call)
              else if (p.kind == PlaceKind.doctor)
                // Volunteer doctors are reached through the app.
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/patient/new');
                  },
                  icon: const Icon(LucideIcons.messageSquarePlus),
                  label: Text(ctx.tr('request_consultation')),
                )
              else
                _line(LucideIcons.phoneOff, ctx.tr('cm_no_phone')),
              if (p.website.isNotEmpty) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    final w = p.website.startsWith('http')
                        ? p.website
                        : 'https://${p.website}';
                    final uri = Uri.tryParse(w);
                    if (uri != null) {
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(LucideIcons.globe),
                  label: Text(ctx.tr('cm_website')),
                ),
              ],
              if (!p.partner) ...[
                const SizedBox(height: 12),
                Text(
                  ctx.tr('cm_osm_note'),
                  style: TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(IconData icon, String text, {bool ltr = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.turquoise),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            textDirection: ltr ? TextDirection.ltr : null,
            textAlign: TextAlign.start,
          ),
        ),
      ],
    ),
  );

  Marker _marker(CarePlace p) {
    final size = p.partner ? 46.0 : 34.0;
    return Marker(
      point: p.point,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: () => _showPlace(p),
        child: Semantics(
          button: true,
          label: p.name,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: p.partner ? placeColor(p) : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: p.partner ? AppColors.onPrimary : AppColors.grey,
                    width: p.partner ? 3 : 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33263B36), blurRadius: 6),
                  ],
                ),
                child: Icon(
                  placeIcon(p),
                  color: p.partner ? AppColors.onPrimary : AppColors.grey,
                  size: p.partner ? 22 : 17,
                ),
              ),
              if (p.partner)
                PositionedDirectional(
                  top: -3,
                  end: -3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.badgeCheck,
                      size: 17,
                      color: AppColors.vivid,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allCarePlacesProvider);
    final directory = ref.watch(healthDirectoryProvider);
    final places = _visible(all);
    // Non-partners first so partners are drawn on top.
    final ordered = [
      for (final p in places)
        if (!p.partner) p,
      for (final p in places)
        if (p.partner) p,
    ];
    final partners = places.where((p) => p.partner).length;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('cm_title')),
        actions: [
          IconButton(
            tooltip: context.tr('cm_list'),
            onPressed: () => _showList(
              _me == null
                  ? [for (final p in places.take(200)) (p, null)]
                  : nearest(places, _me!).take(60).toList(),
            ),
            icon: const Icon(LucideIcons.list),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.search),
                hintText: context.tr('cm_search'),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: FilterChip(
                    avatar: Icon(
                      LucideIcons.badgeCheck,
                      size: 18,
                      color: AppColors.vivid,
                    ),
                    label: Text(context.tr('cm_partners_only')),
                    selected: _partnersOnly,
                    showCheckmark: false,
                    onSelected: (v) => setState(() => _partnersOnly = v),
                  ),
                ),
                for (final f in PlaceFilter.values)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: ChoiceChip(
                      label: Text(context.tr(_filterKey(f))),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: const MapOptions(
                    initialCenter: _mauritania,
                    initialZoom: 12,
                    minZoom: 4,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'mr.aounsanad.shifa',
                      maxZoom: 19,
                    ),
                    MarkerLayer(
                      markers: [
                        for (final p in ordered) _marker(p),
                        if (_me != null)
                          Marker(
                            point: _me!,
                            width: 26,
                            height: 26,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.info,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.onPrimary,
                                  width: 4,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                // OpenStreetMap attribution (required by its licence).
                Positioned(
                  left: 6,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    color: const Color(0xB3FFFFFF),
                    child: const Text(
                      '© OpenStreetMap',
                      style: TextStyle(fontSize: 10, color: Color(0xFF263B36)),
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 10,
                  start: 10,
                  end: 10,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _CountPill(
                      total: places.length,
                      partners: partners,
                      loading: directory.loading,
                      failed: directory.failed,
                      onRetry: () => ref
                          .read(healthDirectoryProvider.notifier)
                          .load(force: true),
                    ),
                  ),
                ),
                const PositionedDirectional(
                  bottom: 24,
                  start: 10,
                  child: _Legend(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _locating ? null : _nearestToMe,
        icon: _locating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(LucideIcons.locateFixed),
        label: Text(context.tr('cm_nearest_btn')),
      ),
    );
  }
}

class _PlaceAvatar extends StatelessWidget {
  const _PlaceAvatar(this.p, {required this.radius});
  final CarePlace p;
  final double radius;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: p.partner ? placeColor(p) : AppColors.secondary,
    child: Icon(
      placeIcon(p),
      color: p.partner ? AppColors.onPrimary : AppColors.grey,
      size: radius * .8,
    ),
  );
}

/// «معتمدة ومشاركة في التطبيق» / «غير مشاركة في التطبيق».
class PartnerBadge extends StatelessWidget {
  const PartnerBadge({super.key, required this.partner});
  final bool partner;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: partner ? AppColors.answeredSoft : AppColors.secondary,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          partner ? LucideIcons.badgeCheck : LucideIcons.info,
          size: 16,
          color: partner ? AppColors.answeredText : AppColors.grey,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            context.tr(partner ? 'cm_partner' : 'cm_not_partner'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: partner ? AppColors.answeredText : AppColors.grey,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.total,
    required this.partners,
    required this.loading,
    required this.failed,
    required this.onRetry,
  });
  final int total;
  final int partners;
  final bool loading;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 8, 6),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [BoxShadow(color: Color(0x22263B36), blurRadius: 6)],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            context.tr('cm_count', args: {'n': total, 'p': partners}),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        if (loading) ...[
          const SizedBox(width: 8),
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ] else if (failed)
          TextButton.icon(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: onRetry,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: Text(context.tr('cm_reload')),
          ),
      ],
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend();
  @override
  Widget build(BuildContext context) {
    Widget item(bool partner) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: partner ? AppColors.primary : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: partner ? AppColors.primary : AppColors.grey,
              width: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          context.tr(partner ? 'cm_partner' : 'cm_not_partner'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x22263B36), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [item(true), const SizedBox(height: 4), item(false)],
      ),
    );
  }
}
