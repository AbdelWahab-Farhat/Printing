import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/payment_review_queue_cubit.dart';
import 'package:dayaa/features/orders/presentation/widgets/payment_review_line.dart';
import 'package:dayaa/features/orders/repositories/order_payment_repository.dart';
import 'package:dayaa/features/orders/usecases/manage_order_payments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderPaymentRepository extends Mock implements OrderPaymentRepository {}

/// «مراجعة الدفعات» — the badge on a payment, and the reviewer's queue.
///
/// **Every decision is the server's**: whether a row carries a badge, whether this person may
/// review it, and why not. These tests hold the screen to drawing exactly what it was told.
///
/// Arrange - Act - Assert throughout.
void main() {
  Widget host(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Directionality(textDirection: TextDirection.rtl, child: child),
        ),
      ),
    );
  }

  OrderPayment payment({
    int id = 1,
    bool requiresReview = true,
    bool isReviewed = false,
    bool canReview = false,
    bool canUnreview = false,
    String? blockedReason,
    bool isReversed = false,
    PaymentRecorder? reviewer,
  }) {
    return OrderPayment(
      id: id,
      orderId: 7,
      type: OrderPaymentType.payment,
      typeLabel: 'دفعة',
      amount: '100.00',
      method: PaymentMethod.cash,
      methodLabel: 'كاش',
      isReversed: isReversed,
      requiresReview: requiresReview,
      isReviewed: isReviewed,
      reviewedBy: reviewer,
      canReview: canReview,
      canUnreview: canUnreview,
      reviewBlockedReason: blockedReason,
    );
  }

  group('the badge', () {
    testWidgets('a row nobody is asked to check says nothing at all', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(PaymentReviewLine(payment: payment(requiresReview: false), isBusy: false, onReview: (_) {})),
      );

      // Assert
      expect(find.text('غير مراجَعة'), findsNothing);
      expect(find.textContaining('تمت المراجعة'), findsNothing);
    });

    testWidgets('an unreviewed row offers «مراجعة» to somebody the server allows', (tester) async {
      // Arrange
      bool? answer;
      await tester.pumpWidget(
        host(
          PaymentReviewLine(
            payment: payment(canReview: true),
            isBusy: false,
            onReview: (reviewed) => answer = reviewed,
          ),
        ),
      );

      // Act
      await tester.tap(find.text('مراجعة'));

      // Assert
      expect(find.text('غير مراجَعة'), findsOneWidget);
      expect(answer, isTrue);
    });

    testWidgets('a reversed payment says why the button is not there', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(
          PaymentReviewLine(
            payment: payment(blockedReason: 'الدفعة ملغاة — لا شيء فيها يُراجع'),
            isBusy: false,
            onReview: (_) {},
          ),
        ),
      );

      // Assert
      expect(find.text('مراجعة'), findsNothing);
      expect(find.text('الدفعة ملغاة — لا شيء فيها يُراجع'), findsOneWidget);
    });

    testWidgets('a reviewed row names who checked it, and may be taken back', (tester) async {
      // Arrange
      bool? answer;
      await tester.pumpWidget(
        host(
          PaymentReviewLine(
            payment: payment(
              isReviewed: true,
              canUnreview: true,
              reviewer: const PaymentRecorder(id: 3, name: 'سارة'),
            ),
            isBusy: false,
            onReview: (reviewed) => answer = reviewed,
          ),
        ),
      );

      // Act
      await tester.tap(find.text('إلغاء المراجعة'));

      // Assert
      expect(find.text('تمت المراجعة — سارة'), findsOneWidget);
      expect(answer, isFalse);
    });

    testWidgets('a reversed payment nobody reviewed has nothing left to check', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(PaymentReviewLine(payment: payment(isReversed: true), isBusy: false, onReview: (_) {})),
      );

      // Assert
      expect(find.text('غير مراجَعة'), findsNothing);
    });
  });

  group('the queue', () {
    late _MockOrderPaymentRepository repository;
    late PaymentReviewQueueCubit cubit;

    Paginated<OrderPayment> pageOf(List<OrderPayment> items) => Paginated<OrderPayment>(
      items: items,
      meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: items.length),
    );

    setUp(() {
      repository = _MockOrderPaymentRepository();
      cubit = PaymentReviewQueueCubit(
        getQueue: GetPaymentReviewQueue(repository),
        reviewPayment: ReviewOrderPayment(repository),
      );
    });

    tearDown(() => cubit.close());

    test('a reviewed entry leaves the list and the count follows it', () async {
      // Arrange
      final first = payment(id: 1, canReview: true);
      final second = payment(id: 2, canReview: true);
      when(() => repository.reviewQueue(page: 1)).thenAnswer((_) async => Right(pageOf([first, second])));
      when(() => repository.review(7, 1, reviewed: true)).thenAnswer((_) async => Right(first));
      await cubit.load();

      // Act
      final failure = await cubit.review(first);

      // Assert
      expect(failure, isNull);
      final state = cubit.state as PagedLoaded<OrderPayment>;
      expect(state.page.items.map((p) => p.id), [2]);
      expect(cubit.waiting, 1);
    });

    test('a refusal keeps the entry where it was and says why', () async {
      // Arrange
      final only = payment(id: 1, canReview: true);
      when(() => repository.reviewQueue(page: 1)).thenAnswer((_) async => Right(pageOf([only])));
      when(() => repository.review(7, 1, reviewed: true)).thenAnswer(
        (_) async => const Left(
          Failure.server(message: 'الدفعة ملغاة — لا شيء فيها يُراجع', statusCode: 422),
        ),
      );
      await cubit.load();

      // Act
      final failure = await cubit.review(only);

      // Assert
      expect(failure?.message, 'الدفعة ملغاة — لا شيء فيها يُراجع');
      expect(cubit.waiting, 1);
    });

    test('choosing refunds asks the server for refunds alone', () async {
      // Arrange
      when(() => repository.reviewQueue(page: 1)).thenAnswer((_) async => Right(pageOf(const [])));
      when(
        () => repository.reviewQueue(page: 1, type: OrderPaymentType.refund),
      ).thenAnswer((_) async => Right(pageOf(const [])));
      await cubit.load();

      // Act
      await cubit.showType(OrderPaymentType.refund);

      // Assert
      verify(() => repository.reviewQueue(page: 1, type: OrderPaymentType.refund)).called(1);
      expect(cubit.type, OrderPaymentType.refund);
    });
  });
}
