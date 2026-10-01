import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «تصنيفات المصروفات» — كلُّ التصنيفات، والموقوفةُ منها كذلك، تُضاف وتُسمّى وتُوقف.
///
/// **الحفظُ يرقّع القائمة ولا يعيد تحميلها**: الخادمُ يعيد التصنيفَ كما حفظه، فيحلّ مكانَ
/// صفّه — أو يُلحق بآخرها إن كان جديداً — بلا طلبٍ ثانٍ.
class ExpenseCategoriesCubit extends Cubit<ExpenseCategoriesState> {
  ExpenseCategoriesCubit({
    required GetExpenseCategories getCategories,
    required SaveExpenseCategory saveCategory,
  }) : _getCategories = getCategories,
       _saveCategory = saveCategory,
       super(const ExpenseCategoriesLoading());

  final GetExpenseCategories _getCategories;
  final SaveExpenseCategory _saveCategory;

  Future<void> load() async {
    final result = await _getCategories(activeOnly: false);

    if (isClosed) return;

    emit(
      result.fold(
        ExpenseCategoriesFailed.new,
        (categories) => ExpenseCategoriesLoaded(categories),
      ),
    );
  }

  /// يعيد الفشلَ ليُعرض، ولا شيء عند النجاح — الصفُّ يتبدّل وحده.
  Future<Failure?> save({
    int? id,
    required String name,
    bool? requiresEmployee,
    bool? isActive,
  }) async {
    final result = await _saveCategory(
      id: id,
      name: name,
      requiresEmployee: requiresEmployee,
      isActive: isActive,
    );

    return result.fold((failure) => failure, (saved) {
      if (state case ExpenseCategoriesLoaded(:final categories) when !isClosed) {
        final known = categories.any((c) => c.id == saved.id);

        emit(
          ExpenseCategoriesLoaded([
            for (final c in categories) c.id == saved.id ? saved : c,
            if (!known) saved,
          ]),
        );
      }

      return null;
    });
  }
}

sealed class ExpenseCategoriesState {
  const ExpenseCategoriesState();
}

final class ExpenseCategoriesLoading extends ExpenseCategoriesState {
  const ExpenseCategoriesLoading();
}

final class ExpenseCategoriesFailed extends ExpenseCategoriesState {
  const ExpenseCategoriesFailed(this.failure);

  final Failure failure;
}

final class ExpenseCategoriesLoaded extends ExpenseCategoriesState {
  const ExpenseCategoriesLoaded(this.categories);

  final List<ExpenseCategory> categories;
}
