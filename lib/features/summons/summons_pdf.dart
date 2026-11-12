import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/summons.dart';

/// Fonts and logo used by the PDF (loaded from the app's assets).
class SummonsPdfAssets {
  final ByteData regular;
  final ByteData bold;
  final Uint8List logo;
  const SummonsPdfAssets({
    required this.regular,
    required this.bold,
    required this.logo,
  });
}

const _green = PdfColor.fromInt(0xFF0A5C36);
const _mint = PdfColor.fromInt(0xFFE8F5E9);
const _ink = PdfColor.fromInt(0xFF2C3E50);
const _grey = PdfColor.fromInt(0xFF5B6168);

String _two(int n) => n.toString().padLeft(2, '0');

final _arabic = RegExp(r'[\u0600-\u06FF]');

/// Arabic data (names, addresses) stays right-to-left on a French card.
pw.TextDirection? _dirOf(String text) =>
    _arabic.hasMatch(text) ? pw.TextDirection.rtl : null;

/// A4 printable card (any print shop can print it). [tr] translates keys of the app (Arabic or French);
/// [rtl] is true for Arabic.
Future<Uint8List> buildSummonsPdf(
  Summons s,
  SummonsPdfAssets assets, {
  required String Function(String key) tr,
  required bool rtl,
}) async {
  final theme = pw.ThemeData.withFont(
    base: pw.Font.ttf(assets.regular),
    bold: pw.Font.ttf(assets.bold),
  );
  final logo = pw.MemoryImage(assets.logo);
  final a = s.appointment;
  final date =
      '${tr('wd_${a.weekday}')} ${_two(a.day)}/${_two(a.month)}/${a.year}';
  final time = '${_two(a.hour)}:${_two(a.minute)}';
  final issued =
      '${_two(s.issuedAt.day)}/${_two(s.issuedAt.month)}/${s.issuedAt.year}';

  pw.Widget row(String label, String value, {bool ltr = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 78,
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: _grey),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value.isEmpty ? '—' : value,
            textDirection: ltr ? pw.TextDirection.ltr : _dirOf(value),
            textAlign: ltr && rtl
                ? pw.TextAlign.right
                : (!rtl && _dirOf(value) != null ? pw.TextAlign.left : null),
            style: pw.TextStyle(
              fontSize: 11.5,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        ),
      ],
    ),
  );

  pw.Widget section(String title, List<pw.Widget> children) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 6),
    padding: const pw.EdgeInsets.fromLTRB(10, 5, 10, 5),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _green, width: 0.8),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _green,
          ),
        ),
        pw.SizedBox(height: 2),
        ...children,
      ],
    ),
  );

  final doc = pw.Document(
    title: '${tr('summons_title')} ${s.code}',
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
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _green,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 42,
                  height: 42,
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Image(logo),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        tr('app_name_plain'),
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        tr('association_name'),
                        style: const pw.TextStyle(
                          fontSize: 9.5,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      tr('summons_title'),
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: _green,
                      ),
                    ),
                    pw.Text(
                      '${tr('summons_number')}: ${s.code}',
                      style: const pw.TextStyle(fontSize: 10, color: _grey),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: _mint,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text(
                  tr(
                    s.issuer == SummonsIssuer.doctor
                        ? 'summons_by_doctor'
                        : 'summons_by_facility',
                  ),
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _green,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          // Appointment (the most important block)
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 6),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _mint,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        tr('summons_appointment'),
                        style: const pw.TextStyle(fontSize: 10, color: _grey),
                      ),
                      pw.Text(
                        date,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Text(
                  time,
                  textDirection: pw.TextDirection.ltr,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: _green,
                  ),
                ),
              ],
            ),
          ),
          section(tr('summons_patient'), [
            row(tr('summons_patient_name'), s.patientName),
            if (s.patientRef.isNotEmpty)
              row(tr('summons_file_number'), s.patientRef, ltr: true),
          ]),
          section(
            tr(
              s.issuer == SummonsIssuer.doctor
                  ? 'summons_doctor'
                  : 'summons_facility',
            ),
            [
              row(tr('summons_name'), s.issuerName),
              row(
                tr(
                  s.issuer == SummonsIssuer.doctor
                      ? 'specialty'
                      : 'facility_type',
                ),
                tr(s.issuerDetailKey),
              ),
              row(tr('phone'), '+222 ${s.issuerPhone}', ltr: true),
            ],
          ),
          section(tr('summons_place'), [
            row(tr('address'), s.place),
            row(tr('city'), s.city),
          ]),
          if (s.instructions.isNotEmpty)
            section(tr('summons_instructions'), [
              pw.Text(
                s.instructions,
                textDirection: _dirOf(s.instructions),
                style: const pw.TextStyle(fontSize: 10.5, color: _ink),
              ),
            ]),
          pw.Spacer(),
          // Verification
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: s.qrPayload,
                width: 90,
                height: 90,
                color: _ink,
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${tr('summons_verification')}: ${s.verificationCode}',
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    pw.Text(
                      '${tr('summons_issued_on')}: $issued',
                      style: const pw.TextStyle(fontSize: 9, color: _grey),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      tr('summons_footer'),
                      style: const pw.TextStyle(fontSize: 9, color: _grey),
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
  return doc.save();
}
