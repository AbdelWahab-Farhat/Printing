import 'package:dayaa/core/chat/chat_message.dart';
import 'package:dayaa/core/files/local_files.dart';
import 'package:dio/dio.dart';

/// جسمُ طلب الرسالة — **واحدٌ للمحادثتين** (التذاكر الداخلية وتذكرة التصميم)، فالخادمُ يقرؤهما
/// بقواعد واحدة.
///
/// **JSON بلا ملف، وmultipart به** — والملفاتُ تُقرأ من القرص وهي تُرسل. **الصوتُ في `file`**
/// بمدّته وموجته، **والصورُ ألبوماً في `files[]`** بالترتيب الذي اختيرت به، كبريمولا. و`multiCompatible`
/// يكتب `files[]=` و`waveform[]=` لكل عنصر: الصيغةُ الافتراضية تكرّر المفتاح بلا قوسين، وPHP يُبقي
/// آخرها (RULES §٦، القاعدة ٧).
Future<Object> outgoingChatPayload(OutgoingChatMessage message) async {
  final text = message.body?.trim();
  final fields = <String, dynamic>{
    'client_token': message.clientToken,
    if (text != null && text.isNotEmpty) 'body': text,
    'reply_to_message_id': ?message.replyToMessageId,
  };
  final voice = message.voice;

  if (voice != null) {
    return FormData.fromMap({
      ...fields,
      'file': await LocalFiles.multipart(voice.path, filename: voice.name),
      'duration_seconds': ?message.durationSeconds,
      'waveform': ?message.waveform,
    }, ListFormat.multiCompatible);
  }

  if (message.images.isEmpty) return fields;

  return FormData.fromMap({
    ...fields,
    'files': [
      for (final image in message.images)
        await LocalFiles.multipart(image.path, filename: image.name),
    ],
  }, ListFormat.multiCompatible);
}
