import 'dart:math' as math;

import 'package:dayaa/core/chat/chat_message.dart';

/// ما يفعله كلُّ Cubit محادثةٍ بين الموظفين بقائمة رسائله — التذاكر الداخلية ومحادثة تذكرة التصميم.
///
/// دوالٌّ لا صنف: لا حالة هنا، والـCubit صاحبُ المحادثة يملك ما على الشاشة.

/// الرسالةُ مكانها: تحلّ محلّ نسختها إن كانت، وإلا تُلحق بترتيب رقمها.
///
/// [keepFlags] للبثّ: نسختُه بلا قارئ — `can_edit` فيها `false` دائماً — فتبقى أعلامُ النسخة التي
/// على الشاشة، ويُؤخذ منه ما قيل: النصُّ، والسحبُ، والتعديل.
List<ChatMessage> placeChatMessage(
  List<ChatMessage> messages,
  ChatMessage incoming, {
  required bool keepFlags,
}) {
  final index = messages.indexWhere((m) => m.id == incoming.id);

  if (index == -1) return [...messages, incoming]..sort((a, b) => a.id.compareTo(b.id));

  final existing = messages[index];
  final merged = keepFlags
      ? incoming.copyWith(
          isMine: existing.isMine,
          canEdit: existing.canEdit && !incoming.isDeleted,
          canDelete: existing.canDelete && !incoming.isDeleted,
          mutationBlockReason: existing.mutationBlockReason,
        )
      : incoming;

  return [...messages]..[index] = merged;
}

/// رسائلُ جواب الخادم، ومعها أيُّ رسالةٍ وصلت حيّةً ولم يعرفها الجواب — كمحادثة الدعم.
///
/// `null` حين لا شيء ناقص، فيبقى الجوابُ كما هو بلا نسخة.
List<ChatMessage>? chatMessagesMissingFrom(List<ChatMessage> answer, List<ChatMessage> onScreen) {
  final known = {for (final message in answer) message.id};
  final missing = onScreen.where((message) => !known.contains(message.id));

  if (missing.isEmpty) return null;

  return [...answer, ...missing]..sort((a, b) => a.id.compareTo(b.id));
}

/// ستّةَ عشرَ بايتاً ستّ‌عشرياً — رمزُ الإرسال، فريدٌ بما يكفي لمحادثةٍ واحدة.
String randomClientToken() {
  final random = math.Random.secure();

  return List<String>.generate(32, (_) => random.nextInt(16).toRadixString(16)).join();
}
