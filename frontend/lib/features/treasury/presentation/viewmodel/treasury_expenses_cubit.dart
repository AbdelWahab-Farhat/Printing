import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';

/// «المصاريف» — مصاريف كل الحسابات في تبويبٍ واحد، فلا يُفتح كل حسابٍ ليُعرف ما خرج منه.
/// TREASURY-DESIGN §٢١.
///
/// يبدأ على «هذا الشهر»، ويُقصر بالفترة والتصنيف والحساب — كلُّها على الخادم، ومعها المجموع
/// ([total]) الذي يحسبه الخادم على الفترة كلها لا على الصفحة المحمّلة.
///
/// **يُعاد ولا يُرقَّع** بعد مصروفٍ جديد أو عكس: كلاهما يغيّر المجموع، والمجموع جوابُ الخادم.
class TreasuryExpensesCubit extends PagedCubit<TreasuryMovement> {
  TreasuryExpensesCubit({
    required GetTreasuryExpenses getExpenses,
    required GetExpenseCategories getCategories,
    required ReverseTreasuryOperation reverseOperation,
    DateTime Function()? now,
  }) : _getExpenses = getExpenses,
       _getCategories = getCategories,
       _reverseOperation = reverseOperation,
       _now = now ?? DateTime.now;

  final GetTreasuryExpenses _getExpenses;
  final GetExpenseCategories _getCategories;
  final ReverseTreasuryOperation _reverseOperation;
  final DateTime Function() _now;

  ExpensePeriod period = ExpensePeriod.thisMonth;

  /// تاريخا «من – إلى»، حين تكون [period] هي.
  ({DateTime from, DateTime to})? customRange;

  ExpenseCategory? category;
  TreasuryAccount? account;

  /// المجموع كما قاله الخادم للفترة المصفّاة، و«0.00» قبل أن يجيب.
  String get total => switch (state) {
    PagedLoaded(:final page) => '${page.extraMeta['expenses_total'] ?? '0.00'}',
    _ => '0.00',
  };

  /// أول يومٍ وآخره لما يُعرض الآن، أو `null` لـ«الكل».
  ({DateTime from, DateTime to})? get range => switch (period) {
    ExpensePeriod.custom => customRange,
    _ => period.rangeAt(_now()),
  };

  /// [between] لـ«من – إلى» وحدها، وتغيّره يُعيد القراءة ولو بقيت الفترة «من – إلى».
  Future<void> showPeriod(ExpensePeriod value, {({DateTime from, DateTime to})? between}) {
    if (value == period && between == null) return Future<void>.value();

    period = value;
    customRange = value == ExpensePeriod.custom ? between : null;

    return load();
  }

  Future<void> showCategory(ExpenseCategory? value) {
    if (value?.id == category?.id) return Future<void>.value();

    category = value;

    return load();
  }

  Future<void> showAccount(TreasuryAccount? value) {
    if (value?.id == account?.id) return Future<void>.value();

    account = value;

    return load();
  }

  /// كل التصنيفات، المعطَّل منها أيضاً: مصروفٌ قديم سُجّل تحت تصنيفٍ أُطفئ بعده.
  Future<Either<Failure, List<ExpenseCategory>>> categories() => _getCategories(activeOnly: false);

  /// يعكس عمليةَ المصروف، ثم يُعاد التبويب ليُقرأ المجموع من جديد.
  Future<Failure?> reverse(TreasuryMovement expense, {required String reason}) async {
    final operationId = expense.operationId;

    if (operationId == null) return null;

    final result = await _reverseOperation(operationId, reason: reason);

    return result.fold((failure) => failure, (_) async {
      await refresh();

      return null;
    });
  }

  @override
  Object identityOf(TreasuryMovement item) => item.id;

  @override
  Future<Either<Failure, Paginated<TreasuryMovement>>> fetchPage({
    String? search,
    required int page,
  }) {
    final shown = range;

    return _getExpenses(
      page: page,
      from: shown?.from,
      to: shown?.to,
      categoryId: category?.id,
      accountId: account?.id,
    );
  }
}

typedef TreasuryExpensesState = PagedState<TreasuryMovement>;
