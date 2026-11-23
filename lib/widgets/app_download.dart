import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_info.dart';
import '../core/l10n.dart';
import '../core/theme.dart';

/// «حمّل التطبيق»: shown in the web version only, to install the phone app.
class AppDownloadCard extends StatelessWidget {
  const AppDownloadCard({super.key, this.force = false});

  /// Show it outside the web too (tests).
  final bool force;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && !force) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.smartphone, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('dl_title'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      context.tr('dl_sub'),
                      style: TextStyle(fontSize: 13, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(androidApkUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(LucideIcons.download),
            label: Text(context.tr('dl_android')),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('dl_iphone'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}
