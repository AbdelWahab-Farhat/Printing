import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/shops/models/shop.dart';
import 'package:dayaa_client/features/shops/presentation/viewmodel/shops_cubit.dart';
import 'package:dayaa_client/features/shops/repositories/shop_repository.dart';
import 'package:dayaa_client/features/shops/usecases/list_shops.dart';
import 'package:dayaa_client/features/shops/usecases/remove_shop.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockShopRepository extends Mock implements ShopRepository {}

/// «متاجري» — القائمة تُرقَّع ولا تُعاد قراءتها: المتجر المحفوظ يعود من النموذج ويوضع مكانه.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockShopRepository repository;

  const noor = Shop(id: 1, name: 'متجر النور', cityId: 1, cityName: 'بنغازي');
  const amal = Shop(id: 2, name: 'متجر الأمل', cityId: 2, cityName: 'طرابلس');

  setUp(() => repository = _MockShopRepository());

  ShopsCubit build() => ShopsCubit(list: ListShops(repository), remove: RemoveShop(repository));

  group('load', () {
    blocTest<ShopsCubit, ShopsState>(
      'emits loading then the shops, in the order they were added',
      // Arrange
      build: () {
        when(() => repository.list()).thenAnswer((_) async => const Right([noor, amal]));

        return build();
      },
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => const [
        ShopsState.loading(),
        ShopsState.loaded([noor, amal]),
      ],
    );

    blocTest<ShopsCubit, ShopsState>(
      'shows the server’s own words when the first load fails',
      // Arrange
      build: () {
        when(() => repository.list())
            .thenAnswer((_) async => const Left(NetworkFailure(message: 'لا يوجد اتصال')));

        return build();
      },
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => const [
        ShopsState.loading(),
        ShopsState.failure(NetworkFailure(message: 'لا يوجد اتصال')),
      ],
    );

    blocTest<ShopsCubit, ShopsState>(
      'an account with no shops is an empty list, not an error',
      // Arrange
      build: () {
        when(() => repository.list()).thenAnswer((_) async => const Right(<Shop>[]));

        return build();
      },
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => const [
        ShopsState.loading(),
        ShopsState.loaded(<Shop>[]),
      ],
    );
  });

  group('saved', () {
    blocTest<ShopsCubit, ShopsState>(
      'a new shop joins the end of the list, where the server puts it',
      // Arrange
      build: build,
      seed: () => const ShopsState.loaded([noor]),
      // Act
      act: (cubit) => cubit.saved(amal),
      // Assert
      expect: () => const [
        ShopsState.loaded([noor, amal]),
      ],
      verify: (_) => verifyNever(() => repository.list()),
    );

    blocTest<ShopsCubit, ShopsState>(
      'an edited shop takes its own place rather than moving to the end',
      // Arrange
      build: build,
      seed: () => const ShopsState.loaded([noor, amal]),
      // Act
      act: (cubit) => cubit.saved(noor.copyWith(name: 'النور الجديد')),
      // Assert
      expect: () => [
        ShopsState.loaded([noor.copyWith(name: 'النور الجديد'), amal]),
      ],
    );
  });

  group('remove', () {
    blocTest<ShopsCubit, ShopsState>(
      'keeps the list on screen while the delete is in flight, then drops the row',
      // Arrange
      build: () {
        when(() => repository.remove(1)).thenAnswer((_) async => const Right(unit));

        return build();
      },
      seed: () => const ShopsState.loaded([noor, amal]),
      // Act
      act: (cubit) => cubit.remove(1),
      // Assert
      expect: () => const [
        ShopsState.loaded([noor, amal], isBusy: true),
        ShopsState.loaded([amal]),
      ],
    );

    blocTest<ShopsCubit, ShopsState>(
      'a refused delete leaves every shop where it was, with the reason beside it',
      // Arrange
      build: () {
        when(() => repository.remove(1)).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'تعذّر الحذف', statusCode: 500)),
        );

        return build();
      },
      seed: () => const ShopsState.loaded([noor, amal]),
      // Act
      act: (cubit) => cubit.remove(1),
      // Assert
      expect: () => const [
        ShopsState.loaded([noor, amal], isBusy: true),
        ShopsState.loaded(
          [noor, amal],
          lastFailure: ServerFailure(message: 'تعذّر الحذف', statusCode: 500),
        ),
      ],
    );
  });
}
