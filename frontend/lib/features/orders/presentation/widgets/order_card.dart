import 'dart:async';

import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/customers/presentation/widgets/design_thumbnail.dart';
import 'package:dayaa/features/customers/presentation/widgets/design_viewer.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_deleted_badge.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_status_chip.dart';
import 'package:dayaa/features/orders/presentation/widgets/partial_delivery_badge.dart';
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
                  // **الشارة إلى جانب الشريط لا فوقه ولا تحته.** الحالة تُقرأ أولاً، فتبقى لها
                  // عرض البطاقة تقريباً؛ و«مستعجل» طبقةٌ فوق الحالة لا حالةٌ ثانية، فتأخذ من
                  // السطر نفسه بقدر كلمتها وحدها. وتغيب تماماً في الطلبية العادية — لا مكان
                  // محجوز لها ولا شرطة، فالبطاقة التي لا شارة فيها هي البطاقة كما كانت.
                  Row(
                    children: [
                      // **«محذوفة» تأخذ مكان «مستعجل» لا مكاناً بجانبها.** طلبيةٌ خرجت من المحل
                      // لا يستعجلها أحد — والشارات الثلاث معاً لا يتّسع لها أضيق هاتف. انظر
                      // [OrderDeletedBadge].
                      if (order.isArchived) ...[
                        const OrderDeletedBadge(besideBanner: true),
                        SizedBox(width: 8.w),
                      ] else if (order.isUrgent) ...[
                        const _UrgentBadge(),
                        SizedBox(width: 8.w),
                      ],
                      // **وواقعةٌ ثالثة على السطر نفسه، رمادية.** «استلام جزئي» ليست حالةً ولا
                      // إنذاراً: الطلبية التي أخذ العميل بعضها وسُوّي حسابها انتهت كما يجب،
                      // والأحمر هنا يجعل من نصف القائمة مشكلة. وتغيب حين يغيب المفتاح — لا
                      // تُحمَّل بنود كل حمولة، و«لم يُسأل» ليست «لا».
                      //
                      // وهي وحدها ما يُضغط داخل البطاقة دون أن يفتح الطلبية: الضغطة عليها
                      // تفتح ورقة «قبل وبعد» — انظر [PartialDeliveryBadge].
                      if (order.isPartiallyDelivered ?? false) ...[
                        PartialDeliveryBadge(order: order),
                        SizedBox(width: 8.w),
                      ],
                      Expanded(
                        child: OrderStatusChip(
                          status: order.status,
                          label: order.statusLabel,
                          banner: true,
                        ),
                      ),
                    ],
                  ),
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
                      // **الخانة الثالثة، وقد صار لها ما تقوله.** كانت فارغةً محجوزةً لتستقيم
                      // الأعمدة — خانتان تتمدّدان على عرض البطاقة تقفان تحت لا شيء — والوزن
                      // يملؤها دون أن يطيل البطاقة بسطر. ويغيب بغياب الجواب: `weightLabel` تعود
                      // `null` في طلبيةٍ لا شيء فيها يُوزن وفي طلبيةٍ لم تُوزن بعد، و«٠ كجم»
                      // تحت اسمٍ عريض تُقرأ كوزنٍ قيس فوجد صفراً. فتعود الخانة فارغةً كما كانت.
                      Expanded(
                        child: switch (order.weightLabel) {
                          final label? => _Cell(label: 'وزن الطلبية', value: label),
                          null => const SizedBox.shrink(),
                        },
                      ),
                    ],
                  ),
                  // **كود النورس، وسطرٌ لا يظهر إلا لمن له كود.** رقمُ الطردِ عند شركة التوصيل
                  // هو ما يُقال في الهاتف حين يسأل زبونٌ «فين طلبيتي؟»، وكان لا يُعرف إلا بفتح
                  // الطلبية. صفٌّ مستقلٌّ لا خانةٌ رابعة: ثلاث خانات تتقاسم عرض الهاتف بالكاد،
                  // ورابعةٌ تجعل الأربعة كلها غير مقروءة. ويغيب كاملاً عن الطلبية التي لم تذهب
                  // إلى ناقل — وهي الأغلب — فلا يطول أحدٌ بطاقتَه بسطرٍ فارغ.
                  if (order.nawrisParcel case final parcel?) ...[
                    SizedBox(height: 26.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _Cell(label: 'كود النورس', value: parcel.code)),
                      ],
                    ),
                  ],
                  // **آخر ما على البطاقة، لا وسطها.** «طلبية إيه؟» سؤالٌ يأتي بعد «لمن» و«بكام»
                  // و«فين»، وهو أول ما كان يفتح الموظفُ الطلبية لأجله. صفٌّ واحد لا قائمة:
                  // البطاقة أصلاً بطول ثلاثة صفوف، وقائمةُ بنودٍ تحتها تُخرج اثنتين من كل ثلاث
                  // بطاقات خارج الشاشة. والغلاف فوقها، لأنه يُلمَح ولا يُقرأ.
                  _Footer(covers: order.artworks, items: order.items ?? const []),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
/// ذيل البطاقة: ما يُطبع على الطلبية، ثم ما فيها بنداً بنداً.
///
/// **الغلاف أولاً.** ما يميّز طلبيةً عن أخرى في قائمة تُقرأ بالعين هو الصورة المطبوعة عليها، لا
/// اسم المنتج ولا رقمه — فهي أعلى الذيل، والأسماء تحتها.
///
/// **وصورة المنتج نُزعت.** كانت تُرسم بجانب كل بند، وهي صورة الكتالوج نفسها — الكيس الأبيض
/// إيّاه على كل سطر من كل طلبية في المحل — فلا تقول شيئاً عن الطلبية التي هي تحتها، وتزاحم
/// الاسمَ وحدَه القادر على قوله.
///
/// **بندٌ في سطر، ومعه كميته.** «أكياس الشحن السادة» وحده لا يقول كم منها، و«طلبية ٢١٬٢٣٢ د.ل»
/// بلا كمية هي نفس السؤال الذي كانت البطاقة تُفتح لأجله. الكمية هنا هي **المطلوبة** لا
/// المحتسبة: البطاقة لا تضع سعراً بجانبها يحتاج أن تتّفق معه حسابياً، والرقم الذي اتُّفق عليه
/// مع الزبون هو ما يبحث عنه من يمرّ على القائمة. النواقص لها سطرها الأحمر في صفحة الطلبية.
///
/// **وما زاد عن بندين يُطوى.** خمسة أسطر تحت كل بطاقة تُخرج ما بعدها من الشاشة، فالاثنان
/// الأولان ظاهران دائماً والبقية خلف زرٍّ يقول عددها.
///
/// ويغيب الذيل كلّه — الخطُّ الفاصل معه — عن طلبيةٍ لا أغلفة فيها ولا بنود: خطٌّ تحته فراغ في
/// قائمة تُقرأ سطراً سطراً هو سطرٌ يُقرأ ولا يقول شيئاً.
class _Footer extends StatefulWidget {
  const _Footer({required this.covers, required this.items});

  /// ما يُطبع على الطلبية، بالترتيب الذي اختير به. فارغةٌ في كيسٍ سادة — ولا مربّع رمادي بديل:
  /// مكانٌ محجوزٌ لصورة لا وجود لها أسفل كل بطاقة في القائمة أسوأ من غيابه.
  final List<CustomerDesign> covers;

  final List<OrderItem> items;

  /// ما يسعه ذيل البطاقة قبل أن تطول: بندان، وما بعدهما بطلبٍ من القارئ.
  static const int _collapsedCount = 2;

  @override
  State<_Footer> createState() => _FooterState();
}

class _FooterState extends State<_Footer> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final items = widget.items;
    final covers = widget.covers;

    if (covers.isEmpty && items.isEmpty) return const SizedBox.shrink();

    final foldable = items.length > _Footer._collapsedCount;

    final shown = _expanded || !foldable
        ? items
        : items.take(_Footer._collapsedCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 20.h),
        Divider(height: 1, thickness: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
        SizedBox(height: 10.h),
        if (covers.isNotEmpty) ...[
          _Covers(covers: covers),
          SizedBox(height: 10.h),
        ],
        // الفتح والطيّ حركةٌ واحدة متّصلة، لا قفزة في ارتفاع البطاقة.
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final item in shown) _Line(item: item)],
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

/// أغلفة الطلبية، صفّاً واحداً.
///
/// **الواحد أكبر، والاثنان فأكثر أصغر.** الغلاف الوحيد هو وجه الطلبية فيأخذ حجمه، وحين يصير
/// اثنين فالمطلوب أن يُعرفا معاً من نظرة لا أن يطول ذيل البطاقة بمربّعين كبيرين.
///
/// و`Wrap` لا `Row`: طلبيةٌ بأربعة تصاميم تنزل إلى سطر ثانٍ بدل أن تفيض عن عرض الهاتف — وهي
/// نادرة بقدر ما هي ممكنة، ولا شيء هنا يستحق شريطاً يُسحب بالإصبع داخل بطاقةٍ تُسحب بالإصبع.
///
/// **وللغلاف ضغطته وحده.** البطاقة كلها ضغطةٌ تفتح الطلبية، وهذا هو الاستثناء الوحيد فيها:
/// مربّعٌ بهذا الحجم يقول «هذا هو التصميم» ولا يقول ما فيه، ومن ضغط على الصورة أراد الصورة لا
/// الطلبية. يفتحها [showDesign] بملء الشاشة — والعارض نفسه الذي تفتحه صفحة الطلبية، بزرّ
/// التحميل والفتح خارج التطبيق، فلا نسخة ثانية منه تتفرّع عنه.
class _Covers extends StatelessWidget {
  const _Covers({required this.covers});

  final List<CustomerDesign> covers;

  @override
  Widget build(BuildContext context) {
    final side = covers.length == 1 ? 64.0 : 44.0;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: [
          for (final cover in covers)
            InkWell(
              // أعمق في الحلبة من `GestureDetector` البطاقة، فيفوز بالضغطة عليه وحده.
              onTap: () => unawaited(showDesign(context, cover)),
              borderRadius: BorderRadius.circular(10.r),
              child: DesignThumbnail(design: cover, size: side, radius: 10.r),
            ),
        ],
      ),
    );
  }
}

/// سطر واحد: اسمه، مقاسه، وكم منه.
///
/// **والمقاس ليس زينة.** «أكياس شحن ــ سادة» تُكتب مرتين على الطلبية الواحدة — مقاسان من منتج
/// واحد — فكان السطران توأمين لا يفرّق بينهما شيء، والمقاس هو الفارق كلّه وهو ما يُسأل عنه.
/// بجانب الاسم لا تحته: البطاقة في قائمة، وسطرٌ ثانٍ لكل بند يضاعف طول ذيلها.
///
/// وهو أخفت من الاسم لا مثله: الاسم يُقرأ أولاً ويقود العين إلى مقاسه، كما تفعل [_Cell] بعنوانها
/// وقيمتها.
class _Line extends StatelessWidget {
  const _Line({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        children: [
          // الاسم والمقاس صفٌّ داخل الصفّ، يتقاسمان ما تركته الكمية: المقاس يُقصّ آخرَ الاسم
          // حين يطول، ولا يُدفع هو خارج السطر — فبغيابه يصير السطران توأمين.
          Expanded(
            child: Row(
              children: [
                Flexible(
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
                  item.variantLabel,
                  // مقاسٌ يُكتب «25*35»، فيُقرأ من اليسار كما يُكتب على الكيس.
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
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


/// «مستعجل» — ما طلبه العميل، لا ما تأخّرنا نحن فيه.
///
/// **الأحمر المملوء لا الباهت.** «نواقص» و«راجع» تلبسان `errorContainer` أصلاً — الأحمر الباهت —
/// فشارةٌ بالدرجة نفسها تذوب في الشريط الذي تقف بجانبه؛ والمملوء هو اللون الوحيد على البطاقة
/// الذي لا تلبسه حالةٌ من الحالات، فيُقرأ طبقةً فوق الحالة لا حالةً ثانية تنازعها.
///
/// **ولا تلوين للبطاقة كلها.** جُرّب في «شارة الدفع» قبل هذا ورُفض: طلاء صفٍّ كامل في قائمة
/// تُقرأ سطراً سطراً يخطف العين، وقائمةٌ نصفها مطليّ لا تُبرز شيئاً.
///
/// والأيقونة تسبق الكلمة كما تفعل في `OrderStatusChip.showIcon`: الشكل يُقرأ قبل الحرف، وهذه
/// الشارة تحديداً وُضعت لتُلمَح لا لتُقرأ.
class _UrgentBadge extends StatelessWidget {
  const _UrgentBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      // نفس ارتفاع الشريط بجانبه تقريباً، فيستقيم السطر دون أن تُحاذى الشارة يدوياً.
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: scheme.error,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.urgent, size: 16.sp, color: scheme.onError),
          SizedBox(width: 5.w),
          Text(
            'مستعجل',
            style: context.textTheme.labelLarge?.copyWith(
              color: scheme.onError,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
