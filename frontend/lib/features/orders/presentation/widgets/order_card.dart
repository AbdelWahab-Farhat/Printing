import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/presentation/widgets/order_status_chip.dart';

/// One order in the list.
///
/// A labelled grid, two rows of three: what the order is worth and where it stands read as a
/// pair of facts, not a headline, because the status chip above already says the one thing a
/// work queue is scanned for first. The six cells below answer the questions that follow in the
/// order they get asked — «لمن» ثم «بكام» ثم «فين» — rather than four lines stacked by category.
///
/// **العربون والمتبقي ليسا هنا بعد.** لا يوجد لهما عمود في الباك اند حتى الآن — أُجِّل الأمر
/// وسُجِّل في BACKLOG.md، فبطاقة تعرض رقماً لم يُحسب بعد أسوأ من بطاقة لا تعرضه.
class OrderCard extends StatelessWidget {
  const OrderCard({required this.order, this.onTap, super.key});

  final Order order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          // Same border-plus-shadow finish as CustomerCard and ProductCard: a card against this
          // background reads as its own surface only once it has an edge, not just a colour.
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OrderStatusChip(status: order.status, label: order.statusLabel, compact: true),
              SizedBox(height: 12.h),
              Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
              SizedBox(height: 12.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Cell(
                      label: 'كود العميل',
                      value: order.customer?.code ?? '#${order.customerId}',
                      isLtr: true,
                    ),
                  ),
                  Expanded(child: _Cell(label: 'رقم الفاتورة', value: '#${order.code}')),
                  Expanded(
                    child: _Cell(
                      label: 'رقم الاستلام',
                      value: order.recipientPhone ?? order.customer?.phone ?? '—',
                      isLtr: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Cell(
                      label: 'سعر الطلبية',
                      value: order.grandTotal,
                      emphasize: true,
                    ),
                  ),
                  Expanded(
                    child: _Cell(
                      label: 'مكان الاستلام',
                      value: order.isOfficePickup ? order.cityName : order.destination,
                    ),
                  ),
                  Expanded(child: _Cell(label: 'تاريخ الإنشاء', value: order.placedAgo)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One labelled fact — the label above, muted and small; the value below it.
class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.value,
    this.isLtr = false,
    this.emphasize = false,
  });

  final String label;
  final String value;

  /// A phone number or a customer code — read left-to-right even inside this RTL card.
  final bool isLtr;

  /// The order's price: the one number on the card worth the primary colour.
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          textAlign: TextAlign.center,
          textDirection: isLtr ? TextDirection.ltr : null,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: emphasize ? scheme.primary : scheme.onSurface,
          ),
        ),
      ],
    );
  }
}
