import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/stock_items/models/stock_item.dart';
import 'package:dayaa/features/stock_items/models/stock_unit.dart';
import 'package:dayaa/features/stock_items/usecases/save_stock_item.dart';
import 'package:dayaa/features/stock_items/usecases/set_stock_item_unit.dart';
import 'package:dayaa/features/stock_items/usecases/set_stock_item_variants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'save_stock_item_cubit.freezed.dart';
part 'save_stock_item_state.dart';

/// The ViewModel behind the stock item form.
///
/// It holds no draft: the form owns its controllers, because those are widget-lifecycle resources
/// that have to be disposed, and a Cubit is not a disposal mechanism.
///
/// **Two writes live here, and they are deliberately not one.** [submit] corrects a record;
/// [changeUnit] performs an act that empties every warehouse holding the item. They travel to two
/// endpoints, they end in two different places on the screen — a save closes the form, a unit
/// change stays on it and shows what the shelf now says — and while either is in flight only its
/// own control may spin. Folding them into one `submitting` case is how the save button ends up
/// turning while somebody is answering a dialog about zeroing a balance.
class SaveStockItemCubit extends Cubit<SaveStockItemState> {
  SaveStockItemCubit({
    required SaveStockItem saveStockItem,
    required SetStockItemUnit setStockItemUnit,
    required SetStockItemVariants setStockItemVariants,
  }) : _saveStockItem = saveStockItem,
       _setStockItemUnit = setStockItemUnit,
       _setStockItemVariants = setStockItemVariants,
       super(const SaveStockItemState.initial());

  final SaveStockItem _saveStockItem;
  final SetStockItemUnit _setStockItemUnit;
  final SetStockItemVariants _setStockItemVariants;

  /// Adds a shelf, or corrects one.
  ///
  /// [unit] is only ever sent when [stockItemId] is null — the API carries no rule for it on an
  /// update — but it is taken on both paths so the form can hand over what it is showing without
  /// deciding which call it is making.
  Future<void> submit({
    int? stockItemId,
    int? stockItemGroupId,
    required String name,
    String? widthCm,
    String? heightCm,
    required StockUnit unit,
    String? description,
    required bool isActive,
    required int sortOrder,
    List<int>? variantIds,
  }) async {
    // Ignored rather than queued: a second tap while the first request is in flight is a second
    // POST, and it comes back as «يوجد صنف مخزني بنفس الاسم والمقاس» against the row the first
    // one just wrote.
    if (state.isBusy) return;

    emit(const SaveStockItemState.submitting());

    final result = await _saveStockItem(
      stockItemId: stockItemId,
      stockItemGroupId: stockItemGroupId,
      name: name,
      widthCm: widthCm,
      heightCm: heightCm,
      unit: unit,
      description: description,
      isActive: isActive,
      sortOrder: sortOrder,
    );

    // The form may have been popped while the request was in flight.
    if (isClosed) return;

    // **The links go second, and only if the material was stored.** On a new material there is no
    // id to point anything at until the first call answers, so the order is forced rather than
    // chosen — and it is the safe one either way: a link list can be re-sent, typing cannot.
    if (result case Right(value: final item) when variantIds != null) {
      await _pointVariants(item, variantIds);

      return;
    }

    emit(result.fold((f) => SaveStockItemState.failure(f), (i) => SaveStockItemState.success(i)));
  }

  /// The second half of a save: which product sizes draw on the material that was just stored.
  ///
  /// **A failure here does not undo the material.** It exists, correctly, with everything that
  /// was typed into it; what did not happen is the rewiring. So the form stays open on the
  /// selection and says so — see [SaveStockItemState.linksRefused] — rather than reporting a
  /// failure that would read as «nothing was saved» and send somebody to type it all again.
  Future<void> _pointVariants(StockItem item, List<int> variantIds) async {
    final linked = await _setStockItemVariants(item.id, variantIds);

    if (isClosed) return;

    emit(
      linked.fold(
        (f) => SaveStockItemState.linksRefused(item, f),
        SaveStockItemState.success,
      ),
    );
  }

  /// Changes what the pile is counted in — **after somebody has been told the balance will be
  /// zeroed, and has agreed**.
  ///
  /// The warning is the sheet's job rather than this one's, because a Cubit that put a dialog on
  /// the screen would be a Cubit no test could reach. What is enforced here is narrower and still
  /// worth having: nothing may be sent while another write is in flight, so the act cannot be
  /// fired twice by an impatient second tap on a shelf whose balances are already being emptied.
  Future<void> changeUnit(int stockItemId, {required StockUnit unit}) async {
    if (state.isBusy) return;

    emit(const SaveStockItemState.changingUnit());

    final result = await _setStockItemUnit(stockItemId, unit: unit);

    if (isClosed) return;

    emit(
      result.fold((f) => SaveStockItemState.failure(f), (i) => SaveStockItemState.unitChanged(i)),
    );
  }

  /// Clears a previous failure so the error under a field disappears as the user corrects it.
  void clearFailure() {
    if (state is SaveStockItemFailure) emit(const SaveStockItemState.initial());
  }
}
