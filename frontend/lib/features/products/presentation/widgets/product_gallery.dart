import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/features/products/models/product.dart';

/// The pictures of a product, as the product screen shows them.
///
/// **Full width and square, not a strip that scrolls sideways.** The gallery this replaces was
/// 240 wide, so on a 430-wide phone the photograph took a little over half the screen and the
/// rest was the edge of the next one. A product screen's first job is the product.
///
/// Square because the photographs are: the placeholder every backfilled product carries is
/// 225×225, and a 16:9 window would crop a bag's top and bottom away to fit a shape nothing in
/// this catalogue is.
class ProductGallery extends StatefulWidget {
  const ProductGallery({required this.images, super.key});

  final List<ProductImage> images;

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  final _controller = PageController();

  /// Which picture is on screen, so the dots can say so.
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordered = galleryOrder(widget.images);

    // Nothing at all rather than an empty box holding a third of the screen open. A product
    // cannot be created without a photo any more, but one from before that rule — or a list
    // that has not loaded — still reaches here.
    if (ordered.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // The width it was given, and the same number for the height. Fixed before the first
        // picture resolves, so the page below does not jump as each one lands.
        final side = constraints.maxWidth;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: side,
              height: side,
              child: PageView.builder(
                controller: _controller,
                itemCount: ordered.length,
                onPageChanged: (index) => setState(() => _current = index),
                itemBuilder: (context, index) => _Photo(
                  image: ordered[index],
                  // Only worth saying when there is something for it to be primary *among*.
                  // «الصورة الرئيسية» over the only photograph distinguishes it from nothing.
                  showBadge: ordered.length > 1 && ordered[index].isPrimary,
                ),
              ),
            ),
            // One dot under one picture says nothing and is a row of pixels to explain.
            if (ordered.length > 1) ...[
              SizedBox(height: 10.h),
              _Dots(
                key: const ValueKey('product-gallery-dots'),
                count: ordered.length,
                current: _current,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// The pictures in the order they should be seen: the primary one first, then the rest exactly
/// as the server sent them.
///
/// **The rest are not re-sorted, deliberately.** `ProductImageResource` already orders by
/// `sort_order` then `id`, so sorting again here would be a second opinion about an order the
/// shop set on purpose — and a second implementation to keep in step with the first.
///
/// **A new list — the caller's is never touched.** The page hands over `product.images`, which
/// is the model's own list, and reordering it in place would reorder the product itself.
List<ProductImage> galleryOrder(List<ProductImage> images) {
  return [
    ...images.where((image) => image.isPrimary),
    ...images.where((image) => !image.isPrimary),
  ];
}

/// One photograph, filling its page.
class _Photo extends StatelessWidget {
  const _Photo({required this.image, this.showBadge = false});

  final ProductImage image;

  /// Whether to mark this one as the product's primary.
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // A tinted panel while it arrives and if it never does: a broken-image glyph is something
    // the user can do nothing about, and a spinner over a catalogue photo is noise.
    Widget panel([IconData? glyph]) => ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: glyph == null
          ? null
          : Center(child: Icon(glyph, size: 24.sp, color: scheme.outline)),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: image.url,
          fit: BoxFit.cover,
          placeholder: (context, url) => panel(),
          errorWidget: (context, url, error) => panel(AppIcons.error),
        ),
        if (showBadge)
          PositionedDirectional(
            top: 10.h,
            start: 10.w,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(999.r),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                child: Text(
                  'الصورة الرئيسية',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Which of the pictures is on screen.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current, super.key});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.symmetric(horizontal: 3.w),
            // The current one is a stadium rather than a bigger circle: it reads as "you are
            // here" at a glance, where two sizes of dot read as two kinds of dot.
            width: index == current ? 18.w : 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3.w),
              color: index == current ? scheme.primary : scheme.outlineVariant,
            ),
          ),
      ],
    );
  }
}

/// One product's picture at thumbnail size — the catalogue's row, the picker's tile.
///
/// **Always exactly [side] square, before the photograph arrives and if it never does.** A
/// catalogue that reflows as each row's picture lands is unreadable while it settles.
class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({required this.image, required this.side, this.radius, super.key});

  /// Null draws the placeholder square — a product whose photos have not been loaded with it.
  final ProductImage? image;

  final double side;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final url = image?.url;

    Widget panel(IconData glyph) => ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: Center(child: Icon(glyph, size: side * 0.4, color: scheme.onSurfaceVariant)),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? 10.r),
      child: SizedBox(
        width: side,
        height: side,
        child: url == null
            ? panel(AppIcons.products)
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) => ColoredBox(color: scheme.surfaceContainerHigh),
                errorWidget: (context, url, error) => panel(AppIcons.error),
              ),
      ),
    );
  }
}
