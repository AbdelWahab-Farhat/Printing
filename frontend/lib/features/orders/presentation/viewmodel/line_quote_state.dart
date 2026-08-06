part of 'line_quote_cubit.dart';

/// What can be under the quantity box, and nothing else.
@freezed
sealed class LineQuoteState with _$LineQuoteState {
  /// Nothing has been asked yet, or the box was emptied.
  const factory LineQuoteState.idle() = LineQuoteIdle;

  const factory LineQuoteState.loading() = LineQuoteLoading;

  const factory LineQuoteState.priced(PriceQuote quote) = LineQuotePriced;

  /// The catalogue refused to price this — below the minimum, no tier for this quantity, or a
  /// product priced on request reached the endpoint anyway. Carries the server's sentence,
  /// which is the useful thing to show.
  const factory LineQuoteState.failure(Failure failure) = LineQuoteFailure;

  /// «حسب الطلب» — there is no catalogue price and the clerk names one.
  const factory LineQuoteState.byHand() = LineQuoteByHand;
}

extension LineQuoteStateX on LineQuoteState {
  PriceQuote? get quote => switch (this) {
    LineQuotePriced(:final quote) => quote,
    _ => null,
  };

  bool get isByHand => this is LineQuoteByHand;
}
