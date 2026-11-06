import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'credit_categories_cubit.freezed.dart';
part 'credit_categories_state.dart';

/// التصنيفات التي يصلح عليها «مستحق» — خانة ورقة الإيداع.
///
/// **لا تصنيف نظامٍ سوى «رواتب»**، وهي قاعدة الخادم نفسها (§١٠): عرضُ «سلفة موظف» هنا ثم رفضُها بعد
/// الضغط زرٌّ يعد بما لا يكون.
class CreditCategoriesCubit extends Cubit<CreditCategoriesState> {
  CreditCategoriesCubit({required GetExpenseCategories getCategories})
    : _getCategories = getCategories,
      super(const CreditCategoriesState.loading());

  final GetExpenseCategories _getCategories;

  Future<void> load() async {
    if (state is CreditCategoriesFailed) emit(const CreditCategoriesState.loading());

    final result = await _getCategories();

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => CreditCategoriesState.failed(failure),
        (categories) => CreditCategoriesState.loaded([
          for (final category in categories)
            if (category.fitsEmployeeCredit) category,
        ]),
      ),
    );
  }
}
