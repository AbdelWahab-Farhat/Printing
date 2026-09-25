import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/picked_file.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'outgoing_message.freezed.dart';

/// أين وصلت رسالةٌ لم يقبلها الخادم بعد.
enum OutgoingStatus {
  /// في الطريق — ساعةٌ على النص، وحلقةُ تقدّمٍ على الملف.
  sending,

  /// رفضها الخادم أو انقطع الاتصال. تبقى في مكانها بعلامةٍ حمراء حتى يعيدها صاحبها أو يحذفها.
  failed,
}

/// رسالةٌ كتبها العميل ولم تصبح رسالةً في الخيط بعد.
///
/// **تُرسم في مكانها بساعةٍ لا بعلامة ✓**، كما يفعل تطبيق المحادثة المرجع. الساعة تقول «لم تصل
/// بعد» بوضوح، فلا يظنّ صاحبها أنها أُرسلت — وهو الخوف الذي أبقى هذه الشاشة بلا رسائل معلّقة
/// من قبل. وحين ترفض تبقى بعلامةٍ حمراء وزرّ إعادة، ولا يضيع ما كُتب.
///
/// **[clientToken] هويّتها من أول لحظة.** يُرسل مع الطلب، ويعود على الرسالة التي كتبها الخادم —
/// في ردّ الطلب أو في البثّ الحيّ، أيّهما سبق — فتُعرف الفقاعة التي صارت تلك الرسالة. ويجعل
/// الإعادة آمنة: الرمز نفسه لا يكتب رسالةً ثانية.
@freezed
abstract class OutgoingMessage with _$OutgoingMessage {
  const factory OutgoingMessage({
    required String clientToken,
    @Default('') String body,

    /// ملفٌّ على هذا الهاتف، يُرفع مع الرسالة. يُقرأ من مساره مرّةً واحدة — انظر [PickedFile].
    PickedFile? file,

    required DateTime createdAt,
    @Default(OutgoingStatus.sending) OutgoingStatus status,

    /// من ٠ إلى ١، للملفات وحدها. النصّ يصل في طلبٍ صغير لا تقدّم فيه يُرى.
    @Default(0) double progress,

    Failure? failure,
  }) = _OutgoingMessage;
}

extension OutgoingMessageX on OutgoingMessage {
  bool get isFailed => status == OutgoingStatus.failed;

  /// «صورة» أم ملف؟ من الامتداد، لأن الملف لم يصل الخادم الذي يقرّر من البايتات بعد.
  bool get isImage {
    final name = file?.name.toLowerCase() ?? '';

    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp') ||
        name.endsWith('.heic');
  }
}
