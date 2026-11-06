import 'dart:async';

import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/features/wallet/models/wallet_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// الكلُّ ثم الأنواع — **تلتفّ ولا تُمرَّر**، كرقائق سجلّ المستثمر: فلترٌ لا يُرى لا يُسأل. وتبدأ من
/// أول السطر، في محفظة العميل وفي «المعاملات المالية» معاً.
class WalletEntryFilters extends StatelessWidget {
  const WalletEntryFilters({required this.selected, required this.onSelect, super.key});

  final WalletEntryFilter selected;
  final Future<void> Function(WalletEntryFilter) onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 6.h),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final filter in WalletEntryFilter.values)
              FilterOptionChip(
                label: filter.label,
                isSelected: filter == selected,
                onTap: () => unawaited(onSelect(filter)),
              ),
          ],
        ),
      ),
    );
  }
}
