import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/investment_fund/models/fund_breakdown.dart';
import 'package:dayaa/features/investment_fund/presentation/viewmodel/fund_detail_cubit.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_detail_body.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_total_card.dart';
import 'package:dayaa/features/investment_fund/usecases/fund_breakdown_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// بضاعةٌ اشتراها الصندوقُ بماله ولم تصل الرفَّ بعد — أمراً أمراً.
///
/// طلبُ المالك 2026-09-24: «تقدر تعرض القيمة الموجودة في عمليات الشراء التي لم تصل بعد واشتُريت
/// بمال الصندوق حتى أعرف إجماليها». ثمنُها خرج من الخزينة يومَ الشراء، فهي مالُ الصندوق بتكلفتها
/// الواصلة إلى أن تُستلم — وما وصل منها انتقل إلى «بضاعة على الرفّ» ولا يُعدّ هنا ثانيةً.
///
/// والأقدمُ أوّلاً: لوريٌ طال انتظارُه هو ما فُتحت الشاشةُ لأجله.
class FundGoodsOnOrderPage extends StatelessWidget {
  const FundGoodsOnOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FundDetailCubit<FundOnOrder>(() => sl<GetFundOnOrder>()())..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('بضاعة مشتراة لم تصل')),
        body: FundDetailBody<FundOnOrder>(
          builder: (context, held) => [
            FundTotalCard(label: 'المجموع', amount: held.total),
            SizedBox(height: 16.h),
            if (held.orders.isEmpty)
              const FundEmptyLine('لا مشتريات للصندوق في الطريق')
            else
              // البابُ إلى أمر الشراء نفسه — منه يُسجَّل الاستلام.
              for (final order in held.orders)
                _PurchaseCard(
                  key: ValueKey(order.purchaseOrderId),
                  order: order,
                  onTap: () => context.push(Routes.purchaseOrder(order.purchaseOrderId)),
                ),
          ],
        ),
      ),
    );
  }
}

/// أمرُ شراءٍ في الطريق: رقمُه وحالتُه، وقيمةُ ما لم يصل أكبرَ ما في البطاقة، ثم مادّةً مادّة
/// كم بقي منها من أصل ما طُلب.
///
/// على شكل بطاقة الطلبية في شاشات البضاعة الخارجة — الإطارُ نفسُه لسؤالٍ من العائلة نفسِها.
class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({required this.order, this.onTap, super.key});

  final FundPurchaseOnOrder order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(20.r);
    final quiet = context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: scheme.surfaceContainerLowest,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'أمر شراء #${order.purchaseOrderId}',
                        style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Text(
                        order.statusLabel,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  '${order.value.grouped} د.ل',
                  textDirection: TextDirection.ltr,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
                if (_who case final who?) ...[
                  SizedBox(height: 6.h),
                  Text(who, style: quiet),
                ],
                if (order.lines.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  Divider(height: 1.h, color: scheme.outlineVariant.withValues(alpha: 0.6)),
                  SizedBox(height: 8.h),
                  for (final line in order.lines) _Line(line: line),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// من أيّ مورّدٍ ومتى طُلب.
  String? get _who {
    final parts = <String>[
      if (order.vendorName case final name? when name.isNotEmpty) name,
      if (order.orderDate case final at?) at.dayLabel,
    ];

    return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// مادّةٌ في الأمر: اسمُها، وكم بقي منها من أصل ما طُلب، وقيمةُ الباقي.
class _Line extends StatelessWidget {
  const _Line({required this.line});

  final FundOnOrderLine line;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final unit = line.unitLabel == null ? '' : ' ${line.unitLabel}';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  line.name ?? line.code ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium,
                ),
                Text(
                  'باقي ${line.quantityRemaining.grouped} من ${line.quantityOrdered.grouped}$unit',
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            '${line.value.grouped} د.ل',
            textDirection: TextDirection.ltr,
            style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
