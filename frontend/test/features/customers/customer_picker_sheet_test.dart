import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/presentation/viewmodel/customers_cubit.dart';
import 'package:printing/features/customers/presentation/widgets/customer_picker_sheet.dart';
import 'package:printing/features/customers/repositories/customer_repository.dart';
import 'package:printing/features/customers/usecases/get_customers.dart';

/// Naming the customer an order is being taken for.
///
/// **This is the only place in the app where a customer is chosen for an order.** «طلبية جديدة»
/// opened from a customer's own screen names them by *being on that screen* — there is no field
/// in the form, because `customer_id` is read on create and ignored afterwards, so the wrong one
/// cannot be corrected. The home-screen shortcut has no such screen behind it, so it asks here,
/// before the form opens, and hands the answer to the same route.
///
/// Arrange - Act - Assert throughout.
class _MockCustomerRepository extends Mock implements CustomerRepository {}

void main() {
  late _MockCustomerRepository repository;

  const nour = Customer(
    id: 7,
    code: 'C7',
    name: 'مطبعة النور',
    phone: '0912345678',
    isActive: true,
  );

  Paginated<Customer> page(List<Customer> items) => Paginated(
    items: items,
    meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: items.length),
  );

  setUp(() async {
    await Injector.reset();

    repository = _MockCustomerRepository();

    when(
      () => repository.customers(
        search: any(named: 'search'),
        isActive: any(named: 'isActive'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(page([nour])));

    sl.registerFactory<CustomersCubit>(
      () => CustomersCubit(getCustomers: GetCustomers(repository), onlyActive: true),
      instanceName: Injector.activeCustomersCubit,
    );
  });

  tearDown(Injector.reset);

  /// A screen with one button on it, standing in for the home shortcut.
  Widget host(void Function(Customer?) onPicked) => ScreenUtilInit(
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
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async => onPicked(await showCustomerPicker(context: context)),
              child: const Text('افتح'),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('it offers only the customers still being sold to', (tester) async {
    // Arrange
    await tester.pumpWidget(host((_) {}));

    // Act
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    // Assert — a deactivated customer is somebody the shop stopped selling to, and `CreateOrder`
    // refuses the order anyway. Offering them here would mean filling in a whole form for a
    // request that cannot be granted.
    verify(
      () => repository.customers(
        search: any(named: 'search'),
        isActive: true,
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).called(1);

    expect(find.text('مطبعة النور'), findsOneWidget);
  });

  testWidgets('picking one hands that customer back to the caller', (tester) async {
    // Arrange
    Customer? picked;

    await tester.pumpWidget(host((customer) => picked = customer));
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('مطبعة النور'));
    await tester.pumpAndSettle();

    // Assert — the whole customer, not an id: the form opens with their name already in place
    // rather than on a spinner, which is what the customer's own screen hands it today.
    expect(picked, nour);
  });

  testWidgets('backing out answers with nobody', (tester) async {
    // Arrange
    var calls = 0;
    Customer? picked;

    await tester.pumpWidget(
      host((customer) {
        calls++;
        picked = customer;
      }),
    );

    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    // Act
    Navigator.of(tester.element(find.text('مطبعة النور'))).pop();
    await tester.pumpAndSettle();

    // Assert — an ordinary ending. The caller must not open an order form on it.
    expect(calls, 1);
    expect(picked, isNull);
  });
}
