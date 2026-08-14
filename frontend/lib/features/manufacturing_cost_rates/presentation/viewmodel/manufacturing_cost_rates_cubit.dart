import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/manufacturing_cost_rates/models/manufacturing_cost_rate.dart';
import 'package:dayaa/features/manufacturing_cost_rates/usecases/manufacturing_cost_rate_usecases.dart';

/// معدلات تكلفة التصنيع — the management screen's ViewModel.
///
/// The debounce, the out-of-order guard, appending pages and keeping the list when a page fails
/// all come from [PagedCubit]. What is added here is the filter the screen offers and the two
/// things the list can do to a row.
///
/// **There is no text search**, because the endpoint has none: a rate has no name — it is a kind
/// of cost pinned to a rung — and a box that filtered nothing would be worse than no box. So
/// [fetchPage] takes the `search` the base class hands it and ignores it.
///
/// **The list is never narrowed to one product either**, though the API would allow it: the
/// default rate is *also* part of a product's answer, and hiding it would make the ladder read as
/// though that product had no labour cost at all.
///
/// **Both row actions reload rather than patch in place.** Stopping a rate changes what a
/// filtered list should contain and deleting one changes the paging; a locally edited copy would
/// disagree with the server the moment either happened.
class ManufacturingCostRatesCubit extends PagedCubit<ManufacturingCostRate> {
  ManufacturingCostRatesCubit({
    required GetManufacturingCostRates getRates,
    required SetManufacturingCostRateActivation setRateActivation,
    required DeleteManufacturingCostRate deleteRate,
  }) : _getRates = getRates,
       _setRateActivation = setRateActivation,
       _deleteRate = deleteRate;

  final GetManufacturingCostRates _getRates;
  final SetManufacturingCostRateActivation _setRateActivation;
  final DeleteManufacturingCostRate _deleteRate;

  /// Which kind of cost the list is narrowed to. `null` — the default — shows all of them.
  ManufacturingCostType? costType;

  /// `null` shows the stopped rates too, which is what a screen for *curating* the table has to
  /// do: a rate somebody stopped last month is exactly the one they come back to look for.
  bool? isActive;

  /// Whether the list is showing everything it could.
  bool get isFiltered => costType != null || isActive != null;

  @override
  Future<Either<Failure, Paginated<ManufacturingCostRate>>> fetchPage({
    String? search,
    required int page,
  }) {
    // The filter rides along with every page, including the ones `loadMore` asks for.
    return _getRates(costType: costType, isActive: isActive, page: page);
  }

  /// Both axes at once, because the sheet answers them together — two methods would fetch the
  /// list twice for one tap on «تطبيق».
  Future<void> filterBy({
    required ManufacturingCostType? costType,
    required bool? isActive,
  }) async {
    if (costType == this.costType && isActive == this.isActive) return;

    this.costType = costType;
    this.isActive = isActive;
    await load();
  }

  /// Stops a rate applying, or starts it again.
  ///
  /// Answers with the failure so the screen can say why nothing changed; `null` means it did.
  Future<Failure?> setActivation(
    ManufacturingCostRate rate, {
    required bool isActive,
  }) async {
    final result = await _setRateActivation(rate.id, isActive: isActive);

    if (isClosed) return null;

    final failure = result.fold<Failure?>((failure) => failure, (_) => null);
    if (failure == null) await refresh();

    return failure;
  }

  /// Removes a rate from the table.
  Future<Failure?> remove(ManufacturingCostRate rate) async {
    final result = await _deleteRate(rate.id);

    if (isClosed) return null;

    final failure = result.fold<Failure?>((failure) => failure, (_) => null);
    if (failure == null) await refresh();

    return failure;
  }
}

/// The state this screen switches on. A name for `PagedState<ManufacturingCostRate>`, so the view
/// reads as a rates screen while there is one implementation behind every list in the app.
typedef ManufacturingCostRatesState = PagedState<ManufacturingCostRate>;
typedef ManufacturingCostRatesInitial = PagedInitial<ManufacturingCostRate>;
typedef ManufacturingCostRatesLoading = PagedLoading<ManufacturingCostRate>;
typedef ManufacturingCostRatesLoaded = PagedLoaded<ManufacturingCostRate>;
typedef ManufacturingCostRatesFailure = PagedFailure<ManufacturingCostRate>;
