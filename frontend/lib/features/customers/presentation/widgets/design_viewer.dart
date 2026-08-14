import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/customers/usecases/save_design_to_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// The three things anybody ever does to a design file: look at it, save it, hand it to another
/// app.
///
/// They live here rather than on the library screen because the artwork is met in two places —
/// the customer's library and the order that is being printed from it — and the second is where
/// the question «هل أستطيع رؤية ما سنطبعه؟» is actually asked. Two copies of a full-screen
/// viewer would drift the day one of them learns to render a PDF.

/// Shows it: full screen if this app can draw it, otherwise handed to the phone.
Future<void> showDesign(BuildContext context, CustomerDesign design) async {
  if (design.isImage && design.fileUrl != null) {
    await showDialog<void>(
      context: context,
      builder: (context) => DesignViewer(design: design),
    );

    return;
  }

  await openDesignExternally(context, design);
}

/// Hands the file to whatever the phone already opens PDFs with.
///
/// **No `try`/`catch`, and no PDF renderer either.** Every renderer on pub.dev ships a native
/// engine to solve a problem the operating system already solved. Each step here answers
/// instead of throwing — an unparsable URL is null, a scheme nothing handles is `false` — so
/// the one boundary rule this app has is not bent for a convenience.
Future<void> openDesignExternally(BuildContext context, CustomerDesign design) async {
  final url = design.fileUrl;
  final uri = url == null ? null : Uri.tryParse(url);

  if (uri == null) {
    context.showError('لا يوجد رابط لهذا الملف');

    return;
  }

  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (opened || !context.mounted) return;

  context.showError('لا يوجد تطبيق على هذا الجهاز يفتح هذا الملف');
}

/// Downloads the file and offers it to the phone's own save sheet.
///
/// **«تحميل» on a phone is not a folder.** Where a file should end up — Photos, Files, straight
/// into WhatsApp to the printer — is a question only the operating system can answer, and it
/// already asks it. So the bytes are fetched, written to a temp file, and handed over; «حفظ
/// الصورة» and «حفظ في الملفات» are rows the OS provides.
///
/// The signed link expires, so this fetches with whatever URL the screen is holding *now* —
/// which is why the design is passed rather than a stored address.
Future<void> saveDesign(BuildContext context, CustomerDesign design) async {
  final messenger = context;
  final result = await sl<SaveDesignToDevice>()(design);

  if (!messenger.mounted) return;

  await result.fold(
    (failure) async => messenger.showFailure(failure),
    (path) async {
      // `sharePositionOrigin` is required on iPad, where a share sheet is a popover that has to
      // be anchored to something — without it the call throws on that one form factor.
      final box = context.findRenderObject() as RenderBox?;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          fileNameOverrides: [SaveDesignToDevice.fileNameFor(design)],
          sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    },
  );
}

/// One image, as large as the screen allows, and zoomable.
class DesignViewer extends StatelessWidget {
  const DesignViewer({required this.design, super.key});

  final CustomerDesign design;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              // Artwork is read close up — a logo's kerning, a colour against a background —
              // so it zooms further than a photo viewer would.
              maxScale: 6,
              child: CachedNetworkImage(
                imageUrl: design.fileUrl!,
                cacheKey: 'customer-design-${design.id}',
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
            child: Row(
              children: [
                // Saving comes first, on the side the thumb reaches: it is what somebody who
                // opened the artwork full screen most often wants next.
                IconButton(
                  tooltip: 'تحميل',
                  onPressed: () => unawaited(saveDesign(context, design)),
                  icon: Icon(AppIcons.download, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.black45),
                ),
                SizedBox(width: 8.w),
                IconButton(
                  tooltip: 'فتح خارج التطبيق',
                  onPressed: () => unawaited(openDesignExternally(context, design)),
                  icon: Icon(AppIcons.openExternal, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.black45),
                ),
              ],
            ),
          ),
          // What it is, at the bottom, where it does not sit over the artwork.
          PositionedDirectional(
            bottom: MediaQuery.paddingOf(context).bottom + 16.h,
            start: 16.w,
            end: 16.w,
            child: Text(
              [design.label, ?design.dimensionsLabel, ?design.sizeLabel].join('  ·  '),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
