import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/cities/models/city.dart';

/// What a city card reads off the model, and nothing a widget is allowed to work out for
/// itself: whether this row is a branch or a destination, what its pill says, and what the line
/// under its name says.
///
/// Arrange - Act - Assert throughout.
void main() {
  Map<String, dynamic> cityJson(Map<String, dynamic> overrides) => {
    'id': 3,
    'name': 'طرابلس',
    'fulfilment_type': 'delivery',
    'fulfilment_type_label': 'توصيل',
    'is_office_pickup': false,
    'is_region_required': true,
    'delivery_price': '15.00',
    'darb_branch': 'زناتة، طرابلس',
    'regions_count': 50,
    ...overrides,
  };

  group('fulfilment type', () {
    test('an office pickup row is read from the server enum, not from its price', () {
      // Arrange — a branch that also happens to be free. The old rule was
      // `price == '0.00' && !isRegionRequired`, which this row satisfies *and* which a
      // free-delivery city would satisfy too.
      final json = cityJson({
        'name': 'إستلام مكتب(قرجي)',
        'fulfilment_type': 'office_pickup',
        'fulfilment_type_label': 'استلام مكتب',
        'is_office_pickup': true,
        'is_region_required': false,
        'delivery_price': '0.00',
        'regions_count': 0,
      });

      // Act
      final city = City.fromJson(json);

      // Assert
      expect(city.fulfilmentType, FulfilmentType.officePickup);
      expect(city.isOfficePickup, isTrue);
    });

    test('a city we deliver to for nothing is still a city, not a branch', () {
      // Arrange — free delivery, no regions: indistinguishable from a branch by price alone.
      final json = cityJson({
        'delivery_price': '0.00',
        'is_region_required': false,
        'regions_count': 0,
      });

      // Act
      final city = City.fromJson(json);

      // Assert
      expect(city.isOfficePickup, isFalse);
    });

    test('a fulfilment type this build has never heard of is treated as delivery', () {
      // Arrange — the server may add a case (shipping abroad, a courier) before the app ships.
      final json = cityJson({'fulfilment_type': 'air_freight'});

      // Act
      final city = City.fromJson(json);

      // Assert — a row we cannot classify is still a place on the map, not a crash.
      expect(city.fulfilmentType, FulfilmentType.delivery);
    });
  });

  group('priceLabel', () {
    test('a branch is free, and says so', () {
      // Arrange
      final city = City.fromJson(
        cityJson({'fulfilment_type': 'office_pickup', 'delivery_price': '0.00'}),
      );

      // Act
      final label = city.priceLabel;

      // Assert
      expect(label, 'مجاني');
    });

    test('a priced city shows the server string with the currency after it', () {
      // Arrange
      final city = City.fromJson(cityJson({}));

      // Act
      final label = city.priceLabel;

      // Assert — the server's own '15.00', never a double that reformatted it.
      expect(label, '15.00 د.ل');
    });

    test('no agreed rate is said in words, never as a zero', () {
      // Arrange — null is "nobody has agreed a price", which is not free.
      final city = City.fromJson(cityJson({'delivery_price': null}));

      // Act
      final label = city.priceLabel;

      // Assert
      expect(label, 'لم يُحدد');
      expect(label, isNot(contains('0')));
    });
  });

  group('subtitle', () {
    test('a branch says what it is instead of counting regions it has none of', () {
      // Arrange
      final city = City.fromJson(
        cityJson({'fulfilment_type': 'office_pickup', 'regions_count': 0, 'darb_branch': null}),
      );

      // Act
      final subtitle = city.subtitle;

      // Assert
      expect(subtitle, 'استلام ذاتي — بدون توصيل');
    });

    test('a city counts its regions and names its درب branch', () {
      // Arrange
      final city = City.fromJson(cityJson({}));

      // Act
      final subtitle = city.subtitle;

      // Assert
      expect(subtitle, '50 منطقة · زناتة، طرابلس');
    });

    test('nothing to say is null, so the card draws one line rather than an empty second', () {
      // Arrange
      final city = City.fromJson(cityJson({'regions_count': 0, 'darb_branch': null}));

      // Act
      final subtitle = city.subtitle;

      // Assert
      expect(subtitle, isNull);
    });
  });

  group('regions', () {
    test('a city with regions is worth opening; one without is not', () {
      // Arrange
      final withRegions = City.fromJson(cityJson({}));
      final withoutRegions = City.fromJson(cityJson({'regions_count': 0}));

      // Act
      final opens = withRegions.hasRegions;
      final doesNot = withoutRegions.hasRegions;

      // Assert
      expect(opens, isTrue);
      expect(doesNot, isFalse);
    });
  });
}
