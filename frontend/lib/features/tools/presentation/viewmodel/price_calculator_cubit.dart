import 'dart:async';

import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/line_quote_cubit.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/usecases/get_price_quote.dart';
import 'package:dayaa/features/tools/models/price_estimate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'price_calculator_cubit.freezed.dart';
part 'price_calculator_state.dart';

/// حاسبة الأسعار — what a customer's list would cost, without taking an order for it.
///
/// **Every price is the server's.** Each line asks `QuoteProductPrice` exactly as a line on a
/// new order does, so the figure read to the customer here is the figure on the invoice later.
/// Pricing the tiers locally would be a second implementation of pricing, and the day the two
/// disagree the clerk has quoted one number and the order charges another.
///
/// Nothing here writes anything: there is no order, no customer and no draft behind the screen.
class PriceCalculatorCubit extends Cubit<PriceCalculatorState> {
  PriceCalculatorCubit({
    required GetPriceQuote getPriceQuote,
    this.debounce = const Duration(milliseconds: 400),
  }) : _getPriceQuote = getPriceQuote,
       super(const PriceCalculatorState());

  final GetPriceQuote _getPriceQuote;

  /// Long enough that typing «300» is one request, short enough that the price appears while
  /// the clerk is still looking at the box.
  final Duration debounce;

  final Map<int, Timer> _pending = {};

  /// The latest request per line. Answers land out of order — `30`'s after `300`'s — and only
  /// the latest may write.
  final Map<int, int> _latest = {};

  int _nextKey = 0;

  /// Adds a size and returns the line's key, so the screen can open it for a quantity.
  int add(Product product, ProductVariant variant) {
    final key = _nextKey++;
    final line = CalculatorLine(
      key: key,
      product: product,
      variant: variant,
      // A product priced «حسب الطلب» has no answer to fetch; the line says so from the start.
      quote: product.hasListedPrices ? const LineQuoteState.idle() : const LineQuoteState.byHand(),
    );

    emit(state.copyWith(lines: [...state.lines, line]));

    return key;
  }

  void setQuantity(int key, String quantity) {
    final line = state.lineOf(key);
    if (line == null || line.quantity == quantity) return;

    _replace(line.copyWith(quantity: quantity));
    _requote(key, after: debounce);
  }

  /// The clerk's own price for a line the catalogue does not price. Nothing to ask the server:
  /// the line's total follows from it by the order's own rule ([handLineTotal]).
  void setUnitPrice(int key, String unitPrice) {
    final line = state.lineOf(key);
    if (line == null || !line.isPricedByHand || line.unitPrice == unitPrice) return;

    _replace(line.copyWith(unitPrice: unitPrice));
  }

  /// Moves a line to another size of the same product, keeping its quantity.
  ///
  /// A size already on the list is refused: two lines of one size are priced separately —
  /// 100 and 200 come out as 100 and as 200, never as the 300 the customer is buying.
  void changeVariant(int key, ProductVariant variant) {
    final line = state.lineOf(key);
    if (line == null || line.variant.id == variant.id) return;
    if (state.variantIds.contains(variant.id)) return;

    _replace(line.copyWith(variant: variant));
    _requote(key, after: Duration.zero);
  }

  void remove(int key) {
    _forget(key);
    emit(
      state.copyWith(
        lines: [
          for (final line in state.lines)
            if (line.key != key) line,
        ],
      ),
    );
  }

  void clear() {
    for (final key in [..._pending.keys, ..._latest.keys]) {
      _forget(key);
    }
    emit(const PriceCalculatorState());
  }

  void _requote(int key, {required Duration after}) {
    _pending.remove(key)?.cancel();

    final line = state.lineOf(key);
    if (line == null || line.isPricedByHand) return;

    // An empty box is not a question, and «الكمية مطلوبة» is not news to somebody mid-typing.
    if (line.westernQuantity.isEmpty) {
      _latest[key] = (_latest[key] ?? 0) + 1;
      _replace(line.copyWith(quote: const LineQuoteState.idle()));

      return;
    }

    _pending[key] = Timer(after, () {
      _pending.remove(key);
      unawaited(_quote(key));
    });
  }

  Future<void> _quote(int key) async {
    final line = state.lineOf(key);
    if (line == null) return;

    final request = (_latest[key] ?? 0) + 1;
    _latest[key] = request;
    _replace(line.copyWith(quote: const LineQuoteState.loading()));

    final result = await _getPriceQuote(
      productId: line.product.id,
      variantId: line.variant.id,
      quantity: line.quantity,
    );

    if (isClosed || _latest[key] != request) return;

    final current = state.lineOf(key);
    if (current == null) return;

    _replace(
      current.copyWith(
        quote: result.fold((f) => LineQuoteState.failure(f), (q) => LineQuoteState.priced(q)),
      ),
    );
  }

  void _replace(CalculatorLine updated) {
    emit(
      state.copyWith(
        lines: [for (final line in state.lines) line.key == updated.key ? updated : line],
      ),
    );
  }

  /// Drops a line's timer and makes any answer still in flight for it a stale one.
  void _forget(int key) {
    _pending.remove(key)?.cancel();
    _latest[key] = (_latest[key] ?? 0) + 1;
  }

  @override
  Future<void> close() {
    for (final timer in _pending.values) {
      timer.cancel();
    }
    _pending.clear();

    return super.close();
  }
}
