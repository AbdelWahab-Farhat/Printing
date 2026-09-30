import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// مال الطلبية في ثلاث خانات تفصلها شعرتان: سعر الطلبية، والمدفوع، والمتبقي.
///
/// **واحدةٌ للقائمة والطلبية المفتوحة** (بطاقة «طلباتي» و`OrderMoneyCard`): المبلغ الذي يراه
/// العميل في القائمة بلونه وحجمه هو ما يراه حين يفتحها.
///
/// **كل رقمٍ هنا رقم الخادم.** المتبقي لا يُطرح في الهاتف من السعر والمدفوع: رقمان لسؤالٍ
/// واحد، واحدٌ من الخادم وآخر من الهاتف، يختلفان يوماً مع الفاتورة التي في يد العميل.
class OrderMoneyCells extends StatelessWidget {
  const OrderMoneyCells({
    required this.total,
    required this.paidAmount,
    required this.balance,
    required this.isAwaitingQuote,
    super.key,
  });

  /// أرقام الخادم، وكلٌّ منها null حين لا جواب.
  final String? total;
  final String? paidAmount;
  final String? balance;

  /// بندٌ بلا سعرٍ بعد: جملةٌ مكان سعر الطلبية.
  final bool isAwaitingQuote;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final balance = this.balance;

    // مستحقٌّ ما بقي شيء: برتقالي العلامة لا أحمر الإنذار — مالٌ على طلبيةٍ تسير جيداً ليس
    // خطأً. وصفرٌ أخضر: الطلبية مسدّدة.
    final owesSomething = balance != null && thousandths(balance) > BigInt.zero;
    final paidSomething = paidAmount != null && thousandths(paidAmount!) != BigInt.zero;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Cell(
              label: 'سعر الطلبية',
              amount: total,
              // **جملةٌ مكان الرقم ما دام بندٌ بلا سعر**: الرقم المخزَّن مجموع البنود المسعَّرة
              // وحدها، أصغر مما سيُطلب — والخادم يرسل null لذلك.
              missing: isAwaitingQuote ? awaitingQuoteLabel : '—',
              tone: scheme.onSurface,
            ),
          ),
          VerticalDivider(width: 1, thickness: 1, color: scheme.surfaceContainerHigh),
          Expanded(
            child: _Cell(
              label: 'المدفوع',
              amount: paidAmount,
              tone: paidSomething ? scheme.paid : scheme.onSurfaceVariant,
            ),
          ),
          VerticalDivider(width: 1, thickness: 1, color: scheme.surfaceContainerHigh),
          Expanded(
            child: _Cell(
              label: 'المتبقي',
              amount: balance,
              tone: owesSomething ? scheme.primary : scheme.paid,
              heavy: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// خانةٌ من الثلاث: اسمها فوقها، ورقمها تحته بعملته.
class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.amount,
    required this.tone,
    this.missing = '—',
    this.heavy = false,
  });

  final String label;

  /// رقم الخادم، أو null حين لا جواب.
  final String? amount;

  /// ما يُكتب حين لا رقم.
  final String missing;

  final Color tone;

  /// «المتبقي» أثقل الثلاثة: هو ما جاء العميل يسأل عنه.
  final bool heavy;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final figure = context.textTheme.titleLarge?.copyWith(
      fontSize: 20.sp,
      fontWeight: heavy ? FontWeight.w900 : FontWeight.w800,
      height: 1.3,
      color: tone,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 4.h),
          if (amount case final amount?)
            Text.rich(
              TextSpan(
                text: amount.asMoney,
                style: figure,
                children: [
                  TextSpan(
                    // عملةٌ بجانب الرقم أصغر منه، فيبقى الرقم ما تقع عليه العين.
                    text: ' د.ل',
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            )
          else if (missing == '—')
            Text(missing, textAlign: TextAlign.center, style: figure?.copyWith(color: scheme.onSurfaceVariant))
          else
            Text(
              missing,
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                height: 1.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
