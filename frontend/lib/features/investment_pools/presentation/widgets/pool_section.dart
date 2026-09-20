import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// How loud a section is.
///
/// [warning] exists for exactly one thing: a list that is **blocking an action**. It is not a
/// severity scale — a section that is merely important stays [plain], because a screen where
/// three things are shouting has nothing that stands out.
enum PoolSectionTone { plain, warning }

/// One titled block on a pool's screen.
///
/// The pool screens are a column of these and nothing else, so the spacing, the corner and the
/// weight of a heading are decided once here. Six screens each choosing is how «الشركاء» ends up
/// a different size from «المواد» one scroll below it.
class PoolSection extends StatelessWidget {
  const PoolSection({
    required this.title,
    required this.children,
    this.subtitle,
    this.tone = PoolSectionTone.plain,
    this.trailing,
    super.key,
  });

  final String title;

  /// One quiet line under the heading, for a rule somebody would otherwise have to be told.
  final String? subtitle;

  final List<Widget> children;
  final PoolSectionTone tone;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isWarning = tone == PoolSectionTone.warning;

    final background = isWarning
        ? scheme.errorContainer.withValues(alpha: 0.35)
        : scheme.surfaceContainerLowest;

    final border = isWarning
        ? scheme.error.withValues(alpha: 0.5)
        : scheme.outlineVariant.withValues(alpha: 0.7);

    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isWarning ? scheme.onErrorContainer : null,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          if (subtitle != null) ...[
            SizedBox(height: 2.h),
            Text(
              subtitle!,
              style: context.textTheme.bodySmall?.copyWith(
                color: isWarning
                    ? scheme.onErrorContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
          ],
          SizedBox(height: 8.h),
          ...children,
        ],
      ),
    );
  }
}
