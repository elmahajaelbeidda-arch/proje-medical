import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/l10n.dart';
import 'package:shifa/features/summons/summons_pdf.dart';
import 'package:shifa/models/summons.dart';

void main() {
  test('summons PDF is generated in Arabic and French', () async {
    final assets = SummonsPdfAssets(
      regular: ByteData.sublistView(
        File('assets/fonts/ElMessiri-Regular.ttf').readAsBytesSync(),
      ),
      bold: ByteData.sublistView(
        File('assets/fonts/ElMessiri-Bold.ttf').readAsBytesSync(),
      ),
      logo: File('assets/images/logo_icon.png').readAsBytesSync(),
    );
    final s = Summons(
      id: 'cv1001',
      patientId: 'p1',
      patientName: 'محمد الأمين',
      patientRef: 'P-001',
      issuer: SummonsIssuer.facility,
      issuerId: 'f1',
      issuerName: 'مستشفى الأمل الخاص',
      issuerDetailKey: 'ft_hospital',
      issuerPhone: '45 25 10 10',
      place: 'تفرغ زينة، شارع جمال عبد الناصر',
      city: 'نواكشوط',
      appointment: DateTime(2026, 11, 15, 10, 30),
      instructions: 'إحضار بطاقة التعريف والتحاليل السابقة.',
      sourceId: 'ref1',
      issuedAt: DateTime(2026, 11, 12),
    );
    for (final lang in ['ar', 'fr']) {
      final bytes = await buildSummonsPdf(
        s,
        assets,
        tr: (k) => AppStrings.of(lang, k),
        rtl: lang == 'ar',
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      final out = Platform.environment['SUMMONS_PDF_OUT'];
      if (out != null) File('$out/summons_$lang.pdf').writeAsBytesSync(bytes);
    }
    expect(s.verificationCode, hasLength(6));
    expect(s.code, 'CV-1001');
  });
}
