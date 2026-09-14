import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/fixed_point.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «استلام جزئي» مفتوحةً: ماذا كان، وماذا صار، ولماذا.
///
/// **الشارة على البطاقة تقول إن شيئاً حدث؛ وهذه تقول ماذا بالضبط.** كان الجواب موزّعاً على
/// ثلاثة أماكن: «غير مُستلَم ٢٠٠ قطعة» على سطر البند، و«منها خسارة تسليم ٣٥٠» تحت تكلفته،
/// والكيلوات الراجعة في سجل حركة المخزون — شاشةٌ أخرى وصنفٌ آخر وطرحٌ باليد. والقيمة قبل
/// التسليم لم تكن في أي منها: الفاتورة تعرض ما صارت إليه، والرقم الذي كانت عليه لا يُحفَظ.
///
/// **«قبل ← بعد» لا «الفرق» وحده.** السؤال الذي تُفتح هذه الورقة لأجله هو «الرقم ده من وين
/// جا»، وجوابه القيمتان؛ والفرق مكتوبٌ بينهما بين قوسين حتى لا يُطرح باليد.
///
/// **وكلُّ كمّيةٍ بوحدتها مكتوبة.** ما تركه الزبون يُعدّ بوحدة البيع — القطعة — وما وُضع على
/// الرفّ يُوزن بوحدة المخزن، وهما رقمان مختلفان لا يُشتقّ أحدهما من الآخر. خلطهما في عمودٍ
/// واحد هو بالضبط الخطأ الذي يصنع رقماً لا أصل له.
///
/// **ولا حساب هنا إلا واحداً، ومعلَناً.** قيمة البند قبل التسليم غير مخزَّنة — الخادم يكتب
/// `line_total` فوق نفسه — فتُبنى من `(billable + undelivered) × unit_price`، أي من نفس
/// الأطراف التي بناها الخادم، وبحساب [multiplyToMoney] العشري لا بـ`double`. وهي مكتوبةٌ هكذا
/// لتعزل أثر التسليم الجزئي وحده: بندٌ ناقصٌ **و**متروكٌ بعضه يُظهر هنا الشطر الثاني فقط، وهو
/// ما تسأل عنه الورقة.
Future<void> showPartialDeliverySheet({
  required BuildContext context,
  required Order order,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PartialDeliverySheet(order: order),
  );
}

class _PartialDeliverySheet extends StatelessWidget {
  const _PartialDeliverySheet({required this.order});

  final Order order;

  /// ما كُتب عند النقل إلى «تم الاستلام» — وهي النقلة الوحيدة التي تُسجَّل فيها هذه الواقعة.
  ///
  /// **آخرها لا أوّلها**: الطلبية قد تُرجَّع وتُسلَّم من جديد، والسبب المقصود هو سبب المرّة
  /// التي أنتجت الأرقام المعروضة. وخالٍ في القائمة: `transitions` لا تُحمَّل إلا مع الطلبية
  /// المفتوحة — و«لا سبب مكتوب» و«لم يُسأل عنه» يُرسمان هنا سواء، لأن كليهما «لا شيء يُقال».
  String? get _reason {
    final records = order.transitions;

    if (records == null) return null;

    for (final record in records.reversed) {
      if (record.toStatus != OrderStatus.delivered) continue;

      final reason = record.reason?.trim();

      if (reason != null && reason.isNotEmpty) return reason;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final lines = (order.items ?? const <OrderItem>[])
        .where((item) => item.wasPartlyLeftBehind)
        .toList();
    final reason = _reason;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            Text(
              'استلام جزئي — طلبية #${order.code}',
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 16.h),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // البنود المتروك بعضها وحدها. البند الذي أخذه الزبون كاملاً ليس جزءاً من
                    // هذه الواقعة، وسطرٌ عنه هنا يجعل الورقة نسخةً ثانية من الفاتورة.
                    for (final item in lines)
                      Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: _LineBlock(item: item),
                      ),
                    if (reason != null) ...[
                      Divider(height: 1, color: scheme.outlineVariant),
                      SizedBox(height: 12.h),
                      Text(
                        'السبب',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(reason, style: context.textTheme.bodyLarge),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// بندٌ واحد: البضاعة قبل وبعد، وما صار بالمتروك، والقيمة قبل وبعد.
class _LineBlock extends StatelessWidget {
  const _LineBlock({required this.item});

  final OrderItem item;

  /// قيمة البند لو أخذ الزبون كلّ ما كان مستحقّاً له — انظر شرح [showPartialDeliverySheet].
  String get _priceBefore => multiplyToMoney(
    addDecimals(item.billableQuantity ?? item.quantity, item.undeliveredQuantity ?? '0'),
    item.unitPrice,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final before = _priceBefore;
    final after = item.lineTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          item.variantLabel,
          style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 8.h),
        _Change(
          label: 'البضاعة',
          before: '${addDecimals(item.billableQuantity ?? item.quantity, item.undeliveredQuantity ?? '0').grouped} ${item.pricingUnitLabel}',
          after: '${(item.billableQuantity ?? item.quantity).grouped} ${item.pricingUnitLabel}',
        ),
        // **بوحدة المخزن، وحيث رجعت بضاعةٌ فقط.** الأكياس المطبوعة تحمل تصميم الزبون ولا
        // يشتريها أحد، فلا رفّ يُفتح لها — و«رجع ٠ كجم» ادّعاءٌ بأن أحداً فتحه.
        if (item.restockedQuantity case final restocked?)
          _Fact(
            label: 'رجع إلى المخزن',
            value: '${restocked.grouped} ${item.stockUnitLabel ?? item.pricingUnitLabel}',
          )
        else if (item.deliveryLoss case final loss?)
          _Fact(
            label: 'لم يرجع — خسارة',
            value: loss.grouped,
            tone: scheme.error,
          ),
        _Change(label: 'السعر', before: before.grouped, after: after.grouped, difference: subtractDecimals(after, before)),
      ],
    );
  }
}

/// «١٧٠٥ ← ١٣٦٤ (−٣٤١)» — القيمتان، والفرق بينهما مكتوباً لا مطروحاً باليد.
///
/// **مبنيٌّ من عناصر لا من نصٍّ واحد، ولهذا سببان يقعان معاً.** أوّلهما أن السطر كان نصّاً
/// واحداً مفروضاً عليه الاتجاه اللاتيني، فوقعت «قبل» يساراً و«بعد» يميناً — والقارئ العربي
/// يبدأ من اليمين، فقرأ «صار» قبل «كان». وثانيهما أن `←` حرفٌ **يُقلَب** داخل النص العربي
/// (`Bidi_Mirrored`)، فالسهم الذي يُكتب يساراً قد يُرسم يميناً حسب المحرّك.
///
/// فالترتيب صار من [Wrap] يرثُ اتجاه الصفحة — أوّل عنصرٍ فيه هو الأيمن، وهو «قبل» — والسهم
/// وحده في `Text` لاتيني، فلا يُقلَب ولا يُترك للمحرّك أن يقرّر.
class _Change extends StatelessWidget {
  const _Change({
    required this.label,
    required this.before,
    required this.after,
    this.difference,
  });

  final String label;
  final String before;
  final String after;

  /// الفرق، أو خالٍ حيث يكون مكتوباً في الطرفين أصلاً — الكمّيتان تحملان وحدتهما، وفرقٌ ثالث
  /// بجانبهما يجعل السطر ثلاث كمّيات في سطرٍ واحد.
  final String? difference;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final style = context.textTheme.bodyMedium;
    final value = style?.copyWith(fontWeight: FontWeight.w700);

    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style?.copyWith(color: scheme.onSurfaceVariant))),
          SizedBox(width: 8.w),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6.w,
              children: [
                Text(before, style: value?.copyWith(color: scheme.onSurfaceVariant)),
                // لاتينيٌّ عمداً: `←` من الحروف التي يقلبها اتجاه النص، وهذا يمنع القلب.
                Text('←', textDirection: TextDirection.ltr, style: value),
                Text(after, style: value),
                if (difference case final difference?)
                  Text('(${trimDecimals(difference)})', style: style?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// واقعةٌ بطرفٍ واحد: ما رجع إلى الرفّ، أو ما أُكل خسارةً.
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.tone});

  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final style = context.textTheme.bodyMedium;

    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style?.copyWith(color: scheme.onSurfaceVariant))),
          SizedBox(width: 8.w),
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: style?.copyWith(fontWeight: FontWeight.w700, color: tone),
          ),
        ],
      ),
    );
  }
}
