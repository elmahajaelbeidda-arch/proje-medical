import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../widgets/brand.dart';
import '../patient/home_tab.dart' show HomeCard, ServiceTile, shifaVerse;

/// «عن التطبيق»: the full introduction (shortened on the home screen).
class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('about_app_title'))),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        HomeCard(
          child: Column(
            children: [
              Image.asset(
                'assets/images/logo_icon.png',
                width: 96,
                height: 96,
                semanticLabel: context.tr('app_name'),
              ),
              const SizedBox(height: 8),
              const BrandName(fontSize: 26, color: AppColors.primary),
              Text(
                context.tr('association'),
                style: const TextStyle(fontSize: 13, color: AppColors.grey),
              ),
              const SizedBox(height: 14),
              const Text(
                shifaVerse,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.8,
                  color: AppColors.turquoiseText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                'سورة المائدة · 32',
                textDirection: TextDirection.rtl,
                style: TextStyle(fontSize: 13, color: AppColors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        HomeCard(
          child: BrandRichText(
            context.tr('about_shifa'),
            style: const TextStyle(
              fontSize: 15,
              height: 1.8,
              color: AppColors.text,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ServiceTile(
          icon: LucideIcons.users,
          title: context.tr('about_association'),
          subtitle: context.tr('association'),
          onTap: () => context.push('/about'),
        ),
        ServiceTile(
          icon: LucideIcons.fileText,
          title: context.tr('disclaimer'),
          subtitle: context.tr('chat_notice'),
          onTap: () => context.push('/disclaimer'),
        ),
      ],
    ),
  );
}
