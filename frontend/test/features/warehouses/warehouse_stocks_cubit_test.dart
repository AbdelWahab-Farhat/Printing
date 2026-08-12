import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/warehouses/models/warehouse_stock.dart';
import 'package:printing/features/warehouses/models/warehouse_stock_summary.dart';
import 'package:printing/features/warehouses/presentation/viewmodel/stock_summary_cubit.dart';
import 'package:printing/features/warehouses/presentation/viewmodel/warehouse_stocks_cubit.dart';
import 'package:printing/features/warehouses/repositories/warehouse_repository.dart';
import 'package:printing/features/warehouses/usecases/get_stock_summary.dart';
import 'package:printing/features/warehouses/usecases/get_warehouse_stocks.dart';
import 'package:printing/features/warehouses/usecases/set_low_stock_threshold.dart';

/// The shelves screen's two ViewModels: the list, and the numbers above it.
///
/// The list's filter is three-way now — everything, what is asking to be refilled, and what has
/// run out — and each of the three has to reach the server as the filter the summary counted
/// with, or a button will promise a number the list then contradicts.
///
/// Arrange - Act - Assert throughout.
class _MockWarehouseRepository extends Mock implements WarehouseRepository {}

void main() {
  late _MockWarehouseRepository repository;

  const summary = WarehouseStockSummary(
    totalLines: 24,
    totalQuantity: '12450.000',
    lowStockCount: 4,
    outOfStockCount: 2,
    healthyCount: 18,
  );

  Paginated<WarehouseStock> emptyPage() => const Paginated<WarehouseStock>(
    items: <WarehouseStock>[],
    meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 0),
  );

  WarehouseStocksCubit buildList() => WarehouseStocksCubit(
    warehouseId: 1,
    getStocks: GetWarehouseStocks(repository),
    setThreshold: SetLowStockThreshold(repository),
  );

  StockSummaryCubit buildSummary() =>
      StockSummaryCubit(warehouseId: 1, getSummary: GetStockSummary(repository));

  setUp(() {
    repository = _MockWarehouseRepository();

    when(
      () => repository.stocks(
        any(),
        lowStock: any(named: 'lowStock'),
        inStock: any(named: 'inStock'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(emptyPage()));

    when(() => repository.stockSummary(any())).thenAnswer((_) async => const Right(summary));
  });

  group('the list filter', () {
    test('«الكل» asks the server for no narrowing at all', () async {
      // Arrange
      final cubit = buildList();

      // Act
      await cubit.load();

      // Assert
      verify(
        () => repository.stocks(1, lowStock: null, inStock: null, page: 1, perPage: any(named: 'perPage')),
      ).called(1);
      await cubit.close();
    });

    test('«تحت الحد» asks for the lines that have fallen to their level', () async {
      // Arrange
      final cubit = buildList();

      // Act
      await cubit.filterBy(StockShelfFilter.low);

      // Assert
      verify(
        () => repository.stocks(1, lowStock: true, inStock: null, page: 1, perPage: any(named: 'perPage')),
      ).called(1);
      await cubit.close();
    });

    test('«نافد» asks for what is *not* in stock, which is a different question', () async {
      // Arrange
      final cubit = buildList();

      // Act
      await cubit.filterBy(StockShelfFilter.out);

      // Assert — not `lowStock`, because a shelf nobody set a threshold on is empty all the same
      verify(
        () => repository.stocks(1, lowStock: null, inStock: false, page: 1, perPage: any(named: 'perPage')),
      ).called(1);
      await cubit.close();
    });

    test('choosing the filter already showing does not re-ask', () async {
      // Arrange
      final cubit = buildList();
      await cubit.load();

      // Act
      await cubit.filterBy(StockShelfFilter.all);

      // Assert
      verify(
        () => repository.stocks(
          any(),
          lowStock: any(named: 'lowStock'),
          inStock: any(named: 'inStock'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).called(1);
      await cubit.close();
    });
  });

  group('the summary', () {
    blocTest<StockSummaryCubit, StockSummaryState>(
      'loads the whole warehouse, whatever the list is filtered to',
      build: buildSummary,
      act: (cubit) => cubit.load(),
      expect: () => [
        const StockSummaryState.loading(),
        const StockSummaryState.loaded(summary),
      ],
      verify: (_) => verify(() => repository.stockSummary(1)).called(1),
    );

    blocTest<StockSummaryCubit, StockSummaryState>(
      'a failed summary is a card that stays away, not a screen that breaks',
      build: () {
        when(() => repository.stockSummary(any())).thenAnswer(
          (_) async => const Left(Failure.server(message: 'تعذر الاتصال')),
        );

        return buildSummary();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const StockSummaryState.loading(),
        const StockSummaryState.failure(),
      ],
    );

    blocTest<StockSummaryCubit, StockSummaryState>(
      'a refresh keeps the numbers on screen rather than blanking them first',
      build: buildSummary,
      seed: () => const StockSummaryState.loaded(summary),
      act: (cubit) => cubit.refresh(),
      // No `loading` in between: the card is already showing numbers, and replacing them with a
      // skeleton for the length of a request is a flicker, not information.
      expect: () => <StockSummaryState>[],
      verify: (_) => verify(() => repository.stockSummary(1)).called(1),
    );

    blocTest<StockSummaryCubit, StockSummaryState>(
      'a refresh that fails leaves the numbers that were already there',
      build: buildSummary,
      seed: () => const StockSummaryState.loaded(summary),
      act: (cubit) {
        when(() => repository.stockSummary(any())).thenAnswer(
          (_) async => const Left(Failure.network(message: 'انقطع الاتصال')),
        );

        return cubit.refresh();
      },
      expect: () => <StockSummaryState>[],
    );
  });
}
