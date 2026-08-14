import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_invoice_pdf.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

/// Draws the invoice and writes it somewhere the phone can hand to its own share sheet.
///
/// **The temp directory, not Documents** — the same call [SaveDesignToDevice] makes, and for the
/// same reason: the file is a courier. It exists for the seconds between «مشاركة الفاتورة» and
/// the sheet where somebody picks WhatsApp, Files or mail. The invoice is not data we hold; it is
/// the order rendered, and the order lives on the server.
///
/// **The fonts are parsed once for the life of the process.** Two 150KB TrueType faces, and
/// re-parsing them per invoice is the difference between a share sheet that opens now and one
/// that opens in a moment. They never change, so the cache can never go stale.
class SaveOrderInvoicePdf {
  SaveOrderInvoicePdf();

  static const String _regular = 'assets/fonts/Almarai-Regular.ttf';
  static const String _bold = 'assets/fonts/Almarai-Bold.ttf';
  static const String _logo = 'assets/images/logo.png';

  static InvoiceAssets? _assets;

  /// The written file's path, ready to be shared.
  Future<Either<Failure, String>> call(Order order) async {
    try {
      final assets = _assets ??= await _loadAssets();
      final bytes = await OrderInvoicePdf.build(order: order, assets: assets);

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${OrderInvoicePdf.fileNameFor(order)}');
      await file.writeAsBytes(bytes);

      return Right(file.path);
    } on Object {
      // Broad on purpose: this touches the asset bundle, a font parser and a filesystem, and
      // none of the three failing is something the user can be told anything useful about beyond
      // "it did not happen".
      return const Left(Failure.unexpected(message: 'تعذّر إنشاء ملف الفاتورة'));
    }
  }

  static Future<InvoiceAssets> _loadAssets() async {
    return InvoiceAssets(
      base: pw.Font.ttf(await rootBundle.load(_regular)),
      bold: pw.Font.ttf(await rootBundle.load(_bold)),
      logo: await _logoBytes(),
    );
  }

  /// The mark, or nothing at all.
  ///
  /// Swallowed rather than raised: an invoice without the logo is still a correct invoice, and
  /// failing the whole share because one PNG could not be read would be the tail wagging the dog.
  static Future<Uint8List?> _logoBytes() async {
    try {
      return (await rootBundle.load(_logo)).buffer.asUint8List();
    } on Object {
      return null;
    }
  }
}
