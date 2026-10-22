import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «الطلبية لدى نورس» — said in the form, before any money is taken.
///
/// **Before, because after can be too late.** Nawris has refused changes once the courier holds
/// the parcel, and the person at the counter is the one who can still ring the courier. The
/// sentence is the server's; this only gives it somewhere to stand.
class CarrierNoticeBox extends StatelessWidget {
  const CarrierNoticeBox({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        message,
        style: context.textTheme.bodySmall?.copyWith(color: scheme.onTertiaryContainer),
      ),
    );
  }
}
