import 'dart:async';
import 'dart:math' as math;

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/chat/chat_message.dart';
import 'package:dayaa/core/chat/chat_thread_logic.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/local_files.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/voice/voice_note_cache.dart';
import 'package:dayaa/core/voice/voice_recorder.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_thread.dart';
import 'package:dayaa/features/design_tickets/usecases/design_ticket_thread_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'design_ticket_thread_cubit.freezed.dart';
part 'design_ticket_thread_state.dart';

/// محادثةُ تذكرة تصميم واحدة — **ما يفعله `InternalThreadCubit` بالرسائل، كما هو**: النصُّ والصورةُ
/// والصوت، والاقتباس، والتعديلُ والسحبُ خلال عشرين دقيقة، والبثُّ الحيّ (DESIGN-TICKET-CHAT §٦).
/// وليس فيها إغلاقٌ ولا تحويل: التذكرةُ تُغلق باعتمادها أو إلغائها، والمحادثةُ معها.
///
/// **كلُّ كتابةٍ تُجاب بالمحادثة كلّها أو بالرسالة نفسها**، فلا شيء هنا يخمّن رقماً أو وقتاً خصّصه
/// الخادم. **والمحادثةُ حيّة** — ما يقوله الطرفُ الآخر يصل من المقبس ويوضع مكانه، ويُقرأ في الحال
/// لأن أحداً ينظر، فتصير ✓✓ عنده.
///
/// **والجرسُ يُصحَّح من هنا** ([onBellCount]): فتحُ المحادثة يطفئ جرسَها على الخادم، والرقمُ
/// الجديد يوضع فوق الجرس كما كانت شاشةُ الملاحظات تفعل — بلا سؤالٍ ثانٍ عن `unread-count`.
class DesignTicketThreadCubit extends Cubit<DesignTicketThreadState> {
  DesignTicketThreadCubit({
    required int ticketId,
    required int? me,
    required GetDesignTicketThread get,
    required SendDesignTicketMessage send,
    required EditDesignTicketMessage edit,
    required RetractDesignTicketMessage retract,
    required MarkDesignTicketThreadRead markRead,
    required WatchDesignTicketThread watch,
    required VoiceNoteCache voiceCache,
    void Function(int unreadTotal)? onBellCount,
    String Function()? newToken,
  }) : _ticketId = ticketId,
       _me = me,
       _get = get,
       _send = send,
       _edit = edit,
       _retract = retract,
       _markRead = markRead,
       _voiceCache = voiceCache,
       _onBellCount = onBellCount,
       _newToken = newToken ?? randomClientToken,
       super(const DesignTicketThreadState.loading()) {
    _live = [
      watch.thread(ticketId).listen(_absorbLive),
      // ما قيل في الانقطاع فات ولن يُعاد على المقبس.
      watch.resumed.listen((_) => unawaited(_readQuietly())),
    ];
  }

  /// اسمُ هذه المحادثة في مفاتيح الصوت والصور على الهاتف — انظر `VoicePlayback.keyForAttachment`.
  static const String attachmentScope = 'design';

  final int _ticketId;
  final int? _me;
  final GetDesignTicketThread _get;
  final SendDesignTicketMessage _send;
  final EditDesignTicketMessage _edit;
  final RetractDesignTicketMessage _retract;
  final MarkDesignTicketThreadRead _markRead;
  final VoiceNoteCache _voiceCache;
  final void Function(int unreadTotal)? _onBellCount;
  final String Function() _newToken;
  late final List<StreamSubscription<Object?>> _live;

  /// يرتفع مع كل كتابةٍ وكل خبرٍ حيّ؛ القراءةُ الصامتة لا تُعرض إن ارتفع أثناءها.
  int _generation = 0;

  int? get me => _me;

  /// يقرأ المحادثة — **وهذا ما يعلّمها مقروءة** على الخادم ويطفئ جرسها.
  Future<void> load() async {
    emit(const DesignTicketThreadState.loading());

    final result = await _get(_ticketId);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => DesignTicketThreadState.failure(failure),
        (thread) => DesignTicketThreadState.loaded(thread: thread),
      ),
    );

    // الجرسُ أُطفئ مع القراءة؛ ورقمُه الجديد يأتي من هنا. فشلُه لا يُقال: شارةٌ لم تُصحَّح بعدُ
    // ليست عطباً في محادثةٍ فُتحت كما ينبغي.
    if (result.isRight()) unawaited(_readAndSetTheBell());
  }

  // ───────────────────────────── الكتابة ─────────────────────────────

  /// كلامٌ، ويقتبس الرسالةَ المختارة إن كانت. **فشلٌ يُبقي الكلام في الصندوق** — شأنُ الشاشة.
  Future<bool> sendText(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return Future<bool>.value(false);

    return _post(OutgoingChatMessage(clientToken: _newToken(), body: trimmed));
  }

  /// صورٌ من الهاتف **رسالةً واحدة** بتعليقها، كبريمولا — بالترتيب الذي اختيرت به، حتى
  /// [OutgoingChatMessage.maxImages].
  Future<bool> sendImages(List<PickedFile> images, {String caption = ''}) {
    if (images.isEmpty) return Future<bool>.value(false);

    return _post(
      OutgoingChatMessage(
        clientToken: _newToken(),
        body: caption.trim(),
        images: images.take(OutgoingChatMessage.maxImages).toList(growable: false),
      ),
    );
  }

  /// رسالةٌ صوتية سُجّلت للتوّ. **إن لم تصل بقيت** فوق الصندوق ([DesignTicketThreadLoaded.unsentVoice]).
  Future<bool> sendVoice(VoiceRecording recording) {
    final current = state;
    if (current is! DesignTicketThreadLoaded) return Future<bool>.value(false);

    return _postVoice(
      PendingVoice(
        path: recording.path,
        durationSeconds: math.max(1, recording.duration.inSeconds),
        waveform: recording.waveform,
        clientToken: _newToken(),
        replyToMessageId: current.replyingTo?.id,
      ),
    );
  }

  /// يعيد الصوتَ الذي لم يصل — **بالرمز نفسه**، فإن كان قد وصل لم يُكتب ثانية.
  Future<bool> retryVoice() {
    final current = state;
    if (current is! DesignTicketThreadLoaded) return Future<bool>.value(false);

    final pending = current.unsentVoice;

    return pending == null ? Future<bool>.value(false) : _postVoice(pending);
  }

  /// يرمي الصوتَ الذي لم يصل.
  void discardVoice() {
    final current = state;
    if (current is! DesignTicketThreadLoaded) return;

    final pending = current.unsentVoice;
    if (pending == null) return;

    LocalFiles.delete(pending.path);
    emit(current.copyWith(unsentVoice: null));
  }

  Future<bool> _postVoice(PendingVoice pending) async {
    final size = await LocalFiles.length(pending.path);

    return _post(
      OutgoingChatMessage(
        clientToken: pending.clientToken,
        voice: PickedFile(path: pending.path, name: 'voice.m4a', sizeBytes: size),
        durationSeconds: pending.durationSeconds,
        waveform: pending.waveform,
        replyToMessageId: pending.replyToMessageId,
      ),
      onFailure: (current) => current.copyWith(unsentVoice: pending),
      onSuccess: (current, thread) {
        unawaited(_keepVoice(thread, pending));

        return current.copyWith(unsentVoice: null);
      },
    );
  }

  /// صوتي الذي وصل يُحفظ تحت رقم مرفقه **واسمِ هذه المحادثة**، فأسمعه بلا أن أنزّله ثانيةً — ثم
  /// يُمحى التسجيل المؤقت.
  Future<void> _keepVoice(DesignTicketThread thread, PendingVoice pending) async {
    final sent = thread.messages.where((m) => m.clientToken == pending.clientToken).firstOrNull;
    final attachment = sent?.voice;

    if (attachment != null) {
      await _voiceCache.keep(
        VoiceNoteCache.keyFor(attachment.id, scope: attachmentScope),
        pending.path,
      );
    }

    LocalFiles.delete(pending.path);
  }

  /// يختار الرسالةَ التي يُردّ عليها — سحبٌ جانبيّ أو «ردّ» من قائمتها.
  void replyTo(ChatMessage message) {
    final current = state;
    if (current is! DesignTicketThreadLoaded || message.isDeleted) return;

    emit(current.copyWith(replyingTo: message));
  }

  void cancelReply() {
    final current = state;
    if (current is DesignTicketThreadLoaded) emit(current.copyWith(replyingTo: null));
  }

  /// يغيّر نصَّ رسالتي — والخادمُ يرفض بعد عشرين دقيقة بجملته.
  Future<bool> editMessage(int messageId, String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return Future<bool>.value(false);

    return _mutate(() => _edit(_ticketId, messageId, trimmed));
  }

  /// يسحب رسالتي: تبقى مكانها «تم حذف هذه الرسالة».
  Future<bool> retractMessage(int messageId) => _mutate(() => _retract(_ticketId, messageId));

  /// الرسالةُ تُرسل وتنتظر جوابها، والصندوقُ منشغلٌ لا معطّل — كمحادثة التذاكر الداخلية.
  Future<bool> _post(
    OutgoingChatMessage message, {
    DesignTicketThreadLoaded Function(DesignTicketThreadLoaded current)? onFailure,
    DesignTicketThreadLoaded Function(DesignTicketThreadLoaded current, DesignTicketThread thread)?
    onSuccess,
  }) async {
    final loaded = state;

    // لا شيء يُكتب عليه، أو كتابةٌ في الطريق — الحارسُ الثاني يمنع ضغطتين على «إرسال».
    if (loaded is! DesignTicketThreadLoaded || loaded.isWorking) return false;

    final quoted = loaded.replyingTo?.id;
    final outgoing = message.replyToMessageId != null || quoted == null
        ? message
        : message.quoting(quoted);

    _generation++;
    emit(loaded.copyWith(isWorking: true, lastFailure: null));

    final result = await _send(_ticketId, outgoing);

    if (isClosed) return false;

    final current = state;
    if (current is! DesignTicketThreadLoaded) return false;

    return result.fold(
      (failure) {
        final failed = current.copyWith(isWorking: false, lastFailure: failure);
        emit(onFailure?.call(failed) ?? failed);

        return false;
      },
      (thread) {
        final next = current.copyWith(
          isWorking: false,
          lastFailure: null,
          replyingTo: null,
          thread: _keepingLiveMessages(thread, current.thread),
        );
        emit(onSuccess?.call(next, thread) ?? next);

        return true;
      },
    );
  }

  /// تعديلٌ أو سحب — يُجاب بالرسالة وحدها، فتوضع مكانها.
  Future<bool> _mutate(Future<Either<Failure, ChatMessage>> Function() call) async {
    final loaded = state;
    if (loaded is! DesignTicketThreadLoaded || loaded.isWorking) return false;

    _generation++;
    emit(loaded.copyWith(isWorking: true, lastFailure: null));

    final result = await call();

    if (isClosed) return false;

    final current = state;
    if (current is! DesignTicketThreadLoaded) return false;

    return result.fold(
      (failure) {
        emit(current.copyWith(isWorking: false, lastFailure: failure));

        return false;
      },
      (message) {
        emit(
          current.copyWith(
            isWorking: false,
            thread: current.thread.copyWith(
              messages: placeChatMessage(current.thread.messages, message, keepFlags: false),
            ),
          ),
        );

        return true;
      },
    );
  }

  // ───────────────────────────── البثّ الحيّ ─────────────────────────────

  /// خبرٌ حيّ عن هذه المحادثة.
  ///
  /// **حمولةُ البثّ بلا قارئ** — بلا `can_reply` ولا `is_party` تخصّني — فلا تُستبدل بها المحادثة:
  /// يُؤخذ منها ما لا يختلف بين القرّاء (المؤشّران، والطرفان، والحالة)، والرسالةُ توضع مكانها.
  void _absorbLive(DesignTicketThreadChange change) {
    final current = state;
    if (current is! DesignTicketThreadLoaded) return;

    _generation++;

    final live = change.thread;
    final message = change.message;
    final onScreen = current.thread;

    emit(
      current.copyWith(
        thread: onScreen.copyWith(
          ticket: live.ticket,
          messages: message == null
              ? onScreen.messages
              : placeChatMessage(onScreen.messages, message, keepFlags: true),
          readUpTo: live.readUpTo,
          counterpartReadUpTo:
              onScreen.otherSideCursor(live.readUpTo, _me) ?? onScreen.counterpartReadUpTo,
        ),
      ),
    );

    // كتب الطرفُ الآخر والمحادثةُ مفتوحةٌ أمامي: تُقرأ الآن حتى رسالته، فتصير ✓✓ عنده.
    if (change.change == 'message_posted' && message != null && !message.isFrom(_me)) {
      if (onScreen.isParty) unawaited(_readAndSetTheBell(upToMessageId: message.id));
    }
  }

  /// قراءةٌ بلا دائرة تحميل — إلا إن تغيّر شيءٌ أثناءها ([_generation]).
  Future<void> _readQuietly() async {
    if (state is! DesignTicketThreadLoaded) return;

    final generation = _generation;
    final result = await _get(_ticketId);

    if (isClosed) return;

    final current = state;
    if (current is! DesignTicketThreadLoaded || current.isWorking || generation != _generation) {
      return;
    }

    result.fold(
      (_) {},
      (thread) => emit(current.copyWith(thread: _keepingLiveMessages(thread, current.thread))),
    );
  }

  /// يقدّم مؤشّري ويطفئ جرس المحادثة، ويضع رقمَ الجرس الجديد حيث يُرسم.
  Future<void> _readAndSetTheBell({int? upToMessageId}) async {
    final result = await _markRead(_ticketId, upToMessageId: upToMessageId);

    if (isClosed) return;

    result.fold((_) {}, (unreadTotal) => _onBellCount?.call(unreadTotal));
  }

  /// جوابُ الخادم، ومعه أيُّ رسالةٍ وصلت حيّةً ولم يعرفها الجواب.
  static DesignTicketThread _keepingLiveMessages(
    DesignTicketThread answer,
    DesignTicketThread onScreen,
  ) {
    final messages = chatMessagesMissingFrom(answer.messages, onScreen.messages);

    return messages == null ? answer : answer.copyWith(messages: messages);
  }

  @override
  Future<void> close() async {
    for (final subscription in _live) {
      await subscription.cancel();
    }

    return super.close();
  }
}
