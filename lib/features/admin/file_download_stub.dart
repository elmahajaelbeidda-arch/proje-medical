import 'dart:typed_data';

import 'package:printing/printing.dart';

/// Phones and desktop: share sheet (save to files, send by WhatsApp...).
Future<void> saveFile(Uint8List bytes, String fileName, String mime) =>
    Printing.sharePdf(bytes: bytes, filename: fileName);
