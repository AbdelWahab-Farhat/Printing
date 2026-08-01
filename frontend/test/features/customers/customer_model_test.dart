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
}
