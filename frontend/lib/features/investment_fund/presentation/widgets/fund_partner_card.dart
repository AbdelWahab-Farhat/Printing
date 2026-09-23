import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// شريكٌ على سطر — نسبتُه، ورأسُ ماله، وربحُه.
///
/// **النسبةُ أكبرُ رقمٍ على السطر** لأنها السؤال: ماذا يأخذ من ربح الفترة. ورأسُ ماله وربحُه
/// تحتها لأنهما جوابُ سؤالٍ آخر — ماذا وضع وماذا لم يسحب بعد.
///
/// **وأيُّ نسبةٍ هي يقرّرها التبويبُ الذي يعرضه**: «الفترة الحالية» يمرّر نسبتَه في هذه
/// الفترة، و«الفترة القادمة» نسبتَه فيها. سطرٌ واحد للاثنين، فلا يُصلَح أحدُهما ويُنسى الآخر.
class FundPartnerCard extends StatelessWidget {
  const FundPartnerCard({
    super.key,
    required this.holder,
    required this.percent,
    this.badge,
  });

  final FundHolder holder;

  /// النسبةُ بستّ خاناتٍ كما تصل من الخادم.
  final String percent;

  /// كلمةٌ بجانب الاسم — «ينضمّ» لمن اكتتب في نافذة هذه الفترة.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // **السطرُ بابٌ لا لافتة.** ومن وضع المال ومتى، وما سحبه، ومتى يُفكّ حبسُ رأس ماله — كلُّه
    // على شاشته.
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: InkWell(
        onTap: () => context.push(Routes.investor(holder.investorId)),
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      holder.name,
                      style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (badge case final word?) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        word,
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(width: 8.w),
                  Text(
                    // ستُّ خاناتٍ على الشاشة ضجيج؛ اثنتان تكفيان للقراءة، والقسمةُ نفسُها
                    // تجري بالستّ في الخادم.
                    '${_twoPlaces(percent)}%',
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // السهمُ هو ما يقول إنه يُفتح — بلا كلمةٍ تشرحه.
                  Icon(AppIcons.forward, size: 18.sp, color: scheme.onSurfaceVariant),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'رأس المال ${holder.capital.grouped} د.ل',
                      style: context.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    'الربح ${holder.profit.grouped} د.ل',
                    style: context.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _twoPlaces(String value) {
    final parsed = double.tryParse(value);

    return parsed == null ? value : parsed.toStringAsFixed(2);
  }
}
