import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/online_payments/models/online_payment_models.dart';
import 'package:dayaa/features/online_payments/presentation/viewmodel/online_payment_methods_cubit.dart';
import 'package:dayaa/features/online_payments/presentation/viewmodel/online_payments_cubit.dart';
import 'package:dayaa/features/online_payments/repositories/online_payment_repository.dart';
import 'package:dayaa/features/online_payments/usecases/online_payment_usecases.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOnlinePaymentRepository extends Mock implements OnlinePaymentRepository {}

/// «المدفوعات الإلكترونية» — CUSTOMER-WALLET §٥: ما يُقرأ من السلك، و«إعادة التحقق» تضع المحاولة
/// مكانها، والطرقُ تُحفظ ساعة تتغيّر، والحدُّ الفارغ «بلا حد».
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockOnlinePaymentRepository repository;

  const offline = Failure.network(message: FailureMessages.noConnection);

  const pending = PaymentIntent(
    id: 4,
    uuid: 'b1c2',
    methodLabel: 'سداد',
    status: IntentStatus.pending,
    statusLabel: 'بانتظار الدفع',
    netAmount: '100.00',
    grossAmount: '102.50',
    customerFee: '2.50',
    feePayerLabel: 'الزبون',
    reference: 'DY-0004',
    canRecheck: true,
  );

  const succeeded = PaymentIntent(
    id: 4,
    uuid: 'b1c2',
    methodLabel: 'سداد',
    status: IntentStatus.succeeded,
    statusLabel: 'تم الشحن',
    netAmount: '100.00',
    grossAmount: '102.50',
    customerFee: '2.50',
    feePayerLabel: 'الزبون',
    reference: 'DY-0004',
  );

  const sadad = OnlinePaymentMethodSetting(
    id: 1,
    method: 101,
    label: 'سداد',
    flow: 'otp',
    isActive: true,
    dailyLimit: '500.00',
  );

  setUpAll(() => registerFallbackValue(IntentFilter.all));

  setUp(() {
    repository = _MockOnlinePaymentRepository();
  });

  group('السلك', () {
    test('محاولةٌ بزبونها وطلبيتها ومالها كما قاله الخادم', () {
      // Arrange
      final json = <String, dynamic>{
        'id': 4,
        'uuid': 'b1c2',
        'customer': {'id': 3, 'code': 'C3', 'name': 'علي', 'phone': '0911111111'},
        'order_id': 1304,
        'method': 101,
        'method_label': 'سداد',
        'flow': 'otp',
        'status': 'needs_review',
        'status_label': 'تحتاج مراجعة',
        'net_amount': '100.00',
        'gross_amount': '102.50',
        'customer_fee': '2.50',
        'fee_rate': '0.0250',
        'fee_payer': 'customer',
        'fee_payer_label': 'الزبون',
        'provider_fee': null,
        'reference': 'DY-0004',
        'otp_attempts': 2,
        'can_recheck': false,
        'created_at': '2026-10-12T10:00:00Z',
      };

      // Act
      final intent = PaymentIntent.fromJson(json);

      // Assert
      expect(intent.status, IntentStatus.needsReview);
      expect(intent.customerName, 'علي');
      expect(intent.orderId, 1304);
      expect(intent.customerFee, '2.50');
      expect(intent.providerFee, isNull);
      expect(intent.otpAttempts, 2);
      expect(intent.canRecheck, isFalse);
    });

    test('حالةٌ لا يعرفها هذا الإصدار لا تكسر القراءة', () {
      // Act
      final status = IntentStatus.fromWire('refunded');

      // Assert
      expect(status, IntentStatus.unknown);
    });

    test('«العمولة على» تُقرأ من إعدادات المالية، وتغيب عند خادمٍ أقدم', () {
      // Arrange
      final base = <String, dynamic>{
        'own_account_first': true,
        'block_overdraft': true,
        'withdrawal_needs_reason': true,
        'ask_carrier_fee': false,
      };

      // Act
      final now = TreasurySettings.fromJson({...base, 'online_fee_payer': 'shop'});
      final older = TreasurySettings.fromJson(base);

      // Assert
      expect(now.onlineFeePayer, 'shop');
      expect(now.withPickupOffices(const []).onlineFeePayer, 'shop');
      expect(older.onlineFeePayer, isNull);
    });
  });

  group('الصفحة', () {
    OnlinePaymentsCubit build() =>
        OnlinePaymentsCubit(getIntents: GetPaymentIntents(repository), recheck: RecheckPaymentIntent(repository));

    blocTest<OnlinePaymentsCubit, OnlinePaymentsState>(
      'رصيد Ezone وهل الدفع مفعّل يصلان مع الصفحة',
      setUp: () {
        when(
          () => repository.intents(page: 1, filter: any(named: 'filter'), search: any(named: 'search')),
        ).thenAnswer(
          (_) async => const Right(
            Paginated(
              items: [pending],
              meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 1),
              extraMeta: {'enabled': false, 'ezone_balance': '1250.00'},
            ),
          ),
        );
      },
      build: build,
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.enabled, isFalse);
        expect(cubit.ezoneBalance, '1250.00');
      },
    );

    blocTest<OnlinePaymentsCubit, OnlinePaymentsState>(
      '«إعادة التحقق» تضع المحاولة كما عادت مكانها',
      setUp: () {
        when(
          () => repository.intents(page: 1, filter: any(named: 'filter'), search: any(named: 'search')),
        ).thenAnswer(
          (_) async => const Right(
            Paginated(items: [pending], meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 1)),
          ),
        );
        when(() => repository.recheck('b1c2')).thenAnswer((_) async => const Right(succeeded));
      },
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.recheck(pending);
      },
      verify: (cubit) {
        final items = (cubit.state as PagedLoaded<PaymentIntent>).page.items;
        expect(items.single.status, IntentStatus.succeeded);
      },
    );

    blocTest<OnlinePaymentsCubit, OnlinePaymentsState>(
      'فلترُ الحالة يُرسل إلى الخادم',
      setUp: () {
        when(
          () => repository.intents(page: 1, filter: any(named: 'filter'), search: any(named: 'search')),
        ).thenAnswer(
          (_) async => const Right(
            Paginated(items: [], meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 0)),
          ),
        );
      },
      build: build,
      act: (cubit) => cubit.narrowTo(IntentFilter.needsReview),
      verify: (_) {
        verify(() => repository.intents(page: 1, filter: IntentFilter.needsReview)).called(1);
      },
    );
  });

  group('الطرق', () {
    OnlinePaymentMethodsCubit build() => OnlinePaymentMethodsCubit(
      getMethods: GetOnlinePaymentMethods(repository),
      updateMethod: UpdateOnlinePaymentMethod(repository),
    );

    blocTest<OnlinePaymentMethodsCubit, OnlinePaymentMethodsState>(
      'طريقةٌ أُطفئت تُرسم كما عادت من الخادم',
      setUp: () {
        when(() => repository.methods()).thenAnswer(
          (_) async => const Right(OnlinePaymentMethods(enabled: true, feePayer: 'customer', methods: [sadad])),
        );
        when(() => repository.updateMethod(1, isActive: false)).thenAnswer(
          (_) async => const Right(
            OnlinePaymentMethodSetting(id: 1, method: 101, label: 'سداد', flow: 'otp', isActive: false),
          ),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.setActive(sadad, false);
      },
      verify: (cubit) {
        final methods = (cubit.state as OnlinePaymentMethodsLoaded).methods.methods;
        expect(methods.single.isActive, isFalse);
      },
    );

    test('الحدُّ الفارغ يُرسل «بلا حد»، والمكتوب بالأرقام الهندية يُقرأ', () async {
      // Arrange
      when(
        () => repository.updateMethod(1, isActive: any(named: 'isActive'), limits: any(named: 'limits')),
      ).thenAnswer((_) async => const Right(sadad));

      // Act
      await UpdateOnlinePaymentMethod(repository)(1, daily: '٥٠٠', monthly: '', yearly: ' ', withLimits: true);

      // Assert
      verify(
        () => repository.updateMethod(
          1,
          limits: {'daily_limit': '500', 'monthly_limit': null, 'yearly_limit': null},
        ),
      ).called(1);
    });

    test('الفشل يعود لتوست، وما على الشاشة يبقى', () async {
      // Arrange
      when(() => repository.methods()).thenAnswer(
        (_) async => const Right(OnlinePaymentMethods(enabled: true, feePayer: 'customer', methods: [sadad])),
      );
      when(() => repository.updateMethod(1, isActive: false)).thenAnswer((_) async => const Left(offline));
      final cubit = build();
      await cubit.load();

      // Act
      final failure = await cubit.setActive(sadad, false);

      // Assert
      expect(failure, offline);
      expect((cubit.state as OnlinePaymentMethodsLoaded).methods.methods.single.isActive, isTrue);
      await cubit.close();
    });
  });
}
