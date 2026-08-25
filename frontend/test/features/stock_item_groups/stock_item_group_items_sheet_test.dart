import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/stock_item_groups/models/stock_item_group.dart';
import 'package:dayaa/features/stock_item_groups/presentation/viewmodel/stock_item_group_items_cubit.dart';
import 'package:dayaa/features/stock_item_groups/presentation/widgets/stock_item_group_items_sheet.dart';
import 'package:dayaa/features/stock_item_groups/repositories/stock_item_group_repository.dart';
import 'package:dayaa/features/stock_item_groups/usecases/get_stock_item_group.dart';
import 'package:dayaa/features/stock_items/models/stock_item.dart';
import 'package:dayaa/features/stock_items/models/stock_unit.dart';
import 'package:dayaa/features/stock_items/presentation/views/stock_item_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Opening a material **under a category**, from the sheet that lists what the category holds.
///
/// **The form has always been able to do this and nothing ever asked it to.** `StockItemFormArgs`
/// carries a `group`, and given one the form locks the name to the category's and fixes the unit
/// to its `default_unit` — but the only call site passed `item:` and never `group:`, so every
/// material created by hand was born category-less, permanently: `stock_item_group_id` is
/// accepted by `POST /stock-items` and by nothing else.
///
/// So what is asserted here is the *handover*, not the form: that the button exists where a
/// category is already on screen, that it hands over that category, and that the sheet re-reads
/// itself when the form says it saved. The form's own behaviour under a group is its business.
///
/// Arrange - Act - Assert throughout.
class _FakeRepository implements StockItemGroupRepository {
  _FakeRepository(this._group);

  StockItemGroup _group;

  /// How many times the sheet has asked. The reload after a save is the only reason this exists.
  int reads = 0;

  /// Answers the next read with a material added, the way the server would after a create.
  void gainsAMaterial(StockItem item) {
    _group = _group.copyWith(
      items: [..._group.items, item],
      itemsCount: (_group.itemsCount ?? 0) + 1,
    );
  }

  @override
  Future<Either<Failure, StockItemGroup>> group(int groupId) async {
    reads++;

    return Right(_group);
  }

  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Session session;
  late _FakeRepository repository;

  /// What the sheet is opened on — the row that was tapped, counts and all.
  const shippingBags = StockItemGroup(
    id: 3,
    code: 'G3',
    name: 'كيس شحن',
    defaultUnit: StockUnit.piece,
    defaultUnitLabel: 'قطعة',
    isActive: true,
    sortOrder: 0,
    itemsCount: 1,
    items: [
      StockItem(
        id: 7,
        code: 'S7',
        name: 'كيس شحن',
        displayName: 'كيس شحن 25*35',
        unit: StockUnit.piece,
        unitLabel: 'قطعة',
        isActive: true,
        sortOrder: 0,
        widthCm: 25,
        heightCm: 35,
      ),
    ],
  );

  const anotherSize = StockItem(
    id: 8,
    code: 'S8',
    name: 'كيس شحن',
    displayName: 'كيس شحن 35*40',
    unit: StockUnit.piece,
    unitLabel: 'قطعة',
    isActive: true,
    sortOrder: 0,
    widthCm: 35,
    heightCm: 40,
  );

  AuthUser userWith(List<String> permissions) => AuthUser(
    id: 1,
    name: 'عبدالوهاب',
    phone: '0911234567',
    permissions: permissions,
  );

  /// What the form was handed, captured instead of built.
  StockItemFormArgs? handed;

  /// What the form answers when it closes. `true` is «saved», which is what triggers the reload.
  bool? formAnswers;

  setUp(() async {
    await Injector.reset();

    handed = null;
    formAnswers = true;

    session = Session();
    sl.registerSingleton<Session>(session);

    repository = _FakeRepository(shippingBags);
    sl.registerLazySingleton<GetStockItemGroup>(() => GetStockItemGroup(repository));
    sl.registerFactoryParam<StockItemGroupItemsCubit, int, void>(
      (groupId, _) => StockItemGroupItemsCubit(
        groupId: groupId,
        getGroup: sl<GetStockItemGroup>(),
      ),
    );
  });

  tearDown(Injector.reset);

  Widget host() {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showStockItemGroupItemsSheet(
                    context: context,
                    group: shippingBags,
                  ),
                  child: const Text('افتح'),
                ),
              ),
            ),
          ),
        ),
        // Stands in for the real form, which is exercised on its own. All this has to do is
        // record what it was handed and answer the way a saved form answers.
        GoRoute(
          path: '/stock-items/form',
          builder: (context, state) {
            handed = state.extra as StockItemFormArgs?;

            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => context.pop(formAnswers),
                  child: const Text('أغلق النموذج'),
                ),
              ),
            );
          },
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp.router(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
  }

  Future<void> openTheSheet(WidgetTester tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
  }

  testWidgets('the category offers a material of its own', (tester) async {
    // Arrange
    session.adopt(userWith([AppPermission.manageInventory.wire]));

    // Act
    await openTheSheet(tester);

    // Assert
    expect(find.text('مادة جديدة'), findsOneWidget);
  });

  testWidgets('a reader is not offered one', (tester) async {
    // Arrange — the same screen, one permission short.
    session.adopt(userWith([AppPermission.viewInventory.wire]));

    // Act
    await openTheSheet(tester);

    // Assert — absent rather than disabled: the server refuses either way, and a control that
    // cannot be used is a question the reader has to answer for themselves.
    expect(find.text('مادة جديدة'), findsNothing);
    expect(find.text('كيس شحن 25*35'), findsOneWidget);
  });

  testWidgets('the form is handed the category it was opened from', (tester) async {
    // Arrange
    session.adopt(userWith([AppPermission.manageInventory.wire]));
    await openTheSheet(tester);

    // Act
    await tester.tap(find.text('مادة جديدة'));
    await tester.pumpAndSettle();

    // Assert — this is the whole point: given a group the form locks the name to «كيس شحن» and
    // takes «قطعة» from it, and the material is created filed rather than loose.
    expect(handed, isNotNull);
    expect(handed!.item, isNull);
    expect(handed!.group?.id, 3);
    expect(handed!.group?.name, 'كيس شحن');
    expect(handed!.group?.defaultUnit, StockUnit.piece);
  });

  testWidgets('a saved material appears without closing the sheet', (tester) async {
    // Arrange
    session.adopt(userWith([AppPermission.manageInventory.wire]));
    await openTheSheet(tester);
    expect(repository.reads, 1);
    repository.gainsAMaterial(anotherSize);

    // Act
    await tester.tap(find.text('مادة جديدة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أغلق النموذج'));
    await tester.pumpAndSettle();

    // Assert — the sizes are `items[]` on the material's own response, so the only way to see a
    // new one is to ask again.
    expect(repository.reads, 2);
    expect(find.text('كيس شحن 35*40'), findsOneWidget);
  });

  testWidgets('a dismissed form costs nothing', (tester) async {
    // Arrange — the form closed without saving, which is what a back-press answers.
    session.adopt(userWith([AppPermission.manageInventory.wire]));
    formAnswers = null;
    await openTheSheet(tester);

    // Act
    await tester.tap(find.text('مادة جديدة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أغلق النموذج'));
    await tester.pumpAndSettle();

    // Assert — a refetch after a dismissed form flickers the list under the thumb for nothing.
    expect(repository.reads, 1);
  });
}
