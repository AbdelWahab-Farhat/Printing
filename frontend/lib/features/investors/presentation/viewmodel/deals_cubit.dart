import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/features/investors/models/investor_deal.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';

/// The deals list, optionally narrowed to one status or one investor.
class DealsCubit extends PagedCubit<InvestorDeal> {
  DealsCubit({required GetInvestorDeals getDeals}) : _getDeals = getDeals;

  final GetInvestorDeals _getDeals;

  String? _status;
  int? _investorId;

  /// Narrow the list and start again from page one.
  ///
  /// Through the base class's own `search()` rather than by re-fetching here, so the debounce
  /// and the out-of-order guard still apply to a filter change exactly as they do to typing.
  void filter({String? status, int? investorId}) {
    _status = status;
    _investorId = investorId;
    refresh();
  }

  String? get status => _status;

  @override
  Object identityOf(InvestorDeal item) => item.id;

  @override
  Future<Either<Failure, Paginated<InvestorDeal>>> fetchPage({
    String? search,
    required int page,
  }) => _getDeals(search: search, status: _status, investorId: _investorId, page: page);
}
