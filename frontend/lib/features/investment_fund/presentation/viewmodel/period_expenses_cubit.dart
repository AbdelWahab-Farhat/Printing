import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investment_fund/models/period_expenses.dart';
import 'package:dayaa/features/investment_fund/usecases/period_expenses_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'period_expenses_cubit.freezed.dart';

/// تبويبُ «المصاريف» في شاشة الفترة: مصاريفُها وما تحمّله المستثمرون منها.
class PeriodExpensesCubit extends Cubit<PeriodExpensesState> {
  PeriodExpensesCubit({
    required int periodId,
    required GetPeriodExpenses getExpenses,
    required ReverseFundExpense reverseExpense,
  }) : _periodId = periodId,
       _getExpenses = getExpenses,
       _reverseExpense = reverseExpense,
       super(const PeriodExpensesState.loading());

  final int _periodId;
  final GetPeriodExpenses _getExpenses;
  final ReverseFundExpense _reverseExpense;

  Future<void> load() async {
    emit(const PeriodExpensesState.loading());

    final result = await _getExpenses(_periodId);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => PeriodExpensesState.failure(failure),
        (loaded) => PeriodExpensesState.loaded(loaded),
      ),
    );
  }

  /// يعكس المصروف ثم يُعاد التبويب — المجاميعُ وحالُ السطر يقولها الخادم لا هذا الفعل.
  Future<Failure?> reverse(PeriodExpense expense, {required String reason}) async {
    final result = await _reverseExpense(expense.id, reason: reason);

    return result.fold((failure) => failure, (_) async {
      await load();

      return null;
    });
  }
}

@freezed
sealed class PeriodExpensesState with _$PeriodExpensesState {
  const factory PeriodExpensesState.loading() = PeriodExpensesLoading;

  const factory PeriodExpensesState.loaded(PeriodExpenses held) = PeriodExpensesLoaded;

  const factory PeriodExpensesState.failure(Failure failure) = PeriodExpensesFailure;
}
