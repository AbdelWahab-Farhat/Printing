import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/models/customers_filter.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customers_cubit.dart';
import 'package:dayaa/features/customers/repositories/customer_repository.dart';
import 'package:dayaa/features/customers/usecases/get_customers.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/investors_cubit.dart';
import 'package:dayaa/features/investors/repositories/investor_repository.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:dayaa/features/root/presentation/views/parties_page.dart';
import 'package:dayaa/features/vendors/models/vendor.dart';
import 'package:dayaa/features/vendors/presentation/viewmodel/vendors_cubit.dart';
import 'package:dayaa/features/vendors/repositories/vendor_repository.dart';
import 'package:dayaa/features/vendors/usecases/get_vendors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// «الجهات» — the three registers of people, and who is shown which of them.
///
/// The thing worth proving is the gate: a tab the server would answer with 403 must not be
/// swipeable, because the empty list under it reads as «لا يوجد موردون» — a different and wrong
/// sentence from «you may not look».
///
/// Arrange - Act - Assert throughout.
class _MockCustomerRepository extends Mock implements CustomerRepository {}

class _MockVendorRepository extends Mock implements VendorRepository {}

class _MockInvestorRepository extends Mock implements InvestorRepository {}

void main() {
  setUpAll(() => registerFallbackValue(CustomersSort.newest));

  const emptyMeta = PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 0);

  Future<void> arrange(List<String> permissions) async {
    await Injector.reset();

    final customers = _MockCustomerRepository();
    when(
      () => customers.customers(
        search: any(named: 'search'),
        isActive: any(named: 'isActive'),
        hasOrders: any(named: 'hasOrders'),
        sort: any(named: 'sort'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => const Right(Paginated<Customer>(items: [], meta: emptyMeta)),
    );
    sl.registerFactory<CustomersCubit>(
      () => CustomersCubit(getCustomers: GetCustomers(customers)),
    );

    final vendors = _MockVendorRepository();
    when(
      () => vendors.vendors(
        search: any(named: 'search'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => const Right(Paginated<Vendor>(items: [], meta: emptyMeta)));
    sl.registerFactory<VendorsCubit>(() => VendorsCubit(getVendors: GetVendors(vendors)));

    final investors = _MockInvestorRepository();
    when(
      () => investors.investors(
        search: any(named: 'search'),
        isActive: any(named: 'isActive'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => const Right(Paginated<Investor>(items: [], meta: emptyMeta)));
    sl.registerFactory<InvestorsCubit>(
      () => InvestorsCubit(getInvestors: GetInvestors(investors)),
    );

    sl.registerSingleton<Session>(
      Session()
        ..adopt(
          AuthUser(
            id: 1,
            name: 'عبدالوهاب',
            phone: '0911234567',
            permissions: permissions,
          ),
        ),
    );
  }

  tearDown(Injector.reset);

  /// The frame the app actually boots into — the dial draws into the app's overlay, so the
  /// locale belongs on `MaterialApp` rather than on a `Directionality` inside it.
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
      home: PartiesPage(),
    ),
  );

  testWidgets('all three registers are tabs of one screen', (tester) async {
    // Arrange
    await arrange(['customers.view', 'vendors.view', 'investors.view']);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('العملاء'), findsOneWidget);
    expect(find.text('الموردون'), findsOneWidget);
    expect(find.text('المستثمرون'), findsOneWidget);
  });

  testWidgets('a register this reader may not open is not a tab', (tester) async {
    // Arrange — customers and suppliers, but no investors.
    await arrange(['customers.view', 'vendors.view']);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — absent, not empty: a tab whose list would come back 403 reads as «لا يوجد
    // مستثمرون», which is not what happened.
    expect(find.text('المستثمرون'), findsNothing);
    expect(find.text('الموردون'), findsOneWidget);
  });

  testWidgets('one register left is a list, not a tab bar over a single tab', (tester) async {
    // Arrange
    await arrange(['customers.view']);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('one dial adds any of the three', (tester) async {
    // Arrange — a phone rather than the binding's 800×600, because the dial's children are
    // pills laid out against the real screen width.
    tester.view
      ..physicalSize = const Size(430 * 3, 932 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await arrange([
      'customers.view',
      'customers.manage',
      'vendors.view',
      'vendors.manage',
      'investors.view',
      'investors.manage',
    ]);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act — open it.
    await tester.tap(find.byType(FloatingActionButton).last);
    await tester.pumpAndSettle();

    // Assert — three registers, one button, and «إضافة عميل» is the one nearest the thumb.
    expect(find.text('إضافة عميل'), findsOneWidget);
    expect(find.text('إضافة مورد'), findsOneWidget);
    expect(find.text('إضافة مستثمر'), findsOneWidget);
  });

  testWidgets('the dial offers only what this reader may write', (tester) async {
    // Arrange — may read all three, may register only a customer.
    await arrange([
      'customers.view',
      'customers.manage',
      'vendors.view',
      'investors.view',
    ]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — one action collapses the dial to a plain button, already labelled.
    expect(find.text('إضافة عميل'), findsOneWidget);
    expect(find.text('إضافة مورد'), findsNothing);
    expect(find.text('إضافة مستثمر'), findsNothing);
  });
}
