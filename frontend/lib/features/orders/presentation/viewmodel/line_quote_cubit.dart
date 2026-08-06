import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/products/models/price_quote.dart';
import 'package:printing/features/products/usecases/get_price_quote.dart';

part 'line_quote_state.dart';
part 'line_quote_cubit.freezed.dart';

/// The price under the quantity box, as it is typed.
///
/// **The app holds every price break already** — the catalogue endpoint sends them with each
/// product — and this asks the server anyway. Reading the ladder here to save a request would
/// be a second implementation of pricing beside `QuoteProductPrice`, and the day the two
/// disagree a customer is quoted one number and invoiced another. It also gets the refusals
/// right for free: below the minimum, no tier for this quantity, priced on request — each comes
/// back as a sentence worth reading rather than a blank.
///
/// One of these per line being edited, not one per screen.
class LineQuoteCubit extends Cubit<LineQuoteState> {
  LineQuoteCubit({required GetPriceQuote getPriceQuote})
    : _getPriceQuote = getPriceQuote,
      super(const LineQuoteState.idle());

  final GetPriceQuote _getPriceQuote;

  /// Which request is the current one.
  ///
  /// Typing `300` sends a request per keystroke and the answers may land out of order — `30`'s
  /// arriving after `300`'s would leave the wrong price under the box. Only the latest is
  /// allowed to emit.
  int _latest = 0;

  Future<void> quote({
    required int productId,
    required int variantId,
    required String quantity,
  }) async {
    // Every keystroke arrives here, including the one that empties the box. An empty quantity
    // is not a question, and the server's «الكمية مطلوبة» is not news to somebody mid-typing.
    if (quantity.trim().isEmpty) {
      _latest++;
      emit(const LineQuoteState.idle());

      return;
    }

    final request = ++_latest;
    emit(const LineQuoteState.loading());

    final result = await _getPriceQuote(
      productId: productId,
      variantId: variantId,
      quantity: quantity,
    );

    if (isClosed || request != _latest) return;

    emit(result.fold(LineQuoteState.failure, LineQuoteState.priced));
  }

  /// The line is for a product the catalogue prices «حسب الطلب».
  ///
  /// There is no answer to fetch — `QuoteProductPrice` refuses these outright — so the clerk
  /// names the price and the API honours it for this one category. Any answer still in flight
  /// is abandoned, which is what stops a stale price appearing under a hand-priced line.
  void priceByHand() {
    _latest++;
    emit(const LineQuoteState.byHand());
  }
}
