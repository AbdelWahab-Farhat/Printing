import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/features/investment_pools/models/investment_pool.dart';
import 'package:dayaa/features/investment_pools/usecases/investment_pool_usecases.dart';

/// The pools list, optionally narrowed to one investor or one shelf.
///
/// **Legacy صفقات never appear here.** The server filters on `kind`, so the two lists cannot leak
/// into each other — this holds no opinion about it and needs none.
class InvestmentPoolsCubit extends PagedCubit<InvestmentPool> {
  InvestmentPoolsCubit({required GetInvestmentPools getPools})
    : _getPools = getPools;

  final GetInvestmentPools _getPools;

  int? _investorId;
  int? _stockItemId;

  /// Narrow the list and start again from page one.
  ///
  /// Through the base class's `refresh()` rather than by re-fetching here, so the debounce and
  /// the out-of-order guard still apply to a filter change exactly as they do to typing.
  void filter({int? investorId, int? stockItemId}) {
    _investorId = investorId;
    _stockItemId = stockItemId;
    refresh();
  }

  @override
  Object identityOf(InvestmentPool item) => item.id;

  @override
  Future<Either<Failure, Paginated<InvestmentPool>>> fetchPage({
    String? search,
    required int page,
  }) => _getPools(
    search: search,
    investorId: _investorId,
    stockItemId: _stockItemId,
    page: page,
  );
}
