import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/admin_provider.dart';
import '../../core/app_info.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../widgets/app_download.dart';
import '../../widgets/brand.dart';
import '../patient/home_tab.dart' show VerseText;

/// «عن التطبيق»: the full introduction (shortened on the welcome and home
/// screens), how to reach the association, and the app version.
class AboutAppScreen extends ConsumerWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(appSettingsProvider).info;
    final whatsapp = info.whatsapp.replaceAll(RegExp(r'\D'), '');
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('about_app_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Center(
            child: Image.asset(
              'assets/images/logo_icon.png',
              width: 80,
              height: 80,
              semanticLabel: context.tr('app_name'),
            ),
          ),
          const SizedBox(height: 12),
          BrandName(
            fontSize: 24,
            color: AppColors.primary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          VerseText(
            style: TextStyle(
              fontSize: 16,
              height: 1.7,
              color: AppColors.turquoiseText,
            ),
          ),
          const SizedBox(height: 20),
          _WhiteCard(
            child: Text(
              context.tr('about_shifa'),
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 15,
                height: 1.8,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('contact_us'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                if (info.phone.isNotEmpty)
                  _ContactRow(
                    icon: LucideIcons.phone,
                    label: context.tr('phone'),
                    value: info.phone,
                    uri: Uri(scheme: 'tel', path: info.phone),
                  ),
                if (whatsapp.isNotEmpty)
                  _ContactRow(
                    icon: LucideIcons.messageCircle,
                    label: context.tr('whatsapp'),
                    value: info.whatsapp,
                    uri: Uri.parse(
                      'https://wa.me/${whatsapp.length == 8 ? '222$whatsapp' : whatsapp}',
                    ),
                  ),
                if (info.email.isNotEmpty)
                  _ContactRow(
                    icon: LucideIcons.mail,
                    label: context.tr('email'),
                    value: info.email,
                    uri: Uri(scheme: 'mailto', path: info.email),
                  ),
              ],
            ),
          ),
          if (kIsWeb) ...[const SizedBox(height: 16), const AppDownloadCard()],
          const SizedBox(height: 24),
          Text(
            '${context.tr('version')} $appVersion',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: AppColors.shadow,
    ),
    child: child,
  );
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.uri,
  });
  final IconData icon;
  final String label;
  final String value;
  final Uri uri;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () => launchUrl(uri, mode: LaunchMode.externalApplication),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: AppColors.grey),
                ),
                Text(
                  value,
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRightDir, size: 18, color: AppColors.grey),
        ],
      ),
    ),
  );
}
