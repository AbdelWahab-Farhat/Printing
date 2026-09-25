import 'dart:math' as math;

import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/features/catalog/models/product.dart';
import 'package:dayaa_client/features/catalog/presentation/viewmodel/product_detail_cubit.dart';
import 'package:dayaa_client/features/catalog/presentation/widgets/cart_flight.dart';
import 'package:dayaa_client/features/catalog/presentation/widgets/price_tiers.dart';
import 'package:dayaa_client/features/catalog/presentation/widgets/product_header.dart';
import 'package:dayaa_client/features/catalog/presentation/widgets/quantity_picker.dart';
import 'package:dayaa_client/features/catalog/presentation/widgets/quantity_sheet.dart';
import 'package:dayaa_client/features/catalog/presentation/widgets/size_picker.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/models/order_draft.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/cart_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// منتجٌ واحد: صورته، ومقاساته، وكم تكلّف الكمية منه — الاتجاه «أ» من لوحة صفحة المنتج.
///
/// **كل سعرٍ هنا من الخادم.** اختيار مقاسٍ أو تغيير الكمية يعيد السؤال؛ لا شيء في هذه الشاشة
/// يضرب سعر وحدةٍ في عدد. قواعد الكسور في مكانٍ واحد، ونسخةٌ منها هنا هي التي ستخالف الفاتورة.
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
  /// من أين تطير صورة المنتج وإلى أين — الزر والسلة ([CartFlight]).
  final _buttonKey = GlobalKey();
  final _cartKey = GlobalKey();

  /// لمس الرقم فوق السلايدر: ورقةٌ تُكتب فيها كميةٌ بعينها، وما يُكتب يُسعَّر كأي كمية.
  Future<void> _typeQuantity(ProductDetailLoaded state) async {
    final cubit = context.read<ProductDetailCubit>();

    final typed = await showQuantitySheet(
      context,
      // **`asPlainNumber` لا `asQuantity`:** «2,000» ليس رقماً يقبله الحقل ولا الخادم.
      initial: state.quantity.asPlainNumber,
      unitLabel: state.product.pricingUnitLabel,
      wholeOnly: state.product.isPricedByThePiece,
    );

    if (typed == null || !mounted) return;

    cubit.setQuantity(typed);
  }

  /// يضع هذا المنتج، بالمقاس والكمية المختارين، في السلة.
  ///
  /// **يضيف ولا ينتقل.** السلة تعيش بعد هذه الشاشة — [CartCubit] هو الـ Cubit الوحيد المفرد في
  /// التطبيق — فالعودة إلى الكتالوج وفتح منتجٍ ثانٍ تُبقي ما فيها.
  void _order(ProductDetailLoaded state) {
    final variantId = state.selectedVariantId;
    if (variantId == null) return;

    // سطرٌ كميته ليست رقماً ليس سطراً — انظر [ProductDetailStateX.hasOrderableQuantity].
    if (!state.hasOrderableQuantity) {
      context.showError('أدخل كمية صحيحة');

      return;
    }

    // الاسم والمقاس يسافران مع المعرّفات كي ترسم السلة ما يستطيع العميل مراجعته — «مقاس رقم
    // ١٢» سلةٌ لا يقرؤها أحد قبل الإرسال. انظر `OrderDraftLine`.
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
          // الكمية بوحدتها — «١٠٠ قطعة» أو «١٢٫٥ كجم» — فيعرف العميل في السلة بأيّهما تُحسب.
          switch (state.product.pricingUnitLabel) {
            final unit? => '${state.quantity.asQuantity} $unit',
            null => 'الكمية ${state.quantity.asQuantity}',
          },
        ].join(' · '),
        orderGroup: state.product.orderGroup,
      ),
    );

    // **الرفض قاعدة الخادم مقروءةً مسبقاً.** `CreateOrder` يرفض طلبيةً تختلف أسطرها على مكان
    // صنعها؛ قولها هنا يُسمعها العميل عند اللمسة التي سبّبتها، لا في آخر سلةٍ ممتلئة. والرسالة
    // تقول ما يُفعل لا ما المنتج: التطبيق يحمل رمزاً مبهماً ولا يعرف «هذا المنتج وسيط».
    if (refusal == CartRefusal.differentGroup) {
      context.showInfo('هذا المنتج يُطلب في طلبية مستقلة — أرسل سلتك أولاً أو أفرغها');

      return;
    }

    // **الصورة تطير إلى السلة، وهي التأكيد.** ومع تقليل الحركة لا تطير، فيُقال بالكلمات.
    // «حدّثنا الكمية» تُقال دائماً: خبرٌ آخر غير «أُضيف»، ولا ترويه الصورة.
    final moving = !MediaQuery.disableAnimationsOf(context);
    if (moving) {
      CartFlight.launch(
        context,
        from: _buttonKey,
        to: _cartKey,
        image: state.product.primaryImageUrl,
      );
    }

    if (refusal == CartRefusal.alreadyIn) {
      context.showInfo('حدّثنا الكمية في سلتك');
    } else if (!moving) {
      context.showInfo('أُضيف إلى سلتك');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductDetailCubit, ProductDetailState>(
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
            onEditQuantity: () => _typeQuantity(loaded),
            buttonKey: _buttonKey,
            cartKey: _cartKey,
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
    required this.onEditQuantity,
    required this.buttonKey,
    required this.cartKey,
    required this.onOrder,
  });

  final ProductDetailLoaded state;
  final VoidCallback onEditQuantity;
  final GlobalKey buttonKey;
  final GlobalKey cartKey;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductDetailCubit>();
    final product = state.product;
    final tiers = state.selectedVariant?.tiersInOrder ?? const <PriceTier>[];

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) {
          final folded = MediaQuery.paddingOf(context).top + ProductHeader.barHeight;

          return CustomScrollView(
            slivers: [
              ProductHeader(product: product, cartKey: cartKey),

              // الاسم في شريحةٍ وحده كي يمرّ تحت الشريط حين تنطوي الصورة: الشريط يحمل الاسم
              // حينها، ونسختان منه واحدةٌ فوق الأخرى تكرار.
              SliverPadding(
                // حافة الورقة المدوّرة في أسفل الصورة هي أعلى هذه الصفحة؛ بلا صورةٍ لا حافة.
                padding: EdgeInsets.fromLTRB(16.w, product.images.isEmpty ? 18.h : 0, 16.w, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Title(product: product),
                      if (product.description case final description?
                          when description.trim().isNotEmpty) ...[
                        SizedBox(height: 12.h),
                        Text(description, style: context.textTheme.bodyMedium),
                      ],
                      if (product.features.isNotEmpty) ...[
                        SizedBox(height: 12.h),
                        for (final feature in product.features) _Feature(text: feature),
                      ],
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                // **ما تحت الاسم يملأ الشاشة تحت الشريط على الأقل**، فتنطوي الصورة كلها ويمرّ
                // الاسم تحت الشريط مهما قصرت الصفحة. صفحةٌ قصيرة بلا هذا تقف قبل أن ينطوي الرأس،
                // فيبقى نصف صورةٍ ولا يظهر الاسم في الشريط أبداً.
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: math.max(0, box.maxHeight - folded)),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // مقاسٌ واحد ليس اختياراً: يُختار وحده ولا يُرسم له صف.
                        if (product.variants.length > 1) ...[
                          SizedBox(height: 22.h),
                          SizePicker(
                            variants: product.variants,
                            selectedId: state.selectedVariantId,
                            onSelected: cubit.selectVariant,
                          ),
                        ],

                        SizedBox(height: 24.h),
                        QuantityPicker(
                          quantity: state.quantity,
                          unitLabel: product.pricingUnitLabel,
                          value: state.quantityOnSlider,
                          floor: product.quantityFloor,
                          ceiling: product.quantityCeiling,
                          onEdit: onEditQuantity,
                          onSlide: cubit.slide,
                          onSlideEnd: (_) => cubit.refreshQuote(),
                          onIncrease: cubit.increase,
                          onDecrease: state.canDecrease ? cubit.decrease : null,
                        ),

                        // **لا تفصيل حساب تحت هذا.** الإجمالي في الزر، وسعر الوحدة على بطاقات الكسور —
                        // أو على بطاقةٍ واحدة لمنتجٍ بسعرٍ واحد.
                        if (product.hasListedPrices) ...[
                          if (tiers.length > 1) ...[
                            SizedBox(height: 12.h),
                            PriceTiers(
                              tiers: tiers,
                              floor: product.quantityFloor,
                              quote: state.quote,
                              isStale: state.isQuoting,
                              onChosen: cubit.chooseTier,
                            ),
                          ] else if (tiers.length == 1) ...[
                            SizedBox(height: 18.h),
                            SinglePrice(
                              unitLabel: product.pricingUnitLabel,
                              unitPrice: tiers.single.unitPrice,
                            ),
                          ],
                          // سعرٌ لم يصل لا يُسقط الصفحة: المنتج مقروء، والسعر وحده الناقص.
                          if (state.quoteFailure case final failure?) ...[
                            SizedBox(height: 10.h),
                            Text(
                              failure.message,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colorScheme.error,
                              ),
                            ),
                          ],
                        ] else ...[
                          SizedBox(height: 18.h),
                          const _PricedOnRequest(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _OrderBar(
        buttonKey: buttonKey,
        label: _orderLabel(state),
        onOrder: state.selectedVariantId == null ? null : onOrder,
      ),
    );
  }
}

/// «أضف إلى السلة · ٨٨٠ د.ل» — الإجمالي من جواب الخادم، في الزر نفسه بدل بطاقة حساب.
///
/// **بلا رقمٍ ما دام الجديد في الطريق** — أثناء السحب وقبل وصول الجواب — كي لا يبقى على الزر
/// إجماليٌّ لكميةٍ أخرى. ولا رقم لمنتجٍ يُسعَّر حسب الطلب، ولا لسعرٍ رفضه الخادم.
String _orderLabel(ProductDetailLoaded state) {
  const add = 'أضف إلى السلة';
  final quote = state.quote;

  if (!state.product.hasListedPrices || quote == null || state.isQuoting) return add;

  return '$add · ${quote.total.asMoney} د.ل';
}

/// الاسم وبجانبه كيف يُباع، وتحته الكود.
class _Title extends StatelessWidget {
  const _Title({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final code = product.code;
    final unit = product.pricingUnitLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                key: const ValueKey('product-title'),
                style: context.textTheme.titleLarge?.copyWith(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ),
            if (unit != null) ...[
              SizedBox(width: 12.w),
              _Tag(
                icon: product.isPricedByThePiece ? AppIcons.soldByPiece : AppIcons.soldByWeight,
                label: 'بال$unit',
              ),
            ],
          ],
        ),
        if (code != null) ...[
          SizedBox(height: 8.h),
          _Tag(label: code),
        ],
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final icon = this.icon;

    return Container(
      height: 28.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15.sp, color: scheme.secondary),
            SizedBox(width: 6.w),
          ],
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: scheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.settled, size: 16.sp, color: context.colorScheme.primary),
          SizedBox(width: 6.w),
          Expanded(child: Text(text, style: context.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

/// منتجٌ يُسعَّر حسب الطلب: لا كسور ولا إجمالي، بل ما سيحدث بعد الإرسال.
class _PricedOnRequest extends StatelessWidget {
  const _PricedOnRequest();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

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
}

/// «أضف إلى السلة» بعرض الشاشة، مثبّتاً في أسفلها، والإجمالي فيه.
class _OrderBar extends StatelessWidget {
  const _OrderBar({required this.buttonKey, required this.label, required this.onOrder});

  /// من هنا تقلع صورة المنتج إلى السلة.
  final GlobalKey buttonKey;

  final String label;

  /// null لمنتجٍ بلا مقاسات — لا ينبغي أن يكون في الكتالوج، وزرٌّ سيفشل أسوأ من زرٍّ معطّل.
  final VoidCallback? onOrder;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
          child: KeyedSubtree(
            key: buttonKey,
            child: AppButton(label: label, onPressed: onOrder),
          ),
        ),
      ),
    );
  }
}
