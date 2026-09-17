part of 'place_order_cubit.dart';

/// Everything the order screen can be.
@freezed
sealed class PlaceOrderState with _$PlaceOrderState {
  const factory PlaceOrderState.loading() = PlaceOrderLoading;

  const factory PlaceOrderState.ready({
    /// Every destination, with its neighbourhoods. Fetched once — the picker does not page.
    required List<City> cities,

    /// The customer's library, for attaching artwork. **Empty is fine**: attaching a design is
    /// optional, and an empty library is also what a failed fetch looks like here, because
    /// neither is worth refusing an order over.
    @Default(<CustomerDesign>[]) List<CustomerDesign> designs,

    @Default(<OrderDraftLine>[]) List<OrderDraftLine> lines,

    int? cityId,
    int? regionId,
    @Default(<int>[]) List<int> designIds,

    @Default(false) bool isSubmitting,

    /// The order the shop created, once it has. **«بانتظار المراجعة»** — nothing is confirmed
    /// and nothing is priced against stock until a person has read it.
    CustomerOrderDetail? placed,

    Failure? lastFailure,
  }) = PlaceOrderReady;

  /// The destination picker did not load. The server requires a `city_id`, so this screen
  /// genuinely cannot proceed — better said here than discovered at submit.
  const factory PlaceOrderState.failure(Failure failure) = PlaceOrderFailure;
}

extension PlaceOrderStateX on PlaceOrderState {
  /// The city currently chosen, resolved from the list rather than stored twice.
  City? get selectedCity => switch (this) {
    PlaceOrderReady(:final cities, :final cityId) => () {
      for (final city in cities) {
        if (city.id == cityId) return city;
      }

      return null;
    }(),
    _ => null,
  };

  /// The neighbourhoods to offer, which is none until a city is chosen.
  List<Region> get regions => selectedCity?.regions ?? const <Region>[];

  /// Whether «أرسل الطلبية» may be tapped.
  ///
  /// **Three conditions, and each mirrors a server rule rather than inventing one.** `items` is
  /// required and non-empty, `city_id` is required, and a city that requires a region is one
  /// `RequestOrderRequest` would accept without it — so this is the only rule here that is
  /// stricter than the server, and it is stricter because an order whose neighbourhood is
  /// missing is one somebody has to ring the customer about.
  bool get canSubmit => switch (this) {
    PlaceOrderReady(:final lines, :final cityId, :final regionId) =>
      lines.isNotEmpty &&
          cityId != null &&
          (!(selectedCity?.needsRegion ?? false) || regionId != null),
    _ => false,
  };

  bool get isSubmitting => switch (this) {
    PlaceOrderReady(:final isSubmitting) => isSubmitting,
    _ => false,
  };
}
