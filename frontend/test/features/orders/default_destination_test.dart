import 'package:dayaa/features/cities/models/city.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/orders/models/default_destination.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where «طلبية جديدة» starts: a chosen shop's place, else the customer's own address, else
/// nothing. Arrange - Act - Assert throughout.
void main() {
  const tripoli = City(id: 1, name: 'طرابلس', isRegionRequired: false);
  const soukAlJumaa = Region(id: 11, cityId: 1, name: 'سوق الجمعة');
  const misrata = City(id: 2, name: 'مصراتة', isRegionRequired: false);
  const zarrouq = Region(id: 21, cityId: 2, name: 'الزروق');

  const shop = CustomerShop(
    id: 3,
    name: 'فرع مصراتة',
    cityId: 2,
    city: misrata,
    regionId: 21,
    region: zarrouq,
  );

  const withAddress = Customer(
    id: 7,
    code: 'A7',
    name: 'مطبعة النور',
    phone: '0913334444',
    isActive: true,
    cityId: 1,
    city: tripoli,
    regionId: 11,
    region: soukAlJumaa,
    shops: [shop],
  );

  final withoutAddress = withAddress.copyWith(
    cityId: null,
    city: null,
    regionId: null,
    region: null,
  );

  group('defaultDestinationFor', () {
    test('a chosen shop wins over the customer’s own address', () {
      // Act
      final destination = defaultDestinationFor(withAddress, shop);

      // Assert
      expect(destination.city, misrata);
      expect(destination.region, zarrouq);
    });

    test('with no shop, the customer’s own address', () {
      // Act
      final destination = defaultDestinationFor(withAddress, null);

      // Assert
      expect(destination.city, tripoli);
      expect(destination.region, soukAlJumaa);
    });

    test('with neither, nothing', () {
      // Act
      final destination = defaultDestinationFor(withoutAddress, null);

      // Assert
      expect(destination.city, isNull);
      expect(destination.region, isNull);
    });

    test('a region is never kept without its city', () {
      // Arrange — the city was deleted; the server sends `city: null` beside a live region.
      final orphaned = withAddress.copyWith(city: null);

      // Act
      final destination = defaultDestinationFor(orphaned, null);

      // Assert
      expect(destination.city, isNull);
      expect(destination.region, isNull);
    });
  });

  group('initialShopFor', () {
    test('no shop while the customer has an address of their own', () {
      expect(initialShopFor(withAddress), isNull);
    });

    test('the only shop, when there is no address', () {
      expect(initialShopFor(withoutAddress), shop);
    });

    test('no guess among several shops', () {
      // Arrange
      final several = withoutAddress.copyWith(
        shops: const [shop, CustomerShop(id: 4, name: 'فرع طرابلس')],
      );

      // Assert
      expect(initialShopFor(several), isNull);
    });

    test('nothing for a customer with no shops', () {
      expect(initialShopFor(withoutAddress.copyWith(shops: const [])), isNull);
    });
  });
}
