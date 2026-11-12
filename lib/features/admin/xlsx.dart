import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// One sheet: first row is the header.
class XlsxSheet {
  final String name;
  final List<List<Object?>> rows;
  final bool rtl;
  const XlsxSheet(this.name, this.rows, {this.rtl = true});
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

String _col(int i) {
  var n = i + 1, s = '';
  while (n > 0) {
    final r = (n - 1) % 26;
    s = String.fromCharCode(65 + r) + s;
    n = (n - 1) ~/ 26;
  }
  return s;
}

/// Minimal but valid Excel workbook (inline strings, numbers, bold header,
/// right-to-left sheets for Arabic).
Uint8List buildXlsx(List<XlsxSheet> sheets) {
  final a = Archive();
  void add(String path, String xml) {
    final bytes = utf8.encode(xml);
    a.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  add(
    '[Content_Types].xml',
    '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
${[for (var i = 0; i < sheets.length; i++) '<Override PartName="/xl/worksheets/sheet${i + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'].join('\n')}
</Types>''',
  );
  add('_rels/.rels', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''');
  add(
    'xl/workbook.xml',
    '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<sheets>
${[for (var i = 0; i < sheets.length; i++) '<sheet name="${_esc(sheets[i].name.length > 31 ? sheets[i].name.substring(0, 31) : sheets[i].name)}" sheetId="${i + 1}" r:id="rId${i + 1}"/>'].join('\n')}
</sheets>
</workbook>''',
  );
  add(
    'xl/_rels/workbook.xml.rels',
    '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
${[for (var i = 0; i < sheets.length; i++) '<Relationship Id="rId${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${i + 1}.xml"/>'].join('\n')}
<Relationship Id="rId${sheets.length + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''',
  );
  add(
    'xl/styles.xml',
    '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font></fonts>
<fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF0A5C36"/><bgColor indexed="64"/></patternFill></fill></fills>
<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/></cellXfs>
<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>''',
  );

  for (var s = 0; s < sheets.length; s++) {
    final sheet = sheets[s];
    final cols = sheet.rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);
    final b = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write(
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">',
      )
      ..write(
        '<sheetViews><sheetView workbookViewId="0"${sheet.rtl ? ' rightToLeft="1"' : ''}/></sheetViews>',
      );
    if (cols > 0) {
      b.write(
        '<cols><col min="1" max="$cols" width="22" customWidth="1"/></cols>',
      );
    }
    b.write('<sheetData>');
    for (var r = 0; r < sheet.rows.length; r++) {
      b.write('<row r="${r + 1}">');
      final row = sheet.rows[r];
      for (var c = 0; c < row.length; c++) {
        final v = row[c];
        final ref = '${_col(c)}${r + 1}';
        final style = r == 0 ? ' s="1"' : '';
        if (v == null) continue;
        if (v is num) {
          b.write('<c r="$ref"$style><v>$v</v></c>');
        } else {
          b.write(
            '<c r="$ref" t="inlineStr"$style><is><t xml:space="preserve">${_esc('$v')}</t></is></c>',
          );
        }
      }
      b.write('</row>');
    }
    b.write('</sheetData></worksheet>');
    add('xl/worksheets/sheet${s + 1}.xml', b.toString());
  }
  return Uint8List.fromList(ZipEncoder().encode(a));
}
