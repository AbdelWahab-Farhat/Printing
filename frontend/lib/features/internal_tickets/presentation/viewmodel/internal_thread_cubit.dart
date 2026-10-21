import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/voice/voice_note_cache.dart';
import 'package:dayaa/core/voice/voice_recorder.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/repositories/internal_tickets_repository.dart';
import 'package:dayaa/features/internal_tickets/usecases/internal_tickets_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'internal_thread_cubit.freezed.dart';
part 'internal_thread_state.dart';

/// محادثةٌ داخلية واحدة: ما قيل فيها، وما يفعله القارئ بها — كمحادثة الدعم، وفوقها ما في بريمولا:
/// الصوت، والاقتباس، والتعديلُ والسحبُ خلال عشرين دقيقة، والتحويل.
///
/// **كلُّ كتابةٍ تُجاب بالتذكرة كلّها أو بالرسالة نفسها**، فلا شيء هنا يخمّن رقماً أو وقتاً خصّصه
/// الخادم: الرسالةُ تظهر حين كتبها فعلاً.
///
/// **والمحادثةُ حيّة** — ما يقوله الزميل، أو يعدّله، أو يسحبه، يصل من المقبس ويوضع مكانه ساعةَ
/// يُقال. ورسالةُ الزميل تُقرأ في الحال بقراءةٍ صامتة، لأن أحداً ينظر — فتصير ✓✓ عنده.
class InternalThreadCubit extends Cubit<InternalThreadState> {
  InternalThreadCubit({
    required int ticketId,
    required int? me,
    required GetInternalTicket get,
    required SendInternalMessage send,
    required EditInternalMessage edit,
    required RetractInternalMessage retract,
    required MarkInternalTicketRead markRead,
    required CloseInternalTicket close,
    required TransferInternalTicket transfer,
    required GetColleagues colleagues,
    required WatchInternalTickets watch,
    required VoiceNoteCache voiceCache,
    String Function()? newToken,
  }) : _ticketId = ticketId,
       _colleagues = colleagues,
       _me = me,
       _get = get,
       _send = send,
       _edit = edit,
       _retract = retract,
       _markRead = markRead,
       _close = close,
       _transfer = transfer,
       _voiceCache = voiceCache,
       _newToken = newToken ?? _randomToken,
       super(const InternalThreadState.loading()) {
    _live = [
      watch.ticket(ticketId).listen(_absorbLive),
      // ما قيل في الانقطاع فات ولن يُعاد على المقبس.
      watch.resumed.listen((_) => unawaited(_readQuietly())),
    ];
  }

  final int _ticketId;
  final int? _me;
  final GetInternalTicket _get;
  final SendInternalMessage _send;
  final EditInternalMessage _edit;
  final RetractInternalMessage _retract;
  final MarkInternalTicketRead _markRead;
  final CloseInternalTicket _close;
  final TransferInternalTicket _transfer;
  final GetColleagues _colleagues;
  final VoiceNoteCache _voiceCache;
  final String Function() _newToken;
  late final List<StreamSubscription<Object?>> _live;

  /// يرتفع مع كل كتابةٍ وكل خبرٍ حيّ؛ القراءةُ الصامتة لا تُعرض إن ارتفع أثناءها — كمحادثة الدعم.
  int _generation = 0;

  int? get me => _me;

  /// يقرأ المحادثة — **وهذا ما يعلّمها مقروءة** على الخادم.
  Future<void> load() async {
    emit(const InternalThreadState.loading());

    final result = await _get(_ticketId);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => InternalThreadState.failure(failure),
        (ticket) => InternalThreadState.loaded(ticket: ticket),
      ),
    );
  }

  // ───────────────────────────── الكتابة ─────────────────────────────

  /// كلامٌ، ويقتبس الرسالةَ المختارة إن كانت. **فشلٌ يُبقي الكلام في الصندوق** — شأنُ الشاشة.
  Future<bool> sendText(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return Future<bool>.value(false);

    return _post(OutgoingInternalMessage(clientToken: _newToken(), body: trimmed));
  }

  /// صورةٌ من الهاتف، وما في الصندوق تعليقاً.
  Future<bool> sendImage(PickedFile image, {String caption = ''}) =>
      _post(OutgoingInternalMessage(clientToken: _newToken(), body: caption.trim(), file: image));

  /// رسالةٌ صوتية سُجّلت للتوّ. **إن لم تصل بقيت** فوق الصندوق ([InternalThreadLoaded.unsentVoice]).
  Future<bool> sendVoice(VoiceRecording recording) {
    final current = state;
    if (current is! InternalThreadLoaded) return Future<bool>.value(false);

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
    if (current is! InternalThreadLoaded) return Future<bool>.value(false);

    final pending = current.unsentVoice;

    return pending == null ? Future<bool>.value(false) : _postVoice(pending);
  }

  /// يرمي الصوتَ الذي لم يصل.
  void discardVoice() {
    final current = state;
    if (current is! InternalThreadLoaded) return;

    final pending = current.unsentVoice;
    if (pending == null) return;

    _deleteFile(pending.path);
    emit(current.copyWith(unsentVoice: null));
  }

  Future<bool> _postVoice(PendingVoice pending) async {
    final sent = await _post(
      OutgoingInternalMessage(
        clientToken: pending.clientToken,
        file: PickedFile(
          path: pending.path,
          name: 'voice.m4a',
          sizeBytes: File(pending.path).lengthSync(),
        ),
        durationSeconds: pending.durationSeconds,
        waveform: pending.waveform,
        replyToMessageId: pending.replyToMessageId,
      ),
      onFailure: (current) => current.copyWith(unsentVoice: pending),
      onSuccess: (current, ticket) {
        unawaited(_keepVoice(ticket, pending));

        return current.copyWith(unsentVoice: null);
      },
    );

    return sent;
  }

  /// صوتي الذي وصل يُحفظ تحت رقم مرفقه، فأسمعه بلا أن أنزّله ثانيةً — ثم يُمحى التسجيل المؤقت.
  Future<void> _keepVoice(InternalTicket ticket, PendingVoice pending) async {
    final sent = ticket.messages.where((m) => m.clientToken == pending.clientToken).firstOrNull;
    final attachment = sent?.voice;

    if (attachment != null) {
      await _voiceCache.keep(VoiceNoteCache.keyFor(attachment.id), pending.path);
    }

    _deleteFile(pending.path);
  }

  /// يختار الرسالةَ التي يُردّ عليها — سحبٌ جانبيّ أو «ردّ» من قائمتها.
  void replyTo(InternalMessage message) {
    final current = state;
    if (current is! InternalThreadLoaded || message.isDeleted) return;

    emit(current.copyWith(replyingTo: message));
  }

  void cancelReply() {
    final current = state;
    if (current is InternalThreadLoaded) emit(current.copyWith(replyingTo: null));
  }

  /// يغيّر نصَّ رسالتي — والخادمُ يرفض بعد عشرين دقيقة بجملته.
  Future<bool> editMessage(int messageId, String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return Future<bool>.value(false);

    return _mutate(() => _edit(_ticketId, messageId, trimmed));
  }

  /// يسحب رسالتي: تبقى مكانها «تم حذف هذه الرسالة».
  Future<bool> retractMessage(int messageId) => _mutate(() => _retract(_ticketId, messageId));

  /// نهائيّ — لا إعادة فتح.
  Future<bool> closeTicket() => _write(() => _close(_ticketId));

  /// صاحبُها يسلّمها لموظفٍ آخر يحلّ محلّه — فيخرج منها، والشاشةُ تُغلق بعد النجاح.
  Future<bool> transferTo(int newOwnerId) =>
      _write(() => _transfer(_ticketId, newOwnerId: newOwnerId));

  /// مَن يُحوَّل إليه — ورقةُ «مع مَن؟» نفسها. فشلُها يُقال بجانب المحادثة، والورقةُ لا تُفتح.
  Future<List<Colleague>> colleaguesForTransfer() async {
    final result = await _colleagues();

    if (isClosed) return const [];

    return result.fold((failure) {
      final current = state;
      if (current is InternalThreadLoaded) emit(current.copyWith(lastFailure: failure));

      return const [];
    }, (colleagues) => colleagues);
  }

  /// الرسالةُ تُرسل وتنتظر جوابها، والصندوقُ منشغلٌ لا معطّل — كمحادثة الدعم.
  Future<bool> _post(
    OutgoingInternalMessage message, {
    InternalThreadLoaded Function(InternalThreadLoaded current)? onFailure,
    InternalThreadLoaded Function(InternalThreadLoaded current, InternalTicket ticket)? onSuccess,
  }) {
    final current = state;
    final quoted = current is InternalThreadLoaded ? current.replyingTo?.id : null;

    final withQuote = message.replyToMessageId != null || quoted == null
        ? message
        : OutgoingInternalMessage(
            clientToken: message.clientToken,
            body: message.body,
            file: message.file,
            durationSeconds: message.durationSeconds,
            waveform: message.waveform,
            replyToMessageId: quoted,
          );

    return _write(
      () => _send(_ticketId, withQuote),
      onFailure: onFailure,
      onSuccess: (state, ticket) =>
          (onSuccess?.call(state, ticket) ?? state).copyWith(replyingTo: null),
    );
  }

  /// الشكلُ الذي تشترك فيه كلُّ كتابةٍ تُجاب بالتذكرة: منشغل، ثم جوابُ الخادم على الشاشة أو ما
  /// كان عليها وسببُ أنّ الكتابة لم تأخذ. يُرجع أأخذت، فتمسح الشاشةُ صندوقها عند النجاح وحده.
  Future<bool> _write(
    Future<Either<Failure, InternalTicket>> Function() call, {
    InternalThreadLoaded Function(InternalThreadLoaded current)? onFailure,
    InternalThreadLoaded Function(InternalThreadLoaded current, InternalTicket ticket)? onSuccess,
  }) async {
    final loaded = state;

    // لا شيء يُكتب عليه، أو كتابةٌ في الطريق — الحارسُ الثاني يمنع ضغطتين على «إرسال».
    if (loaded is! InternalThreadLoaded || loaded.isWorking) return false;

    _generation++;
    emit(loaded.copyWith(isWorking: true, lastFailure: null));

    final result = await call();

    if (isClosed) return false;

    final current = state;
    if (current is! InternalThreadLoaded) return false;

    return result.fold(
      (failure) {
        final failed = current.copyWith(isWorking: false, lastFailure: failure);
        emit(onFailure?.call(failed) ?? failed);

        return false;
      },
      (ticket) {
        final next = current.copyWith(
          isWorking: false,
          lastFailure: null,
          ticket: _keepingLiveMessages(ticket, current.ticket),
        );
        emit(onSuccess?.call(next, ticket) ?? next);

        return true;
      },
    );
  }

  /// تعديلٌ أو سحب — يُجاب بالرسالة وحدها، فتوضع مكانها.
  Future<bool> _mutate(Future<Either<Failure, InternalMessage>> Function() call) async {
    final loaded = state;
    if (loaded is! InternalThreadLoaded || loaded.isWorking) return false;

    _generation++;
    emit(loaded.copyWith(isWorking: true, lastFailure: null));

    final result = await call();

    if (isClosed) return false;

    final current = state;
    if (current is! InternalThreadLoaded) return false;

    return result.fold(
      (failure) {
        emit(current.copyWith(isWorking: false, lastFailure: failure));

        return false;
      },
      (message) {
        emit(
          current.copyWith(
            isWorking: false,
            ticket: current.ticket.copyWith(
              messages: _placed(current.ticket.messages, message, keepFlags: false),
            ),
          ),
        );

        return true;
      },
    );
  }

  // ───────────────────────────── البثّ الحيّ ─────────────────────────────

  /// خبرٌ حيّ عن هذه التذكرة.
  ///
  /// **حمولةُ البثّ بلا قارئ** — بلا `can_reply` ولا `counterpart` تخصّني — فلا تُستبدل بها التذكرة:
  /// يُؤخذ منها ما لا يختلف بين القرّاء (المؤشّران، الحالة، الطرفان)، والرسالةُ توضع مكانها. وما
  /// يغيّر ما أملكه — إغلاقٌ أو تحويل — يُقرأ من جديد بقراءةٍ صامتة تعرفني.
  void _absorbLive(InternalTicketChange change) {
    final current = state;
    if (current is! InternalThreadLoaded) return;

    _generation++;

    final live = change.ticket;
    final message = change.message;
    final messages = message == null
        ? current.ticket.messages
        : _placed(current.ticket.messages, message, keepFlags: true);

    emit(
      current.copyWith(
        ticket: current.ticket.copyWith(
          messages: messages,
          readUpTo: live.readUpTo,
          counterpartReadUpTo: _otherSideCursor(current.ticket, live.readUpTo),
          lastMessageAt: live.lastMessageAt,
        ),
      ),
    );

    if (change.change == 'closed' || change.change == 'transferred') {
      unawaited(_readQuietly());

      return;
    }

    // كتب الزميلُ والمحادثةُ مفتوحةٌ أمامي: تُقرأ الآن حتى رسالته، فتصير ✓✓ عنده.
    if (change.change == 'message_posted' && message != null && !message.isFrom(_me)) {
      if (current.ticket.isParty) unawaited(_markRead(_ticketId, upToMessageId: message.id));
    }
  }

  /// مؤشّرُ الطرف الآخر عندي، من المؤشّرين كما جاءا في البثّ.
  int? _otherSideCursor(InternalTicket ticket, InternalReadUpTo? cursors) {
    if (cursors == null) return ticket.counterpartReadUpTo;
    if (ticket.opener?.id == _me) return cursors.assignee;
    if (ticket.assignee?.id == _me) return cursors.opener;

    return ticket.counterpartReadUpTo;
  }

  /// قراءةٌ بلا دائرة تحميل — إلا إن تغيّر شيءٌ أثناءها ([_generation]).
  Future<void> _readQuietly() async {
    if (state is! InternalThreadLoaded) return;

    final generation = _generation;
    final result = await _get(_ticketId);

    if (isClosed) return;

    final current = state;
    if (current is! InternalThreadLoaded || current.isWorking || generation != _generation) return;

    result.fold(
      (_) {},
      (ticket) => emit(current.copyWith(ticket: _keepingLiveMessages(ticket, current.ticket))),
    );
  }

  /// الرسالةُ مكانها: تحلّ محلّ نسختها إن كانت، وإلا تُلحق بترتيب رقمها.
  ///
  /// [keepFlags] للبثّ: نسختُه بلا قارئ — `can_edit` فيها `false` دائماً — فتبقى أعلامُ النسخة التي
  /// على الشاشة، ويُؤخذ منه ما قيل: النصُّ، والسحبُ، والتعديل.
  static List<InternalMessage> _placed(
    List<InternalMessage> messages,
    InternalMessage incoming, {
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

  /// جوابُ الخادم، ومعه أيُّ رسالةٍ وصلت حيّةً ولم يعرفها الجواب — كمحادثة الدعم.
  static InternalTicket _keepingLiveMessages(InternalTicket answer, InternalTicket onScreen) {
    final known = {for (final message in answer.messages) message.id};
    final missing = onScreen.messages.where((message) => !known.contains(message.id));

    if (missing.isEmpty) return answer;

    return answer.copyWith(
      messages: [...answer.messages, ...missing]..sort((a, b) => a.id.compareTo(b.id)),
    );
  }

  static void _deleteFile(String path) {
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }

  /// ستّةَ عشرَ حرفاً ستّ‌عشرياً — رمزُ الإرسال، فريدٌ بما يكفي لتذكرةٍ واحدة.
  static String _randomToken() {
    final random = math.Random.secure();

    return List<String>.generate(32, (_) => random.nextInt(16).toRadixString(16)).join();
  }

  @override
  Future<void> close() async {
    for (final subscription in _live) {
      await subscription.cancel();
    }

    return super.close();
  }
}
