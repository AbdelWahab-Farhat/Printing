import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_invoice_pdf.dart';
import 'package:dayaa/features/orders/models/order_message.dart';
import 'package:dayaa/features/orders/usecases/save_order_invoice_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Puts the order in the customer's hands, as words.
///
/// **The two ways out are deliberately different jobs.** This button copies; [shareOrderInvoice]
/// opens the phone's own sheet. Both send the same [OrderMessage], so there is one answer to
/// "what does an order say" no matter which one was used.
///
/// It copies rather than opening WhatsApp directly, and that is not a shortcut: the customer's
/// chat may be under a number the order does not carry, the order may be going to a group, and
/// the person sending it usually wants to add a sentence of their own before it goes. A clipboard
/// leaves all three to them. Sending it *somewhere* is what the dial's share arm is for.
class CopyInvoiceButton extends StatelessWidget {
  const CopyInvoiceButton({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return AppButton.tonal(
      label: 'نسخ الفاتورة',
      icon: AppIcons.copy,
      onPressed: () {
        // Not awaited, and the confirmation is not made to wait on it: the platform call is
        // local and the only thing an await would buy is a frame of nothing.
        unawaited(Clipboard.setData(ClipboardData(text: OrderMessage.of(order))));

        // A clipboard gives no sign of its own — without this, a successful copy and a dead
        // button look exactly alike.
        context.showSuccess('تم نسخ الفاتورة', details: 'ألصقها في محادثة الزبون');
      },
    );
  }
}

/// Draws the official invoice and hands the **file** to whatever the phone sends files with.
///
/// **A PDF, not the text.** The button above already sends the words; this is the document —
/// letterhead, ruled table, page numbers — and it is what somebody keeps, prints, or attaches to
/// a mail. See [OrderInvoicePdf] for what is on it and why.
///
/// A share sheet rather than a WhatsApp link, for the reason a share sheet always wins: it lists
/// the apps actually installed, remembers who was messaged last, and its «حفظ في الملفات» row is
/// how this invoice gets *saved* without the app growing a file browser of its own.
Future<void> shareOrderInvoice(BuildContext context, Order order) async {
  // Measured before the await: an iPad's share sheet is a popover that has to be anchored to
  // something on screen, and this is the last moment that is certainly still true.
  final box = context.findRenderObject() as RenderBox?;
  final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;

  // The first invoice of a session parses two TrueType faces before it can draw anything. A dial
  // that closes onto a screen doing nothing visible reads as a button that failed.
  context.showInfo('جارٍ تجهيز الفاتورة…');

  final result = await sl<SaveOrderInvoicePdf>()(order);

  if (!context.mounted) return;

  await result.fold(
    (failure) async => context.showFailure(failure),
    (path) async => SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'application/pdf')],
        // What the person sees in the sheet, and what it is called wherever they save it.
        fileNameOverrides: [OrderInvoicePdf.fileNameFor(order)],
        // Ignored by every chat app and used by every mail app, which would otherwise send this
        // with an empty subject line.
        subject: OrderMessage.subjectOf(order),
        sharePositionOrigin: origin,
      ),
    ),
  );
}
