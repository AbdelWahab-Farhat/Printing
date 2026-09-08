import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/usecases/save_order_invoice_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the user is told when the invoice does not come out.
///
/// **The one line was not enough to work with.** «تعذّر إنشاء ملف الفاتورة» was reported from a
/// phone and nothing in the app knew why: the usecase catches everything the asset bundle, the
/// font parser and the filesystem can throw, and every one of them came back as that sentence.
/// The cause is now the toast's second line, so the next report names the failure instead of
/// describing it.
///
/// **The failure here is real, not mocked.** A unit test has no plugins registered, so
/// `getTemporaryDirectory()` throws `MissingPluginException` — the same shape of failure a phone
/// hits when the build is older than the plugin, and exactly the step this test needs to prove
/// is reported by name.
///
/// Arrange - Act - Assert throughout.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final order = Order(
    id: 1228,
    code: '1228',
    status: OrderStatus.taken,
    statusLabel: 'تم الاستلام',
    isFinal: true,
    customerId: 2,
    cityId: 1,
    designSource: 'ours',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'إستلام مكتب',
    isOfficePickup: true,
    designSourceLabel: 'من عندنا',
    itemsTotal: '880.00',
    designFee: '0.00',
    deliveryPrice: '0.00',
    discount: '0.00',
    grandTotal: '880.00',
    paidAmount: '880.00',
    remainingAmount: '0.00',
    paymentStatusLabel: 'مدفوعة بالكامل',
    placedAt: DateTime(2026, 9, 7),
  );

  test('a failed invoice says what went wrong, not only that it went wrong', () async {
    // Arrange — no plugins registered, so the write step cannot succeed.
    final save = SaveOrderInvoicePdf();

    // Act
    final result = await save(order);

    // Assert — the same Arabic the user has always read, and under it the exception's own words.
    final failure = result.fold<Failure>((failure) => failure, (path) => fail('built at $path'));

    expect(failure.message, 'تعذّر إنشاء ملف الفاتورة');
    expect(failure.details, contains('MissingPluginException'));
  });
}
