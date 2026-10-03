import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «1,250 د.ل» / «−80 د.ل». الإشارة تُفصل قبل التجميع فلا يقع سالبٌ بين الأرقام، والسالبُ
/// الطباعي هو الذي تطبعه دفاتر التطبيق.
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

/// ما في الحساب كما يقوله الناس: «1,250 د.ل» للمال، و«علينا 1,000 د.ل» للدَّين — لا «−1,000»
/// أبداً، فهي تُقرأ خطأً. و«لنا عنده» حين يكون عند الدائن مالٌ للشركة. TREASURY-DESIGN §٢٠.
String treasuryBalanceLabel(TreasuryAccount account) {
  if (!account.isPayable) return treasuryMoney(account.balance ?? '0');

  return owedLabel(account.owed, holder: 'عنده');
}

/// ما علينا كما يقوله الناس: «علينا 1,000 د.ل»، أو — حين يكون عند الدائن مالٌ للشركة — «لنا
/// عنده 50 د.ل». [holder] «عنده» لدائنٍ واحد و«عندهم» لأكثر. لا سالبَ عارياً أبداً.
String owedLabel(String owed, {String holder = 'عندهم'}) => owed.startsWith('-')
    ? 'لنا $holder ${treasuryMoney(owed.substring(1))}'
    : 'علينا ${treasuryMoney(owed)}';

/// الرقم أعلى شاشة الخزينة — كل ما في الحسابات، أو رصيد حسابٍ واحد.
class TreasuryTotalCard extends StatelessWidget {
  const TreasuryTotalCard({
    required this.label,
    required this.amount,
    this.footnote,
    this.inline = false,
    super.key,
  });

  final String label;
  final String amount;
  final String? footnote;

  /// سطر واحد: العنوان في جهة القراءة والرقم مقابله — للوحة الحسابات، حيث المساحة لما تحت
  /// الرقم. صفحة الحساب تبقى على البطاقة الطويلة.
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final overdrawn = amount.startsWith('-');

    if (inline) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: overdrawn ? scheme.errorContainer : scheme.primaryContainer,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              treasuryMoney(amount),
              textDirection: TextDirection.ltr,
              style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
    }

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

/// سطرٌ من سجلّ الحساب — ما حدث، ومن فعله، والرصيد الذي تركه.
///
/// على شكل سطر نقد الصندوق، وهو شكل كل سطر دفترٍ في التطبيق: الحدث وقصّته على جهة القراءة،
/// والمبلغ بإشارته والرصيد بعده على الجهة الأخرى. **المعكوس يبقى ظاهراً مشطوباً**، وسطرُ عكسه
/// فوقه.
class TreasuryMovementRow extends StatelessWidget {
  const TreasuryMovementRow({required this.movement, this.onTap, this.onOptions, super.key});

  final TreasuryMovement movement;

  /// يفتح مصدر المال حين يكون له باب — الطلبية اليوم. فارغٌ: لا شيء يُفتح.
  final VoidCallback? onTap;

  /// «...» — العكس. فارغٌ حين لا يُعكس السطر أو لا يملك القارئ ذلك، فلا يُرسم الزر.
  final VoidCallback? onOptions;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tone = movement.isReversed
        ? scheme.onSurfaceVariant
        : movement.isIn
        ? scheme.primary
        : scheme.error;
    final quiet = context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final struck = movement.isReversed ? TextDecoration.lineThrough : null;

    final story = [
      // «المصاريف» تجمع الحسابات كلها، فيقول كل سطرٍ من أيّها خرج.
      if (movement.accountName case final account?) 'من $account',
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
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    decoration: struck,
                  ),
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
                  decoration: struck,
                ),
              ),
              if (movement.balanceAfter case final after?) ...[
                SizedBox(height: 2.h),
                Text('الرصيد ${treasuryMoney(after)}', style: quiet),
              ],
            ],
          ),
          if (onOptions case final options?)
            TreasuryOptionsButton(tooltip: 'خيارات الحركة', onPressed: options),
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
            TreasuryFigures(lines: lines, emphasis: emphasis),
          ],
        ),
      ),
    );
  }
}

/// أسطر «البيان — المبلغ» وتحتها السطر الذي تُقال لأجله، بلا بطاقة ولا عنوان: داخل تبويب
/// يكون اسم التبويب هو العنوان.
class TreasuryFigures extends StatelessWidget {
  const TreasuryFigures({required this.lines, this.emphasis, super.key});

  final List<(String, String)> lines;
  final (String, String)? emphasis;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
    );
  }
}

/// زرُّ «...» على صفّ — بابُ التعديل والعكس، لا اللمسة التي تفتح الصف.
class TreasuryOptionsButton extends StatelessWidget {
  const TreasuryOptionsButton({required this.tooltip, required this.onPressed, super.key});

  /// اسمٌ يقرؤه قارئ الشاشة ويجده الاختبار.
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Icon(AppIcons.more, color: context.colorScheme.onSurfaceVariant),
      onPressed: onPressed,
    );
  }
}

/// صفٌّ واحد في ورقة «...».
class TreasuryOption {
  const TreasuryOption({
    required this.icon,
    required this.label,
    required this.onSelected,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelected;

  /// يكتب ما لا يُمحى — عكسٌ: بلون الخطأ.
  final bool isDestructive;
}

/// ورقة «...» لصفّ: عنوانه، ثم ما يُفعل به.
///
/// **على شكل ورقة خيارات التصميم** (`customer_designs_page.dart`): رأسٌ يسمّي الصف، ثم صفوفٌ
/// بأيقوناتها، والهدّامُ بلون الخطأ — **داخل `SingleChildScrollView`** لأن الورقة لا تتجاوز
/// نصف الشاشة، وعلى هاتفٍ قصير وقع صفٌّ خارج ما يُرسم.
///
/// الصفّ المختار يُنفَّذ بعد أن تُغلق الورقة، بسياق الصفحة لا بسياقها.
Future<void> showTreasuryOptions(
  BuildContext context, {
  required String title,
  String? subtitle,
  required List<TreasuryOption> options,
}) async {
  final chosen = await showModalBottomSheet<TreasuryOption>(
    context: context,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.h),
            ListTile(
              title: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: sheetContext.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              subtitle: subtitle == null ? null : Text(subtitle),
            ),
            const Divider(height: 1),
            for (final option in options)
              ListTile(
                leading: Icon(
                  option.icon,
                  color: option.isDestructive ? sheetContext.colorScheme.error : null,
                ),
                title: Text(
                  option.label,
                  style: option.isDestructive
                      ? TextStyle(color: sheetContext.colorScheme.error)
                      : null,
                ),
                onTap: () => Navigator.of(sheetContext).pop(option),
              ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    ),
  );

  chosen?.onSelected();
}

/// رفضُ الخادم تحت عنصرٍ لا مربّع خطأ له — مفتاحٌ أو زرّ — بلون الخطأ وحجم رسالة الحقل.
class TreasuryFieldError extends StatelessWidget {
  const TreasuryFieldError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 12.w, top: 4.h),
      child: Text(
        message,
        style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.error),
      ),
    );
  }
}
