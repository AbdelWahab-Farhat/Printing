import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ticket_change.freezed.dart';
part 'ticket_change.g.dart';

/// تذكرةٌ تغيّرت، كما يسمعها المكتب على قناته الحيّة (`private-support.desk`).
///
/// **الشكلُ نفسه الذي يرسله `GET support/tickets`** لصفّ الطابور — المورد نفسه على الخادم — فالصفّ
/// الذي يُرقَّع من المقبس هو الصفّ الذي كان سيُقرأ بطلب. بلا الخيط: [SupportTicket.messages] فارغ
/// هنا دائماً، والرسالةُ الجديدة وحدها في [message].
@freezed
abstract class TicketChange with _$TicketChange {
  const factory TicketChange({
    required SupportTicket ticket,

    /// ما قيل، حين يكون التغيير رسالة. فارغٌ للإسناد والإغلاق وإعادة الفتح والقراءة.
    TicketMessage? message,
  }) = _TicketChange;

  factory TicketChange.fromJson(Map<String, dynamic> json) => _$TicketChangeFromJson(json);
}
