import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';

/// Style for the brand name "شِفاءٌ لِلنّاس", in the app's own font, with
/// enough line height for the diacritics (kasra under ش and ل, tanween over
/// ء, shadda over ن) so none of them is clipped.
TextStyle brandNameStyle(
  BuildContext context, {
  required double fontSize,
  Color? color,
}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final base = Theme.of(context).textTheme.headlineLarge ?? const TextStyle();
  return base.copyWith(
    fontWeight: FontWeight.w800,
    fontSize: fontSize,
    height: 1.7,
    color: color ?? (dark ? Colors.white : AppColors.ink),
    letterSpacing: 0,
  );
}

/// The app name as a heading (logo lockup, splash, login...).
class BrandName extends StatelessWidget {
  const BrandName({super.key, this.fontSize = 40, this.color, this.textAlign});

  final double fontSize;
  final Color? color;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      context.tr('app_name'),
      textAlign: textAlign,
      maxLines: 1,
      softWrap: false,
      style: brandNameStyle(context, fontSize: fontSize, color: color),
    );
  }
}

/// Text in which every occurrence of the app name is emphasised (bold),
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
    final nameStyle = base.copyWith(fontWeight: FontWeight.w800);

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
