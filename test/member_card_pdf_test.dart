import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/l10n.dart';
import 'package:shifa/features/cards/member_card_pdf.dart';
import 'package:shifa/features/summons/summons_pdf.dart';
import 'package:shifa/models/member_card.dart';

void main() {
  test('registration card PDF in Arabic and French', () async {
    final assets = SummonsPdfAssets(
      regular: ByteData.sublistView(
        File('assets/fonts/ElMessiri-Regular.ttf').readAsBytesSync(),
      ),
      bold: ByteData.sublistView(
        File('assets/fonts/ElMessiri-Bold.ttf').readAsBytesSync(),
      ),
      logo: File('assets/images/logo_icon.png').readAsBytesSync(),
    );
    final issued = DateTime(2026, 10, 13);
    final card = MemberCard(
      number: memberNumber(MemberKind.doctor, 'reg23', issued),
      kind: MemberKind.doctor,
      holderId: 'reg23',
      name: 'د. سارة بن علي',
      idValue: '1054321098',
      detailKey: 'sp_internal',
      city: 'نواكشوط',
      issuedAt: issued,
    );
    for (final lang in ['ar', 'fr']) {
      final bytes = await buildMemberCardPdf(
        card,
        assets,
        verifyUrl: 'https://example.org/#/verify-card?n=${card.number}',
        tr: (k) => AppStrings.of(lang, k),
        rtl: lang == 'ar',
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      final out = Platform.environment['CARD_PDF_OUT'];
      if (out != null) File('$out/card_$lang.pdf').writeAsBytesSync(bytes);
    }
  });
}
