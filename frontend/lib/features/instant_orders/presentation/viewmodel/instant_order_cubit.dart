import 'dart:async';

import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/uuid.dart';
import 'package:dayaa/features/instant_orders/models/instant_models.dart';
import 'package:dayaa/features/instant_orders/repositories/instant_order_repository.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Where the instant-order screen stands.
@immutable
class InstantOrderState {
  const InstantOrderState({
    this.isLoading = true,
    this.loadFailure,
    this.branches = const [],
    this.branchId,
    this.catalogue,
    this.isLoadingCatalogue = false,
    this.customer,
    this.isLookingUp = false,
    this.lines = const [],
    this.isSubmitting = false,
    this.submitFailure,
    this.result,
    this.updated,
  });

  final bool isLoading;
  final Failure? loadFailure;
  final List<SellingBranch> branches;
  final int? branchId;
  final InstantCatalogue? catalogue;
  final bool isLoadingCatalogue;

  /// The customer this phone belongs to, once looked up. Null: a new customer.
  final FoundCustomer? customer;
  final bool isLookingUp;
  final List<InstantLine> lines;
  final bool isSubmitting;
  final Failure? submitFailure;

  /// Set once a new order was taken.
  final InstantOrderResult? result;

  /// Set once an edit was saved.
  final Order? updated;

  SellingBranch? get branch => branches.where((branch) => branch.id == branchId).firstOrNull;

  /// The server's sentence for one field, if the last save was refused there.
  String? errorFor(String key) => switch (submitFailure) {
    ServerFailure(:final fieldErrors?) => fieldErrors[key]?.firstOrNull,
    _ => null,
  };

  InstantOrderState copyWith({
    bool? isLoading,
    Failure? loadFailure,
    List<SellingBranch>? branches,
    int? branchId,
    InstantCatalogue? catalogue,
    bool? isLoadingCatalogue,
    FoundCustomer? customer,
    bool clearCustomer = false,
    bool? isLookingUp,
    List<InstantLine>? lines,
    bool? isSubmitting,
    Failure? submitFailure,
    bool clearSubmitFailure = false,
    InstantOrderResult? result,
    Order? updated,
  }) {
    return InstantOrderState(
      isLoading: isLoading ?? this.isLoading,
      loadFailure: loadFailure ?? this.loadFailure,
      branches: branches ?? this.branches,
      branchId: branchId ?? this.branchId,
      catalogue: catalogue ?? this.catalogue,
      isLoadingCatalogue: isLoadingCatalogue ?? this.isLoadingCatalogue,
      customer: clearCustomer ? null : (customer ?? this.customer),
      isLookingUp: isLookingUp ?? this.isLookingUp,
      lines: lines ?? this.lines,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitFailure: clearSubmitFailure ? null : (submitFailure ?? this.submitFailure),
      result: result ?? this.result,
      updated: updated ?? this.updated,
    );
  }
}

/// The one-screen instant sale — INSTANT-ORDERS-PLAN.md §3.
///
/// **The branch comes first.** Its warehouse decides what may be sold and how much is free, so
/// products are listed only once a branch is chosen — automatically when the employee has one,
/// from a choice when they have several. Changing it re-reads the catalogue, and every line is
/// judged against the new warehouse.
///
/// **The shelf is checked here as the lines are typed, and again by the server.** A line asking
/// more than is free is marked and blocks the button; the server's own check, under a lock, is
/// the one that counts.
///
/// **On an edit** the branch and the customer are fixed (§16-4): only the lines, the discount
/// and the notes move, and what the order already holds counts as free to it.
class InstantOrderCubit extends Cubit<InstantOrderState> {
  InstantOrderCubit({required InstantOrderRepository repository, this.editing})
    : _repository = repository,
      super(const InstantOrderState());

  final InstantOrderRepository _repository;

  /// The order being edited, or null for a new sale.
  final Order? editing;

  /// One token per sale on screen: a retry after a dropped connection sends the same one, so the
  /// server writes the order once. The screen closes once a sale has gone through.
  final String _clientToken = uuidV4();

  int _lookup = 0;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));

    final result = await _repository.branches();

    if (isClosed) return;

    await result.fold(
      (failure) async => emit(state.copyWith(isLoading: false, loadFailure: failure)),
      (branches) async {
        final order = editing;

        // An edit stays at its branch; a new sale opens on the only branch, if there is one.
        final branchId = order != null
            ? order.cityId
            : (branches.length == 1 ? branches.single.id : null);

        emit(
          state.copyWith(
            isLoading: false,
            branches: order != null && branches.every((b) => b.id != order.cityId)
                ? [...branches, SellingBranch(id: order.cityId, name: order.cityName)]
                : branches,
            branchId: branchId,
            lines: order == null ? null : _linesOf(order),
          ),
        );

        if (branchId != null) await _loadCatalogue(branchId);
      },
    );
  }

  Future<void> chooseBranch(int branchId) async {
    if (editing != null || branchId == state.branchId) return;

    emit(state.copyWith(branchId: branchId, clearSubmitFailure: true));

    await _loadCatalogue(branchId);
  }

  Future<void> _loadCatalogue(int branchId) async {
    emit(state.copyWith(isLoadingCatalogue: true));

    final result = await _repository.products(branchId);

    if (isClosed || state.branchId != branchId) return;

    result.fold(
      (failure) => emit(state.copyWith(isLoadingCatalogue: false, submitFailure: failure)),
      (catalogue) => emit(state.copyWith(isLoadingCatalogue: false, catalogue: catalogue)),
    );
  }

  /// Looks the phone up. An answer for an older number is dropped.
  Future<void> lookUp(String phone) async {
    final request = ++_lookup;

    if (phone.trim().length < 9) {
      emit(state.copyWith(clearCustomer: true, isLookingUp: false));

      return;
    }

    emit(state.copyWith(isLookingUp: true));

    final result = await _repository.findCustomer(phone.trim());

    if (isClosed || request != _lookup) return;

    result.fold(
      (_) => emit(state.copyWith(isLookingUp: false, clearCustomer: true)),
      (customer) => emit(
        customer == null
            ? state.copyWith(isLookingUp: false, clearCustomer: true)
            : state.copyWith(isLookingUp: false, customer: customer),
      ),
    );
  }

  /// Adds a size, or adds to its line when it is already on the order.
  void addLine(InstantProduct product, InstantVariant variant, double quantity) {
    final lines = [...state.lines];
    final index = lines.indexWhere((line) => line.variantId == variant.id);

    if (index >= 0) {
      lines[index] = lines[index].withQuantity(lines[index].quantity + quantity);
    } else {
      lines.add(
        InstantLine(
          productId: product.id,
          variantId: variant.id,
          productName: product.name,
          variantLabel: variant.label,
          unitLabel: product.unitLabel,
          quantity: quantity,
        ),
      );
    }

    emit(state.copyWith(lines: lines, clearSubmitFailure: true));
  }

  void setQuantity(int index, double quantity) {
    final lines = [...state.lines];
    lines[index] = lines[index].withQuantity(quantity);

    emit(state.copyWith(lines: lines, clearSubmitFailure: true));
  }

  void removeLine(int index) {
    emit(state.copyWith(lines: [...state.lines]..removeAt(index), clearSubmitFailure: true));
  }

  /// What the shelf can give this size — the free stock, plus what this order already holds
  /// when it is being edited.
  double availableFor(int variantId) {
    final free = state.catalogue?.find(variantId)?.variant.available ?? 0;

    return free + (_heldByOrder[variantId] ?? 0);
  }

  /// The sentence under a line that asks more than the shelf has, or null.
  String? shortfallFor(InstantLine line) {
    final asked = state.lines
        .where((other) => other.variantId == line.variantId)
        .fold<double>(0, (sum, other) => sum + other.quantity);
    final available = availableFor(line.variantId);

    if (state.catalogue == null || asked <= available) return null;

    return 'الكمية غير متوفرة — المتاح ${_figure(available)} ${line.unitLabel}';
  }

  /// The lines' estimated total before the discount. The server prices the order itself.
  double get estimatedTotal => state.lines.fold<double>(0, (sum, line) {
    final variant = state.catalogue?.find(line.variantId)?.variant;
    final price = variant?.unitPriceFor(line.quantity) ?? 0;

    return sum + price * line.quantity;
  });

  bool get hasShortfall => state.lines.any((line) => shortfallFor(line) != null);

  Future<void> submit({
    required String phone,
    required String name,
    required int? cityId,
    required int? regionId,
    required int discount,
    required String? notes,
  }) async {
    final branchId = state.branchId;
    final order = editing;

    if (state.isSubmitting || branchId == null || state.lines.isEmpty) return;

    emit(state.copyWith(isSubmitting: true, clearSubmitFailure: true));

    if (order != null) {
      final result = await _repository.update(
        order.id,
        lines: state.lines,
        discount: discount,
        notes: notes,
      );

      if (isClosed) return;

      result.fold(
        (failure) => emit(state.copyWith(isSubmitting: false, submitFailure: failure)),
        (saved) => emit(state.copyWith(isSubmitting: false, updated: saved)),
      );

      return;
    }

    final result = await _repository.create(
      clientToken: _clientToken,
      branchId: branchId,
      phone: phone,
      name: name,
      cityId: cityId,
      regionId: regionId,
      lines: state.lines,
      discount: discount,
      notes: notes,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(isSubmitting: false, submitFailure: failure)),
      (taken) => emit(state.copyWith(isSubmitting: false, result: taken)),
    );
  }

  Map<int, double> get _heldByOrder {
    final order = editing;
    if (order == null) return const {};

    final held = <int, double>{};

    for (final item in order.items ?? const <OrderItem>[]) {
      held[item.productVariantId] =
          (held[item.productVariantId] ?? 0) + (double.tryParse(item.quantity) ?? 0);
    }

    return held;
  }

  static List<InstantLine> _linesOf(Order order) => [
    for (final item in order.items ?? const <OrderItem>[])
      InstantLine(
        lineId: item.id,
        productId: item.productId,
        variantId: item.productVariantId,
        productName: item.productName,
        variantLabel: item.variantLabel,
        unitLabel: item.pricingUnitLabel,
        quantity: double.tryParse(item.quantity) ?? 0,
      ),
  ];

  static String _figure(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();
}
