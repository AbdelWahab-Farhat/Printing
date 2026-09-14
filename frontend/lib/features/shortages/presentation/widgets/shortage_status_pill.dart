import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Where a shortage stands, in one word.
///
/// **The word is the server's** — `status_label`, never this app's copy of it — so a status
/// renamed on the backend is renamed on the card without a release. The colour is the app's, and
/// it is chosen from [ShortageStatus] so a status this build has never heard of still draws, in
/// the neutral tone, wearing the name it arrived with.
class ShortageStatusPill extends StatelessWidget {
  const ShortageStatusPill({required this.shortage, super.key});

  final Shortage shortage;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final (background, foreground) = switch (shortage.status) {
      // Nobody has picked it up yet.
      ShortageStatus.fresh => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      // Somebody is out looking — the same family as work in hand elsewhere in the app.
      ShortageStatus.searching => (scheme.primaryContainer, scheme.onPrimaryContainer),
      // The one that genuinely needs somebody: the goods could not be found.
      ShortageStatus.unavailable => (scheme.errorContainer, scheme.onErrorContainer),
      // Green, like every «انتهى هذا» in this app.
      ShortageStatus.completed => (scheme.paid, scheme.onPrimary),
      ShortageStatus.unknown => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        shortage.statusLabel,
        style: context.textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
