// dartz exports an `Order` of its own; hidden so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/features/orders/models/managed_line.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One line of «إدارة الطلبية» as typed.
@immutable
class ManageLineDraft {
  const ManageLineDraft({
    required this.item,
    required this.quantity,
    required this.unitPrice,
    this.warehouseQuantity = '',
  });

  factory ManageLineDraft.of(OrderItem item) =>
      ManageLineDraft(item: item, quantity: item.quantity, unitPrice: item.unitPriceOrZero);

  final OrderItem item;
  final String quantity;
  final String unitPrice;
  final String warehouseQuantity;

  double? get _quantity => _number(quantity);
  double? get _price => _number(unitPrice);

  bool get quantityChanged => _quantity != double.tryParse(item.quantity);

  bool get priceChanged => _price != double.tryParse(item.unitPriceOrZero);

  bool get isChanged => quantityChanged || priceChanged;

  /// Sold in one unit and stocked in another, after the stock left: a moved quantity has to say
  /// what now leaves the shelf. The question the ordinary edit asks, for the same reason.
  bool needsWeight({required bool movesStock}) =>
      movesStock && (item.isStockedInAnotherUnit ?? false) && quantityChanged;

  bool get hasValidQuantity => (_quantity ?? 0) > 0;

  bool get hasValidPrice => (_price ?? -1) >= 0;

  bool get hasValidWeight => (_number(warehouseQuantity) ?? 0) > 0;

  ManageLineDraft copyWith({String? quantity, String? unitPrice, String? warehouseQuantity}) =>
      ManageLineDraft(
        item: item,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        warehouseQuantity: warehouseQuantity ?? this.warehouseQuantity,
      );

  /// «١٢٫٥» and «12,5» both read as 12.5 — the keyboard produces either.
  static String ascii(String input) =>
      Validators.toWesternDigits(input.trim()).replaceAll('٫', '.').replaceAll(',', '.');

  static double? _number(String input) => double.tryParse(ascii(input));
}

@immutable
class ManageOrderState {
  const ManageOrderState({
    required this.lines,
    required this.movesStock,
    this.isAtCarrier = false,
    this.isSaving = false,
    this.failure,
    this.saved,
  });

  final List<ManageLineDraft> lines;

  /// The order's stock has left the shelf, so a moved quantity moves it again.
  final bool movesStock;

  /// The order has an open parcel at Nawris. An edit never reaches them, so the courier still
  /// collects the old total — said on the screen, as the discount says it. ORDER-EDIT-ANY-STATUS §4.
  final bool isAtCarrier;
  final bool isSaving;
  final Failure? failure;

  /// The order as the server returned it after a save; the screen closes on it.
  final Order? saved;

  bool get isDirty => lines.any((line) => line.isChanged);

  bool get isValid => lines.every(
    (line) =>
        line.hasValidQuantity &&
        line.hasValidPrice &&
        (!line.needsWeight(movesStock: movesStock) || line.hasValidWeight),
  );

  /// The server's message for one field of line [index], when it refused the save.
  String? errorAt(int index, String field) => failure?.fieldError('items.$index.$field');

  ManageOrderState copyWith({
    List<ManageLineDraft>? lines,
    bool? isSaving,
    Failure? Function()? failure,
    Order? saved,
  }) => ManageOrderState(
    lines: lines ?? this.lines,
    movesStock: movesStock,
    isAtCarrier: isAtCarrier,
    isSaving: isSaving ?? this.isSaving,
    failure: failure == null ? this.failure : failure(),
    saved: saved ?? this.saved,
  );
}

/// «إدارة الطلبية»: a line's quantity and price (owner's decision, 2026-11-24). Nothing else on
/// the order is offered; more fields are added one at a time.
class ManageOrderCubit extends Cubit<ManageOrderState> {
  ManageOrderCubit({required Order order, required OrderRepository repository})
    : _orderId = order.id,
      _repository = repository,
      super(
        ManageOrderState(
          lines: [for (final item in order.items ?? const <OrderItem>[]) ManageLineDraft.of(item)],
          movesStock: order.itemEditsMoveStock,
          isAtCarrier: order.nawrisParcel != null,
        ),
      );

  final int _orderId;
  final OrderRepository _repository;

  void setQuantity(int lineId, String value) =>
      _edit(lineId, (line) => line.copyWith(quantity: value));

  void setUnitPrice(int lineId, String value) =>
      _edit(lineId, (line) => line.copyWith(unitPrice: value));

  void setWeight(int lineId, String value) =>
      _edit(lineId, (line) => line.copyWith(warehouseQuantity: value));

  void _edit(int lineId, ManageLineDraft Function(ManageLineDraft) change) {
    emit(
      state.copyWith(
        lines: [
          for (final line in state.lines)
            if (line.item.id == lineId) change(line) else line,
        ],
        failure: () => null,
      ),
    );
  }

  /// Sends only the lines that changed; the server leaves every other line as it is.
  Future<void> save() async {
    if (!state.isDirty || !state.isValid || state.isSaving) return;

    emit(state.copyWith(isSaving: true, failure: () => null));

    final changed = state.lines.where((line) => line.isChanged).toList(growable: false);
    final Either<Failure, Order> result = await _repository.manageLines(
      _orderId,
      lines: [
        for (final line in changed)
          ManagedLine(
            id: line.item.id,
            quantity: ManageLineDraft.ascii(line.quantity),
            unitPrice: ManageLineDraft.ascii(line.unitPrice),
            warehouseQuantity: line.needsWeight(movesStock: state.movesStock)
                ? ManageLineDraft.ascii(line.warehouseQuantity)
                : null,
          ),
      ],
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(isSaving: false, failure: () => _remapped(failure, changed))),
      (order) => emit(state.copyWith(isSaving: false, saved: order)),
    );
  }

  /// The server numbers field errors by the position in what was *sent*, and only the changed
  /// lines were sent. Re-keyed to each line's position on the screen.
  Failure _remapped(Failure failure, List<ManageLineDraft> sent) {
    if (failure case ServerFailure(:final fieldErrors?)) {
      final screen = {
        for (final (index, line) in sent.indexed)
          index: state.lines.indexWhere((draft) => draft.item.id == line.item.id),
      };
      final pattern = RegExp(r'^items\.(\d+)\.(.+)$');

      return failure.copyWith(
        fieldErrors: {
          for (final MapEntry(:key, :value) in fieldErrors.entries)
            switch (pattern.firstMatch(key)) {
              final match? =>
                'items.${screen[int.parse(match[1]!)] ?? match[1]}.${match[2]}',
              null => key,
            }: value,
        },
      );
    }

    return failure;
  }
}
