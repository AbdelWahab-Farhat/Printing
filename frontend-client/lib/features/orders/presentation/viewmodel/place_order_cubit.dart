import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/delivery/models/city.dart';
import 'package:dayaa_client/features/delivery/usecases/list_cities.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/usecases/list_designs.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/models/order_draft.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/cart_cubit.dart';
import 'package:dayaa_client/features/orders/usecases/place_order.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'place_order_cubit.freezed.dart';
part 'place_order_state.dart';

/// The ViewModel for the screen that sends an order.
///
/// **It owns the choices, not the typing.** City, region, which designs are attached and which
/// lines are in the order live here; the recipient's name, phone and address stay in the
/// screen's own controllers and arrive at [submit]. A Cubit that emits on every keystroke
/// rebuilds the whole form to redraw one field, and on a phone that is felt.
///
/// **No total is computed here.** What the order costs is the server's answer, arriving with
/// the order it created — this app has never multiplied a price by a quantity and must not
/// start on the screen where the number is a promise.
class PlaceOrderCubit extends Cubit<PlaceOrderState> {
  PlaceOrderCubit({
    required ListCities cities,
    required ListDesigns designs,
    required PlaceOrder place,
    required CartCubit cart,
  }) : _cities = cities,
       _designs = designs,
       _place = place,
       _cart = cart,
       super(const PlaceOrderState.loading());

  final ListCities _cities;
  final ListDesigns _designs;
  final PlaceOrder _place;

  /// **The basket is the truth about what is in the order, and this Cubit does not keep a
  /// copy.** It used to be handed a list at construction, which was right when the only way here
  /// was one product pushing one line — and would be wrong now: removing a line here and
  /// leaving it in the basket would put it back the next time somebody opened this screen.
  final CartCubit _cart;

  List<OrderDraftLine> get _lines => _cart.state.lines;

  Future<void> load() async {
    emit(const PlaceOrderState.loading());

    // Started together: the destination picker and the design library are one screen.
    final citiesResult = _cities();
    final designsResult = _designs();

    final cities = await citiesResult;

    // **The library failing does not stop an order.** Attaching artwork is optional, and an
    // order refused because a picture list timed out would be the app inventing a rule.
    final library = (await designsResult).fold(
      (_) => const <CustomerDesign>[],
      (list) => list,
    );

    if (isClosed) return;

    emit(
      cities.fold(
        // The destination, though, is required by the server — so a picker that did not load
        // is a screen that cannot proceed, and it says so rather than failing at submit.
        PlaceOrderState.failure,
        (list) => PlaceOrderState.ready(
          cities: list,
          designs: library,
          lines: List<OrderDraftLine>.unmodifiable(_lines),
        ),
      ),
    );
  }

  /// Chooses a destination. **Clears the region**, because a region belongs to the city it was
  /// chosen in — keeping it would send a neighbourhood of somewhere else.
  void chooseCity(int cityId) {
    final ready = _ready;
    if (ready == null || ready.cityId == cityId) return;

    emit(ready.copyWith(cityId: cityId, regionId: null, lastFailure: null));
  }

  void chooseRegion(int? regionId) {
    final ready = _ready;
    if (ready == null) return;

    emit(ready.copyWith(regionId: regionId, lastFailure: null));
  }

  /// Attaches or detaches one of the customer's designs.
  void toggleDesign(int designId) {
    final ready = _ready;
    if (ready == null) return;

    final attached = ready.designIds.contains(designId);

    emit(
      ready.copyWith(
        designIds: attached
            ? [...ready.designIds.where((id) => id != designId)]
            : [...ready.designIds, designId],
      ),
    );
  }

  void addLine(OrderDraftLine line) {
    final ready = _ready;
    if (ready == null) return;

    _cart.add(line);

    emit(ready.copyWith(lines: List<OrderDraftLine>.unmodifiable(_lines)));
  }

  void removeLineAt(int index) {
    final ready = _ready;
    if (ready == null || index < 0 || index >= _lines.length) return;

    _cart.removeAt(index);

    emit(ready.copyWith(lines: List<OrderDraftLine>.unmodifiable(_lines)));
  }

  /// Sends it.
  ///
  /// Returns the order the shop created, so the screen can show it — **«بانتظار المراجعة», and
  /// the screen after this one must say so.** Nothing has been confirmed or priced against
  /// stock; a person reads it first, and congratulating the customer on an accepted order would
  /// be this app promising something the shop has not.
  ///
  /// Null means it failed, and `lastFailure` says why.
  Future<CustomerOrderDetail?> submit({
    String? recipientName,
    String? recipientPhone,
    String? addressDetails,
    String? note,
    int? customerShopId,
  }) async {
    final ready = _ready;
    if (ready == null || ready.isSubmitting || !ready.canSubmit) return null;

    emit(ready.copyWith(isSubmitting: true, lastFailure: null));

    final result = await _place(
      NewOrder(
        cityId: ready.cityId!,
        regionId: ready.regionId,
        customerShopId: customerShopId,
        // The display half is dropped here: the server is sent ids, exactly as
        // `RequestOrderRequest` expects, and a product name in the body would be a second
        // source of truth for something the order already resolves through `product_id`.
        items: [for (final draft in ready.lines) draft.line],
        designIds: ready.designIds,
        recipientName: _orNull(recipientName),
        recipientPhone: _orNull(recipientPhone),
        addressDetails: _orNull(addressDetails),
        customerNote: _orNull(note),
      ),
    );

    if (isClosed) return null;

    final current = _ready;
    if (current == null) return result.fold((_) => null, (order) => order);

    return result.fold(
      (failure) {
        emit(current.copyWith(isSubmitting: false, lastFailure: failure));

        return null;
      },
      (order) {
        // **The basket empties only once the shop has the order.** A failed send leaves it
        // exactly as it was, so the customer can fix a field and try again rather than rebuild
        // what they had already chosen.
        _cart.clear();

        emit(current.copyWith(isSubmitting: false, placed: order));

        return order;
      },
    );
  }

  /// Whitespace is not an address. Sending `"   "` would put a blank line in the order the
  /// shop reads.
  static String? _orNull(String? value) {
    final trimmed = value?.trim();

    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  PlaceOrderReady? get _ready => switch (state) {
    final PlaceOrderReady ready => ready,
    _ => null,
  };
}
