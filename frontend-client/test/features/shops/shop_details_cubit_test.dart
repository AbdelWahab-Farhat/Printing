import 'package:bloc_test/bloc_test.dart';
import 'package:dayaa_client/features/shops/models/shop.dart';
import 'package:dayaa_client/features/shops/presentation/viewmodel/shop_details_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

/// صفحة المتجر: تُفتح على ما في القائمة، ويحلّ محلّه ما يعود من نموذج التعديل.
///
/// Arrange - Act - Assert throughout.
void main() {
  const noor = Shop(id: 5, name: 'متجر النور', cityId: 1, cityName: 'بنغازي');

  blocTest<ShopDetailsCubit, Shop>(
    'opens on the shop it was handed, with no request of its own',
    // Arrange & Act
    build: () => ShopDetailsCubit(noor),
    // Assert
    verify: (cubit) => expect(cubit.state, noor),
  );

  blocTest<ShopDetailsCubit, Shop>(
    'the saved edit replaces what the page shows',
    // Arrange
    build: () => ShopDetailsCubit(noor),
    // Act
    act: (cubit) => cubit.edited(noor.copyWith(name: 'النور الجديد', pageUrl: 'https://x.ly')),
    // Assert
    expect: () => [noor.copyWith(name: 'النور الجديد', pageUrl: 'https://x.ly')],
  );

  blocTest<ShopDetailsCubit, Shop>(
    'another shop is not this page’s to show',
    // Arrange
    build: () => ShopDetailsCubit(noor),
    // Act
    act: (cubit) => cubit.edited(const Shop(id: 6, name: 'متجر الأمل', cityId: 2)),
    // Assert
    expect: () => const <Shop>[],
  );
}
