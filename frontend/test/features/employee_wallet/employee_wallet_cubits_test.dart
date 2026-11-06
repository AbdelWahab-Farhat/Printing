import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/credit_categories_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/employee_wallet_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/employee_wallet_entries_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/my_wallet_cubit.dart';
import 'package:dayaa/features/employee_wallet/repositories/employee_wallet_repository.dart';
import 'package:dayaa/features/employee_wallet/usecases/employee_wallet_usecases.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/repositories/treasury_repository.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements EmployeeWalletRepository {}

class _MockTreasury extends Mock implements TreasuryRepository {}

/// الرأسُ يأخذ رصيد الخادم بعد كل كتابة، والسجلُّ يُرقَّع ولا يُعاد، والأرقام تصل غربية.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockRepository repository;

  const offline = Failure.network(message: FailureMessages.noConnection);
  const refused = Failure.server(message: 'رصيد «بريمولا قرجي» لا يكفي لـ 1,400.00');

  const deposit = EmployeeWalletEntry(
    id: 7,
    userId: 4,
    type: 'deposit',
    typeLabel: 'إيداع',
    direction: 'in',
    amount: '300.00',
    canReverse: true,
  );

  const withdrawal = EmployeeWalletEntry(
    id: 8,
    userId: 4,
    type: 'withdrawal',
    typeLabel: 'سحب',
    direction: 'out',
    amount: '50.00',
    canReverse: true,
  );

  const reversal = EmployeeWalletEntry(
    id: 9,
    userId: 4,
    type: 'reversal',
    typeLabel: 'عكس حركة',
    direction: 'in',
    amount: '50.00',
  );

  const wallet = EmployeeWallet(balance: '1500.00', canMove: true, salary: '2500.00');

  const money = EmployeeMoneyDraft(amount: '٣٠٠', method: EmployeeWalletMethod.cash);

  Paginated<EmployeeWalletEntry> page(List<EmployeeWalletEntry> items) => Paginated(
    items: items,
    meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: items.length),
  );

  setUpAll(() {
    registerFallbackValue(const EmployeeWalletLedger.mine());
    registerFallbackValue(money);
    registerFallbackValue(const EmployeeCreditDraft(amount: '1', categoryId: 1));
  });

  setUp(() => repository = _MockRepository());

  group('رأس المحفظة', () {
    EmployeeWalletCubit build() => EmployeeWalletCubit(
      userId: 4,
      getWallet: GetEmployeeWallet(repository),
      deposit: DepositToEmployeeWallet(repository),
      credit: CreditEmployeeWallet(repository),
      withdraw: WithdrawFromEmployeeWallet(repository),
      adjust: AdjustEmployeeWallet(repository),
    );

    blocTest<EmployeeWalletCubit, EmployeeWalletState>(
      'يقرأ المحفظة',
      // Arrange
      setUp: () => when(() => repository.wallet(4)).thenAnswer((_) async => const Right(wallet)),
      build: build,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => [const EmployeeWalletState.loaded(wallet)],
    );

    blocTest<EmployeeWalletCubit, EmployeeWalletState>(
      'فشل أول قراءة يُقال برسالة الخادم',
      // Arrange
      setUp: () => when(() => repository.wallet(4)).thenAnswer((_) async => const Left(offline)),
      build: build,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => [const EmployeeWalletState.failed(offline)],
    );

    blocTest<EmployeeWalletCubit, EmployeeWalletState>(
      'فشل إعادة القراءة لا يمسح ما على الشاشة',
      // Arrange
      setUp: () {
        var calls = 0;
        when(() => repository.wallet(4)).thenAnswer(
          (_) async => calls++ == 0 ? const Right(wallet) : const Left(offline),
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
        const EmployeeWalletState.loaded(wallet),
        const EmployeeWalletState.loaded(wallet, refreshFailure: offline),
      ],
    );

    blocTest<EmployeeWalletCubit, EmployeeWalletState>(
      'الإيداع يرسل أرقاماً غربية، ويرسم رصيد الخادم، ويبقي ما عداه',
      // Arrange
      setUp: () {
        when(() => repository.wallet(4)).thenAnswer((_) async => const Right(wallet));
        when(
          () => repository.deposit(4, any(), clientToken: 'token'),
        ).thenAnswer(
          (_) async => const Right(EmployeeWalletWrite(entry: deposit, balance: '1800.00')),
        );
      },
      build: build,
      // Act
      act: (cubit) async {
        await cubit.load();
        await cubit.deposit(money, clientToken: 'token');
      },
      // Assert
      expect: () => [
        const EmployeeWalletState.loaded(wallet),
        EmployeeWalletState.loaded(wallet.copyWith(balance: '1800.00')),
      ],
      verify: (cubit) {
        final sent = verify(
          () => repository.deposit(4, captureAny(), clientToken: 'token'),
        ).captured.single as EmployeeMoneyDraft;

        expect(sent.amount, '300');
        expect(cubit.moneyMoved, isTrue);
      },
    );

    blocTest<EmployeeWalletCubit, EmployeeWalletState>(
      'رفض السحب لا يغيّر الرصيد، ويعود لمن طلبه',
      // Arrange
      setUp: () {
        when(() => repository.wallet(4)).thenAnswer((_) async => const Right(wallet));
        when(
          () => repository.withdraw(4, any(), clientToken: 'token'),
        ).thenAnswer((_) async => const Left(refused));
      },
      build: build,
      // Act
      act: (cubit) async {
        await cubit.load();
        final result = await cubit.withdraw(money, clientToken: 'token');

        expect(result, const Left<Failure, EmployeeWalletWrite>(refused));
      },
      // Assert
      expect: () => [const EmployeeWalletState.loaded(wallet)],
      verify: (cubit) => expect(cubit.moneyMoved, isFalse),
    );

    blocTest<EmployeeWalletCubit, EmployeeWalletState>(
      'المستحق يكتب ويرسم رصيد الخادم',
      // Arrange
      setUp: () {
        when(() => repository.wallet(4)).thenAnswer((_) async => const Right(wallet));
        when(
          () => repository.credit(4, any(), clientToken: 'token'),
        ).thenAnswer(
          (_) async => const Right(EmployeeWalletWrite(entry: deposit, balance: '4000.00')),
        );
      },
      build: build,
      // Act
      act: (cubit) async {
        await cubit.load();
        await cubit.credit(
          const EmployeeCreditDraft(amount: '2500.00', categoryId: 3),
          clientToken: 'token',
        );
      },
      // Assert
      expect: () => [
        const EmployeeWalletState.loaded(wallet),
        EmployeeWalletState.loaded(wallet.copyWith(balance: '4000.00')),
      ],
    );

    blocTest<EmployeeWalletCubit, EmployeeWalletState>(
      'التعديل يكتب ويرسم رصيد الخادم',
      // Arrange
      setUp: () {
        when(() => repository.wallet(4)).thenAnswer((_) async => const Right(wallet));
        when(
          () => repository.adjust(
            4,
            amount: '150',
            credit: true,
            reason: 'رصيد افتتاحي',
            clientToken: 'token',
          ),
        ).thenAnswer(
          (_) async => const Right(EmployeeWalletWrite(entry: deposit, balance: '1650.00')),
        );
      },
      build: build,
      // Act
      act: (cubit) async {
        await cubit.load();
        await cubit.adjust(
          amount: '١٥٠',
          credit: true,
          reason: 'رصيد افتتاحي',
          clientToken: 'token',
        );
      },
      // Assert
      expect: () => [
        const EmployeeWalletState.loaded(wallet),
        EmployeeWalletState.loaded(wallet.copyWith(balance: '1650.00')),
      ],
    );

    blocTest<EmployeeWalletCubit, EmployeeWalletState>(
      'رصيدٌ جاء من شاشة أخرى يُرسم ولو لم تنجح القراءة',
      // Arrange
      setUp: () => when(() => repository.wallet(4)).thenAnswer((_) async => const Left(offline)),
      build: build,
      // Act
      act: (cubit) async {
        await cubit.load();
        cubit.applyBalance('90.00');
      },
      // Assert
      expect: () => [
        const EmployeeWalletState.failed(offline),
        const EmployeeWalletState.loaded(EmployeeWallet(balance: '90.00')),
      ],
    );
  });

  group('قراءةٌ بدأت قبل الكتابة', () {
    test('لا ترسم رصيداً قديماً فوق رصيد الخادم بعد الكتابة', () async {
      // Arrange
      final reading = Completer<Either<Failure, EmployeeWallet>>();
      var calls = 0;
      when(
        () => repository.wallet(4),
      ).thenAnswer((_) => calls++ == 0 ? Future.value(const Right(wallet)) : reading.future);
      final cubit = EmployeeWalletCubit(
        userId: 4,
        getWallet: GetEmployeeWallet(repository),
        deposit: DepositToEmployeeWallet(repository),
        credit: CreditEmployeeWallet(repository),
        withdraw: WithdrawFromEmployeeWallet(repository),
        adjust: AdjustEmployeeWallet(repository),
      );
      await cubit.load();
      final pending = cubit.load();

      // Act
      cubit.applyBalance('1800.00');
      reading.complete(const Right(wallet));
      await pending;

      // Assert
      expect(cubit.state, EmployeeWalletState.loaded(wallet.copyWith(balance: '1800.00')));
    });

    test('ولا فوق ما قرأته «محفظتي»', () async {
      // Arrange
      final reading = Completer<Either<Failure, EmployeeWallet>>();
      when(repository.myWallet).thenAnswer((_) => reading.future);
      final cubit = MyWalletCubit(getWallet: GetMyWallet(repository));
      final pending = cubit.load();

      // Act
      cubit.show('90.00');
      reading.complete(const Right(EmployeeWallet(balance: '1500.00')));
      await pending;

      // Assert
      expect(cubit.state, const MyWalletState.loaded('90.00'));
    });
  });

  group('سجل المحفظة', () {
    EmployeeWalletEntriesCubit build([
      EmployeeWalletLedger ledger = const EmployeeWalletLedger.of(4),
    ]) => EmployeeWalletEntriesCubit(
      ledger: ledger,
      getEntries: GetEmployeeWalletEntries(repository),
      reverseEntry: ReverseEmployeeWalletEntry(repository),
    );

    void arrangeEntries(List<EmployeeWalletEntry> items) {
      when(
        () => repository.entries(
          any(),
          page: any(named: 'page'),
          filter: any(named: 'filter'),
          search: any(named: 'search'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => Right(page(items)));
    }

    List<EmployeeWalletEntry> rows(EmployeeWalletEntriesCubit cubit) =>
        (cubit.state as PagedLoaded<EmployeeWalletEntry>).page.items;

    setUpAll(() => registerFallbackValue(EmployeeWalletEntryFilter.all));

    test('السطر المكتوب يُضاف أعلى السجل بلا إعادة قراءة', () async {
      // Arrange
      arrangeEntries(const [withdrawal]);
      final cubit = build();
      await cubit.load();

      // Act
      cubit.addWritten(deposit);

      // Assert
      expect(rows(cubit).map((entry) => entry.id), [7, 8]);
      verify(
        () => repository.entries(
          any(),
          page: any(named: 'page'),
          filter: any(named: 'filter'),
          search: any(named: 'search'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).called(1);
    });

    test('سطرٌ لا يطابق الفلتر لا يُضاف', () async {
      // Arrange
      arrangeEntries(const [withdrawal]);
      final cubit = build();
      await cubit.narrowTo(EmployeeWalletEntryFilter.withdrawal);

      // Act
      cubit.addWritten(deposit);

      // Assert
      expect(rows(cubit).map((entry) => entry.id), [8]);
    });

    test('العكس يشطب الأصل في مكانه ويضيف سطره، ويعود بالرصيد', () async {
      // Arrange
      arrangeEntries(const [withdrawal]);
      when(() => repository.reverse(8, reason: 'خطأ')).thenAnswer(
        (_) async => const Right(EmployeeWalletWrite(entry: reversal, balance: '1550.00')),
      );
      final cubit = build();
      await cubit.load();

      // Act
      final result = await cubit.reverse(withdrawal, reason: 'خطأ');

      // Assert
      expect(result.isRight(), isTrue);
      expect(rows(cubit).map((entry) => entry.id), [9, 8]);
      expect(rows(cubit).last.isReversed, isTrue);
      expect(rows(cubit).last.canReverse, isFalse);
      expect(rows(cubit).last.reversalReason, 'خطأ');
    });

    test('رفض العكس لا يمسّ السجل', () async {
      // Arrange
      arrangeEntries(const [deposit]);
      when(() => repository.reverse(7, reason: 'خطأ')).thenAnswer(
        (_) async => const Left(Failure.server(message: 'لا يمكن عكس 300.00')),
      );
      final cubit = build();
      await cubit.load();

      // Act
      final result = await cubit.reverse(deposit, reason: 'خطأ');

      // Assert
      expect(result.isLeft(), isTrue);
      expect(rows(cubit).single.isReversed, isFalse);
    });

    test('الفلتر والمدى يصلان إلى الخادم، والبحث المكتوب يبقى', () async {
      // Arrange
      arrangeEntries(const [deposit]);
      final cubit = build(const EmployeeWalletLedger.all());
      await cubit.load(search: 'محمد');
      final from = DateTime(2026, 11);
      final to = DateTime(2026, 11, 6);

      // Act
      await cubit.between(from, to);
      await cubit.narrowTo(EmployeeWalletEntryFilter.credit);

      // Assert
      verify(
        () => repository.entries(
          const EmployeeWalletLedger.all(),
          page: 1,
          filter: EmployeeWalletEntryFilter.credit,
          search: 'محمد',
          from: from,
          to: to,
        ),
      ).called(1);
    });
  });

  group('«محفظتي»', () {
    MyWalletCubit build() => MyWalletCubit(getWallet: GetMyWallet(repository));

    blocTest<MyWalletCubit, MyWalletState>(
      'يقرأ الرصيد',
      // Arrange
      setUp: () => when(repository.myWallet).thenAnswer(
        (_) async => const Right(EmployeeWallet(balance: '1500.00')),
      ),
      build: build,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => [const MyWalletState.loaded('1500.00')],
    );

    blocTest<MyWalletCubit, MyWalletState>(
      'الفشل يُقال، ولا يسقط ما حوله',
      // Arrange
      setUp: () => when(repository.myWallet).thenAnswer((_) async => const Left(offline)),
      build: build,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => [const MyWalletState.failed(offline)],
    );

    blocTest<MyWalletCubit, MyWalletState>(
      'فشل إعادة القراءة يُبقي الرقم الذي على الشاشة',
      // Arrange
      setUp: () {
        var calls = 0;
        when(repository.myWallet).thenAnswer(
          (_) async => calls++ == 0
              ? const Right(EmployeeWallet(balance: '1500.00'))
              : const Left(offline),
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
        const MyWalletState.loaded('1500.00'),
        const MyWalletState.loaded('1500.00', refreshFailure: offline),
      ],
    );

    blocTest<MyWalletCubit, MyWalletState>(
      'رصيدٌ جاء من «محفظتي» يُرسم بلا طلب',
      // Arrange
      build: build,
      // Act
      act: (cubit) => cubit.show('90.00'),
      // Assert
      expect: () => [const MyWalletState.loaded('90.00')],
      verify: (_) => verifyNever(repository.myWallet),
    );
  });

  group('تصنيفات المستحق', () {
    late _MockTreasury treasury;

    const salary = ExpenseCategory(
      id: 1,
      name: 'رواتب',
      code: 'salary',
      requiresEmployee: false,
      isActive: true,
      isSystem: true,
    );
    const advance = ExpenseCategory(
      id: 2,
      name: 'سلفة موظف',
      code: 'employee_advance',
      requiresEmployee: true,
      isActive: true,
      isSystem: true,
    );
    const bonus = ExpenseCategory(
      id: 3,
      name: 'مكافآت',
      requiresEmployee: false,
      isActive: true,
      isSystem: false,
    );

    CreditCategoriesCubit build() =>
        CreditCategoriesCubit(getCategories: GetExpenseCategories(treasury));

    setUp(() => treasury = _MockTreasury());

    blocTest<CreditCategoriesCubit, CreditCategoriesState>(
      'لا يعرض من تصنيفات النظام إلا «رواتب»',
      // Arrange
      setUp: () => when(
        () => treasury.expenseCategories(activeOnly: true),
      ).thenAnswer((_) async => const Right([salary, advance, bonus])),
      build: build,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => [
        const CreditCategoriesState.loaded([salary, bonus]),
      ],
    );

    blocTest<CreditCategoriesCubit, CreditCategoriesState>(
      'الفشل يُقال، وإعادة المحاولة تقرأ من جديد',
      // Arrange
      setUp: () {
        var calls = 0;
        when(() => treasury.expenseCategories(activeOnly: true)).thenAnswer(
          (_) async => calls++ == 0 ? const Left(offline) : const Right([bonus]),
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
        const CreditCategoriesState.failed(offline),
        const CreditCategoriesState.loading(),
        const CreditCategoriesState.loaded([bonus]),
      ],
    );
  });
}
