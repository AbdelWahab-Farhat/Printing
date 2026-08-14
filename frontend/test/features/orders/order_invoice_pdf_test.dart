import 'dart:typed_data';

import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_invoice_pdf.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

/// The invoice as a document — the thing that gets printed, kept and attached to a mail.
///
/// **What this can assert, and what it deliberately does not.** A PDF's text is compressed inside
/// the file, so "does it say «المتبقي»" is not a question a byte comparison answers honestly. What
/// it *can* prove is that a real document comes out — real fonts, real logo, a real page tree —
/// for every shape of order the app can hand it, including the awkward ones that used to be
/// discovered on somebody's phone: an order with no lines, one with no customer loaded, and one
/// long enough to paginate. See ORDER-INVOICE-MESSAGE.md.
///
/// Arrange - Act - Assert throughout.
void main() {
  // rootBundle needs a binding, and the fonts are real assets declared in pubspec.
  TestWidgetsFlutterBinding.ensureInitialized();

  late InvoiceAssets assets;

  const customer = Customer(
    id: 10,
    code: 'C10',
    name: 'عبدالوهاب',
    phone: '0944909850',
    isActive: true,
  );

  const item = OrderItem(
    id: 1,
    productId: 3,
    productVariantId: 9,
    productName: 'أكياس الشحن',
    variantLabel: '35*40',
    pricingUnitLabel: 'قطعة',
    quantity: '400',
    unitPrice: '1.050',
    lineTotal: '420.00',
  );

  Order orderWith({List<OrderItem>? items = const [item], Customer? withCustomer = customer}) =>
      Order(
        id: 55,
        code: '55',
        status: OrderStatus.taken,
        statusLabel: 'جديدة',
        isFinal: false,
        customerId: 10,
        cityId: 1,
        designSource: 'ours',
        cityName: 'طرابلس',
        fulfilmentTypeLabel: 'استلام مكتب',
        isOfficePickup: true,
        designSourceLabel: 'من عندنا',
        itemsTotal: '420.00',
        designFee: '25.00',
        deliveryPrice: '0.00',
        discount: '10.00',
        grandTotal: '435.00',
        paidAmount: '100.00',
        remainingAmount: '335.00',
        paymentStatusLabel: 'مدفوعة جزئياً',
        customer: withCustomer,
        items: items,
        notes: 'شعار فقط',
        placedAt: DateTime(2026, 8, 12),
      );

  setUpAll(() async {
    assets = InvoiceAssets(
      base: pw.Font.ttf(await rootBundle.load('assets/fonts/Almarai-Regular.ttf')),
      bold: pw.Font.ttf(await rootBundle.load('assets/fonts/Almarai-Bold.ttf')),
      logo: (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
    );
  });

  test('the Arabic faces really are in the bundle, both weights', () {
    // Arrange — the one failure that turns every word on the page into an empty box, and it
    // happens by somebody tidying pubspec rather than by touching this feature.

    // Act
    final base = assets.base.fontName;
    final bold = assets.bold.fontName;

    // Assert
    expect(base, contains('Almarai'));
    expect(bold, contains('Almarai'));
    expect(base, isNot(bold));
  });

  test('it produces a real PDF, not an empty shell', () async {
    // Arrange
    final order = orderWith();

    // Act
    final bytes = await OrderInvoicePdf.build(order: order, assets: assets);

    // Assert — the magic number, then a size that could only mean an embedded face and a logo.
    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    expect(bytes.length, greaterThan(20000));
  });

  test('an order with no lines still yields a document instead of throwing', () async {
    // Arrange — the list endpoint sends no `items`, and a deep link can land on this.
    final order = orderWith(items: null, withCustomer: null);

    // Act
    final bytes = await OrderInvoicePdf.build(order: order, assets: assets);

    // Assert
    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
  });

  test('an order too long for one page is not silently cut off', () async {
    // Arrange — forty lines is more than an A4 page holds.
    final many = [for (var i = 0; i < 40; i++) item.copyWith(id: i + 1)];
    final short = await OrderInvoicePdf.build(order: orderWith(), assets: assets);

    // Act
    final long = await OrderInvoicePdf.build(order: orderWith(items: many), assets: assets);

    // Assert — a second page is bytes a one-page document does not have.
    expect(long.length, greaterThan(short.length));
    expect(_pageCount(long), greaterThan(1));
    expect(_pageCount(short), 1);
  });

  test('the file is named for the order, so it is findable after it is saved', () {
    // Arrange
    final order = orderWith();

    // Act
    final name = OrderInvoicePdf.fileNameFor(order);

    // Assert — «فاتورة-55.pdf», not «document.pdf».
    expect(name, 'فاتورة-55.pdf');
  });

  test('the brand block is what the shop is called, not what the order is called', () {
    // Arrange

    // Act
    const brand = InvoiceBrand.shop;

    // Assert — the owner's own words, and nothing above them. «بريمولا» was a name read off the
    // shop's handwritten invoices, and a guess on a document the customer keeps was rejected.
    expect(brand.name, 'شركة دعاية لخدمات الطباعة');
    expect(brand.tagline, isNull);
  });
}

/// How many `/Type /Page` objects the file declares.
///
/// Read out of the raw bytes rather than by re-parsing: the page tree's entries are written in
/// clear text even when the content streams beside them are compressed.
int _pageCount(Uint8List bytes) =>
    RegExp(r'/Type\s*/Page[^s]').allMatches(String.fromCharCodes(bytes)).length;
