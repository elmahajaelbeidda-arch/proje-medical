/// Every health facility in Mauritania (hospitals, clinics, laboratories,
/// health centres, pharmacies...), whether or not it takes part in the app.
///
/// Source: OpenStreetMap (open data, © OpenStreetMap contributors), read
/// through the public Overpass API and kept on the device for a week so the
/// map also works offline. Facilities that take part in the app come from
/// the association's own records and are shown apart (see care_map.dart).
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Kind of place on the medical map.
enum CareCategory { hospital, clinic, lab, centre, pharmacy, radiology }

/// A facility from the public directory (not necessarily a partner).
class DirectoryPlace {
  final String id;
  final CareCategory category;

  /// Name in the local script when known, else the main name ('' if none).
  final String name;

  /// Other names (French, Arabic...) used for search and other languages.
  final String nameFr;
  final double lat;
  final double lon;
  final String phone;
  final String website;
  final String openingHours;
  final String address;
  final String city;

  const DirectoryPlace({
    required this.id,
    required this.category,
    required this.name,
    required this.lat,
    required this.lon,
    this.nameFr = '',
    this.phone = '',
    this.website = '',
    this.openingHours = '',
    this.address = '',
    this.city = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'c': category.name,
    'n': name,
    'nf': nameFr,
    'la': lat,
    'lo': lon,
    if (phone.isNotEmpty) 'p': phone,
    if (website.isNotEmpty) 'w': website,
    if (openingHours.isNotEmpty) 'h': openingHours,
    if (address.isNotEmpty) 'a': address,
    if (city.isNotEmpty) 'ci': city,
  };

  static DirectoryPlace? fromJson(Map<String, dynamic> j) {
    final c = CareCategory.values.where((v) => v.name == j['c']);
    if (c.isEmpty) return null;
    return DirectoryPlace(
      id: j['id'] as String,
      category: c.first,
      name: j['n'] as String? ?? '',
      nameFr: j['nf'] as String? ?? '',
      lat: (j['la'] as num).toDouble(),
      lon: (j['lo'] as num).toDouble(),
      phone: j['p'] as String? ?? '',
      website: j['w'] as String? ?? '',
      openingHours: j['h'] as String? ?? '',
      address: j['a'] as String? ?? '',
      city: j['ci'] as String? ?? '',
    );
  }
}

/// Category of an OpenStreetMap element from its tags (null: not health).
CareCategory? categoryFromTags(Map<String, dynamic> t) {
  final amenity = t['amenity'];
  final hc = t['healthcare'];
  if (amenity == 'pharmacy' || hc == 'pharmacy') return CareCategory.pharmacy;
  if (amenity == 'hospital' || hc == 'hospital') return CareCategory.hospital;
  if (hc == 'laboratory' || hc == 'sample_collection') return CareCategory.lab;
  if (hc == 'radiology') return CareCategory.radiology;
  if (hc == 'centre' || hc == 'health_post') return CareCategory.centre;
  if (amenity == 'clinic' ||
      amenity == 'doctors' ||
      amenity == 'dentist' ||
      hc == 'clinic' ||
      hc == 'doctor' ||
      hc == 'dentist') {
    return CareCategory.clinic;
  }
  return null;
}

String _first(String? v) {
  if (v == null) return '';
  return v.split(RegExp(r'[;,]')).first.trim();
}

/// Reads an Overpass `out center tags` answer.
List<DirectoryPlace> parseOverpass(Map<String, dynamic> json) {
  final out = <DirectoryPlace>[];
  final seen = <String>{};
  for (final e in (json['elements'] as List? ?? const [])) {
    if (e is! Map<String, dynamic>) continue;
    final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? const {};
    final category = categoryFromTags(tags);
    if (category == null) continue;
    final center = (e['center'] as Map?)?.cast<String, dynamic>();
    final lat = (e['lat'] ?? center?['lat']) as num?;
    final lon = (e['lon'] ?? center?['lon']) as num?;
    if (lat == null || lon == null) continue;
    final id = 'osm-${e['type']}-${e['id']}';
    if (!seen.add(id)) continue;
    final street = [
      tags['addr:street'],
      tags['addr:housenumber'],
    ].whereType<String>().join(' ');
    out.add(
      DirectoryPlace(
        id: id,
        category: category,
        name: (tags['name:ar'] ?? tags['name'] ?? tags['name:fr'] ?? '')
            .toString()
            .trim(),
        nameFr: (tags['name:fr'] ?? tags['name:en'] ?? tags['name'] ?? '')
            .toString()
            .trim(),
        lat: lat.toDouble(),
        lon: lon.toDouble(),
        phone: _first(
          (tags['phone'] ?? tags['contact:phone'] ?? tags['contact:mobile'])
              as String?,
        ),
        website: _first(
          (tags['website'] ?? tags['contact:website']) as String?,
        ),
        openingHours: (tags['opening_hours'] ?? '').toString(),
        address: street.isNotEmpty
            ? street
            : (tags['addr:full'] ?? tags['addr:suburb'] ?? '').toString(),
        city: (tags['addr:city'] ?? '').toString(),
      ),
    );
  }
  return out;
}

/// All health facilities of Mauritania in OpenStreetMap.
const overpassQuery = '''
[out:json][timeout:90];
area["ISO3166-1"="MR"][admin_level=2]->.mr;
(
  nwr["amenity"~"^(hospital|clinic|doctors|dentist|pharmacy)\$"](area.mr);
  nwr["healthcare"~"^(hospital|clinic|centre|doctor|dentist|laboratory|sample_collection|pharmacy|radiology|health_post)\$"](area.mr);
);
out center tags;
''';

const _endpoints = [
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
];

class DirectoryState {
  final List<DirectoryPlace> places;
  final bool loading;

  /// The last download failed (the cached list, if any, is still shown).
  final bool failed;
  final DateTime? updatedAt;
  const DirectoryState({
    this.places = const [],
    this.loading = false,
    this.failed = false,
    this.updatedAt,
  });
}

class HealthDirectoryNotifier extends Notifier<DirectoryState> {
  static const _key = 'health_directory_v1';
  static const maxAge = Duration(days: 7);

  /// Replaced in tests.
  static Future<String> Function(String query) fetch = _download;

  static Future<String> _download(String query) async {
    Object? error;
    for (final url in _endpoints) {
      try {
        final r = await http
            .post(Uri.parse(url), body: {'data': query})
            .timeout(const Duration(seconds: 100));
        if (r.statusCode == 200) return utf8.decode(r.bodyBytes);
        error = 'HTTP ${r.statusCode}';
      } catch (e) {
        error = e;
      }
    }
    throw Exception('directory download failed: $error');
  }

  @override
  DirectoryState build() {
    Future.microtask(load);
    return const DirectoryState(loading: true);
  }

  Future<void> load({bool force = false}) async {
    DirectoryState cached = const DirectoryState();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        cached = DirectoryState(
          places: [
            for (final p in (j['places'] as List))
              ?DirectoryPlace.fromJson((p as Map).cast<String, dynamic>()),
          ],
          updatedAt: DateTime.tryParse(j['at'] as String? ?? ''),
        );
      }
    } catch (_) {
      // Unreadable cache: download again.
    }
    if (!ref.mounted) return;
    final fresh =
        cached.updatedAt != null &&
        DateTime.now().difference(cached.updatedAt!) < maxAge &&
        cached.places.isNotEmpty;
    if (fresh && !force) {
      state = cached;
      return;
    }
    state = DirectoryState(
      places: cached.places,
      updatedAt: cached.updatedAt,
      loading: true,
    );
    try {
      final body = await fetch(overpassQuery);
      final places = parseOverpass(jsonDecode(body) as Map<String, dynamic>);
      final now = DateTime.now();
      if (!ref.mounted) return;
      state = DirectoryState(places: places, updatedAt: now);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _key,
          jsonEncode({
            'at': now.toIso8601String(),
            'places': [for (final p in places) p.toJson()],
          }),
        );
      } catch (_) {}
    } catch (_) {
      if (!ref.mounted) return;
      state = DirectoryState(
        places: cached.places,
        updatedAt: cached.updatedAt,
        failed: true,
      );
    }
  }
}

final healthDirectoryProvider =
    NotifierProvider<HealthDirectoryNotifier, DirectoryState>(
      HealthDirectoryNotifier.new,
    );
