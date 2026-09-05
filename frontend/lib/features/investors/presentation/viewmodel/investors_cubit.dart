import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';

/// The investors list, optionally narrowed to the people still being dealt with.
///
/// Everything about paging, debouncing and out-of-order responses comes from [PagedCubit]; this
/// only says what a page is and which people are in it.
class InvestorsCubit extends PagedCubit<Investor> {
  InvestorsCubit({required GetInvestors getInvestors}) : _getInvestors = getInvestors;

  final GetInvestors _getInvestors;

  bool? _isActive;

  /// Narrow the list and start again from page one.
  ///
  /// Through the base class's own `load()` rather than by re-fetching here, so the out-of-order
  /// guard still applies to a filter change exactly as it does to typing.
  void filter({bool? isActive}) {
    _isActive = isActive;
    refresh();
  }

  /// The row's identity for de-duplication across pages — see [PagedCubit].
  @override
  Object identityOf(Investor item) => item.id;

  /// An investor only belongs on the list the current filter asked for.
  ///
  /// The picker narrows to the active ones, and the base class keeps everything by default — so
  /// without this, a stopped investor patched into that list would sit there until the next read
  /// and then vanish with nothing to explain it. The same gap the deals list had.
  @override
  bool belongs(Investor item) => _isActive == null || item.isActive == _isActive;

  @override
  Future<Either<Failure, Paginated<Investor>>> fetchPage({
    String? search,
    required int page,
  }) => _getInvestors(search: search, isActive: _isActive, page: page);
}
