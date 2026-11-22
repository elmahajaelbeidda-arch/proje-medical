import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shifa/core/admin_provider.dart';
import 'package:shifa/core/health_directory.dart';
import 'package:shifa/features/admin/demo_admins.dart';
import 'package:shifa/features/care_map/care_map.dart';

/// A small Overpass answer: a hospital (way, with centre), a pharmacy, a
/// lab, a health post, a node that is not a health facility, and a hospital
/// at the same place as the partner facility f1.
Map<String, dynamic> sample(double f1Lat, double f1Lon) => {
  'elements': [
    {
      'type': 'way',
      'id': 1,
      'center': {'lat': 18.09, 'lon': -15.97},
      'tags': {
        'amenity': 'hospital',
        'name': 'Centre Hospitalier National',
        'name:ar': 'المستشفى الوطني',
        'phone': '+222 45 25 21 35; +222 45 25 00 00',
        'opening_hours': '24/7',
      },
    },
    {
      'type': 'node',
      'id': 2,
      'lat': 18.08,
      'lon': -15.96,
      'tags': {'amenity': 'pharmacy', 'name': 'Pharmacie Ibn Sina'},
    },
    {
      'type': 'node',
      'id': 3,
      'lat': 18.07,
      'lon': -15.95,
      'tags': {'healthcare': 'laboratory'},
    },
    {
      'type': 'node',
      'id': 4,
      'lat': 16.5,
      'lon': -15.8,
      'tags': {'healthcare': 'health_post', 'name': 'Poste de santé'},
    },
    {
      'type': 'node',
      'id': 5,
      'lat': 18.0,
      'lon': -15.9,
      'tags': {'amenity': 'school'},
    },
    {
      'type': 'node',
      'id': 6,
      'lat': f1Lat + .0003,
      'lon': f1Lon,
      'tags': {'amenity': 'hospital', 'name': 'Same as partner'},
    },
  ],
};

void main() {
  test('reads facilities and their contact details from OpenStreetMap', () {
    final list = parseOverpass(sample(0, 0));
    expect(list.length, 5); // the school is left out
    final h = list.first;
    expect(h.category, CareCategory.hospital);
    expect(h.name, 'المستشفى الوطني');
    expect(h.nameFr, 'Centre Hospitalier National');
    expect(h.phone, '+222 45 25 21 35');
    expect(h.openingHours, '24/7');
    expect(h.lat, 18.09);
    expect(list[1].category, CareCategory.pharmacy);
    expect(list[2].category, CareCategory.lab);
    expect(list[2].name, ''); // shown as «مختبر»
    expect(list[3].category, CareCategory.centre);
    // Round trip through the device cache.
    final back = DirectoryPlace.fromJson(
      jsonDecode(jsonEncode(h.toJson())) as Map<String, dynamic>,
    )!;
    expect(back.name, h.name);
    expect(back.phone, h.phone);
  });

  test('the map shows every facility and marks the partners', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer(
      overrides: [adminSeedAccountsProvider.overrideWithValue(demoAdmins())],
    );
    addTearDown(c.dispose);
    final f1 = c.read(carePlacesProvider).firstWhere((p) => p.id == 'f1');
    HealthDirectoryNotifier.fetch = (_) async =>
        jsonEncode(sample(f1.point.latitude, f1.point.longitude));
    c.listen(healthDirectoryProvider, (_, _) {});
    await c.read(healthDirectoryProvider.notifier).load(force: true);

    final all = c.read(allCarePlacesProvider);
    final partners = all.where((p) => p.partner).map((p) => p.id).toSet();
    expect(partners, containsAll(['f1', 'd1']));
    final others = all.where((p) => !p.partner).map((p) => p.id).toSet();
    expect(others, containsAll(['osm-way-1', 'osm-node-2', 'osm-node-4']));
    // The clinic at the partner's address is the partner itself.
    expect(others, isNot(contains('osm-node-6')));

    // Kept on the device: works offline next time.
    HealthDirectoryNotifier.fetch = (_) async => throw Exception('offline');
    final c2 = ProviderContainer(
      overrides: [adminSeedAccountsProvider.overrideWithValue(demoAdmins())],
    );
    addTearDown(c2.dispose);
    c2.listen(healthDirectoryProvider, (_, _) {});
    await c2.read(healthDirectoryProvider.notifier).load(force: true);
    final s = c2.read(healthDirectoryProvider);
    expect(s.failed, isTrue);
    expect(s.places.length, 5);
  });
}
