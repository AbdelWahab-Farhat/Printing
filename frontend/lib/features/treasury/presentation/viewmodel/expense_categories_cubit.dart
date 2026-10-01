import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// تصنيفاتُ المصروفات، لمكانين: شاشةُ «تصنيفات المصروفات» تديرها، ونموذجُ «مصروف» يختار منها.
///
/// **الشاشةُ ترى كلَّها والنموذجُ المفعّلةَ وحدها** — [includeInactive]: التصنيفُ الموقوف يُعاد
/// تشغيله من الشاشة، ولا يُسجَّل عليه مصروفٌ جديد. والحفظُ للشاشة وحدها، فلا يحتاج النموذجُ
/// [SaveExpenseCategory].
///
/// **الحفظُ يرقّع القائمة ولا يعيد تحميلها**: الخادمُ يعيد التصنيفَ كما حفظه، فيحلّ مكانَ صفّه —
/// أو يُلحق بآخرها إن كان جديداً — بلا طلبٍ ثانٍ. **وفشلُ القراءة يُقال** لا يُبتلع: نموذجٌ قائمةُ
/// تصنيفاته فارغةٌ بلا سبب لا يُسجَّل فيه مصروف، ومن أمامه لا يعرف لماذا.
class ExpenseCategoriesCubit extends Cubit<ExpenseCategoriesState> {
  ExpenseCategoriesCubit({
    required GetExpenseCategories getCategories,
    SaveExpenseCategory? saveCategory,
    this.includeInactive = false,
  }) : _getCategories = getCategories,
       _saveCategory = saveCategory,
       super(const ExpenseCategoriesLoading());

  final GetExpenseCategories _getCategories;
  final SaveExpenseCategory? _saveCategory;

  /// الموقوفةُ أيضاً — للشاشة التي تديرها، لا للنموذج الذي يسجّل عليها.
  final bool includeInactive;

  /// أوّلُ قراءة، وإعادةُ المحاولة بعد فشل.
  Future<void> load() async {
    if (state is ExpenseCategoriesFailed) emit(const ExpenseCategoriesLoading());

    final result = await _getCategories(activeOnly: !includeInactive);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => ExpenseCategoriesFailed(failure),
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
    final saveCategory = _saveCategory;

    if (saveCategory == null) {
      throw StateError('ExpenseCategoriesCubit built without saveCategory cannot save');
    }

    final result = await saveCategory(
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
