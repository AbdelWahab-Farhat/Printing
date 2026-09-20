import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/investment_pools/repositories/investment_pool_repository.dart';
import 'package:dayaa/features/investment_pools/usecases/investment_pool_usecases.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Which of a lorry's lines are bought with صندوق money.
///
/// **Nobody picks a pool here, and there is deliberately no field for one.** Each material belongs
/// to exactly one pool — held by a unique index, not by a rule anybody has to remember — so the
/// material decides, and the only question left per line is *pool money or the company's*. That is
/// the whole difference from [FundPurchaseOrderPage], where a صفقة was struck around the order and
/// somebody had to name its partners and their amounts.
///
/// **This must be done before the goods arrive.** The cost layer is stamped at the gate and can
/// never be stamped afterwards, so a line already received is shown and locked rather than hidden —
/// «وصلت» answers the question before it is asked.
///
/// Pops `true` when anything was claimed.
Future<bool> showPoolPurchaseSheet({
  required BuildContext context,
  required PurchaseOrder order,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PoolPurchaseForm(order: order),
  );

  return saved ?? false;
}

class _PoolPurchaseForm extends StatefulWidget {
  const _PoolPurchaseForm({required this.order});

  final PurchaseOrder order;

  @override
  State<_PoolPurchaseForm> createState() => _PoolPurchaseFormState();
}

class _PoolPurchaseFormState extends State<_PoolPurchaseForm> {
  /// Which lines are marked, by `stock_item_id`.
  final Set<int> _chosen = {};

  /// سعر السادة per line, by `stock_item_id`. An empty or absent controller means «no price» —
  /// which is not zero, but the other road entirely.
  final Map<int, TextEditingController> _prices = {};

  bool _saving = false;

  @override
  void dispose() {
    for (final controller in _prices.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// A line whose goods have arrived cannot be claimed: its cost layer is already stamped.
  bool _isReceived(PurchaseOrderItem item) =>
      (double.tryParse(item.quantityReceived) ?? 0) > 0;

  TextEditingController _priceFor(int stockItemId) =>
      _prices.putIfAbsent(stockItemId, TextEditingController.new);

  Future<void> _submit() async {
    if (_chosen.isEmpty) {
      context.showError('اختر بنداً واحداً على الأقل');

      return;
    }

    setState(() => _saving = true);

    final lines = _chosen.map((stockItemId) {
      final typed = _prices[stockItemId]?.text.trim() ?? '';

      return PoolPurchaseLine(
        stockItemId: stockItemId,
        printingSalePrice: typed.isEmpty
            ? null
            : Validators.toWesternDigits(typed),
      );
    }).toList();

    final result = await sl<BuyWithPoolMoney>()(
      purchaseOrderId: widget.order.id,
      lines: lines,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    result.fold(
      // The server's own words. It refuses a material that belongs to no pool, a pool that cannot
      // cover its share of the lorry, and a line already received — and its message names which.
      (failure) => context.showError(failure.message),
      (_) {
        Navigator.of(context).pop(true);
        context.showSuccess('تم تحديد البنود التي تُشترى من مال الصناديق');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 8.h,
        bottom: context.keyboardInset + 16.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'الشراء من مال الصناديق',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'اختر البنود التي يدفع ثمنها الصندوق. الصندوق يتحدّد من المادة نفسها — '
              'كل مادة تتبع صندوقاً واحداً.',
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 16.h),

            for (final item in widget.order.items)
              _LineTile(
                item: item,
                isReceived: _isReceived(item),
                isChosen: _chosen.contains(item.stockItemId),
                price: _priceFor(item.stockItemId),
                onChanged: (chosen) => setState(() {
                  if (chosen) {
                    _chosen.add(item.stockItemId);
                  } else {
                    _chosen.remove(item.stockItemId);
                  }
                }),
              ),

            SizedBox(height: 20.h),
            AppButton(
              label: 'احفظ',
              isLoading: _saving,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({
    required this.item,
    required this.isReceived,
    required this.isChosen,
    required this.price,
    required this.onChanged,
  });

  final PurchaseOrderItem item;
  final bool isReceived;
  final bool isChosen;
  final TextEditingController price;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: isChosen,
            // A received line is shown and locked rather than hidden: «وصلت» answers the question
            // before it is asked.
            onChanged: isReceived ? null : (value) => onChanged(value ?? false),
            title: Text(
              item.stockItem?.displayName ?? 'مادة ${item.stockItemId}',
              style: context.textTheme.bodyMedium,
            ),
            subtitle: Text(
              isReceived
                  ? 'وصلت — لا يمكن تحديدها بعد الاستلام'
                  : '${item.quantityOrdered.grouped}'
                        '${item.baseTotalCost == null ? '' : ' · بتكلفة ${item.baseTotalCost!.grouped}'}',
              style: context.textTheme.bodySmall?.copyWith(
                color: isReceived ? scheme.error : scheme.onSurfaceVariant,
              ),
            ),
          ),
          if (isChosen) ...[
            Padding(
              padding: EdgeInsets.only(right: 12.w, left: 12.w, bottom: 4.h),
              child: AppTextField(
                controller: price,
                label: 'سعر السادة لهذه الشحنة — اختياري',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 16.w, left: 16.w, bottom: 8.h),
              child: Text(
                // **Empty is a real answer, not a missing one.** With a price the press buys the
                // pool's plain stock at the shelf and the margin is settled there and then;
                // without one those goods ride the sale itself and are paid out of the delivered
                // order's profit.
                'اتركه فارغاً لتركب هذه البضاعة على البيع نفسه — '
                'وبسعرٍ يشتريها المطبعُ من الصندوق لحظة سحبها.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
