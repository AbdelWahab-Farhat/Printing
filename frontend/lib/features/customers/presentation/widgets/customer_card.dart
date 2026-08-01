import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/features/customers/models/customer.dart';

/// One customer in the list.
///
/// Name, code and phone — the three things a customer is looked up by, so all three are on the
/// card rather than one screen deeper.
class CustomerCard extends StatelessWidget {
  const CustomerCard({required this.customer, this.onTap, super.key});

  final Customer customer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              _Avatar(name: customer.name, isActive: customer.isActive),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        // Only when it is *not* the normal case: a badge on every row stops
                        // being read.
                        if (!customer.isActive) const _InactiveBadge(),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(AppIcons.phone, size: 15.sp, color: scheme.onSurfaceVariant),
                        SizedBox(width: 5.w),
                        Text(
                          customer.phone,
                          // A Libyan number reads left-to-right even inside this RTL card.
                          textDirection: TextDirection.ltr,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        _CodeChip(code: customer.code),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.isActive});

  final String name;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // `characters`, not `[0]`: an Arabic letter carrying a mark is more than one code unit and
    // slicing it renders a broken glyph.
    final initial = name.trim().isEmpty ? '؟' : name.trim().characters.first;

    return Container(
      height: 48.w,
      width: 48.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Text(
        initial,
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: isActive ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        code,
        textDirection: TextDirection.ltr,
        style: context.textTheme.labelMedium?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InactiveBadge extends StatelessWidget {
  const _InactiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: context.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        'موقوف',
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colorScheme.onErrorContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
