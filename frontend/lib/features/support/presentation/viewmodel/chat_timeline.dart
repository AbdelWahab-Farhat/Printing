import 'package:dayaa/features/support/models/support_ticket.dart';
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

/// رسالةٌ في مكانها من سلسلتها.
@immutable
final class ChatEntry extends ChatItem {
  const ChatEntry(this.message, {required this.startsRun, required this.endsRun});

  final TicketMessage message;

  /// أوّلُ سلسلة: مسافةٌ أوسع فوقها، واسمُ الزميل عليها.
  final bool startsRun;

  /// آخرُ سلسلة: الذيل تحتها يشير إلى جهة المتكلّم، وصورتُه بجانبه.
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

/// المحادثة مرصوفةً للرسم، الأقدم أولاً — منقولةٌ من تطبيق العميل.
///
/// **الأيام**: فاصلٌ واحد فوق أول رسالةٍ من كل يوم. **السلاسل**: رسائل المتكلّم الواحد المتتابعة،
/// في اليوم نفسه وبلا صمتٍ طويل بينها، دورٌ واحد — بذيلٍ تحت آخرها فقط. **والمتكلّم في جهة
/// المحل شخصٌ لا جهة**: زميلان يتتابعان سلسلتان، لأن الاسم فوق كلٍّ منهما غيرُ الآخر.
/// و**المغلقة** تُختم بـ«أُغلقت التذكرة».
List<ChatItem> chatTimeline({required List<TicketMessage> messages, bool isClosed = false}) {
  final at = [for (final m in messages) (m.sentAt ?? DateTime.now()).toLocal()];

  bool sameRun(int a, int b) =>
      _speaker(messages[a]) == _speaker(messages[b]) &&
      _dayOf(at[a]) == _dayOf(at[b]) &&
      at[b].difference(at[a]).abs() < _runGap;

  final items = <ChatItem>[];

  for (var index = 0; index < messages.length; index++) {
    final day = _dayOf(at[index]);
    if (index == 0 || day != _dayOf(at[index - 1])) items.add(ChatDay(day));

    items.add(
      ChatEntry(
        messages[index],
        startsRun: index == 0 || !sameRun(index - 1, index),
        endsRun: index == messages.length - 1 || !sameRun(index, index + 1),
      ),
    );
  }

  if (isClosed) items.add(const ChatNotice('أُغلقت التذكرة'));

  return items;
}

/// العميلُ واحدٌ دائماً؛ وفي جهة المحل كلُّ زميلٍ باسمه.
(bool, String?) _speaker(TicketMessage message) => message.from == MessageAuthor.customer
    ? (true, null)
    : (false, message.authorName);

DateTime _dayOf(DateTime local) => DateTime(local.year, local.month, local.day);
