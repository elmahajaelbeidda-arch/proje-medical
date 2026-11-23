import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_info.dart';
import '../core/l10n.dart';
import '../core/theme.dart';

/// Small «حمّل التطبيق لأندرويد» link, in the web version on Android phones
/// and computers only (hidden on iPhone, where no file can be installed).
class AppDownloadCard extends StatelessWidget {
  const AppDownloadCard({
    super.key,
    this.force = false,
    this.oldPhones = false,
  });

  /// Show it outside the web too (tests).
  final bool force;

  /// Also offer the version for older phones (About page).
  final bool oldPhones;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && !force) return const SizedBox.shrink();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const SizedBox.shrink();
    }
    void open(String url) =>
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: () => open(androidApkUrl),
          icon: const Icon(LucideIcons.download, size: 20),
          label: Text(context.tr('dl_android')),
        ),
        if (oldPhones)
          TextButton(
            onPressed: () => open(androidApkOldPhonesUrl),
            child: Text(
              context.tr('dl_old_phones'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.grey),
            ),
          ),
      ],
    );
  }
}
