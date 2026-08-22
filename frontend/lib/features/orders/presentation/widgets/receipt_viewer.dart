import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

/// Looking at the receipt (الواصل) that backs a ledger entry.
///
/// The same split the design viewer settled, for the same reasons: a picture is drawn full
/// screen by this app, and a PDF is handed to whatever the phone already opens PDFs with —
/// every PDF renderer on pub.dev ships a native engine to solve a problem the operating system
/// solved years ago. Which of the two this receipt is comes from the server's
/// `receipt_is_image`, decided from the file it actually stored, so no format list lives here.
Future<void> showReceipt(BuildContext context, OrderPayment payment) async {
  if (payment.receiptUrl == null) {
    context.showError('لا يوجد رابط للواصل');

    return;
  }

  if (payment.receiptIsImage) {
    await showDialog<void>(
      context: context,
      builder: (context) => ReceiptViewer(payment: payment),
    );

    return;
  }

  await _openExternally(context, payment);
}

/// Hands the file to the phone. Each step answers instead of throwing — an unparsable URL is
/// null, a scheme nothing handles is `false` — so the app's one boundary rule is kept.
Future<void> _openExternally(BuildContext context, OrderPayment payment) async {
  final url = payment.receiptUrl;
  final uri = url == null ? null : Uri.tryParse(url);

  if (uri == null) {
    context.showError('لا يوجد رابط للواصل');

    return;
  }

  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (opened || !context.mounted) return;

  context.showError('لا يوجد تطبيق على هذا الجهاز يفتح هذا الملف');
}

/// One image, as large as the screen allows, and zoomable — the reference number on a transfer
/// screenshot is small print, which is what the zoom is for.
class ReceiptViewer extends StatelessWidget {
  const ReceiptViewer({required this.payment, super.key});

  final OrderPayment payment;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              maxScale: 6,
              child: CachedNetworkImage(
                imageUrl: payment.receiptUrl!,
                // The URL is signed and expires, so it cannot be the cache's identity —
                // the entry can, because a ledger row's file never changes.
                cacheKey: 'payment-receipt-${payment.id}',
                fit: BoxFit.contain,
                placeholder: (context, _) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, _, _) => Center(
                  child: Icon(AppIcons.offline, size: 40.sp, color: Colors.white70),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: MediaQuery.paddingOf(context).top + 8.h,
            start: 8.w,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(AppIcons.close, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.black45),
            ),
          ),
          PositionedDirectional(
            top: MediaQuery.paddingOf(context).top + 8.h,
            end: 8.w,
            child: IconButton(
              tooltip: 'فتح خارج التطبيق',
              onPressed: () => unawaited(_openExternally(context, payment)),
              icon: Icon(AppIcons.openExternal, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.black45),
            ),
          ),
          // Whose money and which paper, at the bottom, where it does not sit over the proof.
          if (payment.receiptFilename case final name?)
            PositionedDirectional(
              bottom: MediaQuery.paddingOf(context).bottom + 16.h,
              start: 16.w,
              end: 16.w,
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }
}
