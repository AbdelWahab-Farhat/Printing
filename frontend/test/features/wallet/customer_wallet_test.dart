import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/wallet/models/wallet_models.dart';
import 'package:dayaa/features/wallet/presentation/viewmodel/customer_wallet_cubit.dart';
import 'package:dayaa/features/wallet/presentation/viewmodel/wallet_entries_cubit.dart';
import 'package:dayaa/features/wallet/repositories/wallet_repository.dart';
import 'package:dayaa/features/wallet/usecases/wallet_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockWalletRepository extends Mock implements WalletRepository {}

/// «محفظة العميل» — Docs/payments/CUSTOMER-WALLET.md: ما يقرؤه التطبيق من السلك، والرأسُ يأخذ رصيد
/// الخادم بعد كل كتابة، والسجلُّ يُرقَّع ولا يُعاد.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockWalletRepository repository;

  const offline = Failure.network(message: FailureMessages.noConnection);

  const topUp = CustomerWalletEntry(
    id: 7,
    customerId: 3,
    type: 'topup',
    typeLabel: 'شحن المحفظة',
    isIn: true,
    amount: '100.00',
    canReverse: true,
  );

  Paginated<CustomerWalletEntry> page(List<CustomerWalletEntry> items) => Paginated(
    items: items,
    meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: items.length),
  );

  setUp(() {
    repository = _MockWalletRepository();
  });

  group('السلك', () {
    test('العكسُ يتجه حيث يقول الخادم، والمبلغ موجبٌ دائماً', () {
      // Arrange
      final json = <String, dynamic>{
        'id': 9,
        'customer_id': 3,
        'customer': {'id': 3, 'code': 'C3', 'name': 'علي'},
        'type': 'reversal',
        'type_label': 'عكس حركة',
        'direction': 'out',
        'amount': '100.00',
        'is_reversed': false,
        'can_reverse': false,
        'occurred_at': '2026-10-11T10:00:00Z',
      };

      // Act
      final entry = CustomerWalletEntry.fromJson(json);

      // Assert
      expect(entry.isIn, isFalse);
      expect(entry.isReversal, isTrue);
      expect(entry.signedAmount, '-100.00');
      expect(entry.customerName, 'علي');
      expect(entry.canReverse, isFalse);
    });
  });

  group('رأس المحفظة', () {
    CustomerWalletCubit build() => CustomerWalletCubit(
      customerId: 3,
      getWallet: GetCustomerWallet(repository),
      topUp: TopUpCustomerWallet(repository),
      adjust: AdjustCustomerWallet(repository),
    );

    blocTest<CustomerWalletCubit, CustomerWalletState>(
      'يقرأ الرصيد',
      // Arrange
      setUp: () => when(() => repository.wallet(3)).thenAnswer(
        (_) async => const Right(CustomerWallet(customerId: 3, balance: '150.00')),
      ),
      build: build,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => [isA<CustomerWalletLoaded>().having((s) => s.balance, 'balance', '150.00')],
    );

    blocTest<CustomerWalletCubit, CustomerWalletState>(
      'فشلُ أول قراءةٍ يُقال',
      // Arrange
      setUp: () => when(() => repository.wallet(3)).thenAnswer((_) async => const Left(offline)),
      build: build,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => [isA<CustomerWalletFailed>()],
    );

    blocTest<CustomerWalletCubit, CustomerWalletState>(
      'الشحنُ يرسم رصيد الخادم بعده، ويُذكر لمن فتح الصفحة',
      // Arrange
      setUp: () => when(
        () => repository.topUp(
          3,
          amount: '100',
          method: TopUpMethod.cash,
          treasuryAccountId: any(named: 'treasuryAccountId'),
          reference: any(named: 'reference'),
          notes: any(named: 'notes'),
          receiptPath: any(named: 'receiptPath'),
          receiptFilename: any(named: 'receiptFilename'),
        ),
      ).thenAnswer((_) async => const Right(WalletWrite(entry: topUp, balance: '250.00'))),
      build: build,
      // Act — the use case turns «١٠٠» into Western digits on the way to the wire.
      act: (cubit) => cubit.topUp(amount: '١٠٠', method: TopUpMethod.cash),
      // Assert
      expect: () => [isA<CustomerWalletLoaded>().having((s) => s.balance, 'balance', '250.00')],
      verify: (cubit) => expect(cubit.moneyMoved, isTrue),
    );

    blocTest<CustomerWalletCubit, CustomerWalletState>(
      'رفضُ التعديل لا يغيّر شيئاً',
      // Arrange
      setUp: () => when(
        () => repository.adjust(3, amount: '30', credit: false, reason: 'خطأ'),
      ).thenAnswer((_) async => const Left(offline)),
      build: build,
      // Act
      act: (cubit) => cubit.adjust(amount: '30', credit: false, reason: 'خطأ'),
      // Assert
      expect: () => <CustomerWalletState>[],
      verify: (cubit) => expect(cubit.moneyMoved, isFalse),
    );
  });

  group('سجلّ المحفظة', () {
    WalletEntriesCubit build({int? customerId = 3}) => WalletEntriesCubit(
      customerId: customerId,
      getEntries: GetCustomerWalletEntries(repository),
      reverseEntry: ReverseCustomerWalletEntry(repository),
    );

    test('العكسُ يشطب الأصل في مكانه ويضيف سطره أعلى السجل', () async {
      // Arrange
      when(
        () => repository.entries(customerId: 3, page: 1, filter: WalletEntryFilter.all),
      ).thenAnswer((_) async => Right(page([topUp])));

      const reversal = CustomerWalletEntry(
        id: 8,
        customerId: 3,
        type: 'reversal',
        typeLabel: 'عكس حركة',
        isIn: false,
        amount: '100.00',
        isReversal: true,
      );

      when(
        () => repository.reverse(7, reason: 'خطأ'),
      ).thenAnswer((_) async => const Right(WalletWrite(entry: reversal, balance: '0.00')));

      final cubit = build();
      await cubit.load();

      // Act
      final result = await cubit.reverse(topUp, reason: 'خطأ');

      // Assert
      expect(result.isRight(), isTrue);
      final items = (cubit.state as PagedLoaded<CustomerWalletEntry>).page.items;
      expect(items.map((e) => e.id), [8, 7]);
      expect(items.last.isReversed, isTrue);
      expect(items.last.reversalReason, 'خطأ');

      await cubit.close();
    });

    test('«المعاملات المالية» تسأل بلا عميل وترسل البحث', () async {
      // Arrange
      when(
        () => repository.entries(page: 1, filter: WalletEntryFilter.all, search: 'علي'),
      ).thenAnswer((_) async => Right(page([topUp])));

      final cubit = build(customerId: null);

      // Act
      await cubit.load(search: 'علي');

      // Assert
      expect(cubit.state, isA<PagedLoaded<CustomerWalletEntry>>());
      verify(() => repository.entries(page: 1, filter: WalletEntryFilter.all, search: 'علي')).called(1);

      await cubit.close();
    });

    test('سطرٌ لا يطابق الفلتر لا يُضاف', () async {
      // Arrange
      when(
        () => repository.entries(customerId: 3, page: 1, filter: WalletEntryFilter.orderPayment),
      ).thenAnswer((_) async => Right(page(const [])));

      final cubit = build();
      await cubit.narrowTo(WalletEntryFilter.orderPayment);

      // Act
      cubit.addWritten(topUp);

      // Assert
      expect((cubit.state as PagedLoaded<CustomerWalletEntry>).page.items, isEmpty);

      await cubit.close();
    });
  });
}
