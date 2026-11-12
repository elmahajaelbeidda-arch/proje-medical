import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../models/admin.dart';
import '../summons/summons_screens.dart' show loadPdfAssets;
import 'file_download.dart';
import 'xlsx.dart';

// ---------------------------------------------------------------------------
// Formatting
// ---------------------------------------------------------------------------

String two(int n) => n.toString().padLeft(2, '0');
String fmtDate(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';
String fmtDateTime(DateTime d) =>
    '${fmtDate(d)} ${two(d.hour)}:${two(d.minute)}';

/// 150000 → "150 000 MRU".
String money(int v) {
  final s = v.abs().toString();
  final b = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  // Kept left-to-right inside Arabic text ("150 000 MRU").
  return '\u2066${b.toString()} MRU\u2069';
}

/// Removes direction marks (PDF fonts and Excel do not need them).
String plain(Object? v) =>
    '${v ?? ''}'.replaceAll(RegExp('[\u2066-\u2069]'), '');

String stamp() {
  final d = DateTime.now();
  return '${d.year}${two(d.month)}${two(d.day)}-${two(d.hour)}${two(d.minute)}';
}

// ---------------------------------------------------------------------------
// Layout
// ---------------------------------------------------------------------------

class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    required this.children,
    this.actions = const [],
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 8,
          spacing: 8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                if (subtitle != null) Text(subtitle!, style: text.bodySmall),
              ],
            ),
            if (actions.isNotEmpty)
              Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    );
  }
}

class Panel extends StatelessWidget {
  const Panel({super.key, this.title, required this.child, this.trailing});
  final String? title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    title!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    ),
  );
}

class Kpi extends StatelessWidget {
  const Kpi({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.onTap,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 168,
    child: Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: .14),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        value,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: color,
                        ),
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 2,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class KpiWrap extends StatelessWidget {
  const KpiWrap({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Wrap(spacing: 10, runSpacing: 10, children: children),
  );
}

class SearchBox extends StatelessWidget {
  const SearchBox({super.key, required this.onChanged, this.hint});
  final ValueChanged<String> onChanged;
  final String? hint;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: hint ?? context.tr('ad_search'),
        isDense: true,
      ),
    ),
  );
}

/// Horizontal row of choice chips (filters).
class FilterRow<T> extends StatelessWidget {
  const FilterRow({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });
  final List<T?> values;
  final T? selected;
  final String Function(T? v) label;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        for (final v in values)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: ChoiceChip(
              label: Text(label(v)),
              selected: selected == v,
              onSelected: (_) => onSelected(v),
            ),
          ),
      ],
    ),
  );
}

class NoAccess extends StatelessWidget {
  const NoAccess({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 56, color: AppColors.grey),
          const SizedBox(height: 10),
          Text(context.tr('ad_section_no_access'), textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

void snack(BuildContext context, String key, {bool error = false}) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr(key)),
        backgroundColor: error ? AppColors.emergency : null,
      ),
    );

/// Runs an admin action and shows a message when it is refused.
bool guarded(BuildContext context, void Function() action, {String? ok}) {
  try {
    action();
    if (ok != null) snack(context, ok);
    return true;
  } on AdminPermissionDenied {
    snack(context, 'ad_no_access', error: true);
  } on ArgumentError {
    snack(context, 'ad_invalid', error: true);
  } on StateError {
    snack(context, 'ad_invalid', error: true);
  } on FormatException {
    snack(context, 'ad_invalid', error: true);
  }
  return false;
}

/// Asks for a mandatory reason (rejection, suspension, opening a file...).
Future<String?> askReason(
  BuildContext context, {
  required String title,
  String? label,
}) async {
  final c = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      var error = false;
      return StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: c,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: label ?? ctx.tr('ad_reason'),
              alignLabelWithHint: true,
              errorText: error ? ctx.tr('reason_required') : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.tr('cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (c.text.trim().isEmpty) {
                  setState(() => error = true);
                } else {
                  Navigator.pop(ctx, true);
                }
              },
              child: Text(ctx.tr('confirm')),
            ),
          ],
        ),
      );
    },
  );
  final text = c.text.trim();
  c.dispose();
  return ok == true ? text : null;
}

// ---------------------------------------------------------------------------
// Exports (PDF tables, Excel, CSV, JSON)
// ---------------------------------------------------------------------------

class ReportTable {
  final String title;
  final List<String> headers;
  final List<List<Object?>> rows;
  const ReportTable(this.title, this.headers, this.rows);
}

final _arabic = RegExp(r'[؀-ۿ]');

/// A4 report: header with the association's name, then tables.
Future<Uint8List> buildReportPdf({
  required String title,
  required String subtitle,
  required List<ReportTable> tables,
  required bool rtl,
  required String Function(String) tr,
}) async {
  final assets = await loadPdfAssets();
  final theme = pw.ThemeData.withFont(
    base: pw.Font.ttf(assets.regular),
    bold: pw.Font.ttf(assets.bold),
  );
  const green = PdfColor.fromInt(0xFF176B55);
  const mint = PdfColor.fromInt(0xFFDCEFE5);
  final doc = pw.Document(title: title, author: tr('association_name'));
  pw.TextDirection? dir(String s) =>
      _arabic.hasMatch(s) ? pw.TextDirection.rtl : pw.TextDirection.ltr;
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      theme: theme,
      textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      header: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 6),
        margin: const pw.EdgeInsets.only(bottom: 8),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: green, width: 1)),
        ),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 26,
              height: 26,
              child: pw.Image(pw.MemoryImage(assets.logo)),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.Text(
                '${tr('app_name_plain')} — ${tr('association_name')}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: green,
                ),
              ),
            ),
            pw.Text(
              '${ctx.pageNumber}/${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      ),
      build: (ctx) => [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: green,
          ),
        ),
        pw.Text(subtitle, style: const pw.TextStyle(fontSize: 9.5)),
        pw.SizedBox(height: 10),
        for (final t in tables) ...[
          pw.Text(
            t.title,
            style: pw.TextStyle(
              fontSize: 12.5,
              fontWeight: pw.FontWeight.bold,
              color: green,
            ),
          ),
          pw.SizedBox(height: 4),
          if (t.rows.isEmpty)
            pw.Text('—')
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: .5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: mint),
                  children: [
                    for (final h in t.headers)
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          h,
                          textDirection: dir(h),
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                for (final r in t.rows)
                  pw.TableRow(
                    children: [
                      for (final v in r)
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            plain(v),
                            textDirection: dir(plain(v)),
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          pw.SizedBox(height: 12),
        ],
      ],
    ),
  );
  return doc.save();
}

Future<void> exportPdf(
  BuildContext context, {
  required String title,
  required String fileName,
  required List<ReportTable> tables,
}) async {
  final lang = Localizations.localeOf(context).languageCode;
  final subtitle =
      '${context.tr('ad_generated')}: ${fmtDateTime(DateTime.now())}';
  final bytes = await buildReportPdf(
    title: title,
    subtitle: subtitle,
    tables: tables,
    rtl: lang == 'ar',
    tr: (k) => AppStrings.of(lang, k),
  );
  await saveFile(bytes, '$fileName-${stamp()}.pdf', 'application/pdf');
}

Future<void> exportXlsx(
  BuildContext context, {
  required String fileName,
  required List<ReportTable> tables,
}) async {
  final rtl = Localizations.localeOf(context).languageCode == 'ar';
  final bytes = buildXlsx([
    for (final t in tables)
      XlsxSheet(t.title, [
        t.headers,
        for (final r in t.rows) [for (final v in r) v is num ? v : plain(v)],
      ], rtl: rtl),
  ]);
  await saveFile(
    bytes,
    '$fileName-${stamp()}.xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
}

Future<void> exportText(String text, String fileName, String mime) =>
    saveFile(Uint8List.fromList(utf8.encode(text)), fileName, mime);

/// PDF + Excel buttons for a list of tables.
class ExportButtons extends StatelessWidget {
  const ExportButtons({
    super.key,
    required this.title,
    required this.fileName,
    required this.tables,
    this.onExport,
  });
  final String title;
  final String fileName;
  final List<ReportTable> Function() tables;

  /// Called before exporting (permission check + audit). Return false to stop.
  final bool Function()? onExport;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    children: [
      OutlinedButton.icon(
        onPressed: () {
          if (onExport != null && !onExport!()) return;
          exportPdf(
            context,
            title: title,
            fileName: fileName,
            tables: tables(),
          );
        },
        icon: const Icon(Icons.picture_as_pdf_outlined),
        label: const Text('PDF'),
      ),
      OutlinedButton.icon(
        onPressed: () {
          if (onExport != null && !onExport!()) return;
          exportXlsx(context, fileName: fileName, tables: tables());
        },
        icon: const Icon(Icons.table_view_outlined),
        label: const Text('Excel'),
      ),
    ],
  );
}

/// The app's big full-width buttons are made compact for the dashboard.
Widget adminCompact(BuildContext context, Widget child) {
  final t = Theme.of(context);
  const size = WidgetStatePropertyAll(Size(64, 42));
  return Theme(
    data: t.copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: t.filledButtonTheme.style?.copyWith(minimumSize: size),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: t.outlinedButtonTheme.style?.copyWith(minimumSize: size),
      ),
      textButtonTheme: TextButtonThemeData(
        style: t.textButtonTheme.style?.copyWith(minimumSize: size),
      ),
    ),
    child: child,
  );
}
