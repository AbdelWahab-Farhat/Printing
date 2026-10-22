import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:flutter/foundation.dart';

/// سطرٌ واحد في المحادثة الداخلية كما تُرسم.
sealed class InternalChatItem {
  const InternalChatItem();
}

/// «اليوم» · «أمس» · «14 أغسطس» — مرّةً فوق رسائل يومه.
@immutable
final class InternalChatDay extends InternalChatItem {
  const InternalChatDay(this.day);

  final DateTime day;
}

/// رسالةٌ في مكانها من سلسلتها.
@immutable
final class InternalChatEntry extends InternalChatItem {
  const InternalChatEntry(this.message, {required this.startsRun, required this.endsRun});

  final InternalMessage message;

  /// أوّلُ سلسلة: مسافةٌ أوسع فوقها، واسمُ صاحبها عليها.
  final bool startsRun;

  /// آخرُ سلسلة: الذيل تحتها، وصورةُ صاحبها بجانبها.
  final bool endsRun;
}

/// سطرُ خدمةٍ في وسط المحادثة، كـ«أُغلقت التذكرة».
@immutable
final class InternalChatNotice extends InternalChatItem {
  const InternalChatNotice(this.label);

  final String label;
}

/// صمتٌ أطول من هذا يقطع السلسلة وإن كان المتكلّم واحداً — كمحادثة الدعم.
const Duration _runGap = Duration(minutes: 10);

/// المحادثةُ مرصوفةً للرسم، الأقدم أولاً — بقواعد محادثة الدعم (`chatTimeline`)، **والمتكلّمُ هنا
/// شخصٌ بعينه في الجهتين**: زميلان يتناوبان، وكلٌّ باسمه.
List<InternalChatItem> internalChatTimeline({
  required List<InternalMessage> messages,
  bool isClosed = false,
}) {
  final at = [for (final message in messages) (message.sentAt ?? DateTime.now()).toLocal()];

  bool sameRun(int a, int b) =>
      messages[a].author?.id == messages[b].author?.id &&
      _dayOf(at[a]) == _dayOf(at[b]) &&
      at[b].difference(at[a]).abs() < _runGap;

  final items = <InternalChatItem>[];

  for (var index = 0; index < messages.length; index++) {
    final day = _dayOf(at[index]);
    if (index == 0 || day != _dayOf(at[index - 1])) items.add(InternalChatDay(day));

    items.add(
      InternalChatEntry(
        messages[index],
        startsRun: index == 0 || !sameRun(index - 1, index),
        endsRun: index == messages.length - 1 || !sameRun(index, index + 1),
      ),
    );
  }

  if (isClosed) items.add(const InternalChatNotice('أُغلقت التذكرة'));

  return items;
}

DateTime _dayOf(DateTime local) => DateTime(local.year, local.month, local.day);
