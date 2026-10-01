import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/account_change.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/treasury_account_cubit.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'treasury_fixtures.dart';

/// صفحة الحساب: رأسها (الرصيد والمجاميع) وسجلّها — TREASURY-DESIGN §٩.
///
/// Arrange - Act - Assert throughout.
void main() {
  late MockTreasuryRepository repository;

  const offline = Failure.network(message: FailureMessages.noConnection);

  const detail = TreasuryAccountDetail(account: alisBank);

  const deposit = TreasuryOperation(
    id: 31,
    type: 'deposit',
    typeLabel: 'إيداع',
    amount: '50.00',
    isReversible: true,
  );

  setUpAll(() {
    registerFallbackValue(OperationKind.deposit);
    registerFallbackValue(MovementFilter.all);
  });

  setUp(() {
    repository = MockTreasuryRepository();
  });

  group('رأس الصفحة', () {
    TreasuryAccountCubit build() => TreasuryAccountCubit(
      accountId: alisBank.id,
      getAccount: GetTreasuryAccount(repository),
      getAccounts: GetTreasuryAccounts(repository),
      recordOperation: RecordTreasuryOperation(repository),
      saveAccount: SaveTreasuryAccount(repository),
    );

    void answerDetail(Either<Failure, TreasuryAccountDetail> answer) =>
        when(() => repository.account(alisBank.id)).thenAnswer((_) async => answer);

    blocTest<TreasuryAccountCubit, TreasuryAccountState>(
      'أول تحميلٍ يرسم الحساب',
      // Arrange
      setUp: () => answerDetail(const Right(detail)),
      build: build,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => [isA<TreasuryAccountLoaded>().having((s) => s.detail, 'detail', detail)],
    );

    blocTest<TreasuryAccountCubit, TreasuryAccountState>(
      'فشلُ أول تحميلٍ يُظهر الخطأ',
      // Arrange
      setUp: () => answerDetail(const Left(offline)),
      build: build,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => [isA<TreasuryAccountFailed>().having((s) => s.failure, 'failure', offline)],
    );

    blocTest<TreasuryAccountCubit, TreasuryAccountState>(
      'إعادةُ تحميلٍ فشلت تُبقي الرصيد على الشاشة وتحمل الفشل',
      // Arrange
      setUp: () => answerDetail(const Left(offline)),
      build: build,
      seed: () => const TreasuryAccountLoaded(detail),
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => [
        isA<TreasuryAccountLoaded>()
            .having((s) => s.detail, 'detail', detail)
            .having((s) => s.refreshFailure, 'refreshFailure', offline),
      ],
    );

    Either<Failure, TreasuryOperation>? recorded;

    blocTest<TreasuryAccountCubit, TreasuryAccountState>(
      'عمليةٌ نجحت تقرأ الرأس مرةً واحدة، وتقول للوحة إن مالاً تحرّك',
      // Arrange
      setUp: () {
        when(
          () => repository.recordOperation(
            kind: any(named: 'kind'),
            amount: any(named: 'amount'),
            toAccountId: any(named: 'toAccountId'),
            clientToken: any(named: 'clientToken'),
          ),
        ).thenAnswer((_) async => const Right(deposit));
        answerDetail(const Right(detail));
      },
      build: build,
      seed: () => const TreasuryAccountLoaded(detail),
      // Act
      act: (cubit) async {
        recorded = await cubit.record(
          kind: OperationKind.deposit,
          amount: '50',
          toAccountId: alisBank.id,
          clientToken: 'token-1',
        );
      },
      // Assert
      verify: (cubit) {
        expect(recorded?.fold((_) => null, (operation) => operation.id), deposit.id);
        expect(cubit.change, isA<AccountMoneyMoved>());
        verify(() => repository.account(alisBank.id)).called(1);
      },
    );

    blocTest<TreasuryAccountCubit, TreasuryAccountState>(
      'عمليةٌ رُفضت لا تقرأ شيئاً ولا تقول إن شيئاً تغيّر',
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
      seed: () => const TreasuryAccountLoaded(detail),
      // Act
      act: (cubit) async {
        recorded = await cubit.record(
          kind: OperationKind.withdrawal,
          amount: '900',
          fromAccountId: alisBank.id,
          clientToken: 'token-2',
        );
      },
      // Assert
      expect: () => <TreasuryAccountState>[],
      verify: (cubit) {
        expect(recorded?.isLeft(), isTrue);
        expect(cubit.change, isNull);
        verifyNever(() => repository.account(any()));
      },
    );

    Failure? saved;

    blocTest<TreasuryAccountCubit, TreasuryAccountState>(
      'التعديل يُرسم من ردّ الحفظ نفسه بلا قراءة، ومسحُ الملاحظات يصل الخادم',
      // Arrange
      setUp: () => when(
        () => repository.saveAccount(
          id: alisBank.id,
          name: 'مصرف علي',
          isActive: false,
          notes: '',
        ),
      ).thenAnswer((_) async => Right(alisBank.copyWith(isActive: false))),
      build: build,
      seed: () => const TreasuryAccountLoaded(detail),
      // Act
      act: (cubit) async {
        saved = await cubit.save(name: 'مصرف علي', isActive: false, notes: '');
      },
      // Assert
      expect: () => [
        isA<TreasuryAccountLoaded>()
            .having((s) => s.detail.account.isActive, 'isActive', isFalse),
      ],
      verify: (cubit) {
        expect(saved, isNull);
        expect(cubit.change, isA<AccountEdited>());
        verifyNever(() => repository.account(any()));
      },
    );

    Either<Failure, List<TreasuryAccount>>? targets;

    blocTest<TreasuryAccountCubit, TreasuryAccountState>(
      'حساباتُ التحويل تُطلب من الـ Cubit، وفشلُها يعود فشلاً لا حساباً واحداً',
      // Arrange
      setUp: () => when(
        () => repository.accounts(activeOnly: true),
      ).thenAnswer((_) async => const Left(offline)),
      build: build,
      // Act
      act: (cubit) async {
        targets = await cubit.transferTargets();
      },
      // Assert
      verify: (_) => expect(targets?.fold((failure) => failure, (_) => null), offline),
    );
  });

  group('السجل', () {
    AccountMovementsCubit build() => AccountMovementsCubit(
      accountId: alisBank.id,
      getMovements: GetAccountMovements(repository),
      reverseOperation: ReverseTreasuryOperation(repository),
    );

    final original = movement(id: 70, balanceAfter: '300.00');
    final older = movement(id: 60, kind: 'withdrawal', kindLabel: 'سحب', isIn: false);
    final reversal = movement(
      id: 71,
      isIn: false,
      signedAmount: '-50.00',
      balanceAfter: '250.00',
      operationId: 32,
      isReversal: true,
      isReversible: false,
      reversesMovementId: 70,
      occurredAt: DateTime(2026, 10, 1, 9),
    );

    const reversalOperation = TreasuryOperation(
      id: 32,
      type: 'deposit',
      typeLabel: 'إيداع',
      amount: '50.00',
      isReversible: false,
    );

    void answerFirstPage() => when(
      () => repository.movements(alisBank.id, page: 1),
    ).thenAnswer((_) async => Right(pageOf([original, older])));

    void answerNewest(TreasuryMovement row) => when(
      () => repository.movements(alisBank.id, page: 1, perPage: 1),
    ).thenAnswer((_) async => Right(pageOf([row])));

    Failure? reversed;

    blocTest<AccountMovementsCubit, AccountMovementsState>(
      'العكس يعلّم الأصل ويضع سطر العكس الذي كتبه الخادم أعلى السجل — بلا إعادة القائمة',
      // Arrange
      setUp: () {
        answerFirstPage();
        when(
          () => repository.reverseOperation(30, reason: 'سُجّل مرتين'),
        ).thenAnswer((_) async => const Right(reversalOperation));
        answerNewest(reversal);
      },
      build: build,
      // Act
      act: (cubit) async {
        await cubit.load();
        reversed = await cubit.reverse(original, reason: 'سُجّل مرتين');
      },
      // Assert
      skip: 2,
      expect: () => [
        isA<PagedLoaded<TreasuryMovement>>().having(
          (s) => s.page.items.first.isReversed,
          'original marked',
          isTrue,
        ),
        isA<PagedLoaded<TreasuryMovement>>()
            .having((s) => s.page.items.map((m) => m.id).toList(), 'ids', [71, 70, 60])
            .having((s) => s.page.items[1].isReversible, 'original closed', isFalse),
      ],
      verify: (_) {
        expect(reversed, isNull);
        verify(() => repository.movements(alisBank.id, page: 1)).called(1);
      },
    );

    blocTest<AccountMovementsCubit, AccountMovementsState>(
      'عكسٌ رُفض يعود برفضه ولا يمسّ السجل',
      // Arrange
      setUp: () {
        answerFirstPage();
        when(
          () => repository.reverseOperation(30, reason: 'خطأ'),
        ).thenAnswer((_) async => const Left(Failure.server(message: 'عُكست من قبل')));
      },
      build: build,
      // Act
      act: (cubit) async {
        await cubit.load();
        reversed = await cubit.reverse(original, reason: 'خطأ');
      },
      // Assert
      skip: 2,
      expect: () => <AccountMovementsState>[],
      verify: (_) => expect(reversed?.message, 'عُكست من قبل'),
    );

    blocTest<AccountMovementsCubit, AccountMovementsState>(
      'عمليةٌ جديدة تُضاف سطراً واحداً كتبه الخادم',
      // Arrange
      setUp: () {
        answerFirstPage();
        answerNewest(movement(id: 72, operationId: deposit.id, balanceAfter: '350.00'));
      },
      build: build,
      // Act
      act: (cubit) async {
        await cubit.load();
        await cubit.addWrittenBy(deposit);
      },
      // Assert
      skip: 2,
      expect: () => [
        isA<PagedLoaded<TreasuryMovement>>().having(
          (s) => s.page.items.map((m) => m.id).toList(),
          'ids',
          [72, 70, 60],
        ),
      ],
    );

    blocTest<AccountMovementsCubit, AccountMovementsState>(
      'سطرٌ أحدث ليس لهذه العملية يعني أن غيرها كُتب معها — فيُقرأ السجل',
      // Arrange
      setUp: () {
        answerFirstPage();
        answerNewest(movement(id: 73, operationId: 99));
      },
      build: build,
      // Act
      act: (cubit) async {
        await cubit.load();
        await cubit.addWrittenBy(deposit);
      },
      // Assert
      verify: (_) => verify(() => repository.movements(alisBank.id, page: 1)).called(2),
    );

    blocTest<AccountMovementsCubit, AccountMovementsState>(
      'الفلتر يُرسل إلى الخادم، والسطر الذي لا يطابقه لا يُضاف',
      // Arrange — «المصاريف»، ثم إيداعٌ يُسجَّل من الصفحة
      setUp: () {
        when(
          () => repository.movements(alisBank.id, page: 1, filter: MovementFilter.expenses),
        ).thenAnswer((_) async => Right(pageOf([older])));
        answerNewest(movement(id: 72, operationId: deposit.id, balanceAfter: '350.00'));
      },
      build: build,
      // Act
      act: (cubit) async {
        await cubit.narrowTo(MovementFilter.expenses);
        await cubit.addWrittenBy(deposit);
      },
      // Assert — السجلّ على ما أرسله الخادم للمصاريف، والإيداع لم يُدسّ فيه
      skip: 1,
      expect: () => [
        isA<PagedLoaded<TreasuryMovement>>().having(
          (s) => s.page.items.map((m) => m.id).toList(),
          'ids',
          [60],
        ),
      ],
      verify: (cubit) => expect(cubit.filter, MovementFilter.expenses),
    );

    blocTest<AccountMovementsCubit, AccountMovementsState>(
      'رقمُ الطلبية المبحوث عنه يبقى حين يتغيّر الفلتر',
      // Arrange
      setUp: () {
        when(
          () => repository.movements(
            alisBank.id,
            page: 1,
            filter: any(named: 'filter'),
            search: any(named: 'search'),
          ),
        ).thenAnswer((_) async => Right(pageOf([older])));
      },
      build: build,
      // Act
      act: (cubit) async {
        await cubit.load(search: '1290');
        await cubit.narrowTo(MovementFilter.orders);
      },
      // Assert
      verify: (_) => verify(
        () => repository.movements(
          alisBank.id,
          page: 1,
          filter: MovementFilter.orders,
          search: '1290',
        ),
      ).called(1),
    );
  });
}
