import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/member_card.dart';
import '../summons/summons_pdf.dart' show SummonsPdfAssets;

const _green = PdfColor.fromInt(0xFF176B55);
const _mint = PdfColor.fromInt(0xFFDCEFE5);
const _ink = PdfColor.fromInt(0xFF263B36);
const _grey = PdfColor.fromInt(0xFF5F716C);
const _turquoise = PdfColor.fromInt(0xFF398B89);

String _d(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

final _arabic = RegExp(r'[؀-ۿ]');
pw.TextDirection? _dirOf(String t) =>
    _arabic.hasMatch(t) ? pw.TextDirection.rtl : null;

/// ID-card size (85.6 × 54 mm), front and back, on an A4 page with cutting
/// lines, ready to print, cut and laminate.
Future<Uint8List> buildMemberCardPdf(
  MemberCard card,
  SummonsPdfAssets assets, {
  required String verifyUrl,
  required String Function(String key) tr,
  required bool rtl,
}) async {
  final theme = pw.ThemeData.withFont(
    base: pw.Font.ttf(assets.regular),
    bold: pw.Font.ttf(assets.bold),
  );
  final logo = pw.MemoryImage(assets.logo);
  const w = 85.6 * PdfPageFormat.mm;
  const h = 54 * PdfPageFormat.mm;
  final kindKey = 'mc_kind_${card.kind.name}';

  pw.Widget cut(pw.Widget child) => pw.Container(
    width: w + 8,
    height: h + 8,
    padding: const pw.EdgeInsets.all(4),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(
        color: PdfColors.grey500,
        width: 0.5,
        style: pw.BorderStyle.dashed,
      ),
    ),
    child: pw.ClipRRect(
      horizontalRadius: 8,
      verticalRadius: 8,
      child: pw.Container(
        width: w,
        height: h,
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: _green, width: 0.8),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: child,
      ),
    ),
  );

  pw.Widget line(String label, String value, {bool ltr = false}) => pw.Row(
    children: [
      pw.Text('$label: ', style: const pw.TextStyle(fontSize: 6, color: _grey)),
      pw.Expanded(
        child: pw.Text(
          value.isEmpty ? '—' : value,
          maxLines: 1,
          textDirection: ltr ? pw.TextDirection.ltr : _dirOf(value),
          textAlign: ltr && rtl
              ? pw.TextAlign.right
              : (!rtl && _dirOf(value) != null ? pw.TextAlign.left : null),
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
      ),
    ],
  );

  final front = pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Container(
        color: _green,
        padding: const pw.EdgeInsets.fromLTRB(8, 5, 8, 5),
        child: pw.Row(
          children: [
            pw.Container(
              width: 22,
              height: 22,
              padding: const pw.EdgeInsets.all(2),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Image(logo),
            ),
            pw.SizedBox(width: 6),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    tr('app_name_plain'),
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.Text(
                    tr('association_name'),
                    style: const pw.TextStyle(
                      fontSize: 5.5,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
            pw.Text(
              tr('mc_title'),
              style: pw.TextStyle(
                fontSize: 6.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ],
        ),
      ),
      pw.Expanded(
        child: pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(8, 5, 8, 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      card.name,
                      maxLines: 1,
                      textDirection: _dirOf(card.name),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 2, bottom: 3),
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: pw.BoxDecoration(
                        color: _mint,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        '${tr(kindKey)} • ${tr(card.detailKey)}',
                        style: pw.TextStyle(
                          fontSize: 6,
                          fontWeight: pw.FontWeight.bold,
                          color: _green,
                        ),
                      ),
                    ),
                    line(tr('mc_number'), card.number, ltr: true),
                    line(
                      tr(
                        card.kind == MemberKind.facility
                            ? 'mc_id_facility'
                            : 'mc_id_person',
                      ),
                      card.maskedIdValue,
                      ltr: true,
                    ),
                    if (card.city.isNotEmpty) line(tr('city'), card.city),
                    line(tr('mc_expires'), _d(card.expiresAt), ltr: true),
                  ],
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Column(
                children: [
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: verifyUrl,
                    width: 52,
                    height: 52,
                    color: _ink,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    card.verificationCode,
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      if (card.suspended)
        pw.Container(
          color: _turquoise,
          padding: const pw.EdgeInsets.all(2),
          child: pw.Text(
            tr('cc_suspended'),
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 6, color: PdfColors.white),
          ),
        ),
    ],
  );

  final back = pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Row(
      children: [
        pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(),
          data: verifyUrl,
          width: 88,
          height: 88,
          color: _ink,
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                tr('mc_scan'),
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _green,
                ),
              ),
              pw.SizedBox(height: 3),
              line(tr('mc_code'), card.verificationCode, ltr: true),
              line(tr('mc_issued'), _d(card.issuedAt), ltr: true),
              pw.SizedBox(height: 4),
              pw.Text(
                tr('mc_back_note'),
                style: const pw.TextStyle(fontSize: 5.5, color: _grey),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  pw.Widget labelled(String label, pw.Widget card) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _grey)),
      pw.SizedBox(height: 3),
      card,
    ],
  );

  final doc = pw.Document(
    title: '${tr('mc_title')} ${card.number}',
    author: tr('association_name'),
  );
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      theme: theme,
      textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            tr('mc_title'),
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: _green,
            ),
          ),
          pw.Text(
            tr('mc_print_hint'),
            style: const pw.TextStyle(fontSize: 9.5, color: _grey),
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              labelled(tr('mc_front'), cut(front)),
              labelled(tr('mc_back'), cut(back)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            tr('mc_cut_here'),
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 8, color: _grey),
          ),
        ],
      ),
    ),
  );
  return doc.save();
}
