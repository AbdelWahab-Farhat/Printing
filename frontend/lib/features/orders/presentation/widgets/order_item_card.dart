import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_line_costs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// بندٌ واحد من الطلبية، سطراً تحت صورة التصميم: المقاس وكم قطعة، لا أكثر.
///
/// **لمن يطبع.** المقاس والكمية وحدهما على السطر، لأنهما ما تُضبط عليه المطبعة. اسم المنتج
/// وصورته على الشريط فوق البنود (`OrderProductBanner`)، مرةً لكل مقاساته.
///
/// **والمال في ورقة «⋯» البند**: المبلغ وسعر القطعة الذي يُدقَّق به، والتكلفة وتفصيلها لمن
/// يملكها، ومعها «فتح المنتج» و«تسجيل تلف». مجموع الطلبية في «الحساب» تحت البنود كما كان.
/// والسطر كلّه يفتح الورقة نفسها: هو الهدف الأكبر لإصبعٍ عند المطبعة.
///
/// **ما ينقص البند يبقى عليه.** «ناقص» و«غير مُستلَم» وزرّ «تسجيل تكلفة المورد» حقائق عن هذا
/// البند أو مهامٌّ معلّقة عليه، لا تفاصيل تُطوى في ورقة.
class OrderItemCard extends StatelessWidget {
  const OrderItemCard({
    required this.item,
    required this.showCosts,
    this.showOutsourcingCosts = false,
    this.onOpenProduct,
    this.onScrap,
    this.onVendorCost,
    super.key,
  });

  final OrderItem item;

  /// هل يقول السطر كم كلّف صنعه — `reports.pnl.view`.
  final bool showCosts;

  /// هل تقول ورقة بند الوسيط ما يتقاضاه المورد — صلاحيةٌ غير [showCosts]، انظر [OrderLineCosts].
  final bool showOutsourcingCosts;

  /// null بلا `products.view`، أو على حمولةٍ لم تحمل المنتج.
  final VoidCallback? onOpenProduct;

  /// null حين لا تلف معروض — لا صلاحية، أو طلبيةٌ لا رفّ خلفها بعد.
  final VoidCallback? onScrap;

  /// null إلا على بند وسيطٍ تجاوز «جاهزة» بلا تكلفة مورد، لقارئٍ يملك `products.view_cost` —
  /// الخادم يسمّي البنود، انظر `Order.linesAwaitingVendorCost`.
  final VoidCallback? onVendorCost;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final big = text.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: scheme.onSurface);
    final quiet = text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);

    return InkWell(
      onTap: () => _openOptions(context),
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: _SizeLabel(item.variantLabel, style: big),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      // الكمية المحتسبة، كما كانت: بندٌ نقص ربعه تطبع المطبعة ثلاثة أرباعه، و«ناقص»
                      // تحته يقول من كم.
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: item.pricedQuantity.grouped, style: big),
                            TextSpan(text: ' ${item.pricingUnitLabel}', style: quiet),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _Gaps(item: item),
                  // على السطر لا في الورقة: الرقم الناقص لبندٍ واحد، وربح الطلبية مجهولٌ حتى يُعطى.
                  if (onVendorCost case final record?)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: record,
                        icon: Icon(AppIcons.edit, size: 16.sp),
                        label: const Text('تسجيل تكلفة المورد'),
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'خيارات البند',
              onPressed: () => _openOptions(context),
              icon: Icon(AppIcons.more, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  /// يُغلق الورقة **ثم** يُنادي: ورقة التلف تُفتح فوق الشاشة، لا فوق ورقةٍ في طريقها إلى الإغلاق.
  Future<void> _openOptions(BuildContext context) async {
    final action = await showModalBottomSheet<_LineAction>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) => _LineSheet(
        item: item,
        showCosts: showCosts,
        showOutsourcingCosts: showOutsourcingCosts,
        mayOpenProduct: onOpenProduct != null,
        mayScrap: onScrap != null,
      ),
    );

    switch (action) {
      case _LineAction.openProduct:
        onOpenProduct?.call();
      case _LineAction.scrap:
        onScrap?.call();
      case null:
        break;
    }
  }
}

/// المقاس كما يُقرأ: «25*35» من اليسار إلى اليمين.
///
/// **في سطرٍ عربيٍّ تنقلب الأرقام المفصولة برمز**: «25*35» تُرسم «35*25»، والعرض والطول هما ما
/// تُضبط عليه المطبعة. فالمقاس الذي لا حرف عربياً فيه يُرسم من اليسار، و«سادة» أو «أسود 25*35»
/// يبقيان على اتجاه الشاشة.
class _SizeLabel extends StatelessWidget {
  const _SizeLabel(this.label, {required this.style});

  static final _arabic = RegExp('[؀-ۿ]');

  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: style,
      textDirection: _arabic.hasMatch(label) ? null : TextDirection.ltr,
    );
  }
}

/// ما ينقص البند، تحت مبلغه — لأن الاثنين يجيبان «لماذا يُحتسب أقلّ مما طُلب؟».
class _Gaps extends StatelessWidget {
  const _Gaps({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final error = context.textTheme.bodySmall?.copyWith(
      color: scheme.error,
      fontWeight: FontWeight.w700,
    );
    final muted = context.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // على البند الذي نقص منه، لأنه المكان الوحيد الذي يعني فيه الرقم شيئاً: «ناقص ٤٠» من *أي*
        // مقاس. وما طُلب يُقال معه، لأن «ناقص من كم» هو السؤال التالي.
        if (item.hasShortage) ...[
          SizedBox(height: 4.h),
          Text(
            'ناقص: ${item.shortageQuantity!.grouped} من ${item.quantity.grouped} '
            '${item.pricingUnitLabel} — غير محتسب',
            style: error,
          ),
          // **الفجوة نفسها بوحدة المخزن**، تحت رقم الفاتورة مباشرة: الأول ما يتوقّف الزبون عن دفعه،
          // وهذا ما يُشترى لسدّه. وحيث تتّفق الوحدتان لا يرسل الخادم شيئاً ولا يظهر السطر.
          if (item.shortageWarehouseQuantity case final weighed?) ...[
            SizedBox(height: 2.h),
            Text(
              'ناقص من المخزن: ${weighed.grouped} ${item.stockUnitLabel ?? ''} — هذا ما يُشترى',
              style: error,
            ),
          ]
          // **يُقال ولا يُترك فارغاً.** لا أحد يزن أكياساً غائبة، فهذه حال كل نقصٍ جديد — لكنها ما
          // يمنع تسجيل شرائه، ومشترٍ يُرفض في «النواقص» ولا شيء هنا لن يعرف أين ينظر.
          else if (item.needsAWarehouseShortage) ...[
            SizedBox(height: 2.h),
            Text('الوزن من المخزن غير محدد — حدِّده قبل تسجيل الشراء', style: muted),
          ],
        ],
        // تحت النقص، لأنهما قد يصدقان معاً. وبلون أهدأ: النقص تقصيرنا، وهذا اختيار الزبون مسجَّلاً.
        // والكلمة لمصير البضاعة كلمة الخادم، لا تُستنتج هنا.
        if (item.wasPartlyLeftBehind) ...[
          SizedBox(height: 4.h),
          Text(
            'غير مُستلَم: ${item.undeliveredQuantity!.grouped} ${item.pricingUnitLabel}'
            '${item.undeliveredDispositionLabel == null ? '' : ' — ${item.undeliveredDispositionLabel}'}',
            style: muted,
          ),
        ],
      ],
    );
  }
}

enum _LineAction { openProduct, scrap }

/// ورقة «⋯» البند: ما يُدقَّق به المبلغ، وما يُفعل بالبند.
///
/// **تُمرَّر ولا تفيض**، كورقة الدفعة: هاتفٌ قصير أو خطٌّ مكبَّر يُسقط «تسجيل تلف» خارج الشاشة.
class _LineSheet extends StatelessWidget {
  const _LineSheet({
    required this.item,
    required this.showCosts,
    required this.showOutsourcingCosts,
    required this.mayOpenProduct,
    required this.mayScrap,
  });

  final OrderItem item;
  final bool showCosts;
  final bool showOutsourcingCosts;
  final bool mayOpenProduct;
  final bool mayScrap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 8.h),
            ListTile(
              title: _SizeLabel(
                item.variantLabel,
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(item.productName),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          // الكمية المحتسبة والسعر، فيخرج حساب البند صحيحاً أمام العين: «٧٥ × ٣٢»
                          // بجانب «٢٤٠٠». وبندٌ لم يُسعَّر بعد يقول ذلك مكان «× السعر».
                          '${item.pricedQuantity.grouped} ${item.pricingUnitLabel} '
                          '${item.isPriced ? "× ${item.unitPriceOrZero.grouped}" : awaitingQuoteLabel}',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        item.isPriced ? item.lineTotalOrZero.grouped : '—',
                        textDirection: TextDirection.ltr,
                        style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  if (showCosts || showOutsourcingCosts) ...[
                    SizedBox(height: 4.h),
                    OrderLineCosts(
                      item: item,
                      showProduction: showCosts,
                      showOutsourcing: showOutsourcingCosts,
                    ),
                  ],
                ],
              ),
            ),
            if (mayOpenProduct || mayScrap) const Divider(height: 1),
            if (mayOpenProduct)
              ListTile(
                leading: Icon(AppIcons.products),
                title: const Text('فتح المنتج'),
                trailing: Icon(AppIcons.forward, size: 18.sp, color: scheme.outline),
                onTap: () => Navigator.of(context).pop(_LineAction.openProduct),
              ),
            if (mayScrap)
              ListTile(
                leading: Icon(AppIcons.delete, color: scheme.error),
                title: Text('تسجيل تلف', style: TextStyle(color: scheme.error)),
                onTap: () => Navigator.of(context).pop(_LineAction.scrap),
              ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}
