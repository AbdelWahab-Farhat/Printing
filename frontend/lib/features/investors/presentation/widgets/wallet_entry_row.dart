import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/investors/models/wallet_entry.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// سطرٌ في سجلّ حركات المستثمر — على شكل سطر خزينة الصندوق ([FundCashRow])، لأنهما دفتران يُقرآن
/// بالطريقة نفسها: **ماذا حدث وأين**، ثم **كم بإشارته**، والوقتُ آخرُ ما يُقرأ.
///
/// **الملغى يبقى ظاهراً مشطوباً**، هو وصفُّ عكسه. حذفُهما من القائمة كان سيُخفي سؤالاً يُسأل:
/// «ألم يودع خمسمئة يوم الأحد؟» — نعم، وأُلغيت، وهذا سطرُ إلغائها.
class WalletEntryRow extends StatelessWidget {
  const WalletEntryRow({required this.entry, this.onReverse, super.key});

  final WalletEntry entry;

  /// يعكس الحركة. `null` حين لا يجوز — والخادمُ هو من يقول إن كان يجوز.
  final VoidCallback? onReverse;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tone = entry.isVoid
        ? scheme.onSurfaceVariant
        : entry.isNegative
        ? scheme.error
        : scheme.primary;
    final quiet = context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final struck = entry.isReversed ? TextDecoration.lineThrough : null;

    return Padding(
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
                    if (_where case final where? when where.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(where, style: quiet),
                    ],
                    if (entry.fundUnits case final units?) ...[
                      SizedBox(height: 4.h),
                      Text(
                        '${units.units.grouped} وحدة × ${units.unitPrice.grouped} د.ل',
                        style: quiet,
                      ),
                    ],
                    if (entry.notes case final notes? when notes.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(notes, style: quiet?.copyWith(fontStyle: FontStyle.italic)),
                    ],
                    if (entry.isReversed) ...[
                      SizedBox(height: 4.h),
                      Text(
                        'أُلغيت',
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
                // Gives way to the button on a narrow phone: the name and time are the part a
                // reader can lose to an ellipsis, the action is not.
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
  }

  /// `+800` / `−3,000` — **الإشارةُ لا تسقط أبداً**، وبعلامة الناقص الطباعية كسطر الخزينة.
  String get _amount {
    final signed = entry.signedAmount;

    return signed.startsWith('-') ? '−${signed.substring(1).grouped}' : '+${signed.grouped}';
  }

  /// أين وقعت: الصندوقُ أو الصفقة، والفترة، وطريقةُ الدفع ومرجعُه — ما يُقرأ معاً عند المطابقة.
  String? get _where {
    final parts = <String>[
      if (entry.deal case final deal?) deal.isFund ? 'الصندوق' : 'صفقة ${deal.code}',
      if (entry.period case final period?) 'فترة ${period.code}',
      if (entry.method case final method? when method.isNotEmpty) _methodLabel(method),
      if (entry.reference case final reference? when reference.isNotEmpty) reference,
    ];

    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// الوقتُ ومن سجّل — والصفُّ الذي كتبه النظامُ (ربحُ طلبية، إقفالُ فترة) بلا اسم.
  String get _footer {
    final parts = <String>[
      if (entry.recordedBy case final by?) by.name,
      if (entry.occurredAt case final at?) at.timeLabel,
    ];

    return parts.join(' · ');
  }

  static String _methodLabel(String wire) => PaymentMethod.values
      .firstWhere((method) => method.wire == wire, orElse: () => PaymentMethod.unknown)
      .label;

  /// ما يُعرَف به نوعُ الحركة قبل أن يُقرأ — ونوعٌ لا يعرفه هذا الإصدار لا يُدّعى له شكل.
  IconData get _icon {
    if (entry.isReversal) return AppIcons.reversePayment;

    return switch (entry.type) {
      'deposit' => AppIcons.payment,
      'withdrawal' || 'profit_withdrawal' => AppIcons.refund,
      'allocation' => AppIcons.fundDeposit,
      'release' => AppIcons.fundWithdraw,
      'profit' || 'profit_release' || 'profit_capitalisation' => AppIcons.profit,
      'loss' ||
      'capital_writedown' ||
      'loss_absorbed_by_company' ||
      'loss_carried_out' ||
      'loss_carried_in' => AppIcons.loss,
      _ => AppIcons.more,
    };
  }
}
