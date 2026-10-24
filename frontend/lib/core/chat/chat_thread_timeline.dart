import 'package:dayaa/core/chat/chat_message.dart';
import 'package:flutter/foundation.dart';

/// سطرٌ واحد في محادثة الموظفين كما تُرسم — تذكرةٌ داخلية أو تذكرةُ تصميم.
sealed class ChatThreadItem {
  const ChatThreadItem();
}

/// «اليوم» · «أمس» · «14 أغسطس» — مرّةً فوق رسائل يومه.
@immutable
final class ChatThreadDay extends ChatThreadItem {
  const ChatThreadDay(this.day);

  final DateTime day;
}

/// رسالةٌ في مكانها من سلسلتها.
@immutable
final class ChatThreadEntry extends ChatThreadItem {
  const ChatThreadEntry(this.message, {required this.startsRun, required this.endsRun});

  final ChatMessage message;

  /// أوّلُ سلسلة: مسافةٌ أوسع فوقها، واسمُ صاحبها عليها.
  final bool startsRun;

  /// آخرُ سلسلة: الذيل تحتها، وصورةُ صاحبها بجانبها.
  final bool endsRun;
}

/// سطرُ خدمةٍ في وسط المحادثة، كـ«أُغلقت التذكرة».
@immutable
final class ChatThreadNotice extends ChatThreadItem {
  const ChatThreadNotice(this.label);

  final String label;
}

/// صمتٌ أطول من هذا يقطع السلسلة وإن كان المتكلّم واحداً — كمحادثة الدعم.
const Duration _runGap = Duration(minutes: 10);

/// المحادثةُ مرصوفةً للرسم، الأقدم أولاً — بقواعد محادثة الدعم (`chatTimeline`)، **والمتكلّمُ هنا
/// شخصٌ بعينه في الجهتين**: زميلان يتناوبان، وكلٌّ باسمه.
///
/// [closedNotice] سطرُ الخدمة في آخرها حين انتهت — «أُغلقت التذكرة»، أو «اعتُمد التصميم».
List<ChatThreadItem> chatThreadTimeline({
  required List<ChatMessage> messages,
  String? closedNotice,
}) {
  final at = [for (final message in messages) (message.sentAt ?? DateTime.now()).toLocal()];

  bool sameRun(int a, int b) =>
      messages[a].author?.id == messages[b].author?.id &&
      _dayOf(at[a]) == _dayOf(at[b]) &&
      at[b].difference(at[a]).abs() < _runGap;

  final items = <ChatThreadItem>[];

  for (var index = 0; index < messages.length; index++) {
    final day = _dayOf(at[index]);
    if (index == 0 || day != _dayOf(at[index - 1])) items.add(ChatThreadDay(day));

    items.add(
      ChatThreadEntry(
        messages[index],
        startsRun: index == 0 || !sameRun(index - 1, index),
        endsRun: index == messages.length - 1 || !sameRun(index, index + 1),
      ),
    );
  }

  if (closedNotice != null) items.add(ChatThreadNotice(closedNotice));

  return items;
}

DateTime _dayOf(DateTime local) => DateTime(local.year, local.month, local.day);
