import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// حالةُ الفترة شريحةً بلونها وأيقونتها — طلبُ المالك 2026-10-12: «تميز حالة الفترة باللون
/// مختلف و Chip + icon».
///
/// كانت تُكتب في ذيل العنوان «الفترة P2 — مفتوحة»، فتُقرأ كلمةً ولا تُرى. الآن ثلاثُ حالاتٍ
/// بثلاثة ألوان من [PaymentTone] و[StockTone]: **الأخضرُ للجارية**، و**الكهرمانُ للمنتظِرة
/// طلبياتِها** — لا خطأ فيها ولا انتهت — و**الرماديُّ للمغلقة**.
///
/// **الكلمةُ كلمةُ الخادم** (`status_label`)، واللونُ والأيقونةُ من [status]: حالةٌ لا يعرفها هذا
/// الإصدار تُرسم بالرماديّ وباسمها الذي وصلت به.
class PeriodStatusChip extends StatelessWidget {
  const PeriodStatusChip({required this.status, required this.label, super.key});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tone = PeriodStatusTone.of(context.colorScheme, status);

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(8.w, 4.h, 10.w, 4.h),
      decoration: BoxDecoration(
        color: tone.fill,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tone.icon, size: 16.sp, color: tone.ink),
          SizedBox(width: 4.w),
          Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: tone.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// ألوانُ الحالة في موضعٍ واحد — للشريحة، ولنقطة الفترة في شرائح الفلتر، فلا يتعلّم القارئُ
/// دليلَي ألوان.
class PeriodStatusTone {
  const PeriodStatusTone._({
    required this.fill,
    required this.ink,
    required this.dot,
    required this.icon,
  });

  factory PeriodStatusTone.of(ColorScheme scheme, String status) => switch (status) {
    'open' => PeriodStatusTone._(
      fill: scheme.paidContainer,
      ink: scheme.onPaidContainer,
      dot: scheme.paid,
      icon: AppIcons.periodOpen,
    ),
    'closing' => PeriodStatusTone._(
      fill: scheme.warnContainer,
      ink: scheme.onWarnContainer,
      dot: scheme.warn,
      icon: AppIcons.periodClosing,
    ),
    _ => PeriodStatusTone._(
      fill: scheme.outlineVariant.withValues(alpha: 0.6),
      ink: scheme.onSurfaceVariant,
      dot: scheme.outline,
      icon: AppIcons.periodClosed,
    ),
  };

  final Color fill;
  final Color ink;

  /// النقطةُ أمام رمز الفترة في `FilterOptionChip` — الدرجةُ القويّة من اللون نفسِه.
  final Color dot;
  final IconData icon;
}
