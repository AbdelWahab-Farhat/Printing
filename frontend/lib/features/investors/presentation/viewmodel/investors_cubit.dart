import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';

/// The investors list. Everything about paging, debouncing and out-of-order responses comes
/// from [PagedCubit]; this only says what a page is.
class InvestorsCubit extends PagedCubit<Investor> {
  InvestorsCubit({required GetInvestors getInvestors}) : _getInvestors = getInvestors;

  final GetInvestors _getInvestors;

  /// The row's identity for de-duplication across pages — see [PagedCubit].
  @override
  Object identityOf(Investor item) => item.id;

  @override
  Future<Either<Failure, Paginated<Investor>>> fetchPage({
    String? search,
    required int page,
  }) => _getInvestors(search: search, page: page);
}
