import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/wallet/models/wallet_models.dart';
import 'package:dayaa/features/wallet/usecases/wallet_usecases.dart';

/// سجلّ محفظةٍ واحدة — أو، بلا [customerId]، «المعاملات المالية»: كل المحافظ في صفحة، يُبحث فيها
/// باسم العميل أو هاتفه أو رمزه. الأحدث أولاً، ويُقصر على نوعٍ بـ[filter].
///
/// **يُرقَّع ولا يُعاد**، كسجلّ الحساب: كتابةٌ تعود بسطرها فيُضاف أعلاه ([addWritten])، والعكسُ يشطب
/// أصله في مكانه ويضيف سطره ([reverse]) — وتبقى الصفحات المحمّلة ومكانُ التمرير.
class WalletEntriesCubit extends PagedCubit<CustomerWalletEntry> {
  WalletEntriesCubit({
    this.customerId,
    required GetCustomerWalletEntries getEntries,
    required ReverseCustomerWalletEntry reverseEntry,
  }) : _getEntries = getEntries,
       _reverseEntry = reverseEntry;

  /// null: «المعاملات المالية» — كل المحافظ.
  final int? customerId;
  final GetCustomerWalletEntries _getEntries;
  final ReverseCustomerWalletEntry _reverseEntry;

  WalletEntryFilter filter = WalletEntryFilter.all;

  /// مدى الأيام، كسجلّ حركات المستثمر — `null` في الطرفين: كلُّ الأيام.
  DateTime? from;
  DateTime? to;

  /// فلترٌ آخر — والبحثُ المكتوب يبقى معه.
  Future<void> narrowTo(WalletEntryFilter value) {
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

  /// سطرٌ كتبته الصفحة — شحنٌ أو تعديل — أعلى السجل.
  void addWritten(CustomerWalletEntry entry) => insert(entry);

  /// يعكس السطر: يُشطب أصله في مكانه، ويُضاف سطرُ العكس. يعود بالرصيد بعده لرأس الصفحة.
  Future<Either<Failure, WalletWrite>> reverse(CustomerWalletEntry original, {required String reason}) async {
    final result = await _reverseEntry(original.id, reason: reason);

    result.fold((_) {}, (write) {
      replace(original.markedReversed(reason: reason));
      insert(write.entry);
    });

    return result;
  }

  @override
  Object identityOf(CustomerWalletEntry item) => item.id;

  @override
  bool belongs(CustomerWalletEntry item) => filter.wire == null || item.type == filter.wire;

  @override
  Future<Either<Failure, Paginated<CustomerWalletEntry>>> fetchPage({String? search, required int page}) =>
      _getEntries(
        customerId: customerId,
        page: page,
        filter: filter,
        search: search,
        from: from,
        to: to,
      );
}

typedef WalletEntriesState = PagedState<CustomerWalletEntry>;
