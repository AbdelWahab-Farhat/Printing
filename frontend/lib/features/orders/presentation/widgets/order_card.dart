import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One order in the list.
///
/// **الشكل منقول عن البطاقة التي يعرفها الموظفون** — شريط الحالة يملأ أعلى البطاقة، وتحته شبكة
/// من ثلاثة صفوف في ثلاثة أعمدة، تفصلها مسافات لا خطوط: «لمن» ثم «بكام» ثم «فين ومتى». الترتيب
/// هو ترتيب الأسئلة كما تُسأل، والمال في وسط البطاقة لأنه أكثر ما يُفتح لأجله سطرٌ في قائمة.
///
/// **ولا شارة دفع ولا تلوين للبطاقة.** كلاهما كان يقول ما تقوله الأرقام الثلاثة نفسها — «سعر
/// الطلبية» و«المدفوع» و«المتبقي» — وشارةٌ فوق رقمها المباشر ضجيج، وطلاءُ صفٍّ كامل في قائمة
/// تُقرأ سطراً سطراً يخطف العين إلى ما لم يطلب أحد إبرازه.
class OrderCard extends StatelessWidget {
  const OrderCard({required this.order, this.onTap, super.key});

  final Order order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          // **The reference card's own proportions.** Its three cells run nearer the card's edge
          // than ours did and its rows stand much further apart, so the horizontal inset comes in
          // and the vertical one goes out.
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 18.h),
          // Same border-plus-shadow finish as CustomerCard and ProductCard: a card against this
          // background reads as its own surface only once it has an edge, not just a colour.
          decoration: BoxDecoration(
            // Painted here, not left to the Material above: a `BoxShadow` is drawn as the whole
            // rounded rectangle filled and blurred, so a decoration with a shadow and no colour
            // washes 5% black straight across the card's face and turns the white grey.
            // `BoxDecoration` paints shadows first and the colour over them, which keeps the
            // shadow outside the edge where it belongs.
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          // **النسخ للهاتف لا لنا.** كانت الضغطة المطوّلة تنسخ الخانة كلها وتطلق رسالة، وهي
          // حركة اخترعناها: التحديد بالإصبع ثم «نسخ» من قائمة النظام يعرفها كل من يملك هاتفاً،
          // ويأخذ منها نصف رقم أو خانتين معاً — والضغطة القصيرة تبقى للطلبية نفسها.
          child: SelectionArea(
            // **والضغطة القصيرة تُستردّ من التحديد هنا.** `SelectionArea` تُدخل مُتعرِّفاتها
            // في الحلبة أعمق من `InkWell` فوقها، فتفوز بالنقرة وتبقى الطلبية مقفلة؛ ومُتعرِّفٌ
            // أعمق منها يستردّها، ولا ينازعها على الضغطة المطوّلة ولا على السحب — وهما ما
            // تحتاجه للتحديد.
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                // The band takes the full width from this, and the grid rows fill it anyway.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OrderStatusChip(status: order.status, label: order.statusLabel, banner: true),
                  SizedBox(height: 22.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Cell(
                          label: 'كود العميل',
                          value: order.customer?.code ?? '#${order.customerId}',
                          isLtr: true,
                        ),
                      ),
                      Expanded(
                        child: _Cell(label: 'رقم الفاتورة', value: '#${order.code}'),
                      ),
                      Expanded(
                        child: _Cell(
                          label: 'رقم الاستلام',
                          value: order.recipientPhone ?? order.customer?.phone ?? '—',
                          isLtr: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 26.h),
                  // The money. Every figure is the string the server sent — including the
                  // subtraction: a total assembled on the server and re-derived on the phone is two
                  // answers to one question, and the phone's is the one made of doubles.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Cell(
                          label: 'سعر الطلبية',
                          value: order.grandTotal.grouped,
                          isLtr: true,
                          // The app's own colour for the figure the order is *worth*.
                          tone: scheme.primary,
                        ),
                      ),
                      Expanded(
                        child: _Cell(
                          label: 'المدفوع',
                          value: order.paidAmount.grouped,
                          isLtr: true,
                          // Money that came in — the same green the payment chips use.
                          tone: scheme.paid,
                        ),
                      ),
                      Expanded(
                        child: _Cell(
                          label: 'المتبقي',
                          value: order.remainingAmount.grouped,
                          isLtr: true,
                          // The one thing a work queue is scanned for after the status — red while
                          // anything is owed, and green once nothing is: a zero in alarm red would
                          // make the settled order look like the problem.
                          tone: order.isOutstanding ? scheme.error : scheme.paid,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 26.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Cell(
                          label: 'مكان الاستلام',
                          value: order.isOfficePickup ? order.cityName : order.destination,
                        ),
                      ),
                      Expanded(
                        child: _Cell(label: 'تاريخ الإنشاء', value: order.placedAgo),
                      ),
                      // The third column of a three-column grid, empty: two cells spread
                      // across the whole width would sit under nothing above them.
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
/// One labelled fact — the name above it in bold, the value under it.
///
/// **العنوان هو النصف العريض، لا القيمة.** كان العكس: عنوانٌ رمادي صغير فوق رقمٍ أسود عريض،
/// فكانت الأرقام وحدها ما تراه العين في شبكة من تسع خانات، ولا يُعرف أيّها أيّ إلا بقراءة ما
/// فوقه. البطاقة المرجعية تفعل عكس ذلك: الاسم يُقرأ أولاً ويقود العين إلى قيمته.
///
/// **والقيمة داكنة كالعنوان**، يفرّق بينهما الوزن والحجم لا اللون: الرمادي الخافت في عمودٍ
/// عرضه ثلث شاشة كان أضعف ما في بطاقةٍ كلّ عملها أن تُقرأ من نظرة.
class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value, this.isLtr = false, this.tone});

  final String label;
  final String value;

  /// A phone number, a code or an amount — read left-to-right even inside this RTL card.
  final bool isLtr;

  /// Overrides the value's colour. Spent on the three money cells and nowhere else, so a colour
  /// on this card always means «هذا رقمُ مال».
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            // Two lines, like the reference: «رقم هاتف الاستلام» in a third of a phone is a name
            // that wraps, and an ellipsis in the middle of it would hide the word that identifies
            // the cell.
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            textAlign: TextAlign.center,
            textDirection: isLtr ? TextDirection.ltr : null,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(color: tone ?? scheme.onSurface),
          ),
        ],
      ),
    );
  }
}
