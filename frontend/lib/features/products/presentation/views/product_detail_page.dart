import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_speed_dial.dart';
import 'package:dayaa/core/widgets/permission_gate.dart';
import 'package:dayaa/features/audit/models/audit_subject.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/presentation/viewmodel/product_detail_cubit.dart';
import 'package:dayaa/features/products/presentation/widgets/product_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Everything about one bag.
///
/// Reached by tapping a row in the catalogue — the slot was reserved for it: `ProductCard.onTap`
/// has existed and been passed `null` since the list was written.
///
/// **The card answers one question; this screen answers the rest.** The card exists to settle
/// *"how much for 50×60 at five hundred?"* in one glance, so it is a dense grid and drops
/// everything that is not the number. That is the right trade on a list of ten and the wrong one
/// the moment somebody wants the whole picture — so the things the card deliberately leaves out
/// are precisely what is here: the selling points, the description, the measured dimensions of
/// each size, which sizes are stopped, and what the photographs actually are.
///
/// **The price ladder is laid out per size, not as the card's grid.** The grid packs four
/// columns into a phone's width by making every cell a bare number under a shared heading — it
/// has to. With a page to scroll there is room to say it in full: «١٠٠ فأكثر ← 0.850 د.ل
/// للقطعة», a sentence that cannot be misread, next to the size's real dimensions.
///
/// **It also says which pile each size draws from**, which no other screen can. A size with no
/// «صنف مخزني» behind it is refused by every stock path by name, and until an order fails at
/// «جاهزة» nothing else in the app would ever mention it — so it is stated here, beside the size
/// it is about, rather than left to be discovered.
///
/// Read-only now. One action opens the form; the other two are a history and the photographs.
/// The «وحدة المخزون» action that used to sit here went with its endpoint: a pile is not one
/// product's, so what it is counted in belongs to the shelf, and moving it is done from the
/// stock-item screen — where it empties the shelf through a recorded adjustment. Stopping a
/// product is still an endpoint the app does not call.
class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({required this.productId, super.key});

  final int productId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductDetailCubit>(
      create: (_) => sl<ProductDetailCubit>(param1: productId)..load(),
      child: const _ProductDetailView(),
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  const _ProductDetailView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductDetailCubit>();

    return Scaffold(
      floatingActionButtonLocation: AppSpeedDial.location,
      appBar: AppBar(
        title: BlocBuilder<ProductDetailCubit, ProductDetailState>(
          // The name once it is known, so the bar stops saying something generic the moment it
          // can say something useful.
          builder: (context, state) => Text(state.product?.name ?? 'تفاصيل المنتج'),
        ),
      ),
      floatingActionButton: BlocBuilder<ProductDetailCubit, ProductDetailState>(
        builder: (context, state) {
          final product = state.product;
          if (product == null) return const SizedBox.shrink();

          return _Actions(
            product: product,
            // Re-read rather than trusting what came back: prices are the catalogue's own
            // arithmetic and this screen is the one that has to be right about them.
            onEdit: (context) async {
              final saved = await context.push<bool>(
                Routes.editProduct(product.id),
                // Handed over so the form opens filled without a second request for a product
                // this screen already has.
                extra: product,
              );

              if (saved ?? false) await cubit.load();
            },
          );
        },
      ),
      body: BlocBuilder<ProductDetailCubit, ProductDetailState>(
        builder: (context, state) => switch (state) {
          ProductDetailLoading() => const Center(child: CircularProgressIndicator()),
          ProductDetailFailure(:final failure) => _FailureView(
            message: failure.message,
            onRetry: cubit.load,
          ),
          ProductDetailLoaded(:final product) => RefreshIndicator(
            onRefresh: cubit.load,
            child: _Body(product: product),
          ),
        },
      ),
    );
  }
}

/// What this screen can do, as data.
///
/// [AppSpeedDial] collapses to a plain button when only one action survives the permission
/// filter, so a reader who may look at the catalogue and not change it sees exactly one button
/// rather than a dial with a single arm.
class _Actions extends StatelessWidget {
  const _Actions({required this.product, required this.onEdit});

  final Product product;
  final Future<void> Function(BuildContext context) onEdit;

  @override
  Widget build(BuildContext context) {
    return AppSpeedDial(
      actions: [
        AppAction(
          label: 'تعديل المنتج',
          icon: AppIcons.edit,
          tone: AppActionTone.primary,
          // The same permission the route guards and the server enforces. Hiding it here is the
          // courtesy; the other one is the boundary.
          permission: AppPermission.manageProducts,
          onTap: onEdit,
        ),
        // «وحدة المخزون» used to be the second arm, behind `inventory.manage`. It is gone with
        // its endpoint: the unit belongs to the pile, not to one of the products drawing on it,
        // and it is changed on the stock-item screen — where changing it empties every warehouse
        // holding the item through a recorded adjustment rather than relabelling the figures.
        AppAction(
          label: 'سجل التعديلات',
          icon: AppIcons.history,
          // `logs.view`, not `products.view`, and that is the server's own line: a history shows
          // what *everyone* has done, including prices the reader may have no other way to see.
          // Reading the catalogue does not make somebody an auditor.
          permission: AppPermission.viewActivityLogs,
          onTap: (context) => context.push(
            Routes.activityLog(AuditSubject.product, product.id),
            extra: product.name,
          ),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return ListView(
      // `always`, so pull-to-refresh works on a product short enough not to scroll.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
      children: [
        if (product.images.isNotEmpty) ...[
          ProductGallery(images: product.images),
          SizedBox(height: 12.h),
        ],

        // **Offered whether or not there are photographs, and that is the point.** A product
        // made before a photo was required carries none, so the gallery above draws nothing —
        // and hiding this with it would leave exactly those products with no way to get one.
        //
        // Under the gallery rather than in the speed dial: the photographs are what it is about,
        // and a door reads better beside the thing it leads to than in a list of verbs.
        PermissionGate(
          permission: AppPermission.manageProducts,
          child: Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: AppButton.tonal(
              label: product.images.isEmpty ? 'إضافة صورة' : 'إدارة الصور',
              icon: AppIcons.photos,
              // The name travels so the images screen can say whose they are without asking
              // for a product this screen already holds.
              onPressed: () => context.push(
                Routes.productImages(product.id),
                extra: product.name,
              ),
            ),
          ),
        ),

        _Identity(product: product),
        SizedBox(height: 14.h),

        if (!product.isActive) ...[
          const _StoppedBand(),
          SizedBox(height: 14.h),
        ],

        if (product.hasDescription) ...[
          _Section(title: 'الوصف', child: _Description(text: product.description!)),
          SizedBox(height: 14.h),
        ],

        _Section(title: 'التسعير', child: _Pricing(product: product)),
        SizedBox(height: 14.h),

        _Section(title: 'المقاسات والأسعار', child: _Variants(product: product)),
        SizedBox(height: 14.h),

        // The card drops these on purpose — a selling point is what a salesperson says *after*
        // the number, so on a row whose job is the number it was a line to skip. Here there is
        // nothing to compete with, which is why they were kept on the model.
        if (product.hasFeatures) ...[
          _Section(title: 'المزايا', child: _Features(features: product.features)),
          SizedBox(height: 14.h),
        ],

        _Section(title: 'بيانات المنتج', child: _Identifiers(product: product)),
        SizedBox(height: 14.h),

        _Meta(product: product),
      ],
    );
  }
}

/// The code, the name, and what kind of thing this is.
class _Identity extends StatelessWidget {
  const _Identity({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // The one thing on this screen read down a phone line — «عندك P7؟» — so it leads,
            // in the accent colour, exactly as it does on the card.
            Text(
              product.code,
              textDirection: TextDirection.ltr,
              style: context.textTheme.titleMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                product.name,
                style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          // Both halves are the server's own Arabic, so the app keeps no translation table. The
          // heading is dropped rather than replaced by a dash when a product has none.
          [
            ?product.productCategory?.name,
            'بال${product.pricingUnitLabel}',
          ].join(' · '),
          style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Only shown for a stopped product.
///
/// The active case gets no band at all: a green «نشِط» on every product in the catalogue is a
/// row the eye learns to skip, and then the one time it says something else it is skipped too.
class _StoppedBand extends StatelessWidget {
  const _StoppedBand();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(AppIcons.deactivate, size: 20.sp, color: scheme.onErrorContainer),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'هذا المنتج موقوف — لا يُعرض للبيع، وأسعاره وطلبياته السابقة محفوظة.',
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textTheme.bodyMedium?.copyWith(height: 1.6),
    );
  }
}

/// How this product is priced, before any individual number.
///
/// The floor price and the minimum order are the two facts a quote starts from, so they are
/// stated once here rather than left to be inferred from the ladder below.
class _Pricing extends StatelessWidget {
  const _Pricing({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final startingPrice = product.startingPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (startingPrice != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'يبدأ من',
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              SizedBox(width: 8.w),
              Text(
                startingPrice.grouped,
                textDirection: TextDirection.ltr,
                style: context.textTheme.headlineSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                'د.ل / ${product.pricingUnitLabel}',
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          )
        else
          Text(
            // Never a number this app derived from an empty ladder.
            'السعر حسب الطلب',
            style: context.textTheme.titleSmall?.copyWith(
              color: scheme.tertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
        const _Rule(height: 20),
        _FactRow(
          label: 'طريقة التسعير',
          value: product.pricingModeLabel,
        ),
        SizedBox(height: 8.h),
        _FactRow(
          label: 'أقل كمية للطلب',
          value: '${product.minOrderQuantityLabel} ${product.pricingUnitLabel}',
        ),
      ],
    );
  }
}

/// Every size, and the whole price ladder for each.
class _Variants extends StatelessWidget {
  const _Variants({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final variants = product.variants;

    if (variants.isEmpty) {
      return Text(
        'لا توجد مقاسات مسجّلة لهذا المنتج',
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < variants.length; index++) ...[
          // The one rule on this screen that has real work to do: a size is a heading and three
          // or four price rows, and without a visible line between them the card reads as one
          // long list of numbers whose headings happen to be bold.
          if (index > 0) const _Rule(height: 26),
          _VariantBlock(variant: variants[index], product: product),
        ],
      ],
    );
  }
}

class _VariantBlock extends StatelessWidget {
  const _VariantBlock({required this.variant, required this.product});

  final ProductVariant variant;
  final Product product;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tiers = variant.tiersByQuantity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              variant.label,
              // A size is a Latin run — `25*35` inherits RTL and renders as a different size.
              textDirection: TextDirection.ltr,
              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (variant.dimensionsLabel != null) ...[
              SizedBox(width: 8.w),
              Text(
                // The measured size, which the card has no room for and shows only to a screen
                // reader. It is the answer to "is 25*35 the one that fits an A4 sheet?".
                variant.dimensionsLabel!,
                textDirection: TextDirection.ltr,
                style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            const Spacer(),
            // One word, no container. A stopped size is a decision, not a fault — an
            // error-coloured badge would make the whole block read as broken.
            if (!variant.isActive)
              Text(
                'موقوف',
                style: context.textTheme.labelMedium?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        SizedBox(height: 6.h),
        _Shelf(variant: variant),
        SizedBox(height: 8.h),
        if (tiers.isEmpty)
          Text(
            'لا يوجد سعر مسجّل لهذا المقاس',
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          )
        else
          for (final tier in tiers) _TierRow(tier: tier, product: product),
      ],
    );
  }
}

/// Which pile this size draws from — and, when it draws from none, that it does not.
///
/// **The unlinked case is the one worth the row.** A size with no «صنف مخزني» takes orders
/// exactly like any other until the order reaches «جاهزة», at which point the server refuses it
/// with «غير مرتبط بصنف مخزني — اربطه بصنف قبل حركة المخزون». Nothing before that moment mentions
/// it, so this line is the only warning in the app that arrives while there is still time.
///
/// The linked case prints the shelf's `display_name` and its own unit. The unit is here rather
/// than beside the price because it is a different fact: «قطعة» here is what the *warehouse*
/// counts, and it can honestly differ from what the invoice charges by — a bag bought in by the
/// kilo and sold by the piece.
class _Shelf extends StatelessWidget {
  const _Shelf({required this.variant});

  final ProductVariant variant;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final shelf = variant.stockItem;

    if (shelf == null) {
      return Row(
        children: [
          Icon(AppIcons.error, size: 14.sp, color: scheme.error),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              'غير مرتبط بمادة — لا يمكن صرفه من المخزن',
              style: context.textTheme.labelSmall?.copyWith(color: scheme.error),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(AppIcons.warehouse, size: 14.sp, color: scheme.outline),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            // The server's own composition and the server's own Arabic for the unit — the
            // shortfall message that refuses an order quotes this exact `display_name`, so a
            // second spelling of it here would be a second thing to reconcile.
            '${shelf.displayName} · ${shelf.unitLabel}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          // The `S7` a storekeeper reads down a phone line, and what stands where a product
          // thumbnail would be wrong: two products share this pile, so picturing either is
          // picking one arbitrarily.
          shelf.code,
          textDirection: TextDirection.ltr,
          style: context.textTheme.labelSmall?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// «١٠٠ فأكثر ← 0.850 د.ل للقطعة» — one threshold, said in full.
class _TierRow extends StatelessWidget {
  const _TierRow({required this.tier, required this.product});

  final ProductPriceTier tier;
  final Product product;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      // Four unbreakable numerals in a row have nowhere to go at 2× text scale; everything
      // outside this row scales freely.
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Row(
          children: [
            Icon(AppIcons.forward, size: 14.sp, color: scheme.outline),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                '${tier.minQuantityLabel} ${product.pricingUnitLabel} فأكثر',
                style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            Text(
              tier.unitPrice.grouped,
              textDirection: TextDirection.ltr,
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 4.w),
            Text(
              'د.ل',
              style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _Features extends StatelessWidget {
  const _Features({required this.features});

  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final feature in features)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 3.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 5.h),
                  child: Container(
                    height: 6.w,
                    width: 6.w,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(feature, style: context.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The machine-readable names for this product, and the two that get typed elsewhere.
class _Identifiers extends StatelessWidget {
  const _Identifiers({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CopyRow(
          icon: AppIcons.tag,
          label: 'رمز المنتج',
          value: product.code,
          copiedMessage: 'تم نسخ رمز المنتج',
        ),
        const _Rule(height: 18),
        _CopyRow(
          icon: AppIcons.tag,
          label: 'المعرّف (slug)',
          value: product.slug,
          copiedMessage: 'تم نسخ المعرّف',
        ),
        const _Rule(height: 18),
        _FactRow(label: 'التصنيف', value: product.productCategory?.name ?? 'بلا تصنيف'),
        SizedBox(height: 8.h),
        _FactRow(label: 'وحدة التسعير', value: product.pricingUnitLabel),
        SizedBox(height: 8.h),
        _FactRow(
          // «المادة» — what the bag is cut from, and the reason its sizes have shelves at all.
          // Stated even when there is none: «بلا مادة» is the answer to why every size below
          // says «بلا صنف مخزني», and a row that simply vanished would leave that unexplained.
          label: 'تصنيف المادة',
          value: product.stockItemGroup?.name ?? (product.hasMaterial ? 'تصنيف محدّد' : 'بلا تصنيف'),
        ),
        SizedBox(height: 8.h),
        _FactRow(
          label: 'المقاسات',
          value: product.variants.isEmpty
              ? 'لا توجد'
              : [
                  '${product.variants.length} مقاس',
                  '${product.activeVariants.length} متاح',
                  // Dropped entirely when there are none, which is the ordinary case for a
                  // product with a material. Present, it is the count that will refuse an order
                  // at «جاهزة», said here where somebody is already reading the product.
                  if (product.unlinkedVariants.isNotEmpty)
                    '${product.unlinkedVariants.length} بلا مادة',
                ].join(' · '),
        ),
        SizedBox(height: 8.h),
        _FactRow(label: 'الصور', value: '${product.images.length}'),
        SizedBox(height: 8.h),
        _FactRow(label: 'ترتيب العرض', value: '${product.sortOrder}'),
      ],
    );
  }
}

/// A label on one side, a value on the other. The plain row this screen repeats.
class _FactRow extends StatelessWidget {
  const _FactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// A label, a value, and a way to get the value out of the app.
///
/// Copy rather than "open": there is no `url_launcher` in this project, and a row that looks
/// tappable and does nothing is worse than one that plainly copies.
class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.copiedMessage,
  });

  final IconData icon;
  final String label;
  final String value;
  final String copiedMessage;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return InkWell(
      onTap: () {
        unawaited(Clipboard.setData(ClipboardData(text: value)));
        context.showSuccess(copiedMessage);
      },
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: scheme.onSurfaceVariant),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    // A code and a slug are Latin runs; they read left-to-right even here.
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.copy, size: 16.sp, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final created = product.createdAt;
    final updated = product.updatedAt;

    final lines = [
      if (created != null) 'أُضيف في ${_date(created)}',
      // Only when it says something the line above does not: a product saved once has both
      // stamps within a second of each other, and printing them twice is noise.
      if (updated != null && created != null && updated.difference(created).inMinutes.abs() > 1)
        'آخر تعديل ${_date(updated)}',
    ];

    if (lines.isEmpty) return const SizedBox.shrink();

    return Text(
      lines.join(' · '),
      textAlign: TextAlign.center,
      style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurfaceVariant),
    );
  }

  String _date(DateTime value) => value.dayLabel;
}

/// The line between two blocks inside a card.
///
/// The stock `Divider` draws `outlineVariant` at one logical pixel, which on a phone against
/// this card's white is a rumour of a line — legible in a design tool and not on a desk in a
/// print shop. `outline` is the next step up the same ramp: still furniture, but a line somebody
/// can actually see doing its job.
class _Rule extends StatelessWidget {
  const _Rule({required this.height});

  /// The space the rule occupies, line included — design pixels, scaled here so callers read as
  /// the spacing they are asking for.
  final double height;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height.h,
      thickness: 1,
      color: context.colorScheme.outline.withValues(alpha: 0.5),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.primary,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: 48.sp, color: context.colorScheme.error),
            SizedBox(height: 16.h),
            Text(
              // The server's own Arabic: it usually says what to do about it.
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 20.h),
            FilledButton.icon(
              onPressed: () => unawaited(onRetry()),
              icon: Icon(AppIcons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
