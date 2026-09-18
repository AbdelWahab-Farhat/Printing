import 'package:cached_network_image/cached_network_image.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/bidi.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/utils/number_input_formatters.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:dayaa_client/features/catalog/models/product.dart';
import 'package:dayaa_client/features/catalog/presentation/viewmodel/product_detail_cubit.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/models/order_draft.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/cart_cubit.dart';
import 'package:dayaa_client/features/orders/presentation/views/cart_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One product: its pictures, its sizes, and what a quantity of it costs.
///
/// **Every price here comes from the server.** Picking a size or changing the quantity re-quotes
/// — nothing on this screen multiplies a unit price by a number. The tier rules live in one
/// place, and a copy of them in this app would be the one that disagrees with the invoice.
class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({required this.productId, super.key});

  final int productId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductDetailCubit>(
      create: (_) => sl<ProductDetailCubit>()..load(productId),
      child: const _ProductDetailView(),
    );
  }
}

class _ProductDetailView extends StatefulWidget {
  const _ProductDetailView();

  @override
  State<_ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<_ProductDetailView> {
  final _quantity = TextEditingController();

  /// Whether the field has been filled from the state yet. The quantity starts at the product's
  /// minimum order quantity, which is not known until the product arrives.
  bool _seeded = false;

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  /// Puts this product, at the chosen size and quantity, into the basket.
  ///
  /// **It adds rather than navigates**, which is the whole of the change: the old button pushed
  /// straight to the order screen with one line, so a customer who wanted two products had to
  /// send two orders. The basket outlives this screen — see [CartCubit], the one singleton
  /// Cubit in this app — so going back to the catalogue and opening a second product keeps what
  /// is already in it.
  void _order(ProductDetailLoaded state) {
    final variantId = state.selectedVariantId;
    if (variantId == null) return;

    // A line whose quantity is not a number is not a line — see
    // [ProductDetailStateX.hasOrderableQuantity] for why this is asked here and not left to the
    // keyboard alone.
    if (!state.hasOrderableQuantity) {
      context.showError('أدخل كمية صحيحة');

      return;
    }

    // The name and the size travel with the ids, so the basket can draw something the customer
    // can actually check — «مقاس رقم ١٢» is a basket nobody can read before sending. See
    // `OrderDraftLine`.
    final variant = state.selectedVariant;

    final refusal = sl<CartCubit>().add(
      OrderDraftLine(
        line: NewOrderLine(
          productId: state.product.id,
          productVariantId: variantId,
          quantity: state.quantity,
        ),
        title: state.product.name,
        imageUrl: state.product.primaryImageUrl,
        subtitle: [
          if (variant != null) variant.label,
          'الكمية ${state.quantity.asQuantity}',
        ].join(' · '),
        orderGroup: state.product.orderGroup,
      ),
    );

    // **The refusal is the server's rule read forward.** `CreateOrder` throws
    // `OutsourcedLineCannotShareAnOrder` on an order whose lines disagree about whose bench
    // they are made on; saying it here means the customer hears it on the tap that caused it
    // rather than at the end of a filled basket.
    //
    // And the message says what to *do*, never what the product is: this app holds an opaque
    // token and could not write «هذا المنتج وسيط» truthfully if it tried.
    if (refusal == CartRefusal.differentGroup) {
      context.showInfo('هذا المنتج يُطلب في طلبية مستقلة — أرسل سلتك أولاً أو أفرغها');

      return;
    }

    context.showInfo(
      refusal == CartRefusal.alreadyIn ? 'حدّثنا الكمية في سلتك' : 'أُضيف إلى سلتك',
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductDetailCubit, ProductDetailState>(
      listener: (context, state) {
        if (state case ProductDetailLoaded(:final quantity) when !_seeded) {
          // **`asPlainNumber`, never `asQuantity`.** The API declares quantities at three places
          // and «100.000» in a field somebody is about to edit is three zeros nobody typed —
          // but the grouped form would put a comma in a number the field refuses and the server
          // would reject.
          _quantity.text = quantity.asPlainNumber;
          _seeded = true;
        }
      },
      builder: (context, state) {
        return switch (state) {
          ProductDetailLoading() => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),

          ProductDetailFailure(:final failure) => Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Text(failure.message, textAlign: TextAlign.center),
              ),
            ),
          ),

          final ProductDetailLoaded loaded => _Loaded(
            state: loaded,
            quantity: _quantity,
            onOrder: () => _order(loaded),
          ),
        };
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.state,
    required this.quantity,
    required this.onOrder,
  });

  final ProductDetailLoaded state;
  final TextEditingController quantity;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductDetailCubit>();
    final product = state.product;
    final scheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: const [CartButton()],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        children: [
          if (product.images.isNotEmpty) ...[
            SizedBox(height: 220.h, child: _Gallery(images: product.images)),
            SizedBox(height: 16.h),
          ],

          Text(
            product.name,
            style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (product.code case final code?) ...[
            SizedBox(height: 4.h),
            Text(
              code,
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],

          if (product.description case final description?) ...[
            SizedBox(height: 12.h),
            Text(description, style: context.textTheme.bodyMedium),
          ],

          if (product.features.isNotEmpty) ...[
            SizedBox(height: 12.h),
            for (final feature in product.features)
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(AppIcons.settled, size: 16.sp, color: scheme.primary),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(feature, style: context.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
          ],

          SizedBox(height: 20.h),

          if (product.variants.isNotEmpty) ...[
            Text(
              'المقاس',
              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final variant in product.variants)
                  ChoiceChip(
                    label: Text(variant.label.bidiSafe),
                    selected: variant.id == state.selectedVariantId,
                    onSelected: (_) => cubit.selectVariant(variant.id),
                  ),
              ],
            ),
            SizedBox(height: 20.h),
          ],

          Text(
            'الكمية${product.pricingUnitLabel == null ? '' : ' (${product.pricingUnitLabel})'}',
            style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8.h),
          AppTextField(
            controller: quantity,
            label: 'الكمية',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textDirection: TextDirection.ltr,
            inputFormatters: [
              // A quantity is a number. Letters are a typo, and refusing them at the keyboard
              // is kinder than a validator complaining after the fact.
              //
              // **Two formatters where there was one filter**, because the filter was wrong in
              // both directions at once: it let `1.2.3` through a character at a time, and it
              // swallowed ١٢٣ from an Arabic keyboard without saying why. See
              // `number_input_formatters.dart` for each.
              const WesternDigitsInputFormatter(),
              QuantityInputFormatter(wholeOnly: product.isPricedByThePiece),
            ],
            onChanged: cubit.setQuantity,
          ),

          if (product.minOrderQuantity case final minimum?) ...[
            SizedBox(height: 6.h),
            Text(
              'أقل كمية: ${minimum.asQuantity}',
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],

          SizedBox(height: 20.h),
          _PriceBlock(state: state),
        ],
      ),

      // **The total travels with the button, pinned to the floor.** The design draws them as
      // one bar, and it is the right call for a screen whose whole job is «كم يكلّف؟»: the
      // number has to stay in view while the size and the quantity are being changed, and a
      // total halfway up a scrolling page is a number you have to go looking for after every
      // tap. The breakdown — unit price, the next break, a failed quote — stays up in
      // [_PriceBlock] where there is room to read it.
      bottomNavigationBar: _OrderBar(state: state, onOrder: onOrder),
    );
  }
}

/// «الإجمالي ٤٬٢٥٠ د.ل» and «أضف إلى الطلبية», as one bar.
class _OrderBar extends StatelessWidget {
  const _OrderBar({required this.state, required this.onOrder});

  final ProductDetailLoaded state;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final quote = state.quote;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
          child: Row(
            children: [
              // A product priced on request has no total to show, so the button takes the whole
              // bar rather than sitting beside an em dash.
              if (state.product.hasListedPrices) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'الإجمالي',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    // **Dimmed, not blanked, while a fresh quote is in flight.** A total that
                    // disappears on every keystroke in the quantity field reads as a price
                    // that broke.
                    Opacity(
                      opacity: state.isQuoting ? 0.5 : 1,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            quote?.total.asMoney ?? '—',
                            style: context.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: scheme.primary,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'د.ل',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 14.w),
              ],

              Expanded(
                child: AppButton(
                  label: 'أضف إلى الطلبية',
                  // A product with no sizes cannot be ordered — the catalogue should not
                  // contain one, and offering a button that would fail is worse than not
                  // offering it.
                  onPressed: state.selectedVariantId == null ? null : onOrder,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The total, and what the server said about it.
class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.state});

  final ProductDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // **A decided answer.** The server says whether this product has listed prices; this app
    // never learns what the pricing modes behind that are.
    if (!state.product.hasListedPrices) {
      return AppCard.sunken(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Icon(AppIcons.about, size: 20.sp, color: scheme.primary),
            SizedBox(width: 11.w),
            Expanded(
              child: Text(
                'هذا المنتج يُسعَّر حسب الطلب — أرسل طلبيتك ونعاود الاتصال بك بالسعر.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final quote = state.quote;

    // **The total is not repeated here.** It lives in the bar at the foot of the screen, where
    // it stays in view while the size and the quantity change; this block is the breakdown
    // behind it.
    return AppCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (quote != null)
            Row(
              children: [
                Text(
                  'سعر الوحدة',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '${quote.unitPrice.asMoney} د.ل',
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          else if (state.isQuoting)
            Row(
              children: [
                SizedBox(
                  height: 16.h,
                  width: 16.h,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10.w),
                Text(
                  'نحسب السعر…',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

          // The saving still on the table. Sent by the server, because which break applies is
          // its arithmetic and not this screen's.
          if (quote?.nextTier case final next?) ...[
            SizedBox(height: 10.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.tag, size: 16.sp, color: scheme.tertiary),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    (next.quantityToReach == null
                            ? 'اطلب ${next.minQuantity.asQuantity} وينزل سعر الوحدة إلى '
                                  '${next.unitPrice.asMoney} د.ل'
                            : 'اطلب ${next.quantityToReach!.asQuantity} أكثر وينزل سعر الوحدة '
                                  'إلى ${next.unitPrice.asMoney} د.ل')
                        .bidiSafe,
                    style: context.textTheme.bodySmall?.copyWith(color: scheme.tertiary),
                  ),
                ),
              ],
            ),
          ],

          // A quote that failed leaves the product on screen and says only that the price is
          // missing — it is not a failure of the whole page.
          if (state.quoteFailure case final failure?) ...[
            SizedBox(height: 10.h),
            Text(
              failure.message,
              style: context.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.images});

  final List<ProductImage> images;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      itemCount: images.length,
      itemBuilder: (context, index) => ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: CachedNetworkImage(
          imageUrl: images[index].url,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (context, url) => const SizedBox.shrink(),
          errorWidget: (context, url, error) => Center(
            child: Icon(AppIcons.products, size: 32.sp),
          ),
        ),
      ),
    );
  }
}
