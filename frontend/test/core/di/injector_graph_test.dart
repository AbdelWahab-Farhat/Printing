import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/features/manufacturing_cost_rates/presentation/viewmodel/manufacturing_cost_rates_cubit.dart';
import 'package:printing/features/orders/presentation/viewmodel/line_quote_cubit.dart';
import 'package:printing/features/products/presentation/viewmodel/products_cubit.dart';
import 'package:printing/features/products/usecases/get_price_quote.dart';
import 'package:printing/features/reports/presentation/viewmodel/profit_and_loss_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The graph the app actually builds — not the hand-wired one every widget test builds.
///
/// Every other test registers the two or three objects its screen reaches for and moves on,
/// which is what let `GetPriceQuote` go unregistered while `LineQuoteCubit`'s factory asked for
/// it: nothing but a running phone ever resolved that factory. A `sl<T>()` inside a factory is
/// a dependency the compiler cannot see, so it has to be resolved somewhere for anyone to know
/// it is there.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Arrange — the two platform channels `Injector.init` touches before it registers
    // anything. Neither exists under `flutter_test`, and both are asked for a token the tests
    // below do not care about.
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );

    await Injector.reset();
    await Injector.init(onUnauthorized: () async {});
  });

  tearDown(Injector.reset);

  test('resolves the use case a line quote is built on', () {
    // Act
    final quote = sl<GetPriceQuote>();

    // Assert
    expect(quote, isA<GetPriceQuote>());
  });

  test('builds the Cubit the order form gives each of its lines', () {
    // Act — what `_addLine` does the moment a size is picked out of the product sheet.
    final cubit = sl<LineQuoteCubit>();

    // Assert
    expect(cubit, isA<LineQuoteCubit>());
    addTearDown(cubit.close);
  });

  test('builds the Cubit behind the product sheet itself', () {
    // Act
    final cubit = sl<ProductsCubit>();

    // Assert
    expect(cubit, isA<ProductsCubit>());
    addTearDown(cubit.close);
  });

  test('builds the Cubit the manufacturing cost rates list runs on', () {
    // Act — the factory resolves three use cases inside its closure, none of which the
    // compiler can see from the call site.
    final cubit = sl<ManufacturingCostRatesCubit>();

    // Assert
    expect(cubit, isA<ManufacturingCostRatesCubit>());
    addTearDown(cubit.close);
  });

  test('builds the Cubit behind the profit and loss report', () {
    // Act
    final cubit = sl<ProfitAndLossCubit>();

    // Assert
    expect(cubit, isA<ProfitAndLossCubit>());
    addTearDown(cubit.close);
  });
}
