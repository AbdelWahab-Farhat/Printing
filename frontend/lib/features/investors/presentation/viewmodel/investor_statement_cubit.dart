import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/investors/models/wallet_entry.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';

/// سجلُّ حركات مستثمرٍ واحد — الأحدثُ أوّلاً، بعائلةٍ ومدى أيامٍ اختياريَّين.
///
/// **الفلترُ يُرسل إلى الخادم ولا يُطبَّق على الصفحة.** الصفحةُ خمسةٌ وعشرون صفّاً من دفترٍ قد
/// يطول سنين؛ فلترتُها هنا كانت ستقول «لا أرباح» عن رجلٍ أرباحُه في الصفحة الثالثة.
class InvestorStatementCubit extends PagedCubit<WalletEntry> {
  InvestorStatementCubit({
    required GetInvestorStatement getStatement,
    required ReverseWalletEntry reverseEntry,
  }) : _getStatement = getStatement,
       _reverseEntry = reverseEntry;

  final GetInvestorStatement _getStatement;
  final ReverseWalletEntry _reverseEntry;

  late final int _investorId;

  WalletEntryCategory? _category;
  DateTime? _from;
  DateTime? _to;

  WalletEntryCategory? get category => _category;
  DateTime? get from => _from;
  DateTime? get to => _to;

  /// Whose movements — set once, when the screen opens.
  Future<void> open(int investorId) {
    _investorId = investorId;

    return load();
  }

  /// `null` is every family. Picking the one already picked is a no-op, not a reload.
  Future<void> filterBy(WalletEntryCategory? category) async {
    if (category == _category) return;
    _category = category;

    return load();
  }

  /// Both ends inclusive; both `null` clears the range.
  Future<void> between(DateTime? from, DateTime? to) {
    _from = from;
    _to = to;

    return load();
  }

  /// Undoes one row. Answers the failure, or `null` when it went through.
  ///
  /// **Re-reads rather than patching.** Undoing a row writes a second one and flips the first —
  /// two rows change, and the new one's label and position are the server's to decide.
  Future<Failure?> reverse(WalletEntry entry, {String? notes}) async {
    final result = await _reverseEntry(
      investorId: _investorId,
      entryId: entry.id,
      notes: notes,
    );

    return result.fold((failure) => failure, (_) {
      unawaited(refresh());

      return null;
    });
  }

  @override
  Object identityOf(WalletEntry item) => item.id;

  @override
  Future<Either<Failure, Paginated<WalletEntry>>> fetchPage({
    String? search,
    required int page,
  }) => _getStatement(_investorId, category: _category, from: _from, to: _to, page: page);
}

typedef InvestorStatementState = PagedState<WalletEntry>;
typedef InvestorStatementLoaded = PagedLoaded<WalletEntry>;
