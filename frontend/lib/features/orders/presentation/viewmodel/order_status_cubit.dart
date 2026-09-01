import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/transition_field.dart';
import 'package:dayaa/features/orders/usecases/change_order_status.dart';
import 'package:dayaa/features/orders/usecases/get_order.dart';
import 'package:dayaa/features/shipping_companies/models/shipping_company.dart';
import 'package:dayaa/features/shipping_companies/usecases/get_shipping_companies.dart';
import 'package:dayaa/features/warehouses/models/warehouse.dart';
import 'package:dayaa/features/warehouses/usecases/get_warehouses.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_status_cubit.freezed.dart';
part 'order_status_state.dart';

/// Moving one order: which way, and whatever that way asks for.
///
/// **It knows no statuses and no fields.** The moves come from the order's own
/// `available_transitions`, and what each of them wants comes from that transition's [fields].
/// So a path that starts asking for one more thing is answered by this Cubit without a line
/// changing here — which is the whole reason the description travels with the move.
///
/// The order is fetched rather than handed in: this screen is reachable by deep link, and a
/// screen that only works when another one filled its hands is a screen with a hidden
/// precondition.
class OrderStatusCubit extends Cubit<OrderStatusState> {
  OrderStatusCubit({
    required int orderId,
    required GetOrder getOrder,
    required ChangeOrderStatus changeStatus,
    required GetWarehouses getWarehouses,
    required GetShippingCompanies getShippingCompanies,
  }) : _orderId = orderId,
       _getOrder = getOrder,
       _changeStatus = changeStatus,
       _getWarehouses = getWarehouses,
       _getShippingCompanies = getShippingCompanies,
       super(const OrderStatusState.loading());

  final int _orderId;
  final GetOrder _getOrder;
  final ChangeOrderStatus _changeStatus;

  /// The two lists this app owns, fetched to answer a field on the form's behalf — see
  /// [_fillInTheObvious]. Not to draw a picker: the pickers fetch their own.
  final GetWarehouses _getWarehouses;
  final GetShippingCompanies _getShippingCompanies;

  /// Resolved once per screen and kept, because the answer cannot change while one order is
  /// being moved and the road here is a phone on a mobile connection.
  Warehouse? _mainStore;
  ShippingCompany? _soleCarrier;

  Future<void> load() async {
    if (state.order == null) emit(const OrderStatusState.loading());

    final result = await _getOrder(_orderId);
    if (isClosed) return;

    emit(
      result.fold(
        (failure) => OrderStatusState.failure(failure: failure, order: state.order),
        (order) {
          // The one move on offer is chosen already. A list of one that still has to be tapped
          // is a tap that tells nobody anything — and «تم الاستلام» from «استلام مكتب» is
          // exactly that list.
          final only = order.availableTransitions.length == 1
              ? order.availableTransitions.single
              : null;

          return OrderStatusState.ready(
            order: order,
            selected: only,
            values: only == null ? const {} : _prefilled(only),
          );
        },
      ),
    );

    // The move chosen for the user gets its defaults too — nobody is going to tap and trigger
    // them.
    if (state.selected case final only?) await _fillInTheObvious(only);
  }

  /// Picks a destination, and empties whatever was typed for the last one.
  ///
  /// Deliberately not merged: two paths may both have a `notes`, and carrying an answer across
  /// would submit a sentence written about a different move. What replaces it is not nothing,
  /// though — see [_prefilled].
  Future<void> select(OrderTransition transition) async {
    final order = state.order;
    if (order == null) return;

    emit(
      OrderStatusState.ready(
        order: order,
        selected: transition,
        values: _prefilled(transition),
      ),
    );

    await _fillInTheObvious(transition);
  }

  /// Answers, on the person's behalf, the fields whose answer the app can work out.
  ///
  /// **The warehouse and the carrier are the two kinds whose lists this app owns** — the server
  /// sends no options for either, precisely because the app manages them. So it is the app that
  /// can see when the list has only one sensible answer, and a form that opens holding it saves
  /// a storekeeper the same three taps thirty times a day:
  ///
  /// - «المخزن» opens on the main store. Every other shelf is still one tap away in the picker.
  /// - «شركة التوصيل» opens on the carrier **when it is the only active one**. A second one
  ///   hands the choice straight back: which of two took the parcel is a fact, not a default.
  ///
  /// **A suggestion, never an answer that overrules one.** The lists are fetched over the wire,
  /// so a reply can land after somebody has already picked — or after they have moved to another
  /// destination entirely. Both are checked before anything is written, and a list that fails to
  /// load leaves the field empty rather than the screen broken: the picker was always the way to
  /// fill it in.
  Future<void> _fillInTheObvious(OrderTransition transition) async {
    for (final field in transition.fields) {
      final Object? answer = switch (field.type) {
        TransitionFieldType.warehouse => await _mainWarehouse(),
        TransitionFieldType.shippingCompany => await _onlyActiveCarrier(),
        _ => null,
      };

      if (answer != null) _suggest(transition, field.key, answer);
    }
  }

  /// Writes a default, unless the form has moved on without it.
  void _suggest(OrderTransition transition, String key, Object value) {
    if (isClosed) return;

    // They chose another destination while the list was loading — this answer belongs to a form
    // that is no longer on screen.
    if (state.selected != transition) return;

    // They answered it themselves, or the server sent an answer with the field. Either beats a
    // guess made from a list.
    if (state.values[key] != null) return;

    setValue(key, value);
  }

  /// «الرئيسي», asked of the server by type rather than guessed off the first page.
  Future<Warehouse?> _mainWarehouse() async {
    if (_mainStore case final store?) return store;

    final result = await _getWarehouses(type: WarehouseType.main, perPage: 1);

    return _mainStore = result.fold(
      // A list that would not load is not an emergency here: the field simply opens empty, as
      // it did before any of this existed.
      (_) => null,
      (page) => page.items.isEmpty ? null : page.items.first,
    );
  }

  /// The carrier, when the business deals with exactly one.
  ///
  /// `total` rather than the length of the page is what decides it: two pages of one row each
  /// are still two carriers, and a page size of two only exists to make the question answerable
  /// in one request.
  Future<ShippingCompany?> _onlyActiveCarrier() async {
    if (_soleCarrier case final carrier?) return carrier;

    final result = await _getShippingCompanies(isActive: true, perPage: 2);

    return _soleCarrier = result.fold(
      (_) => null,
      (page) => page.meta.total == 1 && page.items.isNotEmpty ? page.items.first : null,
    );
  }

  /// The answers the server already knows, for the fields that arrive holding one.
  ///
  /// **The prefill is part of the form, not a first draft of it**, so it is re-applied every
  /// time the destination is chosen. Leaving «نواقص» is the case it exists for: the box asking
  /// what arrived of the shortage opens holding the whole of it, and a clerk who agrees submits
  /// without typing.
  Map<String, Object?> _prefilled(OrderTransition transition) {
    final seeded = <String, Object?>{};

    for (final field in transition.fields) {
      if (field.value != null) seeded[field.key] = field.value;
    }

    return seeded;
  }

  /// Records an answer, from a clean form **or from a refused one**.
  ///
  /// **Reading the state's own accessors rather than matching [OrderStatusReady] is the whole
  /// point.** [submit] is sendable from a refusal — that is what its docblock is about — and a
  /// refusal is usually acted on by *changing something* first: the warehouse that was short is
  /// swapped for one that is not. Matching only the ready case dropped every one of those edits
  /// on the floor and then resent the values that had just been refused, so the second attempt
  /// failed exactly like the first and the screen looked broken.
  ///
  /// Landing back on `ready` clears the server's sentence, which is right: the complaint was
  /// about the answer that has just been replaced, and leaving it over a field somebody has
  /// already corrected is a warning about nothing. `TakeOrderCubit.clearFailure()` does the same
  /// on the same reasoning.
  void setValue(String key, Object? value) {
    final order = state.order;
    final selected = state.selected;

    // Nothing to record against — the form is not on screen yet.
    if (order == null) return;

    emit(
      OrderStatusState.ready(
        order: order,
        selected: selected,
        values: {...state.values, key: value},
      ),
    );
  }

  /// Sends the move, and answers with the order the server sent back.
  ///
  /// Null when it was refused — the failure is on the state, in the server's own Arabic, and
  /// the screen stays where it is so nothing typed is lost.
  ///
  /// **Sendable from a refusal, not only from a clean form.** The server refuses for reasons
  /// that pass on their own — a warehouse short of stock at ten and restocked at eleven — so
  /// the same tap has to be answerable a second time. Reading the selection off the state
  /// rather than off [OrderStatusReady] is what allows it, and going back through
  /// `isSubmitting` on the way is what makes the second refusal a *different* state from the
  /// first: identical states are dropped by Bloc, and a refusal nobody is told about twice is a
  /// screen that looks broken.
  Future<Order?> submit() async {
    final order = state.order;
    final selected = state.selected;
    if (order == null || selected == null || state.isSubmitting) return null;

    final values = state.values;
    emit(OrderStatusState.ready(order: order, selected: selected, values: values, isSubmitting: true));

    final result = await _changeStatus(
      _orderId,
      status: selected.status,
      fields: _payload(selected, values),
    );

    if (isClosed) return null;

    return result.fold<Order?>(
      (failure) {
        // The order and everything filled in stay: a refused move must leave the screen
        // showing what it was showing, with the server's sentence over the top.
        emit(
          OrderStatusState.failure(
            failure: failure,
            order: order,
            selected: selected,
            values: values,
          ),
        );

        return null;
      },
      (updated) {
        emit(OrderStatusState.ready(order: updated, selected: null));

        return updated;
      },
    );
  }

  /// What goes on the wire, keyed exactly as the transition described.
  ///
  /// Designs are sent as their ids and nothing else — the file lives in the customer's library
  /// and the order points at it. Text is trimmed, because a sentence of spaces satisfies a
  /// required check while telling the next reader nothing.
  Map<String, Object?> _payload(OrderTransition transition, Map<String, Object?> values) {
    return {
      for (final field in transition.fields)
        if (values[field.key] case final value?)
          field.key: switch (value) {
            final List<CustomerDesign> designs => [for (final design in designs) design.id],
            // The picker hands over the whole company so the button can say its name; only the
            // id crosses the wire, exactly as for a design.
            final ShippingCompany carrier => carrier.id,
            // Same again for the shelf the run comes off: the picker hands over the whole
            // warehouse so the button can name it, and only the id is the server's business.
            final Warehouse store => store.id,
            final String text => text.trim(),
            _ => value,
          },
    };
  }
}
