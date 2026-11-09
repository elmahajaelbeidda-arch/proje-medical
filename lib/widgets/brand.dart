import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';

/// Typeface of the brand name "شِفاءٌ لِلنّاس" (bundled in assets/fonts).
const brandFontFamily = 'Amiri';

/// Style for the brand name: Amiri Bold with enough line height for the
/// diacritics (kasra under ش and ل, tanween over ء, shadda over ن).
TextStyle brandNameStyle({
  required double fontSize,
  Color color = AppColors.ink,
}) {
  return TextStyle(
    fontFamily: brandFontFamily,
    fontWeight: FontWeight.w700,
    fontSize: fontSize,
    height: 1.55,
    color: color,
    letterSpacing: 0,
  );
}

/// The app name, always written in Amiri Bold.
class BrandName extends StatelessWidget {
  const BrandName({super.key, this.fontSize = 40, this.color, this.textAlign});

  final double fontSize;
  final Color? color;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      context.tr('app_name'),
      textAlign: textAlign,
      maxLines: 1,
      softWrap: false,
      style: brandNameStyle(
        fontSize: fontSize,
        color: color ?? (dark ? Colors.white : AppColors.ink),
      ),
    );
  }
}

/// Text in which every occurrence of the app name is set in Amiri Bold,
/// e.g. the introduction "شِفاءٌ لِلنّاس هي منصة رقمية خيرية...".
class BrandRichText extends StatelessWidget {
  const BrandRichText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final name = context.tr('app_name');
    final base = style ?? DefaultTextStyle.of(context).style;
    final nameStyle = base.copyWith(
      fontFamily: brandFontFamily,
      fontWeight: FontWeight.w700,
      // Amiri is optically smaller than the UI font.
      fontSize: (base.fontSize ?? 14) * 1.2,
    );

    final parts = text.split(name);
    final spans = <InlineSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) spans.add(TextSpan(text: name, style: nameStyle));
      if (parts[i].isNotEmpty) spans.add(TextSpan(text: parts[i]));
    }
    return Text.rich(
      TextSpan(style: base, children: spans),
      textAlign: textAlign,
    );
  }
}
