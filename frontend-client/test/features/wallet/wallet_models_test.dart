import 'package:dayaa_client/features/wallet/models/wallet_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// سطر «محفظتي» كما يصل من الخادم — وما يعرفه السطر ليرسم شعار الطريقة ورقم الطلبية.
///
/// Arrange - Act - Assert throughout.
void main() {
  test('an online top-up carries its method and the EzonePay method it came through', () {
    // Arrange
    final json = <String, dynamic>{
      'id': 7,
      'type': 'topup',
      'type_label': 'شحن المحفظة',
      'direction': 'in',
      'amount': '100.00',
      'method': 'online',
      'online_method': 103,
      'method_label': 'ون باي',
    };

    // Act
    final entry = MyWalletEntry.fromJson(json);

    // Assert
    expect(entry.method, 'online');
    expect(entry.onlineMethod, 103);
    expect(entry.methodLabel, 'ون باي');
  });

  test('an order payment carries the code of its order', () {
    // Arrange
    final json = <String, dynamic>{
      'id': 8,
      'type': 'order_payment',
      'type_label': 'دفع طلبية',
      'direction': 'out',
      'amount': '40.00',
      'order_id': 1286,
      'order_code': '1286',
    };

    // Act
    final entry = MyWalletEntry.fromJson(json);

    // Assert
    expect(entry.orderId, 1286);
    expect(entry.orderCode, '1286');
  });

  /// خادمٌ لم يُحدَّث بعد لا يرسل الحقول الثلاثة — السطر يُقرأ كما كان.
  test('a server that sends none of the three still reads', () {
    // Arrange
    final json = <String, dynamic>{
      'id': 9,
      'type': 'topup',
      'type_label': 'شحن المحفظة',
      'direction': 'in',
      'amount': '10.00',
      'method_label': 'دفع إلكتروني',
    };

    // Act
    final entry = MyWalletEntry.fromJson(json);

    // Assert
    expect(entry.method, isNull);
    expect(entry.onlineMethod, isNull);
    expect(entry.orderCode, isNull);
  });
}
