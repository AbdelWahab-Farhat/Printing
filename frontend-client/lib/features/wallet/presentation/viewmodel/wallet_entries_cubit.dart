import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/pagination/paged_cubit.dart';
import 'package:dayaa_client/core/pagination/paged_state.dart';
import 'package:dayaa_client/features/wallet/models/wallet_models.dart';
import 'package:dayaa_client/features/wallet/usecases/wallet_usecases.dart';

/// «محفظتي»: المعاملات، الأحدث أولاً، ورصيدها — يصل في `meta.balance` مع كل صفحة، فلا طلبَ ثانٍ
/// للرأس. يُقصر على نوعٍ بـ[filter].
class WalletEntriesCubit extends PagedCubit<MyWalletEntry> {
  WalletEntriesCubit({required GetWalletEntries getEntries}) : _getEntries = getEntries;

  final GetWalletEntries _getEntries;

  MyWalletFilter filter = MyWalletFilter.all;

  Future<void> narrowTo(MyWalletFilter value) {
    if (value == filter) return Future<void>.value();

    filter = value;

    return load();
  }

  /// الرصيد كما قاله الخادم مع آخر صفحة، أو null قبل أن تصل.
  String? get balance => switch (state) {
    PagedLoaded<MyWalletEntry>(:final page) => walletBalanceIn(page.extraMeta),
    _ => null,
  };

  @override
  Object identityOf(MyWalletEntry item) => item.id;

  @override
  Future<Either<Failure, Paginated<MyWalletEntry>>> fetchPage({String? search, required int page}) =>
      _getEntries(page: page, filter: filter);
}

typedef WalletEntriesState = PagedState<MyWalletEntry>;
