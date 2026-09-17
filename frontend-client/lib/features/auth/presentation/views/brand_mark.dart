import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The FlyerX wordmark, drawn at the top of the sign-in and sign-up screens.
///
/// **Type, not a picture — for now, and deliberately.** The staff app draws
/// `assets/images/logo.png` here; this app has no such asset yet, and `Image.asset` on a missing
/// file is a crash at build rather than a blank space. A stand-in drawn from memory of the real
/// mark would be worse than either: an approximation of somebody's brand, shipped.
///
/// So the name is set in type, which is accurate, and the mark slots in above it the day
/// `assets/images/logo.png` lands — see BACKLOG.md, where the icon and splash are waiting on the
/// same file.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false});

  /// Smaller, for a screen whose subject is not the brand.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // «FlyerX» — the X carries the brand colour, as it does in the printed mark.
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Flyer',
                style: TextStyle(color: scheme.onSurface),
              ),
              TextSpan(
                text: 'X',
                style: TextStyle(color: scheme.primary),
              ),
            ],
          ),
          style: context.textTheme.displaySmall?.copyWith(
            fontSize: (compact ? 28 : 40).sp,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
          // The name is Latin inside an otherwise RTL app, so it is pinned.
          textDirection: TextDirection.ltr,
        ),
        if (!compact) ...[
          SizedBox(height: 8.h),
          Text(
            'أكياس شحن فلاير · إغلاق مُحكم · فتح لمرة واحدة',
            textAlign: TextAlign.center,
            style: context.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
