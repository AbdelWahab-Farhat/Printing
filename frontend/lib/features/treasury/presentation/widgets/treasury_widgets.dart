import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «1,250 د.ل» / «−80 د.ل». The sign is split off before grouping so a minus never lands inside
/// the digits, and the typographic minus is the one the ledgers in this app already print.
String treasuryMoney(String amount, {bool signed = false}) {
  final negative = amount.startsWith('-');
  final digits = (negative ? amount.substring(1) : amount).grouped;
  final sign = negative ? '−' : (signed ? '+' : '');

  return '$sign$digits د.ل';
}

IconData accountKindIcon(AccountKind kind) => switch (kind) {
  AccountKind.cash => AppIcons.cashBox,
  AccountKind.bank => AppIcons.bank,
  AccountKind.wallet => AppIcons.mobileWallet,
  AccountKind.custody => AppIcons.custody,
  AccountKind.payable => AppIcons.payable,
  AccountKind.unknown => AppIcons.treasury,
};

/// What an account holds, as people say it: «1,250 د.ل» for money, «علينا 1,000 د.ل» for a debt
/// — never «−1,000», which reads as a mistake. «لنا عنده» when a creditor holds the company's
/// money. TREASURY-DESIGN §٢٠.
String treasuryBalanceLabel(TreasuryAccount account) {
  if (!account.isPayable) return treasuryMoney(account.balance ?? '0');

  return owedLabel(account.owed, holder: 'عنده');
}

/// What is owed, said the way people say it: «علينا 1,000 د.ل», or — when the creditor holds the
/// company's money instead — «لنا عنده 50 د.ل». [holder] is «عنده» for one creditor, «عندهم» for
/// several. Never a bare minus, which reads as a mistake.
String owedLabel(String owed, {String holder = 'عندهم'}) => owed.startsWith('-')
    ? 'لنا $holder ${treasuryMoney(owed.substring(1))}'
    : 'علينا ${treasuryMoney(owed)}';

/// The figure at the top of a treasury screen — everything held, or one account's balance.
class TreasuryTotalCard extends StatelessWidget {
  const TreasuryTotalCard({required this.label, required this.amount, this.footnote, super.key});

  final String label;
  final String amount;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final overdrawn = amount.startsWith('-');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: overdrawn ? scheme.errorContainer : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Text(label, style: context.textTheme.bodyMedium),
          SizedBox(height: 6.h),
          Text(
            treasuryMoney(amount),
            textDirection: TextDirection.ltr,
            style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (footnote case final note?) ...[
            SizedBox(height: 4.h),
            Text(note, style: context.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// One account on the dashboard: what it is, whose it is, and what it holds.
class TreasuryAccountTile extends StatelessWidget {
  const TreasuryAccountTile({required this.account, required this.onTap, super.key});

  final TreasuryAccount account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final quiet = context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    final subtitle = [
      account.kindLabel,
      if (account.holder case final holder?) 'باسم ${holder.name}',
      if (account.isDefault) 'الافتراضي',
      if (!account.isActive) 'معطَّل',
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Opacity(
        opacity: account.isActive ? 1 : 0.55,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: scheme.secondaryContainer,
                child: Icon(
                  accountKindIcon(account.kind),
                  size: 20.sp,
                  color: scheme.onSecondaryContainer,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 2.h),
                    Text(subtitle, style: quiet),
                  ],
                ),
              ),
              Text(
                treasuryBalanceLabel(account),
                // A bare figure reads left to right; «علينا …» is a sentence and reads as Arabic.
                textDirection: account.isPayable ? null : TextDirection.ltr,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: account.isOverdrawn ? scheme.error : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One line of an account's history — what happened, by whom, and the balance it left.
///
/// The shape of the fund's cash row, which is the shape of every ledger line in this app: the
/// event and its story on the reading side, the signed amount and the balance after on the other.
class TreasuryMovementRow extends StatelessWidget {
  const TreasuryMovementRow({required this.movement, this.onTap, super.key});

  final TreasuryMovement movement;

  /// Opens the order the money belongs to, when there is one.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tone = movement.isIn ? scheme.primary : scheme.error;
    final quiet = context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);

    final story = [
      if (movement.counterpartName case final other?) movement.isIn ? 'من $other' : 'إلى $other',
      ?movement.categoryName,
      ?movement.employeeName,
      if (movement.orderId case final order?) 'الطلبية #$order',
      if (movement.recorderName case final who?) 'سجّلها $who',
    ].join(' · ');

    final row = Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.isReversal ? 'إلغاء: ${movement.kindLabel}' : movement.kindLabel,
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (story.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(story, maxLines: 2, overflow: TextOverflow.ellipsis, style: quiet),
                ],
                if (movement.notes case final notes? when notes.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(notes, style: quiet?.copyWith(fontStyle: FontStyle.italic)),
                ],
                if (movement.occurredAt case final at?) ...[
                  SizedBox(height: 4.h),
                  Text(at.timeLabel, style: quiet),
                ],
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                treasuryMoney(movement.signedAmount, signed: true),
                textDirection: TextDirection.ltr,
                style: context.textTheme.titleLarge?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (movement.balanceAfter case final after?) ...[
                SizedBox(height: 2.h),
                Text('الرصيد ${treasuryMoney(after)}', style: quiet),
              ],
            ],
          ),
        ],
      ),
    );

    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}

/// A titled card of label–amount lines — «لمن المال» and «قيمة المخزون».
class TreasuryFiguresCard extends StatelessWidget {
  const TreasuryFiguresCard({
    required this.title,
    required this.icon,
    required this.lines,
    this.emphasis,
    super.key,
  });

  final String title;
  final IconData icon;
  final List<(String, String)> lines;

  /// The line the card exists to say, drawn bold under the rest.
  final (String, String)? emphasis;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20.sp, color: scheme.primary),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            for (final (label, amount) in lines)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Row(
                  children: [
                    Expanded(child: Text(label, style: context.textTheme.bodyMedium)),
                    Text(treasuryMoney(amount), textDirection: TextDirection.ltr),
                  ],
                ),
              ),
            if (emphasis case (final label, final amount)) ...[
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    treasuryMoney(amount),
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: amount.startsWith('-') ? scheme.error : scheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
