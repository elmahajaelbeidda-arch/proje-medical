import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/admin_provider.dart';
import '../../core/facility_provider.dart';
import '../../core/l10n.dart';
import '../../core/search.dart';
import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../models/blood.dart' show ContactMethod;
import '../../models/facility.dart';
import '../../models/models.dart';
import '../blood/blood_screens.dart' show ContactButtons;
import '../facility/facility_screens.dart'
    show facilityTypeIcon, facilityTypeKey;

// ---------------------------------------------------------------------------
// Data: approved doctors and facilities that have a location
// ---------------------------------------------------------------------------

enum PlaceKind { doctor, facility }

class CarePlace {
  final String id;
  final PlaceKind kind;
  final FacilityType? facilityType;
  final String name;

  /// Specialty or facility type (translation key).
  final String detailKey;

  /// Extra line: services or specialties.
  final String extra;
  final String address;
  final String city;
  final String phone;
  final LatLng point;

  const CarePlace({
    required this.id,
    required this.kind,
    required this.name,
    required this.detailKey,
    required this.address,
    required this.city,
    required this.point,
    this.facilityType,
    this.extra = '',
    this.phone = '',
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
          facilityType: f.type,
          name: f.name,
          detailKey: facilityTypeKey(f.type),
          extra: f.services.join('، '),
          address: f.address,
          city: f.city,
          phone: f.phone,
          point: LatLng(f.latitude!, f.longitude!),
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

/// Filter chips: all, doctors, then each facility type.
enum PlaceFilter { all, doctors, hospital, clinic, lab, pharmacy, radiology }

bool _matches(CarePlace p, PlaceFilter f) => switch (f) {
  PlaceFilter.all => true,
  PlaceFilter.doctors => p.kind == PlaceKind.doctor,
  _ => p.facilityType?.name == f.name,
};

IconData placeIcon(CarePlace p) => p.kind == PlaceKind.doctor
    ? Icons.medical_services
    : facilityTypeIcon(p.facilityType!);

Color placeColor(CarePlace p) =>
    p.kind == PlaceKind.doctor ? AppColors.vivid : AppColors.turquoise;

const _mauritania = LatLng(18.0735, -15.9582); // Nouakchott

class CareMapScreen extends ConsumerStatefulWidget {
  const CareMapScreen({super.key});
  @override
  ConsumerState<CareMapScreen> createState() => _CareMapScreenState();
}

class _CareMapScreenState extends ConsumerState<CareMapScreen> {
  final _map = MapController();
  PlaceFilter _filter = PlaceFilter.all;
  String _q = '';
  LatLng? _me;
  bool _locating = false;

  List<CarePlace> _visible(List<CarePlace> all) => [
    for (final p in all)
      if (_matches(p, _filter) &&
          Search.matches(_q, [
            p.name,
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
    final places = _visible(ref.read(carePlacesProvider));
    if (places.isEmpty) return _snack('cm_none');
    final list = nearest(places, me);
    _map.move(list.first.$1.point, 14);
    _showList(list);
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
            for (final (p, km) in list)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: placeColor(p),
                    child: Icon(placeIcon(p), color: Colors.white, size: 20),
                  ),
                  title: Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('${ctx.tr(p.detailKey)} • ${p.city}'),
                  trailing: km == null
                      ? const Icon(Icons.chevron_left)
                      : Text(
                          formatKm(km),
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.vivid,
                          ),
                        ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _map.move(p.point, 15);
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
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: placeColor(p),
                    child: Icon(placeIcon(p), color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: Theme.of(ctx).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          ctx.tr(p.detailKey),
                          style: const TextStyle(
                            color: AppColors.turquoise,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.verified, color: AppColors.vivid),
                ],
              ),
              const SizedBox(height: 12),
              _line(Icons.place_outlined, '${p.city} — ${p.address}'),
              if (km != null)
                _line(
                  Icons.near_me_outlined,
                  '${ctx.tr('cm_distance')}: ${formatKm(km)}',
                ),
              if (p.extra.isNotEmpty) _line(Icons.list_alt, p.extra),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => openDirections(ctx, p.point),
                icon: const Icon(Icons.directions),
                label: Text(ctx.tr('cm_directions')),
              ),
              const SizedBox(height: 8),
              if (p.phone.isNotEmpty)
                ContactButtons(phone: p.phone, preferred: ContactMethod.call)
              else
                // Volunteer doctors are reached through the app.
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/patient/new');
                  },
                  icon: const Icon(Icons.add_comment_outlined),
                  label: Text(ctx.tr('request_consultation')),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.turquoise),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final places = _visible(ref.watch(carePlacesProvider));
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('cm_title')),
        actions: [
          IconButton(
            tooltip: context.tr('cm_list'),
            onPressed: () => _showList(
              _me == null
                  ? [for (final p in places) (p, null)]
                  : nearest(places, _me!),
            ),
            icon: const Icon(Icons.format_list_bulleted),
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
                prefixIcon: const Icon(Icons.search),
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
                for (final f in PlaceFilter.values)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: ChoiceChip(
                      label: Text(
                        context.tr(
                          f == PlaceFilter.all
                              ? 'all'
                              : f == PlaceFilter.doctors
                              ? 'doctors'
                              : 'ft_${f.name}',
                        ),
                      ),
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
                        for (final p in places)
                          Marker(
                            point: p.point,
                            width: 46,
                            height: 46,
                            child: GestureDetector(
                              onTap: () => _showPlace(p),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: placeColor(p),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x33263B36),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  placeIcon(p),
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
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
                                  color: Colors.white,
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
                    color: Color(0xB3FFFFFF),
                    child: const Text(
                      '© OpenStreetMap',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 10,
                  start: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Color(0x22263B36), blurRadius: 6),
                      ],
                    ),
                    child: Text(
                      context.tr('cm_count', args: {'n': places.length}),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
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
            : const Icon(Icons.my_location),
        label: Text(context.tr('cm_nearest_btn')),
      ),
    );
  }
}
