import 'dart:typed_data';

import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Who the invoice is *from* — the one block on the document that is not the order's own data.
///
/// **Edit it here and nowhere else.** It is a constant rather than a setting because the shop's
/// own name is not something a user of this app should be able to mistype onto an official
/// document; when it needs to come from the server, this class is the seam that makes that one
/// change instead of a hunt through a layout.
class InvoiceBrand {
  const InvoiceBrand({required this.name, this.tagline, this.phone, this.address});

  /// The name on every invoice this build produces — the owner's own words, nothing inferred.
  ///
  /// **«بريمولا» used to stand above this line and no longer does.** It had been read off the
  /// invoices the shop sends by hand, which made it a guess, and a guessed name on an official
  /// document is worse than a plain one: the customer keeps it. The company line the owner
  /// actually gave is the whole letterhead now.
  static const InvoiceBrand shop = InvoiceBrand(name: 'شركة دعاية لخدمات الطباعة');

  final String name;

  /// A second, quieter line under the name — a trade, a slogan. Absent by default: the header
  /// says one true thing rather than one true thing and one invented one.
  final String? tagline;

  /// Printed in the footer when set. Left out entirely rather than guessed: a wrong number on a
  /// document the customer keeps is worse than no number.
  final String? phone;
  final String? address;
}

/// The fonts and the mark the document is drawn with, loaded by whoever calls the builder.
///
/// **Passed in rather than read from the bundle here**, so the layout is a pure function of an
/// order and a few bytes: a test builds a real PDF without a plugin, and the expensive part —
/// parsing 150KB of TrueType — happens once at the caller instead of per invoice.
class InvoiceAssets {
  const InvoiceAssets({required this.base, required this.bold, this.logo});

  final pw.Font base;
  final pw.Font bold;

  /// `assets/images/logo.png`. Null renders the header without it rather than failing — an
  /// invoice with no logo is still an invoice.
  final Uint8List? logo;
}

/// The order as an official invoice: A4, the shop's mark at the top, the lines in a table.
///
/// **This is a document, not the message.** [OrderMessage] is what gets pasted into a chat — one
/// screen of text somebody reads on a phone. This is what gets kept, printed and attached to an
/// email, so it carries the things a chat message has no business carrying: a page of its own, a
/// ruled table with a column per fact, and a footer that says which page of how many.
///
/// ## Why the font is embedded
///
/// A PDF carries its own faces or it carries nothing. Written with the package's built-in
/// Helvetica, every Arabic word on this page comes out as empty boxes — not "slightly wrong", but
/// unreadable — because that face has no Arabic glyphs at all. Almarai ships in
/// `assets/fonts/`, both weights, and the shaping (letters joining, digits staying
/// left-to-right inside right-to-left text) is the `pdf` package's own work once the face is
/// there.
///
/// ## Why it paginates
///
/// [pw.MultiPage], not [pw.Page]. An order of thirty lines is not unusual and a single page
/// would drop the rest of them silently — the header and the footer repeat, and the totals
/// follow the last line wherever it lands.
class OrderInvoicePdf {
  const OrderInvoicePdf._();

  /// The app's own primary, so a printed invoice and the screen it came from are the same green.
  static const PdfColor _brand = PdfColor.fromInt(0xff006a69);
  static const PdfColor _ink = PdfColor.fromInt(0xff161d1c);
  static const PdfColor _quiet = PdfColor.fromInt(0xff5c6665);
  static const PdfColor _rule = PdfColor.fromInt(0xffcfd9d8);
  static const PdfColor _panel = PdfColor.fromInt(0xfff1f7f6);
  static const PdfColor _highlight = PdfColor.fromInt(0xffdff3f1);
  static const PdfColor _danger = PdfColor.fromInt(0xffba1a1a);

  /// `فاتورة-55.pdf` — what the person sees in the share sheet and in whatever they save it to.
  static String fileNameFor(Order order) => 'فاتورة-${order.code}.pdf';

  /// The whole document, as bytes ready to be written or shared.
  static Future<Uint8List> build({
    required Order order,
    required InvoiceAssets assets,
    InvoiceBrand brand = InvoiceBrand.shop,
  }) async {
    final document = pw.Document(
      title: 'فاتورة طلبية ${order.code}',
      author: brand.name,
      creator: brand.name,
    );

    final logo = assets.logo == null ? null : pw.MemoryImage(assets.logo!);

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          // The whole page, not one widget: a table's columns run right-to-left too, and a
          // document that sets this per-widget ends up with a header in Arabic over a table
          // that reads backwards.
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: assets.base, bold: assets.bold).copyWith(
            defaultTextStyle: pw.TextStyle(font: assets.base, fontSize: 10, color: _ink),
          ),
          margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        ),
        header: (context) => _header(order: order, brand: brand, logo: logo),
        footer: (context) => _footer(context: context, brand: brand),
        build: (context) => [
          _parties(order),
          pw.SizedBox(height: 14),
          _items(order),
          pw.SizedBox(height: 14),
          _totals(order),
          if (order.notes?.trim().isNotEmpty ?? false) ...[
            pw.SizedBox(height: 14),
            _notes(order.notes!.trim()),
          ],
          if (order.cancellationReason case final reason?) ...[
            pw.SizedBox(height: 14),
            _notes('سبب الإلغاء: $reason', tone: _danger),
          ],
        ],
      ),
    );

    return document.save();
  }

  /// The mark and the name on the right, what the document *is* on the left.
  ///
  /// Repeated on every page, deliberately: page two of a printed invoice that is lying on a desk
  /// on its own has to say whose it is and which order it belongs to.
  static pw.Widget _header({
    required Order order,
    required InvoiceBrand brand,
    required pw.ImageProvider? logo,
  }) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // First child is the right-hand one under an RTL page — the side an Arabic reader
            // starts on, which is where a letterhead belongs.
            if (logo != null) ...[
              pw.SizedBox(height: 54, width: 54, child: pw.Image(logo, fit: pw.BoxFit.contain)),
              pw.SizedBox(width: 12),
            ],
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  brand.name,
                  style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _brand),
                ),
                if (brand.tagline case final tagline?) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(tagline, style: const pw.TextStyle(fontSize: 10, color: _quiet)),
                ],
              ],
            ),
            pw.Spacer(),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'فاتورة',
                  style: const pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: _ink),
                ),
                pw.SizedBox(height: 5),
                _headerFact('رقم الفاتورة', order.code),
                if (_dayOf(order) case final day?) _headerFact('التاريخ', day),
                _headerFact('الحالة', order.statusLabel),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(height: 2, color: _brand),
        pw.SizedBox(height: 14),
      ],
    );
  }

  static pw.Widget _headerFact(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text('$label: ', style: const pw.TextStyle(fontSize: 9.5, color: _quiet)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  /// Who it is for, and where it goes — two panels on one line.
  ///
  /// Side by side rather than stacked, because they are read as a pair: the person ringing about
  /// this invoice wants the name and the address in the same glance.
  static pw.Widget _parties(Order order) {
    return pw.Row(
      // **Not `stretch`.** A page in a [pw.MultiPage] has no height to stretch to — the row asks
      // for infinity and the package refuses the whole document. The two panels are therefore as
      // tall as their own contents, which is why the shorter one does not reach the taller.
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _panelBox(
            title: 'بيانات الزبون',
            rows: [
              if (order.customer case final customer?) ...[
                ('الإسم', customer.name),
                ('كود الزبون', customer.code),
                ('الرقم', customer.phone),
              ] else
                ('الإسم', '—'),
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _panelBox(
            title: order.isOfficePickup ? 'الاستلام' : 'التوصيل',
            rows: [
              (order.fulfilmentTypeLabel, order.destination),
              if (order.customerShopName case final shop?) ('المحل', shop),
              if (order.addressDetails case final address?) ('العنوان', address),
              if (order.recipientName case final name?) ('المستلم', name),
              if (order.recipientPhone case final phone?) ('هاتف المستلم', phone),
              if (order.shippingCompany case final company?) ('شركة الشحن', company),
              if (order.trackingNumber case final tracking?) ('رقم التتبع', tracking),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _panelBox({required String title, required List<(String, String)> rows}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _panel,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _rule, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _brand),
          ),
          pw.SizedBox(height: 6),
          for (final (label, value) in rows)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2.5),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('$label: ', style: const pw.TextStyle(fontSize: 9, color: _quiet)),
                  pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 9))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// The lines, ruled, a column per fact.
  ///
  /// **Numbered like the message is**, and for the same reason: an order of four sizes gets
  /// discussed by position. A shortage rides under the line it belongs to instead of taking a
  /// column that would be empty on every invoice that went out complete.
  static pw.Widget _items(Order order) {
    final items = order.items ?? const <OrderItem>[];

    if (items.isEmpty) {
      return _panelBox(title: 'البنود', rows: const [('البنود', 'لا توجد بنود على هذه الطلبية')]);
    }

    return pw.Table(
      border: pw.TableBorder.symmetric(
        inside: const pw.BorderSide(color: _rule, width: 0.5),
        outside: const pw.BorderSide(color: _rule, width: 0.5),
      ),
      // Reversed, like every row below it — see [_rtl]. The widths are keyed by *physical*
      // position, so this list is the reading order read backwards.
      columnWidths: const {
        0: pw.FlexColumnWidth(1.5), // الإجمالي
        1: pw.FlexColumnWidth(1.4), // سعر الوحدة
        2: pw.FlexColumnWidth(1.5), // الكمية
        3: pw.FlexColumnWidth(1.3), // المقاس
        4: pw.FlexColumnWidth(3.1), // الصنف
        5: pw.FixedColumnWidth(24), // #
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _brand),
          children: _rtl([
            for (final heading in ['#', 'الصنف', 'المقاس', 'الكمية', 'سعر الوحدة', 'الإجمالي'])
              _cell(heading, bold: true, colour: PdfColors.white, align: pw.TextAlign.center),
          ]),
        ),
        for (final (index, item) in items.indexed)
          pw.TableRow(
            // Every other line tinted. On a printed page it is what stops the eye sliding from
            // one row's size onto the next row's price.
            decoration: index.isOdd ? const pw.BoxDecoration(color: _panel) : null,
            children: _rtl([
              _cell('${index + 1}', align: pw.TextAlign.center),
              _cell(item.productName),
              _cell(item.variantLabel, align: pw.TextAlign.center),
              _cell(
                '${item.quantity.grouped} ${item.pricingUnitLabel}',
                align: pw.TextAlign.center,
                // The shortage is a fact about *this* quantity, so it is said against it.
                note: item.shortageQuantity == null
                    ? null
                    : 'ناقص: ${item.shortageQuantity!.grouped} ${item.pricingUnitLabel}',
              ),
              _cell(item.unitPrice.grouped, align: pw.TextAlign.center),
              _cell(item.lineTotal.grouped, align: pw.TextAlign.center, bold: true),
            ]),
          ),
      ],
    );
  }

  /// Cells written in Arabic reading order, handed back in the order the page needs them.
  ///
  /// **A [pw.Table] lays its children left to right whatever the page's `textDirection` says** —
  /// unlike [pw.Row], which honours it. Unreversed, this invoice came out with «#» against the
  /// left margin and «الإجمالي» on the right: an Arabic reader's eye starts at the serial number
  /// and the money column ends up where the eye finishes rather than where the totals under it
  /// are. Written this way round so the code above still reads «#, الصنف, المقاس…» — the order
  /// somebody describing the invoice would say out loud.
  static List<pw.Widget> _rtl(List<pw.Widget> cells) => cells.reversed.toList(growable: false);

  static pw.Widget _cell(
    String text, {
    bool bold = false,
    PdfColor? colour,
    pw.TextAlign align = pw.TextAlign.right,
    String? note,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            text,
            textAlign: align,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: colour ?? _ink,
            ),
          ),
          if (note != null) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              note,
              textAlign: align,
              style: const pw.TextStyle(fontSize: 8, color: _danger, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  /// How the total was reached, and then the one number the customer is actually reading for.
  ///
  /// Under the money column rather than across the page, so the eye runs straight down from the
  /// last line's «الإجمالي» into the sum of them. Every figure is the string the server sent —
  /// nothing on this page is arithmetic done by the phone.
  ///
  /// **«التوصيل» is absent here as well.** It is off the customer's copy by the owner's own
  /// instruction, and an invoice that showed it while the message hid it would be the two
  /// disagreeing in the customer's hands.
  static pw.Widget _totals(Order order) {
    return pw.Row(
      children: [
        pw.Spacer(),
        pw.SizedBox(
          width: 250,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _totalLine('المنتجات', order.itemsTotal),
              if (order.hasDesignFee) _totalLine('التصميم', order.designFee),
              // **Without the danger colour, unlike the discount under it.** This is a charge
              // the customer owes; red beside it would warn about the wrong thing. What it was
              // for is named in the message that carries this file — the label column here is a
              // column, and a clerk's sentence does not fit in one.
              if (order.hasAdditionalCost)
                _totalLine('التكلفة الإضافية', '+ ${order.additionalCost.grouped}'),
              if (order.hasDiscount) _totalLine('الخصم', '- ${order.discount.grouped}', colour: _danger),
              pw.Container(height: 0.5, color: _rule, margin: const pw.EdgeInsets.symmetric(vertical: 5)),
              _totalLine('الإجمالي', order.grandTotal, bold: true),
              _totalLine('المدفوع', order.paidAmount),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: pw.BoxDecoration(
                  color: _highlight,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'المتبقي',
                      style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Spacer(),
                    pw.Text(
                      _amount(order.remainingAmount),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: order.isOutstanding ? _danger : _brand,
                      ),
                    ),
                  ],
                ),
              ),
              if (order.paymentStatusLabel.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    // The server's own Arabic — «مدفوعة جزئياً» — so a state added later still
                    // prints correctly.
                    order.paymentStatusLabel,
                    style: const pw.TextStyle(fontSize: 8.5, color: _quiet),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _totalLine(
    String label,
    String value, {
    bool bold = false,
    PdfColor? colour,
  }) {
    final style = pw.TextStyle(
      fontSize: bold ? 11 : 9.5,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: colour ?? (bold ? _ink : _quiet),
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.Text(label, style: style),
          pw.Spacer(),
          pw.Text(_amount(value), style: style.copyWith(color: colour ?? _ink)),
        ],
      ),
    );
  }

  static pw.Widget _notes(String text, {PdfColor tone = _quiet}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _panel,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _rule, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ملاحظات',
            style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _brand),
          ),
          pw.SizedBox(height: 4),
          pw.Text(text, style: pw.TextStyle(fontSize: 9.5, color: tone)),
        ],
      ),
    );
  }

  /// The page count, and a way to reach the shop.
  ///
  /// «صفحة ١ من ٢» is not decoration on a document that can be printed: it is how the person
  /// holding it knows whether they were handed all of it.
  static pw.Widget _footer({required pw.Context context, required InvoiceBrand brand}) {
    final reach = [
      if (brand.phone case final phone?) 'هاتف: $phone',
      ?brand.address,
    ].join('  •  ');

    return pw.Column(
      children: [
        pw.SizedBox(height: 10),
        pw.Container(height: 0.5, color: _rule),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            pw.Text(
              'صفحة ${context.pageNumber} من ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: _quiet),
            ),
            pw.Spacer(),
            pw.Text(
              reach.isEmpty ? 'شكراً لتعاملكم معنا' : reach,
              style: const pw.TextStyle(fontSize: 8, color: _quiet),
            ),
          ],
        ),
      ],
    );
  }

  /// Grouped, like every figure on the screens this document mirrors — and safely applied to
  /// a value a caller grouped already, because a number that carries separators is left alone.
  static String _amount(String value) => '${value.grouped} د';

  /// The day the order was taken, `Y-m-d` — the same day [OrderMessage] prints, for the same
  /// reason: a document is read long after it was made.
  static String? _dayOf(Order order) {
    final at = (order.placedAt ?? order.createdAt)?.toLocal();
    if (at == null) return null;

    String two(int value) => value.toString().padLeft(2, '0');

    return '${at.year}-${two(at.month)}-${two(at.day)}';
  }
}
