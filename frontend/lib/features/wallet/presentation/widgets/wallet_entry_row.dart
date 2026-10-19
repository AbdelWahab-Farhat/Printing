import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/wallet/models/wallet_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// سطرٌ في محفظة العميل — **على شكل سطر محفظة المستثمر** (`investors/…/wallet_entry_row.dart`)،
/// بطلب صاحب العمل (٢٠٢٦-١٠-١١): أيقونةُ النوع، ثم **ماذا حدث وأين**، ثم **كم بإشارته**، وتحته
/// «إلغاء الحركة» حين يجوز، ومن سجّلها ومتى.
///
/// **الملغى يبقى ظاهراً مشطوباً**، هو وسطرُ عكسه — «ألم يشحن مئةً يوم الأحد؟» نعم، وأُلغيت.
class CustomerWalletEntryRow extends StatelessWidget {
  const CustomerWalletEntryRow({
    required this.entry,
    this.showCustomer = false,
    this.onTap,
    this.onReverse,
    super.key,
  });

  final CustomerWalletEntry entry;

  /// «المعاملات المالية» تجمع العملاء كلهم، فيقول كل سطرٍ لمن هو.
  final bool showCustomer;

  /// يفتح الطلبية، أو محفظة العميل في الصفحة الجامعة.
  final VoidCallback? onTap;

  /// يعكس الحركة. `null` حين لا يجوز — والخادمُ هو من يقول إن كان يجوز.
  final VoidCallback? onReverse;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tone = entry.isReversed || entry.isReversal
        ? scheme.onSurfaceVariant
        : entry.isIn
        ? scheme.primary
        : scheme.error;
    final quiet = context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final struck = entry.isReversed ? TextDecoration.lineThrough : null;

    final row = Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Icon(_icon, size: 20.sp, color: tone),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.typeLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: struck,
                      ),
                    ),
                    if (_where case final where?) ...[
                      SizedBox(height: 4.h),
                      Text(where, style: quiet),
                    ],
                    if (entry.notes case final notes? when notes.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(notes, style: quiet?.copyWith(fontStyle: FontStyle.italic)),
                    ],
                    if (entry.isReversed) ...[
                      SizedBox(height: 4.h),
                      Text(
                        entry.reversalReason == null ? 'أُلغيت' : 'أُلغيت — ${entry.reversalReason}',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                '$_amount د.ل',
                textDirection: TextDirection.ltr,
                style: context.textTheme.titleLarge?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w800,
                  decoration: struck,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Row(
              children: [
                if (onReverse != null)
                  TextButton.icon(
                    onPressed: onReverse,
                    icon: Icon(AppIcons.reversePayment, size: 16.sp),
                    label: const Text('إلغاء الحركة'),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.error,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                const Spacer(),
                // يفسح للزرّ على هاتفٍ ضيّق: الاسمُ والوقت يحتملان النقاط الثلاث، والفعلُ لا.
                Flexible(
                  child: Text(
                    _footer,
                    style: quiet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }

  /// `+100` / `−80` — **الإشارةُ لا تسقط أبداً**، وبعلامة الناقص الطباعية.
  String get _amount => entry.isIn ? '+${entry.amount.grouped}' : '−${entry.amount.grouped}';

  /// لمن وكيف: العميلُ في الصفحة الجامعة، ثم **طريقةُ الدفع وحدها** — الحسابُ والطلبيةُ والمرجعُ
  /// سقطت بطلب صاحب العمل (٢٠٢٦-١٠-١٧): «وسيلة الدفع فقط التي تهم». الطلبيةُ تُفتح بلمس السطر.
  String? get _where {
    final parts = <String>[
      if (showCustomer && entry.customerName != null) entry.customerName!,
      ?entry.methodLabel,
    ];

    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// من سجّلها ومتى — والزبونُ حين دفع من التطبيق بلا اسم موظف.
  String get _footer => [
    ?entry.recorderName,
    if (entry.occurredAt case final at?) at.timeLabel,
  ].join(' · ');

  /// ما يُعرَف به نوعُ الحركة قبل أن يُقرأ.
  IconData get _icon {
    if (entry.isReversal) return AppIcons.reversePayment;

    return switch (entry.type) {
      'topup' => AppIcons.walletTopUp,
      'order_payment' => AppIcons.payment,
      'order_refund' => AppIcons.refund,
      'adjustment_credit' || 'adjustment_debit' => AppIcons.edit,
      _ => AppIcons.more,
    };
  }
}
