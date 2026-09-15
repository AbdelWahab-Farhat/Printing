import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

/// One piece of paper, as any ledger row describes it.
///
/// The three facts are the server's own answers — whether it is a picture is decided from the
/// bytes it stored, so no format list lives in this app — and [cacheKey] is the row's identity
/// rather than the URL: the link is signed and expires, while the file behind a ledger row never
/// changes.
@immutable
class Receipt {
  const Receipt({
    required this.cacheKey,
    required this.url,
    required this.isImage,
    this.filename,
  });

  final String cacheKey;
  final String? url;
  final bool isImage;
  final String? filename;
}

/// Looking at the receipt (الواصل) that backs a ledger entry.
///
/// **Two ledgers use it**: a customer's payment, and a purchase made to close a نقص. So it is
/// handed a [Receipt] rather than a row — three facts and a cache key — and neither feature has
/// to know what the other's model looks like.
///
/// The same split the design viewer settled, for the same reasons: a picture is drawn full
/// screen by this app, and a PDF is handed to whatever the phone already opens PDFs with —
/// every PDF renderer on pub.dev ships a native engine to solve a problem the operating system
/// solved years ago. Which of the two this receipt is comes from the server's
/// `receipt_is_image`, decided from the file it actually stored, so no format list lives here.
Future<void> showReceipt(BuildContext context, Receipt receipt) async {
  if (receipt.url == null) {
    context.showError('لا يوجد رابط للواصل');

    return;
  }

  if (receipt.isImage) {
    await showDialog<void>(
      context: context,
      builder: (context) => ReceiptViewer(receipt: receipt),
    );

    return;
  }

  await _openExternally(context, receipt);
}

/// Hands the file to the phone. Each step answers instead of throwing — an unparsable URL is
/// null, a scheme nothing handles is `false` — so the app's one boundary rule is kept.
Future<void> _openExternally(BuildContext context, Receipt receipt) async {
  final url = receipt.url;
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
  const ReceiptViewer({required this.receipt, super.key});

  final Receipt receipt;

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
                imageUrl: receipt.url!,
                // The URL is signed and expires, so it cannot be the cache's identity —
                // the entry can, because a ledger row's file never changes.
                cacheKey: receipt.cacheKey,
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
              onPressed: () => unawaited(_openExternally(context, receipt)),
              icon: Icon(AppIcons.openExternal, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.black45),
            ),
          ),
          // Whose money and which paper, at the bottom, where it does not sit over the proof.
          if (receipt.filename case final name?)
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
