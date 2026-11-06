import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:dayaa/features/employee_wallet/usecases/employee_wallet_usecases.dart';

/// سجلٌّ من [EmployeeWalletLedger]: محفظةُ موظف، أو كل المحافظ، أو «محفظتي». الأحدث أولاً، ويُقصر
/// على نوعٍ بـ[filter] وعلى مدى أيام.
///
/// **يُرقَّع ولا يُعاد**، كسجلّ محفظة العميل: كتابةٌ تعود بسطرها فيُضاف أعلاه ([addWritten])،
/// والعكسُ يشطب أصله في مكانه ويضيف سطره ([reverse])، وتبقى الصفحات المحمّلة ومكانُ التمرير.
class EmployeeWalletEntriesCubit extends PagedCubit<EmployeeWalletEntry> {
  EmployeeWalletEntriesCubit({
    required this.ledger,
    required GetEmployeeWalletEntries getEntries,
    required ReverseEmployeeWalletEntry reverseEntry,
  }) : _getEntries = getEntries,
       _reverseEntry = reverseEntry;

  final EmployeeWalletLedger ledger;
  final GetEmployeeWalletEntries _getEntries;
  final ReverseEmployeeWalletEntry _reverseEntry;

  EmployeeWalletEntryFilter filter = EmployeeWalletEntryFilter.all;

  /// مدى الأيام، كسجلّ محفظة العميل — `null` في الطرفين: كلُّ الأيام.
  DateTime? from;
  DateTime? to;

  /// فلترٌ آخر — والبحثُ المكتوب يبقى معه.
  Future<void> narrowTo(EmployeeWalletEntryFilter value) {
    if (value == filter) return Future<void>.value();

    filter = value;

    return load(search: currentSearch);
  }

  /// مدى أيامٍ آخر، أو (null، null) لكلّ الأيام.
  Future<void> between(DateTime? start, DateTime? end) {
    from = start;
    to = end;

    return load(search: currentSearch);
  }

  /// سطرٌ كتبته الصفحة أعلى السجل.
  void addWritten(EmployeeWalletEntry entry) => insert(entry);

  /// يعكس السطر: يُشطب أصله في مكانه، ويُضاف سطرُ العكس. يعود بالرصيد بعده لرأس الصفحة.
  Future<Either<Failure, EmployeeWalletWrite>> reverse(
    EmployeeWalletEntry original, {
    required String reason,
  }) async {
    final result = await _reverseEntry(original.id, reason: reason);

    result.fold((_) {}, (write) {
      replace(original.markedReversed(reason));
      insert(write.entry);
    });

    return result;
  }

  @override
  Object identityOf(EmployeeWalletEntry item) => item.id;

  @override
  bool belongs(EmployeeWalletEntry item) => filter.covers(item);

  @override
  Future<Either<Failure, Paginated<EmployeeWalletEntry>>> fetchPage({
    String? search,
    required int page,
  }) => _getEntries(ledger, page: page, filter: filter, search: search, from: from, to: to);
}

typedef EmployeeWalletEntriesState = PagedState<EmployeeWalletEntry>;
