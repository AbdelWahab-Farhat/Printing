import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/usecases/purchase_order_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One purchase-order cost as a form holds it — delivery, porters, customs.
///
/// **Shared by the order form and the receive sheet**, because a cost planned on the order and
/// one paid when the lorry arrives are the same three questions: what it was for, how much, and
/// who was paid (Docs/purchase-orders/PURCHASE-ORDER-ARRIVAL-COSTS.md).
class AdditionalCostDraft {
  AdditionalCostDraft({
    required String name,
    required String amount,
    this.id,
    this.treasuryAccountId,
    this.paidByLabel,
  }) : name = TextEditingController(text: name),
       amount = TextEditingController(text: amount);

  /// A cost the server already has, opened for correcting.
  factory AdditionalCostDraft.of(PurchaseOrderAdditionalCost cost) => AdditionalCostDraft(
    id: cost.id,
    name: cost.name,
    amount: trimDecimals(cost.amount),
    treasuryAccountId: cost.treasuryAccountId,
    paidByLabel: cost.paidByLabel,
  );

  /// Carried through so an existing cost is corrected rather than deleted and recreated.
  final int? id;

  final TextEditingController name;
  final TextEditingController amount;

  /// Who was paid — null is the vendor's bill.
  int? treasuryAccountId;

  /// What the server said about who was paid, for somebody who may not change it.
  final String? paidByLabel;

  /// Whether anything has been typed into either box.
  ///
  /// **A row nobody filled in is dropped rather than refused.** Tapping «إضافة تكلفة» and
  /// changing your mind is not an error worth blocking a save over, and the same test runs again
  /// in [DraftAdditionalCost.isBlank] before anything reaches the wire.
  bool get isBlank => name.text.trim().isEmpty && amount.text.trim().isEmpty;

  DraftAdditionalCost toDraft() => DraftAdditionalCost(
    id: id,
    name: name.text,
    amount: amount.text,
    treasuryAccountId: treasuryAccountId,
  );

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

/// A cost being typed: what it was for, and how much.
///
/// **Always on the vendor's bill, for now.** The server also takes a drawer or a «التزام» as
/// who was paid (`treasury_account_id`, PURCHASE-ORDER-ARRIVAL-COSTS.md §3), but the owner chose
/// not to offer it yet (2026-10-11). Adding it back is one `TreasuryAccountPicker` here, writing
/// [AdditionalCostDraft.treasuryAccountId].
class AdditionalCostRow extends StatelessWidget {
  const AdditionalCostRow({
    required this.cost,
    required this.onRemove,
    this.onChanged,
    this.requirePositive = false,
    super.key,
  });

  final AdditionalCostDraft cost;
  final VoidCallback onRemove;
  final ValueChanged<String>? onChanged;

  /// A cost paid on arrival is something that was paid — zero is refused. A planned one may be
  /// zero: a listed charge that was waived is still worth keeping on the order.
  final bool requirePositive;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: cost.name,
                  label: 'البيان',
                  hint: 'توصيل، تفريغ، جمارك…',
                  // Only when the row has something in it: an untouched row is dropped before
                  // sending, so refusing to save because of one is a wall with nothing behind it.
                  validator: (value) =>
                      cost.isBlank || (value ?? '').trim().isNotEmpty
                      ? null
                      : 'أدخل بيان التكلفة',
                  onChanged: onChanged,
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: Icon(AppIcons.delete, size: 20.sp),
                color: scheme.error,
                tooltip: 'إزالة التكلفة',
              ),
            ],
          ),
          SizedBox(height: 10.h),
          AppTextField(
            controller: cost.amount,
            label: 'القيمة (د.ل)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,]')),
            ],
            validator: (value) {
              if (cost.isBlank) return null;

              final parsed = double.tryParse(
                Validators.toWesternDigits(
                  value ?? '',
                ).replaceAll(',', '.').trim(),
              );

              if (parsed == null) return 'أدخل القيمة';
              if (parsed < 0) return 'القيمة لا يمكن أن تكون سالبة';

              return requirePositive && parsed == 0
                  ? 'القيمة يجب أن تكون أكبر من صفر'
                  : null;
            },
            onChanged: onChanged,
          ),
          // A cost the server already holds as paid elsewhere keeps saying so, and its account
          // travels back untouched on save.
          if (cost.treasuryAccountId != null) ...[
            SizedBox(height: 10.h),
            Text(
              cost.paidByLabel ?? 'دُفعت من حساب',
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
