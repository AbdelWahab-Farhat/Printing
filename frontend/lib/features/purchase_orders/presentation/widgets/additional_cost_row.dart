import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/usecases/purchase_order_usecases.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_account_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// تكلفةٌ واحدة على أمر شراء كما يحملها النموذج — توصيل، تفريغ، جمارك.
///
/// **يتقاسمها نموذج الأمر وشاشة الاستلام**، لأن التكلفة المخطّطة على الأمر والمدفوعة عند وصول
/// الشاحنة يُسأل عنهما الأسئلة الثلاثة نفسها: على ماذا، وكم، ومن قُبض
/// (Docs/purchase-orders/PURCHASE-ORDER-ARRIVAL-COSTS.md).
class AdditionalCostDraft {
  AdditionalCostDraft({
    required String name,
    required String amount,
    this.id,
    this.treasuryAccountId,
    this.paidByLabel,
  }) : name = TextEditingController(text: name),
       amount = TextEditingController(text: amount);

  /// تكلفةٌ عند الخادم، فُتحت للتصحيح.
  factory AdditionalCostDraft.of(PurchaseOrderAdditionalCost cost) => AdditionalCostDraft(
    id: cost.id,
    name: cost.name,
    amount: trimDecimals(cost.amount),
    treasuryAccountId: cost.treasuryAccountId,
    paidByLabel: cost.paidByLabel,
  );

  /// يُحمل معها لتُصحَّح التكلفة القائمة بدل أن تُحذف وتُنشأ من جديد.
  final int? id;

  final TextEditingController name;
  final TextEditingController amount;

  /// من قُبض — فارغٌ يعني فاتورة المورد.
  int? treasuryAccountId;

  /// ما قاله الخادم عمّن قُبض، لمن لا يملك تغييره.
  final String? paidByLabel;

  /// هل كُتب شيءٌ في أيٍّ من الخانتين.
  ///
  /// **الصفّ الذي لم يُملأ يُسقط ولا يُرفض.** الضغط على «إضافة تكلفة» ثم العدول عنها ليس خطأً
  /// يستحق أن يمنع الحفظ، والاختبار نفسه يُعاد في [DraftAdditionalCost.isBlank] قبل أن يُرسل شيء.
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

/// تكلفةٌ تُكتب: على ماذا، وكم، ومن أيّ حساب.
///
/// **«الحساب» متروكاً يعني «على فاتورة المورد»** — تزيد ما عليك للمورد. أو درجٌ دُفعت منه الآن
/// (كاش، مصرف)، أو «علينا» مفتوحٌ باليد بقيت ديناً له (PURCHASE-ORDER-ARRIVAL-COSTS.md §3).
/// والبضاعة الممولة من المستثمرين لا تقبل غير الدرج: نصيبها مصروفٌ على الصفقة، والمصروف مالٌ خرج.
///
/// **يُعرض لمن يملك «إيداع وسحب ومصروف وتحويل» وحده** — تسمية الحساب صرفٌ منه، والخادم يرفضها
/// بدون الصلاحية (`CostAccountGrant`). ومن لا يملكها يرى ما قاله الخادم عن التكلفة القائمة.
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

  /// تكلفةٌ عند الوصول شيءٌ دُفع — فالصفر يُرفض. والمخطّطة قد تكون صفراً: رسمٌ أُعفي منه يستحق
  /// أن يبقى على الأمر.
  final bool requirePositive;

  bool get _mayNameAnAccount =>
      sl.isRegistered<Session>() && sl<Session>().can(AppPermission.recordTreasuryOperations);

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
                  // حين يكون في الصفّ شيءٌ فقط: الصفّ المتروك يُسقط قبل الإرسال، فرفضُ الحفظ
                  // بسببه جدارٌ لا شيء خلفه.
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
          if (_mayNameAnAccount) ...[
            SizedBox(height: 10.h),
            // الصفّ بلا حالة، والاختيار يُكتب في المسودّة — فيُعاد رسم المنتقي وحده.
            StatefulBuilder(
              builder: (context, setState) => TreasuryAccountPicker(
                method: null,
                incoming: false,
                payables: true,
                label: 'الحساب',
                unsetLabel: 'على فاتورة المورد',
                value: cost.treasuryAccountId,
                onChanged: (id) => setState(() => cost.treasuryAccountId = id),
              ),
            ),
          ]
          // تكلفةٌ يقول الخادم إنها دُفعت من حساب تبقى تقول ذلك، وحسابها يعود كما هو عند الحفظ.
          else if (cost.treasuryAccountId != null) ...[
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
