import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/account_picker_cubit.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'treasury_fixtures.dart';

/// منتقي الحساب على نماذج الدفع — يسأل الخادم بحسب الطريقة، ويسمّي ما سيختاره لـ«تلقائي».
///
/// Arrange - Act - Assert throughout.
void main() {
  late MockTreasuryRepository repository;

  const offline = Failure.network(message: FailureMessages.noConnection);

  const cashOptions = AccountOptions(
    accounts: [AccountOption(id: 1, name: 'الخزنة الرئيسية', kindLabel: 'خزنة', isDefault: true)],
    suggestedId: 1,
    suggestedName: 'الخزنة الرئيسية',
  );

  const bankOptions = AccountOptions(
    accounts: [
      AccountOption(id: 2, name: 'المصرف', kindLabel: 'مصرف', isDefault: true),
      AccountOption(id: 5, name: 'مصرف علي', kindLabel: 'مصرف', isDefault: false),
    ],
    suggestedId: 5,
    suggestedName: 'مصرف علي',
  );

  AccountPickerCubit build() => AccountPickerCubit(
    getOptions: GetAccountOptions(repository),
    getAccounts: GetTreasuryAccounts(repository),
  );

  setUp(() {
    repository = MockTreasuryRepository();
  });

  blocTest<AccountPickerCubit, AccountPickerState>(
    'يعرض ما تقبله الطريقة، ومعه اسمُ ما سيختاره الخادم',
    // Arrange
    setUp: () => when(
      () => repository.accountOptions(method: 'bank_transfer', incoming: true, orderId: 12),
    ).thenAnswer((_) async => const Right(bankOptions)),
    build: build,
    // Act
    act: (cubit) => cubit.load(method: 'bank_transfer', incoming: true, orderId: 12),
    // Assert
    expect: () => [
      isA<AccountPickerLoading>(),
      isA<AccountPickerLoaded>().having((s) => s.options, 'options', bankOptions),
    ],
  );

  blocTest<AccountPickerCubit, AccountPickerState>(
    'تغيّرت الطريقة والجوابُ القديم في الطريق: يُهمَل الجوابُ القديم',
    // Arrange — جوابُ الكاش يصل آخراً، بعد جواب المصرف.
    setUp: () {
      final slowCash = Completer<Either<Failure, AccountOptions>>();
      when(
        () => repository.accountOptions(method: 'cash', incoming: true),
      ).thenAnswer((_) => slowCash.future);
      when(
        () => repository.accountOptions(method: 'bank_transfer', incoming: true),
      ).thenAnswer((_) async {
        Future<void>.delayed(Duration.zero, () => slowCash.complete(const Right(cashOptions)));

        return const Right(bankOptions);
      });
    },
    build: build,
    // Act
    act: (cubit) async {
      unawaited(cubit.load(method: 'cash', incoming: true));
      await cubit.load(method: 'bank_transfer', incoming: true);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    },
    // Assert
    expect: () => [
      isA<AccountPickerLoading>(),
      isA<AccountPickerLoaded>().having((s) => s.options, 'options', bankOptions),
    ],
  );

  blocTest<AccountPickerCubit, AccountPickerState>(
    'فشلٌ يُقال، و«إعادة المحاولة» تسأل السؤال نفسه',
    // Arrange
    setUp: () {
      var calls = 0;
      when(() => repository.accountOptions(method: 'cash', incoming: false)).thenAnswer(
        (_) async => calls++ == 0 ? const Left(offline) : const Right(cashOptions),
      );
    },
    build: build,
    // Act
    act: (cubit) async {
      await cubit.load(method: 'cash', incoming: false);
      await cubit.retry();
    },
    // Assert
    expect: () => [
      isA<AccountPickerLoading>(),
      isA<AccountPickerFailed>().having((s) => s.failure, 'failure', offline),
      isA<AccountPickerLoading>(),
      isA<AccountPickerLoaded>().having((s) => s.options, 'options', cashOptions),
    ],
    verify: (_) => verify(
      () => repository.accountOptions(method: 'cash', incoming: false),
    ).called(2),
  );

  blocTest<AccountPickerCubit, AccountPickerState>(
    'نموذجٌ بلا طريقة يعرض كل ما يُصرف منه، و«تلقائي» ما يختاره الخادم للنقد الخارج',
    // Arrange — مصروف صندوق: الخادم يصرف من نقد المسجِّل أولاً.
    setUp: () {
      when(() => repository.accounts(activeOnly: true)).thenAnswer(
        (_) async => const Right(
          TreasuryAccounts(
            accounts: [cashBox, bank, alisBank, nawris],
            total: '400.00',
            canViewAll: true,
          ),
        ),
      );
      when(() => repository.accountOptions(method: 'cash', incoming: false)).thenAnswer(
        (_) async => const Right(
          AccountOptions(accounts: [], suggestedId: 9, suggestedName: 'خزنة علي'),
        ),
      );
    },
    build: build,
    // Act
    act: (cubit) => cubit.load(method: null, incoming: false),
    // Assert
    expect: () => [
      isA<AccountPickerLoading>(),
      isA<AccountPickerLoaded>()
          .having((s) => s.options.accounts.map((a) => a.id).toList(), 'ids', [1, 2, 5])
          .having((s) => s.options.suggestedName, 'suggestedName', 'خزنة علي'),
    ],
  );
}
