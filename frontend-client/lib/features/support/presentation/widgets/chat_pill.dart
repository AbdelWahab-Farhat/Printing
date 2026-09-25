import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/dates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// سطرٌ صغير في وسط المحادثة: يومٌ («اليوم»، «أمس»، «14 أغسطس»)، أو خبرٌ كـ«أُغلقت التذكرة».
///
/// **بلونَي فقاعة الدعم**، لا بلونٍ جديد: هو كلام المحادثة نفسها، لا زرٌّ ولا تنبيه.
class ChatPill extends StatelessWidget {
  const ChatPill(this.label, {super.key});

  /// فاصلُ يوم — «اليوم» و«أمس» باسميهما، وما قبلهما بتاريخه بلا سنةٍ إن كانت هذه السنة.
  factory ChatPill.day(DateTime day, {Key? key}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final gap = today.difference(DateTime(day.year, day.month, day.day)).inDays;

    return ChatPill(switch (gap) {
      0 => 'اليوم',
      1 => 'أمس',
      _ => day.shortDayLabel,
    }, key: key);
  }

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.incomingBubble,
            borderRadius: BorderRadius.circular(999.r),
            border: scheme.incomingBubbleEdge.a == 0
                ? null
                : Border.all(color: scheme.incomingBubbleEdge),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 3.h),
            child: Text(
              label,
              style: context.textTheme.labelMedium?.copyWith(
                color: scheme.incomingMeta,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
