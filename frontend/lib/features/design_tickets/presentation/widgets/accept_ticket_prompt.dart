import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/amount_sheet.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:flutter/material.dart';

/// جواب [confirmTicketAcceptance]. و`null` مكانه تراجع.
@immutable
class TicketAcceptance {
  const TicketAcceptance({this.pay});

  /// «أجر التصميم» الذي كتبه من يأخذها. `null` يترك ما على التذكرة.
  final String? pay;
}

/// السؤال قبل «قبول الطلب»، في القائمة وعلى التذكرة بالكلمات نفسها.
///
/// **تذكرةٌ بلا أجر تسأل عنه**: من يأخذها من الطابور هو من يعرف أجرها، وسعره المقترح مكتوبٌ في الحقل.
/// ولو قُبلت بلا سؤال لاكتملت بلا مال ولم ينتبه أحد. وتذكرةٌ عليها أجر يبقى سؤالها كما كان.
Future<TicketAcceptance?> confirmTicketAcceptance(
  BuildContext context,
  DesignTicket ticket,
) async {
  const title = 'قبول الطلب؟';
  const confirmLabel = 'قبول الطلب';
  final description = 'ستصبح أنت المصمم المسؤول عن «${ticket.title}»، ولن يستطيع مصمم آخر أخذها.';

  if (ticket.designerPay != null) {
    final confirmed = await showCustomDialog(
      context: context,
      title: title,
      description: description,
      confirmLabel: confirmLabel,
    );

    return (confirmed ?? false) ? const TicketAcceptance() : null;
  }

  final choice = await showAmountSheet(
    context: context,
    title: title,
    description: description,
    label: 'أجر التصميم',
    confirmLabel: confirmLabel,
    initial: ticket.suggestedPay ?? sl<Session>().user?.designService?.suggestedPrice,
  );

  return choice == null ? null : TicketAcceptance(pay: choice.amount);
}
