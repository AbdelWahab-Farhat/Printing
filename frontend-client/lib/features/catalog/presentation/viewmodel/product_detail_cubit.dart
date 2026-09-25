import 'dart:async';
import 'dart:math' as math;

import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/catalog/models/product.dart';
import 'package:dayaa_client/features/catalog/usecases/get_product.dart';
import 'package:dayaa_client/features/catalog/usecases/quote_price.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_detail_cubit.freezed.dart';
part 'product_detail_state.dart';

/// The ViewModel for one product, and for the order being composed against it.
///
/// **Every price on this screen comes from the server.** Picking a size or changing the quantity
/// re-quotes; nothing here multiplies a unit price by a number. That is not caution about
/// arithmetic — it is that the tier rules live in one place, and a copy of them in this app
/// would be the one that disagrees with the invoice.
class ProductDetailCubit extends Cubit<ProductDetailState> {
  ProductDetailCubit({required GetProduct getProduct, required QuotePrice quote})
    : _getProduct = getProduct,
      _quote = quote,
      super(const ProductDetailState.loading());

  final GetProduct _getProduct;
  final QuotePrice _quote;

  /// Bumped on every quote so a slow answer to an old quantity cannot overwrite a newer one —
  /// the classic race on a screen where a stepper fires a request per tap.
  int _quoteToken = 0;

  Future<void> load(int productId) async {
    emit(const ProductDetailState.loading());

    final result = await _getProduct(productId);

    if (isClosed) return;

    emit(
      result.fold(ProductDetailState.failure, (product) {
        final variant = product.variants.isEmpty ? null : product.variants.first;

        return ProductDetailState.loaded(
          product: product,
          selectedVariantId: variant?.id,
          quantity: product.minOrderQuantity ?? '1',
        );
      }),
    );

    // The opening quote, so the total is on screen before the customer touches anything.
    await refreshQuote();
  }

  void selectVariant(int variantId) {
    final loaded = _loaded;
    if (loaded == null || loaded.selectedVariantId == variantId) return;

    // السعر السابق يبقى إلى أن يصل الجديد، والشاشة تخفّته — رقمٌ يختفي مع كل لمسة يُقرأ
    // سعراً انكسر.
    emit(loaded.copyWith(selectedVariantId: variantId));

    unawaited(refreshQuote());
  }

  void setQuantity(String quantity) {
    final loaded = _loaded;
    if (loaded == null || loaded.quantity == quantity) return;

    emit(loaded.copyWith(quantity: quantity));

    unawaited(refreshQuote());
  }

  /// زر +: خطوةٌ إلى الأعلى، إلى أول مضاعفٍ للخطوة فوق الكمية الحالية — ٤٣٧ تصير ٤٥٠ لا ٤٨٧،
  /// فتعود الكمية إلى الدرجات التي يقف عليها السلايدر.
  void increase() {
    final loaded = _loaded;
    if (loaded == null) return;

    final product = loaded.product;
    final current = double.tryParse(loaded.quantity);
    final step = product.quantityStep;

    _moveTo(
      loaded,
      current == null ? product.quantityFloor : ((current / step).floor() + 1) * step,
    );
  }

  /// زر −: خطوةٌ إلى الأسفل، ولا تحت الحد الأدنى — الخادم يرفض ما دونه، فلا يعبره الزر ولا
  /// يكلّف طلباً يعرف جوابه.
  void decrease() {
    final loaded = _loaded;
    if (loaded == null) return;

    final product = loaded.product;
    final current = double.tryParse(loaded.quantity);
    final step = product.quantityStep;

    _moveTo(
      loaded,
      current == null
          ? product.quantityFloor
          : math.max(product.quantityFloor, ((current / step).ceil() - 1) * step),
    );
  }

  /// السلايدر أثناء السحب: الكمية تتبع الإصبع على درجات الخطوة، **ولا يُطلب سعر.** السحب يطلق
  /// عشرات القيم في الثانية؛ الطلب يخرج مرةً واحدة حين يُرفع الإصبع — [refreshQuote] في
  /// `onChangeEnd`.
  void slide(double value) {
    final loaded = _loaded;
    if (loaded == null) return;

    final product = loaded.product;
    final step = product.quantityStep;
    final snapped = ((value / step).round() * step)
        .clamp(product.quantityFloor, product.quantityCeiling)
        .toDouble();

    if (double.tryParse(loaded.quantity) == snapped) return;

    // جوابٌ في الطريق الآن جوابٌ عن كميةٍ لم تعد على الشاشة، فيُسقَط حين يصل.
    _quoteToken++;

    emit(
      loaded.copyWith(
        quantity: _plain(snapped),
        // السعر الظاهر لم يعد لهذه الكمية — إلا لمنتجٍ بلا سعرٍ أصلاً.
        isQuoting: loaded.product.hasListedPrices,
      ),
    );
  }

  /// بطاقة سعر: تطلب عتبتها بالضبط — أو الحد الأدنى إن كانت العتبة دونه، فكسرٌ يبدأ من ١ على
  /// منتجٍ لا يُطلب منه أقل من ١٠٠ يعني ١٠٠.
  void chooseTier(PriceTier tier) {
    final loaded = _loaded;
    if (loaded == null) return;

    _moveTo(
      loaded,
      math.max(double.tryParse(tier.minQuantity) ?? 0, loaded.product.quantityFloor),
    );
  }

  /// يُقارَن بالرقم لا بالنص: «100.000» الآتية من الخادم و«100» الخارجة من زرٍّ كميةٌ واحدة.
  void _moveTo(ProductDetailLoaded loaded, double value) {
    if (double.tryParse(loaded.quantity) == value) return;

    setQuantity(_plain(value));
  }

  /// `550` لا `550.0`: الكمية نصٌّ يُرسل إلى الخادم كما هو، والصفر العشري حشوٌ في الحقل.
  static String _plain(double value) =>
      value == value.roundToDouble() ? value.round().toString() : value.toString();

  /// Re-asks the server for the price of what is currently selected.
  Future<void> refreshQuote() async {
    final loaded = _loaded;
    final variantId = loaded?.selectedVariantId;

    if (loaded == null || variantId == null) return;
    // A product sold on request has no tiers to quote against — the screen draws «اطلب عرض سعر»
    // instead of a total.
    if (!loaded.product.hasListedPrices) return;

    final token = ++_quoteToken;

    emit(loaded.copyWith(isQuoting: true));

    final result = await _quote(
      productId: loaded.product.id,
      variantId: variantId,
      quantity: loaded.quantity,
    );

    if (isClosed) return;

    // A stale answer — the customer changed the size or the quantity while this was in flight.
    // Dropping it is what stops the total flickering back to a number nobody asked for.
    if (token != _quoteToken) return;

    final current = _loaded;
    if (current == null) return;

    emit(
      result.fold(
        // الإجمالي السابق كان لكميةٍ أخرى؛ بجانب رسالة الرفض يصير رقماً كاذباً.
        (failure) => current.copyWith(isQuoting: false, quoteFailure: failure, quote: null),
        (quote) => current.copyWith(isQuoting: false, quote: quote, quoteFailure: null),
      ),
    );
  }

  ProductDetailLoaded? get _loaded => switch (state) {
    final ProductDetailLoaded loaded => loaded,
    _ => null,
  };
}
