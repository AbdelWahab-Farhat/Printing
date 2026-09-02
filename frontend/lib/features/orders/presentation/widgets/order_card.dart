import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_status_chip.dart';
import 'package:dayaa/features/products/presentation/widgets/product_gallery.dart';
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
              // **والبطاقة تُضغط كبطاقة، لا كتسع كلمات.** المُتعرِّف بلا هذا يفحص أبناءه وحدهم،
              // وأبناؤه هنا هي الحروف: فالفراغ بين العنوان وقيمته، وما بين الصفوف، والخانة
              // التاسعة الفارغة — كلّها تسقط منه إلى `SelectionArea` فوقه، وهي تبتلع الضغطة
              // ولا تفتح شيئاً. `opaque` تجعل مساحة البطاقة كلها ضغطةً واحدة تصل الطلبية.
              behavior: HitTestBehavior.opaque,
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
                  // **آخر ما على البطاقة، لا وسطها.** «طلبية إيه؟» سؤالٌ يأتي بعد «لمن» و«بكام»
                  // و«فين»، وهو أول ما كان يفتح الموظفُ الطلبية لأجله. صفٌّ واحد لا قائمة:
                  // البطاقة أصلاً بطول ثلاثة صفوف، وقائمةُ بنودٍ تحتها تُخرج اثنتين من كل ثلاث
                  // بطاقات خارج الشاشة.
                  if (order.items case final items? when items.isNotEmpty) _Items(items: items),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
/// ما في الطلبية، بنداً بنداً، أسفل البطاقة.
///
/// **بندٌ في سطر، ومعه كميته.** «أكياس الشحن السادة» وحده لا يقول كم منها، و«طلبية ٢١٬٢٣٢ د.ل»
/// بلا كمية هي نفس السؤال الذي كانت البطاقة تُفتح لأجله. الكمية هنا هي **المطلوبة** لا
/// المحتسبة: البطاقة لا تضع سعراً بجانبها يحتاج أن تتّفق معه حسابياً، والرقم الذي اتُّفق عليه
/// مع الزبون هو ما يبحث عنه من يمرّ على القائمة. النواقص لها سطرها الأحمر في صفحة الطلبية.
///
/// **وما زاد عن بندين يُطوى.** خمسة أسطر تحت كل بطاقة تُخرج ما بعدها من الشاشة، فالاثنان
/// الأولان ظاهران دائماً والبقية خلف زرٍّ يقول عددها.
///
/// **صورةٌ لمن له صورة فقط** — والمكان محجوزٌ لها في الطلبية التي فيها صورةٌ واحدة على الأقل،
/// لتبقى الأسماء على استقامة واحدة. المربّع الرمادي البديل تعلّمت الشاشةُ تخطّيه في
/// `ProductCard`، وهو هنا أسوأ: مربّعٌ فارغ أسفل كل بطاقة في قائمة تُقرأ سطراً سطراً.
class _Items extends StatefulWidget {
  const _Items({required this.items});

  final List<OrderItem> items;

  /// ما يسعه ذيل البطاقة قبل أن تطول: بندان، وما بعدهما بطلبٍ من القارئ.
  static const int _collapsedCount = 2;

  @override
  State<_Items> createState() => _ItemsState();
}

class _ItemsState extends State<_Items> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final items = widget.items;
    final foldable = items.length > _Items._collapsedCount;

    final shown = _expanded || !foldable
        ? items
        : items.take(_Items._collapsedCount).toList();

    // يُحجز مكان الصورة متى كان في الطلبية صورةٌ واحدة على الأقل، فلا تتعرّج الأسماء.
    final hasAnyImage = items.any((item) => item.productImage != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 20.h),
        Divider(height: 1, thickness: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
        SizedBox(height: 10.h),
        // الفتح والطيّ حركةٌ واحدة متّصلة، لا قفزة في ارتفاع البطاقة.
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in shown) _Line(item: item, reserveImageSlot: hasAnyImage),
            ],
          ),
        ),
        if (foldable)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              // ضغطته له وحده: البطاقة كلها ضغطةٌ تفتح الطلبية، وهذا الزر أعمق منها في الحلبة.
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded ? AppIcons.collapse : AppIcons.expand,
                size: 18.sp,
              ),
              // عدداً بين قوسين لا كلمة: «عرض الكل (٥)» لا تحتاج تمييزاً بين بندين وبنود.
              label: Text(_expanded ? 'إخفاء' : 'عرض الكل (${items.length})'),
              style: TextButton.styleFrom(
                foregroundColor: scheme.primary,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.symmetric(horizontal: 8.w),
              ),
            ),
          ),
      ],
    );
  }
}

/// سطر واحد: صورته، اسمه، وكم منه.
class _Line extends StatelessWidget {
  const _Line({required this.item, required this.reserveImageSlot});

  final OrderItem item;

  /// يبقي الأسماء على استقامة واحدة في طلبيةٍ بعض بنودها مصوَّر وبعضها لا.
  final bool reserveImageSlot;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final image = item.productImage;
    final side = 30.w;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        children: [
          if (image != null)
            ProductThumbnail(image: image, side: side, radius: 9.r)
          else if (reserveImageSlot)
            SizedBox(width: side),
          if (image != null || reserveImageSlot) SizedBox(width: 8.w),
          Expanded(
            child: Text(
              item.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            '${item.quantity.grouped} ${item.pricingUnitLabel}',
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
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
