import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/models/transition_field.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_status_cubit.dart';
import 'package:dayaa/features/orders/presentation/views/order_status_page.dart';
import 'package:dayaa/features/orders/usecases/change_order_status.dart';
import 'package:dayaa/features/orders/usecases/get_order.dart';
import 'package:dayaa/features/shipping_companies/usecases/get_shipping_companies.dart';
import 'package:dayaa/features/warehouses/usecases/get_warehouses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// حقول الوجهة في «تغيير الحالة» تدخل ولا تقفز.
///
/// كانت الحقول تظهر في إطارٍ واحد فتدفع ما تحتها فجأة. المطلوب أن تنفتح مساحتها وتظهر هي
/// تدريجياً، وأن يبقى ذلك كلّه في إطارٍ واحد لمن طلب من هاتفه تقليل الحركة.
///
/// Arrange - Act - Assert throughout.
class _MockGetOrder extends Mock implements GetOrder {}

class _MockChangeOrderStatus extends Mock implements ChangeOrderStatus {}

class _MockGetWarehouses extends Mock implements GetWarehouses {}

class _MockGetShippingCompanies extends Mock implements GetShippingCompanies {}

void main() {
  const cancelReason = 'سبب الإلغاء';
  const designNote = 'ملاحظة للمصمّم';

  Order order() => const Order(
    id: 7,
    code: '7',
    status: OrderStatus.taken,
    statusLabel: 'جديدة',
    isFinal: false,
    customerId: 10,
    cityId: 1,
    designSource: 'none',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'بدون تصميم',
    itemsTotal: '110.00',
    designFee: '0.00',
    deliveryPrice: '15.00',
    discount: '0.00',
    grandTotal: '125.00',
    remainingAmount: '125.00',
    paymentStatusLabel: 'غير مدفوعة',
    availableTransitions: [
      OrderTransition(
        status: OrderStatus.designing,
        label: 'قيد التصميم',
        fields: [
          TransitionField(
            key: 'note',
            type: TransitionFieldType.text,
            label: designNote,
            isRequired: true,
          ),
        ],
      ),
      OrderTransition(
        status: OrderStatus.cancelled,
        label: 'إلغاء تام',
        fields: [
          TransitionField(
            key: 'reason',
            type: TransitionFieldType.text,
            label: cancelReason,
            isRequired: true,
          ),
        ],
      ),
    ],
  );

  Future<void> arrange() async {
    await Injector.reset();

    final getOrder = _MockGetOrder();
    when(() => getOrder(7)).thenAnswer((_) async => Right(order()));

    sl.registerFactoryParam<OrderStatusCubit, int, void>(
      (orderId, _) => OrderStatusCubit(
        orderId: orderId,
        getOrder: getOrder,
        changeStatus: _MockChangeOrderStatus(),
        getWarehouses: _MockGetWarehouses(),
        getShippingCompanies: _MockGetShippingCompanies(),
      ),
    );
  }

  Widget host({bool reduceMotion = false}) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: const OrderStatusPage(orderId: 7),
    ),
  );

  /// كم يُرى من الحقل الآن: حاصل ضرب كلّ شفافيةٍ فوقه في الشجرة.
  double opacityOf(String label) {
    final layers = find.ancestor(
      of: find.text(label).first,
      matching: find.byWidgetPredicate((widget) => widget is FadeTransition || widget is Opacity),
    );

    return layers.evaluate().fold(
      1,
      (seen, element) => switch (element.widget) {
        FadeTransition(:final opacity) => seen * opacity.value,
        Opacity(:final opacity) => seen * opacity,
        _ => seen,
      },
    );
  }

  tearDown(Injector.reset);

  testWidgets('the fields of a chosen destination fade in rather than land at once', (
    tester,
  ) async {
    // Arrange
    await arrange();
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act — a moment into the move, then the rest of it.
    await tester.tap(find.text('إلغاء تام'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final midway = opacityOf(cancelReason);
    await tester.pumpAndSettle();

    // Assert
    expect(midway, lessThan(1));
    expect(opacityOf(cancelReason), 1);
  });

  testWidgets('with reduce motion on, the fields are there in the same frame', (tester) async {
    // Arrange
    await arrange();
    await tester.pumpWidget(host(reduceMotion: true));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('إلغاء تام'));
    await tester.pump();

    // Assert
    expect(opacityOf(cancelReason), 1);
  });

  testWidgets('another destination takes the old fields away and brings its own', (
    tester,
  ) async {
    // Arrange
    await arrange();
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء تام'));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('قيد التصميم'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text(cancelReason), findsNothing);
    expect(find.text(designNote), findsOneWidget);
    expect(opacityOf(designNote), 1);
  });
}
