import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/account_change.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/treasury_cubit.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'treasury_fixtures.dart';

/// لوحة الحسابات — TREASURY-DESIGN §٩.
///
/// Arrange - Act - Assert throughout.
void main() {
  late MockTreasuryRepository repository;

  const offline = Failure.network(message: FailureMessages.noConnection);

  TreasuryCubit build() => TreasuryCubit(
    getAccounts: GetTreasuryAccounts(repository),
    getOwnership: GetTreasuryOwnership(repository),
    getInventoryValue: GetInventoryValue(repository),
    recordOperation: RecordTreasuryOperation(repository),
    saveAccount: SaveTreasuryAccount(repository),
  );

  void answerAccounts(Either<Failure, TreasuryAccounts> answer) =>
      when(() => repository.accounts()).thenAnswer((_) async => answer);

  void answerCards({
    Either<Failure, TreasuryOwnership> owners = const Right(ownership),
    Either<Failure, InventoryValue> shelves = const Right(inventory),
  }) {
    when(() => repository.ownership()).thenAnswer((_) async => owners);
    when(() => repository.inventoryValue()).thenAnswer((_) async => shelves);
  }

  setUpAll(() {
    registerFallbackValue(OperationKind.deposit);
  });

  setUp(() {
    repository = MockTreasuryRepository();
  });

  group('load', () {
    blocTest<TreasuryCubit, TreasuryState>(
      'الحسابات أولاً ثم البطاقتان لمن يرى الكل',
      // Arrange
      setUp: () {
        answerAccounts(const Right(everyAccount));
        answerCards();
      },
      build: build,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => [
        isA<TreasuryLoaded>()
            .having((s) => s.accounts.accounts, 'accounts', everyAccount.accounts)
            .having((s) => s.ownership, 'ownership', isNull),
        isA<TreasuryLoaded>()
            .having((s) => s.ownership, 'ownership', ownership)
            .having((s) => s.inventory, 'inventory', inventory),
      ],
    );

    blocTest<TreasuryCubit, TreasuryState>(
      'من يقرأ حسابه وحده لا تُطلب له بطاقتا الشركة',
      // Arrange
      setUp: () => answerAccounts(
        const Right(TreasuryAccounts(accounts: [alisBank], total: '300.00', canViewAll: false)),
      ),
      build: build,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => [isA<TreasuryLoaded>().having((s) => s.accounts.total, 'total', '300.00')],
      verify: (_) {
        verifyNever(() => repository.ownership());
        verifyNever(() => repository.inventoryValue());
      },
    );

    blocTest<TreasuryCubit, TreasuryState>(
      'فشلُ أول تحميلٍ يُظهر الخطأ نفسه',
      // Arrange
      setUp: () => answerAccounts(const Left(offline)),
      build: build,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => [isA<TreasuryFailed>().having((s) => s.failure, 'failure', offline)],
    );

    blocTest<TreasuryCubit, TreasuryState>(
      'إعادةُ تحميلٍ فشلت تُبقي ما على الشاشة وتحمل الفشل للتوست',
      // Arrange
      setUp: () => answerAccounts(const Left(offline)),
      build: build,
      seed: () => const TreasuryLoaded(
        accounts: everyAccount,
        ownership: ownership,
        inventory: inventory,
      ),
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => [
        isA<TreasuryLoaded>()
            .having((s) => s.accounts, 'accounts', everyAccount)
            .having((s) => s.ownership, 'ownership', ownership)
            .having((s) => s.inventory, 'inventory', inventory)
            .having((s) => s.refreshFailure, 'refreshFailure', offline),
      ],
    );

    blocTest<TreasuryCubit, TreasuryState>(
      'البطاقتان لا تختفيان ثم تعودان أثناء إعادة التحميل',
      // Arrange
      setUp: () {
        answerAccounts(const Right(everyAccount));
        answerCards();
      },
      build: build,
      seed: () => const TreasuryLoaded(
        accounts: everyAccount,
        ownership: ownership,
        inventory: inventory,
      ),
      // Act
      act: (cubit) => cubit.load(),
      // Assert — أول إصدار، قبل أن تُقرأ البطاقتان من جديد، يحمل القديمتين.
      expect: () => [
        isA<TreasuryLoaded>()
            .having((s) => s.ownership, 'ownership', ownership)
            .having((s) => s.inventory, 'inventory', inventory),
        isA<TreasuryLoaded>()
            .having((s) => s.ownership, 'ownership', ownership)
            .having((s) => s.refreshFailure, 'refreshFailure', isNull),
      ],
    );

    blocTest<TreasuryCubit, TreasuryState>(
      'بطاقةٌ فشلت في إعادة التحميل تُبقي رقمها السابق',
      // Arrange
      setUp: () {
        answerAccounts(const Right(everyAccount));
        answerCards(owners: const Left(offline));
      },
      build: build,
      seed: () => const TreasuryLoaded(
        accounts: everyAccount,
        ownership: ownership,
        inventory: inventory,
      ),
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      skip: 1,
      expect: () => [isA<TreasuryLoaded>().having((s) => s.ownership, 'ownership', ownership)],
    );
  });

  group('record', () {
    Failure? answered;

    blocTest<TreasuryCubit, TreasuryState>(
      'عمليةٌ نجحت تعيد قراءة اللوحة، فالأرصدة حساب الخادم',
      // Arrange
      setUp: () {
        when(
          () => repository.recordOperation(
            kind: any(named: 'kind'),
            amount: any(named: 'amount'),
            toAccountId: any(named: 'toAccountId'),
            clientToken: any(named: 'clientToken'),
          ),
        ).thenAnswer(
          (_) async => const Right(
            TreasuryOperation(
              id: 31,
              type: 'deposit',
              typeLabel: 'إيداع',
              amount: '50.00',
              isReversible: true,
            ),
          ),
        );
        answerAccounts(const Right(everyAccount));
        answerCards();
      },
      build: build,
      seed: () => const TreasuryLoaded(accounts: everyAccount),
      // Act
      act: (cubit) async {
        answered = await cubit.record(
          kind: OperationKind.deposit,
          amount: '50',
          toAccountId: 1,
          clientToken: 'token-1',
        );
      },
      // Assert
      verify: (_) {
        expect(answered, isNull);
        verify(
          () => repository.recordOperation(
            kind: OperationKind.deposit,
            amount: '50',
            toAccountId: 1,
            clientToken: 'token-1',
          ),
        ).called(1);
        verify(() => repository.accounts()).called(1);
      },
    );

    blocTest<TreasuryCubit, TreasuryState>(
      'عمليةٌ رُفضت تعود برفضها ولا تقرأ شيئاً',
      // Arrange
      setUp: () => when(
        () => repository.recordOperation(
          kind: any(named: 'kind'),
          amount: any(named: 'amount'),
          fromAccountId: any(named: 'fromAccountId'),
          clientToken: any(named: 'clientToken'),
        ),
      ).thenAnswer((_) async => const Left(Failure.server(message: 'الرصيد لا يكفي'))),
      build: build,
      seed: () => const TreasuryLoaded(accounts: everyAccount),
      // Act
      act: (cubit) async {
        answered = await cubit.record(
          kind: OperationKind.withdrawal,
          amount: '900',
          fromAccountId: 1,
          clientToken: 'token-2',
        );
      },
      // Assert
      expect: () => <TreasuryState>[],
      verify: (_) {
        expect(answered?.message, 'الرصيد لا يكفي');
        verifyNever(() => repository.accounts());
      },
    );
  });

  group('ما تعيده صفحة الحساب', () {
    blocTest<TreasuryCubit, TreasuryState>(
      'حسابٌ عُدِّل يُرقَّع صفُّه بلا طلب',
      // Arrange
      build: build,
      seed: () => const TreasuryLoaded(accounts: everyAccount, ownership: ownership),
      // Act
      act: (cubit) => cubit.applyAccountChange(
        AccountEdited(alisBank.copyWith(isActive: false)),
      ),
      // Assert
      expect: () => [
        isA<TreasuryLoaded>()
            .having(
              (s) => s.accounts.accounts.firstWhere((a) => a.id == alisBank.id).isActive,
              'isActive',
              isFalse,
            )
            .having((s) => s.accounts.total, 'total', '400.00')
            .having((s) => s.ownership, 'ownership', ownership),
      ],
      verify: (_) => verifyNever(() => repository.accounts()),
    );

    blocTest<TreasuryCubit, TreasuryState>(
      'حسابٌ صار افتراضياً ينزع اللقب عن افتراضي نوعه القديم',
      // Arrange
      build: build,
      seed: () => const TreasuryLoaded(accounts: everyAccount),
      // Act
      act: (cubit) => cubit.applyAccountChange(AccountEdited(alisBank.copyWith(isDefault: true))),
      // Assert
      expect: () => [
        isA<TreasuryLoaded>().having(
          (s) => [for (final a in s.accounts.accounts) if (a.isDefault) a.id],
          'defaults',
          [cashBox.id, alisBank.id],
        ),
      ],
    );

    blocTest<TreasuryCubit, TreasuryState>(
      'مالٌ تحرّك يعيد قراءة اللوحة مرةً واحدة',
      // Arrange
      setUp: () {
        answerAccounts(const Right(everyAccount));
        answerCards();
      },
      build: build,
      seed: () => const TreasuryLoaded(accounts: everyAccount),
      // Act
      act: (cubit) => cubit.applyAccountChange(const AccountMoneyMoved()),
      // Assert
      verify: (_) => verify(() => repository.accounts()).called(1),
    );
  });
}
