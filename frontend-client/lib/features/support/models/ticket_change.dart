import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ticket_change.freezed.dart';
part 'ticket_change.g.dart';

/// إحدى تذاكري تغيّرت، كما يُقال لي على قناتي الحيّة (`private-customers.{id}`).
///
/// **الشكلُ نفسه الذي يرسله `GET client/support/tickets`** — المورد نفسه على الخادم — فلا اسمَ
/// موظفٍ فيه ولا مكتب. بلا الخيط: [SupportTicket.messages] فارغ هنا دائماً، ولا سطرَ معاينة؛
/// الرسالةُ الجديدة وحدها في [message]، ومنها يأخذ الصفّ معاينته ([TicketMessageX.previewText]).
@freezed
abstract class TicketChange with _$TicketChange {
  const factory TicketChange({
    required SupportTicket ticket,

    /// ما قيل، حين يكون التغيير رسالة. فارغٌ للإغلاق وإعادة الفتح والقراءة.
    TicketMessage? message,
  }) = _TicketChange;

  factory TicketChange.fromJson(Map<String, dynamic> json) => _$TicketChangeFromJson(json);
}
