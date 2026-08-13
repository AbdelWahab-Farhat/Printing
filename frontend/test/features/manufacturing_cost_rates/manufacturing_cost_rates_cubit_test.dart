import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/manufacturing_cost_rates/models/manufacturing_cost_rate.dart';
import 'package:printing/features/manufacturing_cost_rates/presentation/viewmodel/manufacturing_cost_rates_cubit.dart';
import 'package:printing/features/manufacturing_cost_rates/repositories/manufacturing_cost_rate_repository.dart';
import 'package:printing/features/manufacturing_cost_rates/usecases/manufacturing_cost_rate_usecases.dart';
import 'package:printing/features/vendors/models/stock_arrival.dart';

/// معدلات تكلفة التصنيع — the management screen's ViewModel.
///
/// The repository is faked, nothing touches Dio, and the assertions are on the sequence of states
/// the screen would have rendered.
///
/// **The list is not narrowed to one product, ever**, and one of these pins that: the default
/// rate is part of every product's answer, so a page filtered to «هذا المنتج» would show a ladder
/// with its bottom rung missing and read as though the product had no labour cost at all.
///
/// Arrange - Act - Assert throughout.
class _MockManufacturingCostRateRepository extends Mock
    implements ManufacturingCostRateRepository {}

void main() {
  late _MockManufacturingCostRateRepository repository;
  late ManufacturingCostRatesCubit cubit;

  const workshopLabour = ManufacturingCostRate(
    id: 1,
    costType: ManufacturingCostType.labor,
    costTypeLabel: 'عمالة',
    ratePerUnit: '3.500',
  );
  const bagLabour = ManufacturingCostRate(
    id: 2,
    product: ArrivalRef(id: 3, name: 'كيس ورقي'),
    costType: ManufacturingCostType.labor,
    costTypeLabel: 'عمالة',
    ratePerUnit: '4.000',
  );

  Paginated<ManufacturingCostRate> pageOf(
    List<ManufacturingCostRate> rates, {
    int currentPage = 1,
    int lastPage = 1,
  }) {
    return Paginated<ManufacturingCostRate>(
      items: rates,
      meta: PageMeta(
        currentPage: currentPage,
        perPage: 20,
        lastPage: lastPage,
        total: rates.length,
      ),
    );
  }

  /// Every page this fake is asked for, whatever the filters.
  void answerWith(Either<Failure, Paginated<ManufacturingCostRate>> result) {
    when(
      () => repository.rates(
        productId: any(named: 'productId'),
        productVariantId: any(named: 'productVariantId'),
        costType: any(named: 'costType'),
        isActive: any(named: 'isActive'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => result);
  }

  setUpAll(() => registerFallbackValue(ManufacturingCostType.labor));

  setUp(() {
    repository = _MockManufacturingCostRateRepository();
    cubit = ManufacturingCostRatesCubit(
      getRates: GetManufacturingCostRates(repository),
      setRateActivation: SetManufacturingCostRateActivation(repository),
      deleteRate: DeleteManufacturingCostRate(repository),
    );
  });

  tearDown(() => cubit.close());

  group('the list', () {
    blocTest<ManufacturingCostRatesCubit, ManufacturingCostRatesState>(
      'goes loading then loaded when the ladder answers',
      setUp: () {
        // Arrange
        answerWith(Right(pageOf(const [bagLabour, workshopLabour])));
      },
      build: () => cubit,
      // Act
      act: (cubit) => cubit.load(),
      // Assert — kept in the server's order: the narrow rung first, the default last.
      expect: () => [
        const ManufacturingCostRatesState.loading(),
        isA<ManufacturingCostRatesLoaded>().having(
          (state) => state.page.items.map((rate) => rate.scopeLabel),
          'rungs',
          ['كيس ورقي', 'افتراضي'],
        ),
      ],
    );

    blocTest<ManufacturingCostRatesCubit, ManufacturingCostRatesState>(
      'the management screen asks for the stopped rates too',
      setUp: () {
        // Arrange
        answerWith(Right(pageOf(const [workshopLabour])));
      },
      build: () => cubit,
      // Act
      act: (cubit) => cubit.load(),
      // Assert — a rate somebody stopped last month is exactly the one they come back for.
      verify: (_) {
        verify(
          () => repository.rates(
            productId: null,
            productVariantId: null,
            costType: null,
            isActive: null,
            page: 1,
            perPage: any(named: 'perPage'),
          ),
        ).called(1);
      },
    );

    blocTest<ManufacturingCostRatesCubit, ManufacturingCostRatesState>(
      'the sheet narrows both axes in one request',
      setUp: () {
        // Arrange
        answerWith(Right(pageOf(const [workshopLabour])));
      },
      build: () => cubit,
      // Act
      act: (cubit) => cubit.filterBy(
        costType: ManufacturingCostType.overhead,
        isActive: false,
      ),
      // Assert — two methods would have fetched the list twice for one tap on «تطبيق».
      verify: (_) {
        verify(
          () => repository.rates(
            productId: null,
            productVariantId: null,
            costType: ManufacturingCostType.overhead,
            isActive: false,
            page: 1,
            perPage: any(named: 'perPage'),
          ),
        ).called(1);
      },
    );

    blocTest<ManufacturingCostRatesCubit, ManufacturingCostRatesState>(
      'the same filter twice is one request',
      setUp: () {
        // Arrange
        answerWith(Right(pageOf(const [workshopLabour])));
      },
      build: () => cubit,
      // Act — «تطبيق» on a sheet nobody changed.
      act: (cubit) async {
        await cubit.filterBy(costType: ManufacturingCostType.labor, isActive: null);
        await cubit.filterBy(costType: ManufacturingCostType.labor, isActive: null);
      },
      // Assert
      verify: (_) {
        verify(
          () => repository.rates(
            productId: any(named: 'productId'),
            productVariantId: any(named: 'productVariantId'),
            costType: any(named: 'costType'),
            isActive: any(named: 'isActive'),
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
          ),
        ).called(1);
      },
    );

    blocTest<ManufacturingCostRatesCubit, ManufacturingCostRatesState>(
      'the server\'s own message is what a failure carries',
      setUp: () {
        // Arrange
        answerWith(const Left(Failure.server(message: 'ليس لديك صلاحية')));
      },
      build: () => cubit,
      // Act
      act: (cubit) => cubit.load(),
      // Assert — never replaced with a generic sentence: the server took the trouble to say
      // which refusal it was.
      expect: () => [
        const ManufacturingCostRatesState.loading(),
        isA<ManufacturingCostRatesFailure>().having(
          (state) => state.failure.message,
          'message',
          'ليس لديك صلاحية',
        ),
      ],
    );
  });

  group('stopping a rate', () {
    test('the list is re-read from the server rather than patched in place', () async {
      // Arrange — stopping a rate changes what a filtered list should contain, so a locally
      // edited copy would disagree with the server the moment it happened.
      answerWith(Right(pageOf(const [workshopLabour, bagLabour])));
      when(
        () => repository.setActivation(any(), isActive: any(named: 'isActive')),
      ).thenAnswer((_) async => const Right(workshopLabour));
      await cubit.load();

      // Act
      final failure = await cubit.setActivation(bagLabour, isActive: false);

      // Assert
      expect(failure, isNull);
      verify(() => repository.setActivation(2, isActive: false)).called(1);
      verify(
        () => repository.rates(
          productId: any(named: 'productId'),
          productVariantId: any(named: 'productVariantId'),
          costType: any(named: 'costType'),
          isActive: any(named: 'isActive'),
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).called(2);
    });

    test('a refusal comes back to the screen and the list is left alone', () async {
      // Arrange
      answerWith(Right(pageOf(const [workshopLabour])));
      when(
        () => repository.setActivation(any(), isActive: any(named: 'isActive')),
      ).thenAnswer((_) async => const Left(Failure.forbidden(message: 'لا صلاحية')));
      await cubit.load();

      // Act
      final failure = await cubit.setActivation(workshopLabour, isActive: false);

      // Assert — the screen says why nothing changed, in the server's words.
      expect(failure?.message, 'لا صلاحية');
      verify(
        () => repository.rates(
          productId: any(named: 'productId'),
          productVariantId: any(named: 'productVariantId'),
          costType: any(named: 'costType'),
          isActive: any(named: 'isActive'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).called(1);
    });
  });

  group('deleting a rate', () {
    test('the rate is removed and the list re-read', () async {
      // Arrange — nothing points at a rate by key, so this is never refused.
      answerWith(Right(pageOf(const [workshopLabour])));
      when(() => repository.delete(any())).thenAnswer((_) async => const Right('تم حذف المعدل'));
      await cubit.load();

      // Act
      final failure = await cubit.remove(workshopLabour);

      // Assert
      expect(failure, isNull);
      verify(() => repository.delete(1)).called(1);
    });
  });
}
