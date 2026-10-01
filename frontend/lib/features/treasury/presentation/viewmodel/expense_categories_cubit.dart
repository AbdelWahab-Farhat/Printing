import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// تصنيفات المصروف المفعّلة، لنموذج «مصروف» — من Cubit لا من الويدجت (RULES §٠).
///
/// **فشلُها يُقال**: نموذجٌ قائمةُ تصنيفاته فارغة بلا سبب لا يُسجَّل فيه مصروف، ومن أمامه لا
/// يعرف لماذا.
class ExpenseCategoriesCubit extends Cubit<ExpenseCategoriesState> {
  ExpenseCategoriesCubit({required GetExpenseCategories getCategories})
    : _getCategories = getCategories,
      super(const ExpenseCategoriesLoading());

  final GetExpenseCategories _getCategories;

  /// أول قراءة، وإعادة المحاولة بعد فشل.
  Future<void> load() async {
    if (state is ExpenseCategoriesFailed) emit(const ExpenseCategoriesLoading());

    final result = await _getCategories();

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => ExpenseCategoriesFailed(failure),
        (categories) => ExpenseCategoriesLoaded(categories),
      ),
    );
  }
}

sealed class ExpenseCategoriesState {
  const ExpenseCategoriesState();
}

final class ExpenseCategoriesLoading extends ExpenseCategoriesState {
  const ExpenseCategoriesLoading();
}

final class ExpenseCategoriesLoaded extends ExpenseCategoriesState {
  const ExpenseCategoriesLoaded(this.categories);

  final List<ExpenseCategory> categories;
}

final class ExpenseCategoriesFailed extends ExpenseCategoriesState {
  const ExpenseCategoriesFailed(this.failure);

  final Failure failure;
}
