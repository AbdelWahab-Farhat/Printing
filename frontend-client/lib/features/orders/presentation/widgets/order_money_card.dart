import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// مال الطلبية: ثلاث خاناتٍ كخانات بطاقة «طلباتي» — سعر الطلبية، والمدفوع، والمتبقي — وتحتها
/// ما ليس منها.
///
/// **كل رقمٍ هنا رقم الخادم.** المتبقي لا يُطرح في الهاتف من السعر والمدفوع: رقمان لسؤالٍ
/// واحد، واحدٌ من الخادم وآخر من الهاتف، يختلفان يوماً مع الفاتورة التي في يد العميل.
///
/// **والتوصيل تحت الخانات لا بينها**، باسم «التوصيل للمندوب»: ليس من سعر الطلبية ولا من
/// المتبقي — يأخذه المندوب عند الباب على حسابه (قرار صاحب العمل، ٢٠٢٦-٠٩-٠٨). فوق «المتبقي»
/// يجمعه القارئ إليه.
class OrderMoneyCard extends StatelessWidget {
  const OrderMoneyCard({required this.order, super.key});

  final CustomerOrderDetail order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final balance = order.balance;

    // مستحقٌّ ما بقي شيء: برتقالي العلامة لا أحمر الإنذار — مالٌ على طلبيةٍ تسير جيداً ليس
    // خطأً. وصفرٌ أخضر: الطلبية مسدّدة.
    final owesSomething = balance != null && thousandths(balance) > BigInt.zero;

    final extras = [
      if (order.designFee case final fee? when fee._isSomething) _Extra('التصميم', fee),
      if (order.discount case final discount? when discount._isSomething)
        _Extra('الخصم', discount),
      if (order.deliveryPrice case final delivery? when delivery._isSomething)
        _Extra('التوصيل للمندوب', delivery, icon: AppIcons.outForDelivery),
    ];

    return AppCard.raised(
      padding: EdgeInsets.fromLTRB(8.w, 16.h, 8.w, 14.h),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Cell(
                    label: 'سعر الطلبية',
                    amount: order.total,
                    // **جملةٌ مكان الرقم ما دام بندٌ بلا سعر**: الرقم المخزَّن مجموع البنود
                    // المسعَّرة وحدها، أصغر مما سيُطلب — والخادم يرسل null لذلك.
                    missing: order.isAwaitingQuote ? awaitingQuoteLabel : '—',
                    tone: scheme.onSurface,
                  ),
                ),
                VerticalDivider(width: 1, thickness: 1, color: scheme.surfaceContainerHigh),
                Expanded(
                  child: _Cell(
                    label: 'المدفوع',
                    amount: order.paidAmount,
                    tone: (order.paidAmount?._isSomething ?? false)
                        ? scheme.paid
                        : scheme.onSurfaceVariant,
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
          ),
          if (extras.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 14.h, 8.w, 0),
              child: Divider(height: 1, thickness: 1, color: scheme.surfaceContainerHigh),
            ),
            for (final extra in extras)
              Padding(padding: EdgeInsets.fromLTRB(8.w, 12.h, 8.w, 0), child: extra),
          ],
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

/// سطرٌ تحت الخانات: اسمه، ومبلغه في آخر السطر.
class _Extra extends StatelessWidget {
  const _Extra(this.label, this.amount, {this.icon});

  final String label;
  final String amount;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final style = context.textTheme.bodyMedium?.copyWith(fontSize: 14.sp, height: 1.45);

    return Row(
      children: [
        if (icon case final icon?) ...[
          Icon(icon, size: 18.sp, color: scheme.onSurfaceVariant),
          SizedBox(width: 8.w),
        ],
        Expanded(
          child: Text(
            label,
            style: style?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
          ),
        ),
        Text('${amount.asMoney} د.ل', style: style?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

extension on String {
  /// هل المبلغ يستحق سطراً.
  ///
  /// **لا null عند الخادم لـ«لا خصم».** الخصم ورسم التصميم والتوصيل أعمدةٌ عشرية لا تكون null،
  /// فتصل «0.00» وكانت كل طلبيةٍ ترسم «الخصم 0.00 د.ل» — سطرٌ كل ما فيه أنه موجود. ويُقارَن
  /// بالأجزاء من الألف لا بالنص: الصفر نفسه يصل «0» و«0.00» و«0.000» حسب عموده.
  bool get _isSomething => thousandths(this) != BigInt.zero;
}
