part of 'credit_categories_cubit.dart';

@freezed
sealed class CreditCategoriesState with _$CreditCategoriesState {
  const factory CreditCategoriesState.loading() = CreditCategoriesLoading;

  const factory CreditCategoriesState.failed(Failure failure) = CreditCategoriesFailed;

  const factory CreditCategoriesState.loaded(List<ExpenseCategory> categories) =
      CreditCategoriesLoaded;
}
