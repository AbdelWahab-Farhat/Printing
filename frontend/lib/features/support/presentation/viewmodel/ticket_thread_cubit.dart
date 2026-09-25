import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/models/ticket_change.dart';
import 'package:dayaa/features/support/usecases/support_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ticket_thread_cubit.freezed.dart';
part 'ticket_thread_state.dart';

/// One thread: what was said, and the three things the desk can do about it.
///
/// **Every write answers with the whole ticket**, so nothing here patches the thread by hand:
/// the server returns it with the reply in it, the new assignee on it, or the closure stamped,
/// and this emits that. A screen that appended its own message locally would be guessing at the
/// id and the timestamp the server allocated — and would show a message that is not yet in the
/// database as though it were.
///
/// **والخيطُ حيّ.** ما يقوله العميل أو زميلٌ آخر يصل من المقبس ويُلحق بالخيط ساعةَ يُقال —
/// والرسالةُ هنا كتبها الخادم فعلاً، فليست تخميناً. ورسالةُ العميل تُقرأ في الحال بقراءةٍ صامتة،
/// لأن أحداً ينظر إلى الخيط: هذا ما يُطفئ شارتها عند الزملاء.
class TicketThreadCubit extends Cubit<TicketThreadState> {
  TicketThreadCubit({
    required int ticketId,
    required GetTicket get,
    required ReplyToTicket reply,
    required AssignTicket assign,
    required CloseTicket close,
    required ReopenTicket reopen,
    required WatchTicketChanges watch,
  }) : _ticketId = ticketId,
       _get = get,
       _reply = reply,
       _assign = assign,
       _close = close,
       _reopen = reopen,
       super(const TicketThreadState.loading()) {
    _live = [
      watch().where((change) => change.ticket.id == ticketId).listen(_absorbLive),
      // ما قيل في الانقطاع فات ولن يُعاد على المقبس.
      watch.resumed.listen((_) => unawaited(_readQuietly())),
    ];
  }

  final int _ticketId;
  final GetTicket _get;
  final ReplyToTicket _reply;
  final AssignTicket _assign;
  final CloseTicket _close;
  final ReopenTicket _reopen;
  late final List<StreamSubscription<Object?>> _live;

  /// يرتفع مع كل كتابةٍ وكل خبرٍ حيّ. **القراءةُ الصامتة لا تُعرض إن ارتفع أثناءها**: جوابُها
  /// أقدم مما على الشاشة، وعرضُه يُخفي رسالةً وصلت للتوّ أو يعيد حالةً تغيّرت. عملُها الأهمّ —
  /// نقلُ مؤشّر القراءة على الخادم — وقع على أيّ حال.
  int _generation = 0;

  /// Reads the thread. **This is what clears the unread badge**, server-side — the GET marks the
  /// desk's side read, so this runs because somebody opened the screen and for no other reason.
  Future<void> load() async {
    emit(const TicketThreadState.loading());

    final result = await _get(_ticketId);

    if (isClosed) return;

    // إغلاقان صريحان لا تمريرُ المُنشئ: تمريرُ مُنشئ اتحاد Freezed كدالةٍ يكسر بناء الإصدار —
    // RULES §٤ القاعدة ٧.
    emit(
      result.fold(
        (failure) => TicketThreadState.failure(failure),
        (ticket) => TicketThreadState.loaded(ticket: ticket),
      ),
    );
  }

  /// Sends a reply.
  ///
  /// **A failed send keeps the thread on screen** and reports beside it — losing a conversation
  /// because one request timed out is the worst thing this screen could do. The text the person
  /// typed stays in the field, which is the screen's business and not this Cubit's: clearing it
  /// on failure would throw away the sentence they are being asked to send again.
  ///
  /// [attachment] صورةٌ أو PDF يُرسل معها الكلامُ تعليقاً إن كُتب؛ وبلا ملفٍ ولا كلام لا يُرسل شيء.
  Future<bool> send(String body, {PickedFile? attachment}) {
    final trimmed = body.trim();

    if (trimmed.isEmpty && attachment == null) return Future<bool>.value(false);

    return _write(
      () => _reply(
        _ticketId,
        body: trimmed.isEmpty ? null : trimmed,
        attachment: attachment,
      ),
    );
  }

  /// Puts the ticket on somebody's desk, or [userId] null to put it back in the queue.
  Future<bool> assignTo(int? userId) => _write(() => _assign(_ticketId, userId: userId));

  /// Ends the conversation. Idempotent on the server, so a second press is not a failure.
  Future<bool> closeTicket() => _write(() => _close(_ticketId));

  /// يعيد فتحَ ما أغلقه المكتب، عن قصد — فيعود صندوقُ الرد.
  Future<bool> reopenTicket() => _write(() => _reopen(_ticketId));

  /// The shape all three writes share: mark busy, send, and either put the server's ticket on
  /// screen or keep the one already there and say why the write did not take.
  ///
  /// Returns whether it took, so the screen can clear its field or pop only on success.
  Future<bool> _write(Future<Either<Failure, SupportTicket>> Function() send) async {
    final loaded = state;

    // Nothing to write onto, or a write already in flight. The second guard is what stops a
    // double tap on «إغلاق» from sending two requests.
    if (loaded is! TicketThreadLoaded || loaded.isWorking) return false;

    _generation++;
    emit(loaded.copyWith(isWorking: true, lastFailure: null));

    final result = await send();

    if (isClosed) return false;

    // Re-read rather than reusing `loaded`: the state may have moved on across the await.
    final current = state;
    if (current is! TicketThreadLoaded) return false;

    return result.fold(
      (failure) {
        emit(current.copyWith(isWorking: false, lastFailure: failure));

        return false;
      },
      (ticket) {
        emit(
          current.copyWith(
            isWorking: false,
            ticket: _keepingLiveMessages(ticket, current.ticket),
            lastFailure: null,
          ),
        );

        return true;
      },
    );
  }

  /// خبرٌ حيّ عن هذه التذكرة: حالتُها كما هي الآن، والرسالةُ الجديدة إن كانت.
  ///
  /// **حقولُ التذكرة من الحدث، والخيطُ من الشاشة** — الحدث لا يحمل الخيط، فالرسائل التي على
  /// الشاشة تبقى وتُلحق بها الجديدة مرةً واحدة: ردّي أنا يصل بجواب الطلب وبالمقبس معاً.
  void _absorbLive(TicketChange change) {
    final current = state;
    if (current is! TicketThreadLoaded) return;

    _generation++;

    final message = change.message;
    final messages = current.ticket.messages;
    final merged = message == null || messages.any((m) => m.id == message.id)
        ? messages
        : ([...messages, message]..sort((a, b) => a.id.compareTo(b.id)));

    emit(current.copyWith(ticket: change.ticket.copyWith(messages: merged)));

    // كتب العميلُ والخيطُ مفتوحٌ أمام أحد: تُقرأ رسالته الآن، فتنطفئ شارتها عند الزملاء.
    if (message?.from == MessageAuthor.customer) unawaited(_readQuietly());
  }

  /// قراءةٌ بلا دائرة تحميل: تنقل مؤشّر القراءة على الخادم، وتُصالح ما على الشاشة مع ما فيه —
  /// إلا إن تغيّر شيءٌ أثناءها ([_generation]).
  Future<void> _readQuietly() async {
    if (state is! TicketThreadLoaded) return;

    final generation = _generation;
    final result = await _get(_ticketId);

    if (isClosed) return;

    final current = state;
    if (current is! TicketThreadLoaded || current.isWorking || generation != _generation) return;

    result.fold(
      (_) {},
      (ticket) => emit(current.copyWith(ticket: _keepingLiveMessages(ticket, current.ticket))),
    );
  }

  /// جوابُ الخادم، ومعه أيُّ رسالةٍ وصلت حيّةً ولم يعرفها الجواب.
  ///
  /// **الطلبُ والمقبس يتسابقان**: العميل يكتب بينما ردّي في الطريق، فيصل سطرُه من المقبس قبل
  /// جوابي — وجوابي بُني قبله. استبدالُ الخيط بالجواب كان سيُخفي سطرَه من الشاشة حتى القراءة
  /// التالية. الرسائل لا تُحذف في هذا الخيط، فاتحادُها بالرقم لا يُظهر ما لم يُقل.
  static SupportTicket _keepingLiveMessages(SupportTicket answer, SupportTicket onScreen) {
    final known = {for (final message in answer.messages) message.id};
    final missing = onScreen.messages.where((message) => !known.contains(message.id));

    if (missing.isEmpty) return answer;

    return answer.copyWith(
      messages: [...answer.messages, ...missing]..sort((a, b) => a.id.compareTo(b.id)),
    );
  }

  @override
  Future<void> close() async {
    for (final subscription in _live) {
      await subscription.cancel();
    }

    return super.close();
  }
}
