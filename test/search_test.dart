import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/l10n.dart';
import 'package:shifa/core/search.dart';
import 'package:shifa/data/mock_data.dart';
import 'package:shifa/models/models.dart';

/// The same fields the doctors list searches.
List<String> doctorFields(Doctor d) {
  final sp = Specialty.byId(d.specialtyId).key;
  return [
    d.name,
    AppStrings.of('ar', sp),
    AppStrings.of('fr', sp),
    d.city,
    d.cityFr,
    d.bio,
  ];
}

List<String> find(String query) => MockData.doctors
    .where((d) => Search.matches(query, doctorFields(d)))
    .map((d) => d.id)
    .toList();

void main() {
  test('spoken Arabic sentence with filler words finds the doctor', () {
    // d2 = cardiologist in Nouadhibou
    expect(find('أريد طبيب قلب في نواذيبو'), ['d2']);
    expect(find('أُريدُ طبيبَ القلبِ'), ['d2']); // diacritics + article
  });

  test('specialty, city and name searches', () {
    expect(find('أطفال'), ['d3']);
    expect(find('الأطفال'), ['d3']);
    expect(find('كيفة'), ['d4']);
    expect(find('سارة'), ['d1']);
    expect(find('ساره'), ['d1']); // ة / ه
  });

  test('French queries, accents and word endings', () {
    expect(find('cardiologue à Nouadhibou'), ['d2']);
    expect(find('je cherche un pédiatre'), ['d3']);
    expect(find('DERMATOLOGIE'), ['d7']);
  });

  test('empty or filler-only query matches everything, nonsense nothing', () {
    expect(find('').length, MockData.doctors.length);
    expect(find('أريد طبيب').length, MockData.doctors.length);
    expect(find('zzzz'), isEmpty);
  });
}
