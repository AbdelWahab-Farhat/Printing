import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/instant_orders/models/instant_models.dart';
import 'package:dayaa/features/instant_orders/presentation/viewmodel/instant_order_cubit.dart';
import 'package:dayaa/features/instant_orders/presentation/views/instant_order_page.dart';
import 'package:dayaa/features/instant_orders/repositories/instant_order_repository.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/place_picker_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements InstantOrderRepository {}

/// The instant-order screen drawn like «طلبية جديدة», with only what a counter sale asks.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockRepository repository;
  late Session session;

  setUp(() async {
    await Injector.reset();

    repository = _MockRepository();
    session = Session();

    when(() => repository.branches()).thenAnswer(
      (_) async =>
          const Right([SellingBranch(id: 7, name: 'مكتب قرجي', warehouseName: 'مخزن بريمولا')]),
    );
    when(() => repository.products(any())).thenAnswer(
      (_) async => const Right(InstantCatalogue(products: [], warehouseName: 'مخزن بريمولا')),
    );

    sl
      ..registerSingleton<Session>(session)
      ..registerFactoryParam<InstantOrderCubit, Order?, void>(
        (editing, _) => InstantOrderCubit(repository: repository, editing: editing),
      );
  });

  tearDown(Injector.reset);

  Widget host() => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => const MaterialApp(
      locale: Locale('ar'),
      supportedLocales: [Locale('ar')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: InstantOrderPage(),
    ),
  );

  testWidgets('the sections of «طلبية جديدة» a counter sale uses, and none of the rest', (
    tester,
  ) async {
    // Arrange
    session.adopt(
      const AuthUser(
        id: 1,
        name: 'موظف',
        phone: '0911234567',
        permissions: ['instant_orders.create'],
      ),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — the sections it keeps.
    expect(find.text('العميل'), findsOneWidget);
    expect(find.text('الاستلام'), findsOneWidget);
    expect(find.text('البنود'), findsOneWidget);
    expect(find.text('المخزن: مخزن بريمولا (تلقائي)'), findsOneWidget);
    expect(find.text('لم يُضَف أي منتج بعد'), findsOneWidget);

    // The foot of the list is built only once it scrolls into view.
    await tester.scrollUntilVisible(
      find.text('إجمالي البنود (تقديري)'),
      200,
      // The page's own list, not one of the text fields' scrollers.
      scrollable: find
          .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
          .first,
    );
    expect(find.text('ملاحظات'), findsOneWidget);
    expect(find.text('إجمالي البنود (تقديري)'), findsOneWidget);

    // No discount box without the grant, and none of what a counter sale never asks.
    for (final absent in [
      'الخصم',
      'المحل',
      'المورد',
      'التصميم',
      'التعويض',
      'التكلفة الإضافية',
      'الاستعجال',
    ]) {
      expect(find.text(absent), findsNothing, reason: absent);
    }

    // The button sits under the list, disabled until the form is complete.
    expect(find.text('إنشاء الطلب'), findsOneWidget);
  });

  group('a customer on file', () {
    Future<void> typePhone(WidgetTester tester, FoundCustomer? found) async {
      when(() => repository.findCustomer(any())).thenAnswer((_) async => Right(found));
      session.adopt(
        const AuthUser(
          id: 1,
          name: 'موظف',
          phone: '0911234567',
          permissions: ['instant_orders.create'],
        ),
      );

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'رقم الهاتف'), '0912345678');
      // The lookup waits for the typing to stop.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    }

    Finder nameBox() => find.widgetWithText(TextField, 'الاسم');

    testWidgets('is the banner: no name box, and no address tiles when one is stored', (
      tester,
    ) async {
      // Arrange / Act
      await typePhone(
        tester,
        const FoundCustomer(
          id: 4,
          name: 'سالم',
          phone: '0912345678',
          cityId: 3,
          cityName: 'طرابلس',
          regionName: 'قرجي',
        ),
      );

      // Assert — each stored detail under its own caption, and nothing to type.
      expect(find.text('سالم'), findsOneWidget);
      expect(find.text('طرابلس'), findsOneWidget);
      expect(find.text('قرجي'), findsOneWidget);
      expect(find.text('0912345678'), findsWidgets);
      expect(nameBox(), findsNothing);
      expect(find.byType(PlacePickerTile), findsNothing);
    });

    testWidgets('without a stored address is offered the address tiles to fill it', (tester) async {
      // Arrange / Act
      await typePhone(tester, const FoundCustomer(id: 4, name: 'سالم', phone: '0912345678'));

      // Assert
      expect(nameBox(), findsNothing);
      expect(find.text('غير مسجّلة'), findsNWidgets(2));
      expect(find.text('لا يوجد عنوان مسجّل لهذا العميل — أضفه إن عرفته'), findsOneWidget);
      expect(find.byType(PlacePickerTile), findsNWidgets(2));
    });

    testWidgets('a number not on file keeps the name box', (tester) async {
      // Arrange / Act
      await typePhone(tester, null);

      // Assert
      expect(nameBox(), findsOneWidget);
      expect(find.byType(PlacePickerTile), findsNWidgets(2));
    });
  });

  testWidgets('the discount section appears for whoever holds the grant', (tester) async {
    // Arrange
    session.adopt(
      const AuthUser(
        id: 1,
        name: 'موظف',
        phone: '0911234567',
        permissions: ['instant_orders.create', 'orders.discount'],
      ),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('الخصم'), findsOneWidget);
  });
}
