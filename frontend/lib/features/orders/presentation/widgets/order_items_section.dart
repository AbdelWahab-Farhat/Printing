import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/fixed_point.dart';
import 'package:dayaa/core/widgets/image_viewer.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_item_card.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_product_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// بنود المنتج الواحد من الطلبية، بالترتيب الذي أُخذت به.
///
/// **بالمنتج لا بالتجاور.** من أدخل الطلبية لم يرتّبها، والشريط فوق الصورة يسمّي منتجاً واحداً:
/// بندٌ من منتجٍ آخر بين مقاسين يفتح مجموعته هو، بعد الأولى.
class OrderProductGroup {
  const OrderProductGroup._(this.items);

  static List<OrderProductGroup> of(List<OrderItem> items) {
    // `Map` في دارت يحفظ ترتيب الإدخال، فالمجموعات بترتيب أول بندٍ من كل منتج.
    final byProduct = <int, List<OrderItem>>{};
    for (final item in items) {
      byProduct.putIfAbsent(item.productId, () => []).add(item);
    }

    return [for (final lines in byProduct.values) OrderProductGroup._(lines)];
  }

  final List<OrderItem> items;

  OrderItem get first => items.first;

  /// «450 قطعة»: ما سيُصنع من هذا المنتج، بوحدة بنوده.
  ///
  /// **الكمية المحتسبة لا المطلوبة**، كما على كل سطر: بندٌ نقص أربعون من مئته تطبع المطبعة
  /// ستّين منه. **وnull حين تختلف الوحدات**، لأن قطعاً وكيلوات معاً رقمٌ لا معنى له. والجمع
  /// بالأجزاء من الألف، لا بـ `double`، كي لا يظهر «449.999».
  String? get count {
    final unit = first.pricingUnitLabel;
    if (items.any((item) => item.pricingUnitLabel != unit)) return null;

    final total = items.fold(
      BigInt.zero,
      (sum, item) => sum + thousandths(item.pricedQuantity),
    );

    return '${fromThousandths(total).grouped} $unit';
  }

  /// أول صورة كتالوجٍ بين بنود المنتج، لطلبيةٍ لا تصميم لها.
  String? get photoUrl => items.map((item) => item.productImage?.url).nonNulls.firstOrNull;
}

/// «البنود» على شاشة الطلبية: لكل منتجٍ صورته واسمه وعدد قطعه، وتحتها سطرٌ لكل مقاس.
///
/// **التصميم قبل المنتج.** ما يميّز طلبيةً مطبوعةً عن أخرى هو ما يُطبع عليها، لا الكيس الأبيض
/// نفسه في كل طلبية — فالشريط يرسم أحدث [artworkUrls]، وصورة المنتج حين لا تصميم (كيسٌ سادة،
/// أو ملفٌّ لم يصل بعد)، ولا شيء حين لا هذا ولا ذاك. التصميم للطلبية كلّها، فيُرسم فوق كل منتج.
///
/// **والوزن تحت البنود كما كان**: مجموع البنود نفسها، وتحتها مكانه — في «الحساب» يُقرأ رقماً
/// آخر في الفاتورة.
class OrderItemsSection extends StatelessWidget {
  const OrderItemsSection({
    required this.items,
    required this.showCosts,
    this.artworkUrls = const [],
    this.weight,
    this.showOutsourcingCosts = false,
    this.onScrap,
    this.onVendorCost,
    this.linesAwaitingVendorCost = const [],
    this.onOpenProduct,
    super.key,
  });

  final List<OrderItem> items;

  /// نسخ التصميم التي تُرسم، الأقدم أولاً — انظر `Order.artworks`. فارغةٌ على كيسٍ سادة.
  final List<String> artworkUrls;

  /// «12.5 كجم»، أو null على طلبيةٍ لا وزن تقوله — انظر `Order.weightLabel`.
  final String? weight;

  /// انظر [OrderItemCard.showCosts].
  final bool showCosts;

  /// انظر [OrderItemCard.showOutsourcingCosts].
  final bool showOutsourcingCosts;

  /// null حين لا تلف معروض — لا صلاحية، أو طلبيةٌ لا رفّ خلفها بعد.
  final Future<void> Function(BuildContext context, OrderItem item)? onScrap;

  /// يُعرض على البنود التي في [linesAwaitingVendorCost] وحدها.
  final Future<void> Function(BuildContext context, OrderItem item)? onVendorCost;
  final List<int> linesAwaitingVendorCost;

  /// null لمن لا يملك `products.view`.
  final void Function(OrderItem item)? onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, group) in OrderProductGroup.of(items).indexed) ...[
          if (index > 0) SizedBox(height: 16.h),
          _banner(context, group),
          SizedBox(height: 4.h),
          for (final (row, item) in group.items.indexed) ...[
            if (row > 0) Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.6)),
            OrderItemCard(
              item: item,
              showCosts: showCosts,
              showOutsourcingCosts: showOutsourcingCosts,
              onOpenProduct: onOpenProduct == null ? null : () => onOpenProduct!(item),
              onScrap: onScrap == null ? null : () => onScrap!(context, item).ignore(),
              onVendorCost: onVendorCost == null || !linesAwaitingVendorCost.contains(item.id)
                  ? null
                  : () => onVendorCost!(context, item).ignore(),
            ),
          ],
        ],
        if (weight case final label?) ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Divider(height: 1, color: scheme.outlineVariant),
          ),
          Row(
            children: [
              Text(
                'وزن الطلبية',
                style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              // بلا `textDirection`: «12.5 كجم» رقمٌ وكلمة، وقلبه يضع الوحدة في غير جهتها.
              Text(
                label,
                style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _banner(BuildContext context, OrderProductGroup group) {
    final artwork = artworkUrls.isEmpty ? null : artworkUrls.last;
    final photo = group.photoUrl;
    final url = artwork ?? photo;

    // يفتح العارض على كل النسخ، واقفاً على أحدثها: من يقارن نسخةً بما قبلها يسحب ولا يعود.
    final urls = artwork != null ? artworkUrls : [?photo];

    return OrderProductBanner(
      code: group.first.productCode,
      name: group.first.productName,
      count: group.count,
      imageUrl: url,
      onOpenImage: url == null
          ? null
          : () => openImageViewer(context, urls: urls, initialIndex: urls.length - 1).ignore(),
    );
  }
}
