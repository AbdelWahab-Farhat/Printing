import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/product_thumbnail.dart';
import 'package:dayaa_client/features/catalog/models/product.dart';
import 'package:dayaa_client/features/catalog/presentation/widgets/cart_flight.dart';
import 'package:dayaa_client/features/orders/presentation/views/cart_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// رأس صفحة المنتج: الصورة كبيرةً في الأعلى، تنطوي مع التمرير إلى شريط 4c — رجوع، وصورةٌ صغيرة،
/// والاسم والكود، والسلة.
///
/// **الانطواء إزاحةٌ وشفافية، ولا شيء غيرهما** (قاعدة الحركة في RULES §7): الصورة تصعد بنصف
/// سرعة التمرير وتبهت، والاسم في الشريط يظهر بالشفافية. لا صورةَ تصغر لتصير المصغّرة؛ المصغّرة
/// عنصرٌ ثابت المقاس يظهر في مكانه.
///
/// منتجٌ بلا صورة لا يُفتح على مساحةٍ فارغة: يبدأ بالشريط وحده.
class ProductHeader extends StatelessWidget {
  const ProductHeader({required this.product, required this.cartKey, super.key});

  final Product product;

  /// على خانة السلة في الشريط — إليها تطير صورة المنتج حين يُضاف ([CartFlight]).
  final GlobalKey cartKey;

  /// ارتفاع الشريط المطويّ، بلا شريط الحالة.
  static double get barHeight => 76.h;

  /// ارتفاع الصورة مفتوحةً، بلا شريط الحالة.
  static double get photoHeight => 300.h;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      toolbarHeight: barHeight,
      expandedHeight: product.images.isEmpty ? null : photoHeight,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: _HeaderSpace(product: product, cartKey: cartKey),
    );
  }
}

class _HeaderSpace extends StatelessWidget {
  const _HeaderSpace({required this.product, required this.cartKey});

  final Product product;
  final GlobalKey cartKey;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();

    final maxExtent = settings?.maxExtent ?? 0;
    final range = maxExtent - (settings?.minExtent ?? 0);
    final shrink = maxExtent - (settings?.currentExtent ?? maxExtent);

    // صفرٌ والصورة مفتوحة، وواحدٌ والشريط وحده. رأسٌ لا ينطوي — منتجٌ بلا صورة — مطويٌّ أصلاً.
    final folded = range <= 0 ? 1.0 : (shrink / range).clamp(0.0, 1.0);

    // الاسم يظهر في آخر خُمسَي الانطواء، حين تكون الصورة قد بهتت فلا يُكتب فوقها.
    final barTitle = ((folded - 0.6) / 0.4).clamp(0.0, 1.0);

    // حافة الورقة المدوّرة تذهب في النصف الأول، قبل أن تبلغ الشريط وتغطي ما فيه.
    final sheetEdge = (1 - folded * 2).clamp(0.0, 1.0);

    // لونٌ واحد فوق الصورة وفوق الشريط: فوق الصورة مربّعٌ يُقرأ عليه السهم، وفوق الشريط يكاد
    // يكون لون الحاوية نفسه كما في 4c. لونٌ لا يتبدّل مع التمرير لا يحتاج أن يتحرّك.
    final backdrop = scheme.surfaceContainer.withValues(alpha: 0.85);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (product.images.isNotEmpty) ...[
          Positioned(
            top: -shrink / 2,
            left: 0,
            right: 0,
            height: maxExtent,
            child: Opacity(
              opacity: 1 - folded,
              child: _Gallery(images: product.images),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            height: 25.h,
            child: Opacity(
              opacity: sheetEdge,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                ),
              ),
            ),
          ),
        ],

        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 1,
          child: Opacity(
            opacity: folded,
            child: ColoredBox(color: scheme.outlineVariant),
          ),
        ),

        Positioned(
          top: MediaQuery.paddingOf(context).top,
          left: 0,
          right: 0,
          height: ProductHeader.barHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                _HeaderButton(
                  icon: AppIcons.back,
                  tooltip: 'رجوع',
                  backdrop: backdrop,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Opacity(
                    key: const ValueKey('product-bar-title'),
                    opacity: barTitle,
                    child: _BarTitle(product: product),
                  ),
                ),
                SizedBox(width: 12.w),
                // خانةٌ بمقاسٍ ثابت وإن كانت السلة فارغة فلا تُرسم: يبقى للصورة الطائرة مكانٌ
                // تهبط فيه، ولا يقفز الاسم حين تظهر السلة أول مرة.
                SizedBox.square(
                  key: cartKey,
                  dimension: 44.w,
                  child: OverflowBox(
                    maxWidth: 56.w,
                    maxHeight: 56.w,
                    child: CartButton(backdrop: backdrop),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// المصغّرة والاسم والكود، كما في شريط 4c.
class _BarTitle extends StatelessWidget {
  const _BarTitle({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14.r),
          child: SizedBox.square(
            dimension: 52.w,
            child: ProductThumbnail(image: product.primaryImageUrl),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleMedium?.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              if (product.code case final code?)
                Text(
                  code,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.backdrop,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color backdrop;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 22.sp),
      style: IconButton.styleFrom(
        backgroundColor: backdrop,
        foregroundColor: context.colorScheme.onSurface,
        fixedSize: Size.square(44.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      ),
    );
  }
}

/// صور المنتج تُقلَّب بالسحب جانباً، ونقاطٌ تحتها حين تكون أكثر من واحدة.
///
/// **النقاط تتبدّل لوناً لا عرضاً** — نقطةٌ تطول وهي نشطة عرضٌ يتحرّك، وقاعدة الحركة تمنعه.
/// والصفحة الظاهرة حالةٌ بصرية بحتة لهذا الويدجت وحده، فهي `setState` لا Cubit.
class _Gallery extends StatefulWidget {
  const _Gallery({required this.images});

  final List<ProductImage> images;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final images = widget.images;

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: (page) => setState(() => _page = page),
          itemBuilder: (context, index) => ProductThumbnail(image: images[index].url),
        ),
        if (images.length > 1)
          Positioned(
            left: 0,
            right: 0,
            // فوق حافة الورقة المدوّرة لا تحتها.
            bottom: 38.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < images.length; index++)
                  Container(
                    width: 8.w,
                    height: 8.w,
                    margin: EdgeInsets.symmetric(horizontal: 3.5.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _page
                          ? scheme.primary
                          : scheme.inverseSurface.withValues(alpha: 0.75),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
