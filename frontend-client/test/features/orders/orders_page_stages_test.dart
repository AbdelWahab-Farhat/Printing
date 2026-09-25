import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/orders_cubit.dart';
import 'package:dayaa_client/features/orders/presentation/views/orders_page.dart';
import 'package:dayaa_client/features/orders/presentation/views/stage_pill.dart';
import 'package:dayaa_client/features/orders/presentation/widgets/stage_filter_field.dart';
import 'package:dayaa_client/features/orders/repositories/order_repository.dart';
import 'package:dayaa_client/features/orders/usecases/browse_orders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}

/// «طلباتي»: الحالات خلف حقلٍ واحد يفتح ورقةً سفلية، لا شرائح تأكل أربعة أسطر من الشاشة (طلب
/// المستخدم، 2026-09-25).
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockOrderRepository repository;

  setUp(() {
    repository = _MockOrderRepository();
    when(
      () => repository.list(
        page: any(named: 'page'),
        openOnly: any(named: 'openOnly'),
        stage: any(named: 'stage'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        Paginated<CustomerOrder>(
          items: [],
          meta: PageMeta(currentPage: 1, perPage: 15, lastPage: 1, total: 0),
        ),
      ),
    );
    sl.registerFactory(() => OrdersCubit(browse: BrowseOrders(repository)));

    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(430, 932);
    view.devicePixelRatio = 1;
  });

  tearDown(() async {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
    await sl.reset();
  });

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
      home: OrdersPage(),
    ),
  );

  Finder inSheet(Finder finder) =>
      find.descendant(of: find.byType(BottomSheet), matching: finder);

  testWidgets('the stages sit behind one field, which starts on every order', (tester) async {
    // Arrange
    await tester.pumpWidget(host());

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(StageFilterField), findsOneWidget);
    expect(find.text('كل الحالات'), findsOneWidget);
    expect(find.text('جاري التوصيل'), findsNothing);
  });

  testWidgets('opening it lists every stage in a sheet, each with its icon', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byType(StageFilterField));
    await tester.pumpAndSettle();

    // Assert
    for (final filter in OrdersFilter.values) {
      expect(inSheet(find.text(filter.label)), findsOneWidget, reason: filter.label);
    }
    for (final filter in OrdersFilter.values.skip(1)) {
      expect(inSheet(find.byIcon(stageIcon(filter.stage!))), findsOneWidget, reason: filter.label);
    }
  });

  testWidgets('picking a stage narrows the list, closes the sheet, and the field says it', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(StageFilterField));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(inSheet(find.text('جاري التوصيل')));
    await tester.pumpAndSettle();

    // Assert
    verify(() => repository.list(page: 1, openOnly: false, stage: 'on_the_way')).called(1);
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.descendant(of: find.byType(StageFilterField), matching: find.text('جاري التوصيل')),
      findsOneWidget,
    );
  });

  testWidgets('the stage on screen is ticked when the sheet opens again', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(StageFilterField));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('جاهزة')));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byType(StageFilterField));
    await tester.pumpAndSettle();

    // Assert
    final ticked = inSheet(find.byIcon(AppIcons.check));
    expect(ticked, findsOneWidget);
    final readyRow = find.ancestor(of: inSheet(find.text('جاهزة')), matching: find.byType(InkWell));
    expect(find.descendant(of: readyRow.first, matching: find.byIcon(AppIcons.check)), findsOneWidget);
  });
}
