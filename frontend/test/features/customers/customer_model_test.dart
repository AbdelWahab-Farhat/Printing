import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/customers/models/customer.dart';

/// The seam between Laravel's `snake_case` and this app, tested against the exact body the API
/// sends — see `CustomerResource` and `backend/tests/Feature/Api/V1/CustomerTest.php`.
///
/// This is the whole justification for `@JsonKey` replacing a separate entity class: if the
/// backend renames a field, it fails here rather than showing up as an empty box on a screen.
///
/// Arrange - Act - Assert throughout.
void main() {
  test('parses a freshly created customer, keys and all', () {
    // Arrange — the `data` block of a 201 from POST /customers.
    final json = <String, dynamic>{
      'id': 1,
      'code': 'C1',
      'name': 'مخبز النخيل',
      'phone': '0912345678',
      'is_active': true,
      'shops': <dynamic>[],
      'created_at': '2026-07-31T10:00:00+00:00',
      'updated_at': '2026-07-31T10:00:00+00:00',
    };

    // Act
    final customer = Customer.fromJson(json);

    // Assert
    expect(customer.id, 1);
    expect(customer.code, 'C1');
    expect(customer.name, 'مخبز النخيل');
    expect(customer.phone, '0912345678');
    expect(customer.isActive, isTrue);
    expect(customer.shops, isEmpty);
    expect(customer.createdAt, DateTime.parse('2026-07-31T10:00:00+00:00'));
  });

  test('parses the shops the API returns inline', () {
    // Arrange — coordinates arrive as numbers, ready for a map SDK, and a shop with no page
    // link carries null rather than an empty string.
    final json = <String, dynamic>{
      'id': 2,
      'code': 'C2',
      'name': 'مطبعة النور',
      'phone': '0912345679',
      'is_active': true,
      'shops': <dynamic>[
        {
          'id': 5,
          'name': 'فرع طرابلس',
          'latitude': 32.8872,
          'longitude': 13.1913,
          'page_url': 'https://facebook.com/branch1',
        },
        {
          'id': 6,
          'name': 'فرع بنغازي',
          'latitude': 32.1167,
          'longitude': 20.0686,
          'page_url': null,
        },
      ],
    };

    // Act
    final customer = Customer.fromJson(json);

    // Assert
    expect(customer.hasShops, isTrue);
    expect(customer.shops, hasLength(2));
    expect(customer.shops!.first.name, 'فرع طرابلس');
    expect(customer.shops!.first.latitude, 32.8872);
    expect(customer.shops!.first.pageUrl, 'https://facebook.com/branch1');
    expect(customer.shops!.first.hasPin, isTrue);
    expect(customer.shops!.last.pageUrl, isNull);
  });

  test('an unloaded `shops` key is absent, which is not the same as having none', () {
    // Arrange — `whenLoaded` on the backend omits the key entirely rather than sending [].
    final json = <String, dynamic>{
      'id': 3,
      'code': 'C3',
      'name': 'عميل',
      'phone': '0912345670',
      'is_active': false,
    };

    // Act
    final customer = Customer.fromJson(json);

    // Assert — null, so a screen can tell "not requested" from "this customer has no shops"
    // and avoid claiming the second when it only knows the first.
    expect(customer.shops, isNull);
    expect(customer.hasShops, isFalse);
    expect(customer.isActive, isFalse);
    expect(customer.createdAt, isNull);
  });

  test('a shop reads back the city and the region the API named it by', () {
    // Arrange — the server sends both the ids a form preselects and the names a screen renders,
    // so nothing here has to fetch the delivery map to translate two numbers.
    final json = <String, dynamic>{
      'id': 4,
      'name': 'محل الأناقة',
      'city_id': 3,
      'city': {'id': 3, 'name': 'طرابلس', 'is_region_required': true},
      'region_id': 11,
      'region': {'id': 11, 'city_id': 3, 'name': 'سوق الجمعة'},
      'page_url': null,
    };

    // Act
    final shop = CustomerShop.fromJson(json);

    // Assert
    expect(shop.cityId, 3);
    expect(shop.city!.name, 'طرابلس');
    expect(shop.regionId, 11);
    expect(shop.region!.name, 'سوق الجمعة');
    expect(shop.placeLabel, 'طرابلس · سوق الجمعة');
  });

  test('a shop with no region says only its city', () {
    // Arrange — most cities on the map have no neighbourhoods at all.
    final json = <String, dynamic>{
      'id': 5,
      'name': 'فرع مصراتة',
      'city_id': 9,
      'city': {'id': 9, 'name': 'مصراتة', 'is_region_required': false},
      'region_id': null,
      'region': null,
    };

    // Act
    final shop = CustomerShop.fromJson(json);

    // Assert — «مصراتة ·» with a trailing separator would be the bug this asserts against.
    expect(shop.placeLabel, 'مصراتة');
  });

  test('a shop whose city was not loaded has nothing to say about where it is', () {
    // Arrange — the relation is omitted when it was not requested, and resolves to null for a
    // city that has since been deleted off the map. Both are «we cannot name the place», which
    // a screen has to be able to tell from an empty string it would render as a blank line.
    final json = <String, dynamic>{'id': 6, 'name': 'محل', 'city_id': 3};

    // Act
    final shop = CustomerShop.fromJson(json);

    // Assert
    expect(shop.cityId, 3);
    expect(shop.city, isNull);
    expect(shop.placeLabel, isNull);
  });

  // ─────────────────────────── when they last ordered ───────────────────────────

  test('parses the date of the last order the list was sorted by', () {
    // Arrange — the shape `GET /customers?sort=least_recent_order` sends.
    final json = <String, dynamic>{
      'id': 7,
      'code': 'C7',
      'name': 'مطبعة الأمل',
      'phone': '0918887777',
      'is_active': true,
      'orders_count': 4,
      'last_order_at': '2026-01-14T09:30:00+00:00',
    };

    // Act
    final customer = Customer.fromJson(json);

    // Assert
    expect(customer.lastOrderAt, DateTime.parse('2026-01-14T09:30:00+00:00'));
  });

  test('a customer who has never ordered carries a null date, not a missing one', () {
    // Arrange — the server sends the key with null on that sort, and omits it on every other
    // list. Both land as null here; only the card's other fields tell them apart.
    final json = <String, dynamic>{
      'id': 8,
      'code': 'C8',
      'name': 'عميل جديد',
      'phone': '0917778888',
      'is_active': true,
      'orders_count': 0,
      'last_order_at': null,
    };

    // Act
    final customer = Customer.fromJson(json);

    // Assert
    expect(customer.lastOrderAt, isNull);
    expect(customer.lastOrderAgo, isNull);
  });

  test('says how long the silence has been, in the words a call sheet is read in', () {
    // Arrange — one customer per band, all measured from the same instant.
    final now = DateTime.now();
    Customer at(Duration ago) => Customer(
      id: 1,
      code: 'C1',
      name: 'مطبعة',
      phone: '0910000000',
      isActive: true,
      lastOrderAt: now.subtract(ago),
    );

    // Act
    final labels = [
      at(const Duration(hours: 2)).lastOrderAgo,
      at(const Duration(days: 1)).lastOrderAgo,
      at(const Duration(days: 9)).lastOrderAgo,
      at(const Duration(days: 62)).lastOrderAgo,
      at(const Duration(days: 400)).lastOrderAgo,
    ];

    // Assert — no «منذ ٦٢ يوماً»: past a month nobody converts a day count back into a season.
    expect(labels, ['اليوم', 'أمس', 'منذ 9 أيام', 'منذ شهرين', 'منذ سنة']);
  });

  test('a date the server sent in the future reads as today rather than as nonsense', () {
    // Arrange — clock skew between the phone and the server, which is the only way this
    // happens; «منذ -1 يوم» on a card is worse than a day's imprecision.
    final customer = Customer(
      id: 1,
      code: 'C1',
      name: 'مطبعة',
      phone: '0910000000',
      isActive: true,
      lastOrderAt: DateTime.now().add(const Duration(hours: 3)),
    );

    // Act
    final label = customer.lastOrderAgo;

    // Assert
    expect(label, 'اليوم');
  });
}
