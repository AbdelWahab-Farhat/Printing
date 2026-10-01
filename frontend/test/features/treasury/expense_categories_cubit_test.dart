import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/expense_categories_cubit.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'treasury_fixtures.dart';

/// تصنيفات نموذج «مصروف» — من Cubit لا من الويدجت، وفشلُها يُقال ويُعاد سؤاله.
///
/// Arrange - Act - Assert throughout.
void main() {
  late MockTreasuryRepository repository;

  const offline = Failure.network(message: FailureMessages.noConnection);

  setUp(() {
    repository = MockTreasuryRepository();
  });

  const rent = ExpenseCategory(
    id: 3,
    name: 'إيجار',
    requiresEmployee: false,
    isActive: true,
    isSystem: false,
  );

  ExpenseCategoriesCubit build() =>
      ExpenseCategoriesCubit(getCategories: GetExpenseCategories(repository));

  blocTest<ExpenseCategoriesCubit, ExpenseCategoriesState>(
    'تُقرأ المفعّلة وحدها',
    // Arrange
    setUp: () => when(
      () => repository.expenseCategories(),
    ).thenAnswer((_) async => const Right([rent])),
    build: build,
    // Act
    act: (cubit) => cubit.load(),
    // Assert
    expect: () => [
      isA<ExpenseCategoriesLoaded>().having((s) => s.categories, 'categories', [rent]),
    ],
  );

  blocTest<ExpenseCategoriesCubit, ExpenseCategoriesState>(
    'فشلُها يُقال، وإعادة المحاولة تسأل من جديد',
    // Arrange
    setUp: () {
      var calls = 0;
      when(() => repository.expenseCategories()).thenAnswer(
        (_) async => calls++ == 0 ? const Left(offline) : const Right([rent]),
      );
    },
    build: build,
    // Act
    act: (cubit) async {
      await cubit.load();
      await cubit.load();
    },
    // Assert
    expect: () => [
      isA<ExpenseCategoriesFailed>().having((s) => s.failure, 'failure', offline),
      isA<ExpenseCategoriesLoading>(),
      isA<ExpenseCategoriesLoaded>(),
    ],
  );
}
