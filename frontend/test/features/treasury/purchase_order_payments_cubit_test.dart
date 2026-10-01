import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/treasury/models/vendor_payment.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/purchase_order_payments_cubit.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'treasury_fixtures.dart';

/// «المدفوع للمورد» على أمر الشراء — من Cubit لا من الويدجت، ويُرقَّع بما يعيده الخادم.
///
/// Arrange - Act - Assert throughout.
void main() {
  late MockTreasuryRepository repository;

  const offline = Failure.network(message: FailureMessages.noConnection);

  const first = VendorPayment(
    id: 5,
    type: 'payment',
    typeLabel: 'دفعة',
    amount: '400.00',
    isReversed: false,
    isReversible: true,
    accountName: 'المصرف',
  );

  const summary = PurchaseOrderPayments(
    total: '1000.00',
    paid: '400.00',
    remaining: '600.00',
    predatesTreasury: false,
    payments: [first],
  );

  setUp(() {
    repository = MockTreasuryRepository();
  });

  group('دفعات أمر الشراء', () {
    PurchaseOrderPaymentsCubit build() => PurchaseOrderPaymentsCubit(
      purchaseOrderId: 4,
      vendorId: 9,
      getPayments: GetPurchaseOrderPayments(repository),
      payVendor: PayVendor(repository),
      reversePayment: ReverseVendorPayment(repository),
    );

    blocTest<PurchaseOrderPaymentsCubit, PurchaseOrderPaymentsState>(
      'يقرأ المدفوع والمتبقي والدفعات',
      // Arrange
      setUp: () => when(
        () => repository.purchaseOrderPayments(4),
      ).thenAnswer((_) async => const Right(summary)),
      build: build,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => [isA<PurchaseOrderPaymentsLoaded>().having((s) => s.payments, 'p', summary)],
    );

    blocTest<PurchaseOrderPaymentsCubit, PurchaseOrderPaymentsState>(
      'فشلُ أول قراءةٍ يُقال ولا يُبتلع',
      // Arrange
      setUp: () => when(
        () => repository.purchaseOrderPayments(4),
      ).thenAnswer((_) async => const Left(offline)),
      build: build,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => [isA<PurchaseOrderPaymentsFailed>().having((s) => s.failure, 'f', offline)],
    );

    Failure? answered;

    blocTest<PurchaseOrderPaymentsCubit, PurchaseOrderPaymentsState>(
      'دفعةٌ نجحت تُضاف أعلى القائمة ويتحرّك المدفوع والمتبقي — بلا قراءة',
      // Arrange
      setUp: () => when(
        () => repository.payVendor(
          vendorId: 9,
          purchaseOrderId: 4,
          amount: '250',
          method: 'cash',
          clientToken: 'token-1',
        ),
      ).thenAnswer(
        (_) async => const Right(
          VendorPayment(
            id: 6,
            type: 'payment',
            typeLabel: 'دفعة',
            amount: '250.00',
            isReversed: false,
            isReversible: true,
          ),
        ),
      ),
      build: build,
      seed: () => const PurchaseOrderPaymentsLoaded(summary),
      // Act
      act: (cubit) async {
        answered = await cubit.pay(amount: '250', method: 'cash', clientToken: 'token-1');
      },
      // Assert
      expect: () => [
        isA<PurchaseOrderPaymentsLoaded>()
            .having((s) => s.payments.paid, 'paid', '650.00')
            .having((s) => s.payments.remaining, 'remaining', '350.00')
            .having((s) => s.payments.payments.map((p) => p.id).toList(), 'ids', [6, 5]),
      ],
      verify: (_) {
        expect(answered, isNull);
        verifyNever(() => repository.purchaseOrderPayments(any()));
      },
    );

    blocTest<PurchaseOrderPaymentsCubit, PurchaseOrderPaymentsState>(
      'العكس يشطب الأصل ويضع صفّه، والمدفوع ينقص',
      // Arrange
      setUp: () => when(
        () => repository.reverseVendorPayment(vendorId: 9, paymentId: 5, reason: 'مكرّرة'),
      ).thenAnswer(
        (_) async => const Right(
          VendorPayment(
            id: 7,
            type: 'reversal',
            typeLabel: 'عكس دفعة',
            amount: '400.00',
            isReversed: false,
            isReversible: false,
            reversesPaymentId: 5,
          ),
        ),
      ),
      build: build,
      seed: () => const PurchaseOrderPaymentsLoaded(summary),
      // Act
      act: (cubit) async {
        answered = await cubit.reverse(first, reason: 'مكرّرة');
      },
      // Assert
      expect: () => [
        isA<PurchaseOrderPaymentsLoaded>()
            .having((s) => s.payments.paid, 'paid', '0.00')
            .having((s) => s.payments.remaining, 'remaining', '1000.00')
            .having((s) => s.payments.payments.first.isReversal, 'reversal on top', isTrue)
            .having((s) => s.payments.payments.last.isReversed, 'original struck', isTrue),
      ],
      verify: (_) => expect(answered, isNull),
    );

    blocTest<PurchaseOrderPaymentsCubit, PurchaseOrderPaymentsState>(
      'دفعةٌ رُفضت تعود برفضها والقسم كما هو',
      // Arrange
      setUp: () => when(
        () => repository.payVendor(
          vendorId: 9,
          purchaseOrderId: 4,
          amount: '9000',
          method: 'cash',
          clientToken: 'token-2',
        ),
      ).thenAnswer((_) async => const Left(Failure.server(message: 'الرصيد لا يكفي'))),
      build: build,
      seed: () => const PurchaseOrderPaymentsLoaded(summary),
      // Act
      act: (cubit) async {
        answered = await cubit.pay(amount: '9000', method: 'cash', clientToken: 'token-2');
      },
      // Assert
      expect: () => <PurchaseOrderPaymentsState>[],
      verify: (_) => expect(answered?.message, 'الرصيد لا يكفي'),
    );
  });
}
