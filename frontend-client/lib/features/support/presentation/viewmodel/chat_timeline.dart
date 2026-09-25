import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/outgoing_message.dart';
import 'package:flutter/foundation.dart';

/// سطرٌ واحد في المحادثة كما تُرسم.
sealed class ChatItem {
  const ChatItem();
}

/// «اليوم» · «أمس» · «14 أغسطس» — يُقال مرّةً فوق رسائل يومه، لا تحت كل رسالة.
@immutable
final class ChatDay extends ChatItem {
  const ChatDay(this.day);

  /// منتصف ليل اليوم بتوقيت الهاتف.
  final DateTime day;
}

/// رسالةٌ قبلها الخادم.
@immutable
final class ChatEntry extends ChatItem {
  const ChatEntry(this.message, {required this.startsRun, required this.endsRun});

  final TicketMessage message;

  /// أوّلُ سلسلة: مسافةٌ أوسع فوقها.
  final bool startsRun;

  /// آخرُ سلسلة: الذيل تحتها يشير إلى جهة المتكلّم.
  final bool endsRun;
}

/// رسالةٌ لم يقبلها الخادم بعد — انظر [OutgoingMessage].
@immutable
final class ChatOutgoing extends ChatItem {
  const ChatOutgoing(this.message, {required this.startsRun, required this.endsRun});

  final OutgoingMessage message;
  final bool startsRun;
  final bool endsRun;
}

/// سطرُ خدمةٍ في وسط المحادثة، كـ«أُغلقت التذكرة».
@immutable
final class ChatNotice extends ChatItem {
  const ChatNotice(this.label);

  final String label;
}

/// صمتٌ أطول من هذا يقطع السلسلة وإن كان المتكلّم واحداً: رسالتان بينهما نصف ساعة دوران، لا
/// دورٌ واحد.
const Duration _runGap = Duration(minutes: 10);

/// المحادثة مرصوفةً للرسم، الأقدم أولاً.
///
/// **الأيام**: فاصلٌ واحد فوق أول رسالةٍ من كل يوم. **السلاسل**: رسائل الطرف الواحد المتتابعة،
/// في اليوم نفسه وبلا صمتٍ طويل بينها، دورٌ واحد — بذيلٍ تحت آخرها فقط. **المعلّقة** تأتي بعد
/// ما قبله الخادم، في سلسلة رسائلي؛ ومعلّقةٌ وصلت نسختها من الخادم (بالرمز نفسه) لا تُرسم مرّتين،
/// لأن البثّ الحيّ قد يسبق ردّ الطلب نفسه. و**المغلقة** تُختم بـ«أُغلقت التذكرة» قبل المعلّقة —
/// فالردّ الذي في الطريق هو ما سيعيد فتحها.
List<ChatItem> chatTimeline({
  required List<TicketMessage> messages,
  List<OutgoingMessage> pending = const [],
  bool isClosed = false,
}) {
  final landed = {for (final m in messages) ?m.clientToken};
  final waiting = [for (final p in pending) if (!landed.contains(p.clientToken)) p];

  // (المتكلّم، الساعة، الصنع) لكل سطر، ليُقرَّر الذيل بالنظر إلى ما بعده.
  final rows = <({bool mine, DateTime at, ChatItem Function(bool starts, bool ends) make})>[
    for (final m in messages)
      (
        mine: m.isMine,
        at: (m.sentAt ?? DateTime.now()).toLocal(),
        make: (starts, ends) => ChatEntry(m, startsRun: starts, endsRun: ends),
      ),
    for (final p in waiting)
      (
        mine: true,
        at: p.createdAt.toLocal(),
        make: (starts, ends) => ChatOutgoing(p, startsRun: starts, endsRun: ends),
      ),
  ];

  bool sameRun(int a, int b) =>
      rows[a].mine == rows[b].mine &&
      _dayOf(rows[a].at) == _dayOf(rows[b].at) &&
      rows[b].at.difference(rows[a].at).abs() < _runGap;

  final items = <ChatItem>[];
  final noticeAt = isClosed ? messages.length : -1;

  for (var index = 0; index < rows.length; index++) {
    if (index == noticeAt) items.add(const ChatNotice('أُغلقت التذكرة'));

    final day = _dayOf(rows[index].at);
    if (index == 0 || day != _dayOf(rows[index - 1].at)) items.add(ChatDay(day));

    final starts = index == 0 || !sameRun(index - 1, index);
    final ends = index == rows.length - 1 || !sameRun(index, index + 1);

    items.add(rows[index].make(starts, ends));
  }

  if (noticeAt == rows.length) items.add(const ChatNotice('أُغلقت التذكرة'));

  return items;
}

DateTime _dayOf(DateTime local) => DateTime(local.year, local.month, local.day);
