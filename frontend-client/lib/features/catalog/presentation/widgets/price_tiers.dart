import 'dart:math' as math;

import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/features/catalog/models/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// أسعار الكميات بطاقاتٍ صغيرة تحت السلايدر، لا جدولاً: لكل كسرٍ عتبته وسعر الوحدة فيه.
///
/// **أيّ الكسور يسري، وأيّها التالي، جوابُ الخادم لا حسابٌ هنا** — [PriceQuote.appliedTierMinQuantity]
/// و[PriceQuote.nextTier]. البطاقات تُرسم من الكتالوج، والتعليم عليها من آخر سعرٍ أجاب به. وحين
/// يكون جوابٌ جديد في الطريق تخفت البطاقات، كما يخفت الإجمالي.
///
/// على البطاقة التالية «أضف ٢٠٠» — الباقي إلى السعر الأرخص، من الخادم أيضاً. وعلى الأخيرة حين
/// تسري «أفضل سعر». الضغط على بطاقة يطلب عتبتها.
class PriceTiers extends StatelessWidget {
  const PriceTiers({
    required this.tiers,
    required this.floor,
    required this.quote,
    required this.isStale,
    required this.onChosen,
    super.key,
  });

  /// من الأقل كميةً إلى الأكثر.
  final List<PriceTier> tiers;

  /// الحد الأدنى للمنتج: كسرٌ يبدأ دونه يُكتب «من» الحد الأدنى، لأنه ما يُطلب فعلاً.
  final double floor;

  final PriceQuote? quote;
  final bool isStale;
  final ValueChanged<PriceTier> onChosen;

  @override
  Widget build(BuildContext context) {
    final quote = this.quote;
    final applied = _indexOf(quote?.appliedTierMinQuantity);
    final next = _indexOf(quote?.nextTier?.minQuantity);
    final remaining = quote?.nextTier?.quantityToReach;

    final cards = [
      for (var index = 0; index < tiers.length; index++)
        _TierCard(
          from: '${math.max(double.tryParse(tiers[index].minQuantity) ?? 0, floor)}'.asQuantity,
          unitPrice: tiers[index].unitPrice.asMoney,
          isApplied: index == applied,
          badge: switch (index) {
            _ when index == next && remaining != null => _Badge.next(
              'أضف ${remaining.asQuantity}',
            ),
            _ when index == applied && quote?.nextTier == null => const _Badge.best(),
            _ => null,
          },
          onTap: () => onChosen(tiers[index]),
        ),
    ];

    return Opacity(
      opacity: isStale ? 0.55 : 1,
      child: Padding(
        // متّسعٌ للشارة التي تجلس على حافة البطاقة العليا.
        padding: EdgeInsets.only(top: 12.h),
        child: LayoutBuilder(
          builder: (context, box) {
            final gap = 8.w;
            final narrowest = 96.w;
            final fitted = (box.maxWidth - gap * (cards.length - 1)) / cards.length;

            if (fitted >= narrowest) {
              return Row(
                children: [
                  for (var index = 0; index < cards.length; index++) ...[
                    if (index > 0) SizedBox(width: gap),
                    Expanded(child: cards[index]),
                  ],
                ],
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  for (var index = 0; index < cards.length; index++) ...[
                    if (index > 0) SizedBox(width: gap),
                    SizedBox(width: narrowest, child: cards[index]),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// أيّ بطاقةٍ عتبتها [threshold]. يُقارَن بالرقم: «300.000» و«300» عتبةٌ واحدة.
  int? _indexOf(String? threshold) {
    final wanted = double.tryParse(threshold ?? '');
    if (wanted == null) return null;

    for (var index = 0; index < tiers.length; index++) {
      if (double.tryParse(tiers[index].minQuantity) == wanted) return index;
    }

    return null;
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.from,
    required this.unitPrice,
    required this.isApplied,
    required this.badge,
    required this.onTap,
  });

  final String from;
  final String unitPrice;
  final bool isApplied;
  final _Badge? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final badge = this.badge;

    return Semantics(
      selected: isApplied,
      button: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: isApplied ? scheme.attentionContainer : scheme.surfaceContainer,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
              side: BorderSide(
                color: isApplied ? scheme.primary : scheme.outlineVariant,
                width: 1.5,
              ),
            ),
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                width: double.infinity,
                height: 66.h,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'من $from',
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: unitPrice),
                          TextSpan(
                            text: ' د.ل',
                            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      style: context.textTheme.titleMedium?.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: isApplied ? scheme.onAttentionContainer : scheme.onSurface,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              top: -12.h,
              left: 0,
              right: 0,
              child: Center(child: badge),
            ),
        ],
      ),
    );
  }
}

/// الشارة على حافة البطاقة: كهرمانيّةٌ للكسر التالي — لون «اطلب أكثر وينزل السعر» في الثيم —
/// وخضراء حين يسري أرخص الكسور.
class _Badge extends StatelessWidget {
  const _Badge.next(this.text) : isBest = false;

  const _Badge.best() : text = 'أفضل سعر', isBest = true;

  final String text;
  final bool isBest;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      height: 23.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isBest ? scheme.paidContainer : scheme.tertiary,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        text,
        maxLines: 1,
        style: context.textTheme.labelMedium?.copyWith(
          fontSize: 12.5.sp,
          fontWeight: FontWeight.w800,
          color: isBest ? scheme.onPaidContainer : scheme.onTertiary,
          height: 1.2,
        ),
      ),
    );
  }
}

/// منتجٌ بسعرٍ واحد — السادة بالكيلو — لا سلّم له: بطاقةٌ واحدة بعرض الصف، سعر الوحدة وحده.
///
/// **ولا تُحذف كما حُذف تفصيل الحساب.** الإجمالي صار في الزر، لكن سعر الكيلو لا يظهر في مكانٍ
/// آخر إن غابت هذه، وعميلٌ يرى ٤٩٠ د.ل ولا يرى ٤٩ للكيلو لا يعرف ما يدفع ثمنه.
class SinglePrice extends StatelessWidget {
  const SinglePrice({required this.unitLabel, required this.unitPrice, super.key});

  /// «قطعة» أو «كجم»، فتُقرأ البطاقة «سعر القطعة» أو «سعر الكجم».
  final String? unitLabel;

  /// كما أرسله الخادم في الكتالوج.
  final String unitPrice;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final unit = unitLabel;

    return Container(
      height: 56.h,
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: scheme.outlineVariant, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              unit == null ? 'سعر الوحدة' : 'سعر ال$unit',
              style: context.textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: unitPrice.asMoney),
                TextSpan(
                  text: ' د.ل',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            style: context.textTheme.titleMedium?.copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
