import 'dart:async';
import 'dart:math';

import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/picked_file.dart';
import 'package:dayaa_client/core/files/transfer_cancel.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/models/ticket_change.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/open_thread.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/outgoing_message.dart';
import 'package:dayaa_client/features/support/usecases/get_ticket.dart';
import 'package:dayaa_client/features/support/usecases/reply_to_ticket.dart';
import 'package:dayaa_client/features/support/usecases/watch_ticket_changes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ticket_thread_cubit.freezed.dart';
part 'ticket_thread_state.dart';

/// أكبر ملفٍّ يُرفع في المحادثة — **صورةٌ عن `media.ticket_attachments.max_kilobytes` على
/// الخادم** (٢٥٦٠٠ ك.ب). فحصٌ مسبق يوفّر رفع ملفٍّ كاملٍ ليُرفض في آخره؛ والخادم يرفض على أيّ حال.
const int ticketAttachmentMaxBytes = 25600 * 1024;

/// The ViewModel for one conversation.
///
/// **Loading the thread is what marks it read**, and the server does that on the same call — so
/// there is no «mark as read» to fire here, and no cursor for this app to get wrong.
///
/// **والخيطُ حيّ.** ردُّ المحل يصل من المقبس ويُلحق بالخيط ساعةَ يُكتب — والرسالةُ كتبها الخادم
/// فعلاً، فليست تخميناً — ثم يُقرأ الخيط بصمت، فينتقل مؤشّر القراءة ويرى المحلّ ✓✓. وما دام هذا
/// الـ Cubit حيّاً فالخيطُ «مفتوحٌ على الشاشة» ([OpenThread])، فلا تُضاء له شارة «الدعم».
///
/// **وما يكتبه العميل يظهر في مكانه ساعةَ يُكتب — بساعة، لا بعلامة ✓.** هذا ما يفعله تطبيق
/// المحادثة المرجع، والساعة تقول «لم تصل بعد» بوضوحٍ لا يُخطئه أحد: الخوف الذي أبقى هذه الشاشة
/// بلا رسائل معلّقة — أن يظنّ العميل أن رسالته وصلت — تجيب عنه الساعة، ثم ✓ حين يقبلها الخادم،
/// ثم ✓✓ حين يراها المحل. ورسالةٌ رُفضت تبقى مكانها بعلامةٍ حمراء حتى يعيدها أو يحذفها، فلا
/// يضيع ما كُتب. انظر [OutgoingMessage].
///
/// **الرسائل تُرسل واحدةً بعد واحدة بترتيب كتابتها** ([_drain])، فيصل الخادمَ ما كُتب كما كُتب.
class TicketThreadCubit extends Cubit<TicketThreadState> {
  TicketThreadCubit({
    required this.ticketId,
    required GetTicket get,
    required ReplyToTicket reply,
    required WatchTicketChanges watch,
    required OpenThread openThread,
    String Function()? newToken,
  }) : _get = get,
       _reply = reply,
       _openThread = openThread,
       _newToken = newToken ?? _randomToken,
       super(const TicketThreadState.loading()) {
    openThread.enter(ticketId);

    _live = [
      watch().where((change) => change.ticket.id == ticketId).listen(_absorbLive),
      // ما قيل في الانقطاع فات ولن يُعاد على المقبس.
      watch.resumed.listen((_) => unawaited(_readQuietly())),
    ];
  }

  final int ticketId;
  final GetTicket _get;
  final ReplyToTicket _reply;
  final OpenThread _openThread;
  final String Function() _newToken;
  late final List<StreamSubscription<Object?>> _live;

  /// الرفع الجاري، برمز رسالته — لـ«✕» على حلقة الرفع.
  final Map<String, TransferCancel> _uploads = {};

  /// هل تُفرَّغ قائمة الإرسال الآن؟ مُفرِّغٌ واحد، فتصل الرسائل بترتيبها.
  bool _draining = false;

  /// يرتفع مع كل إرسالٍ وكل خبرٍ حيّ. **القراءةُ الصامتة لا تُعرض إن ارتفع أثناءها**: جوابُها
  /// أقدم مما على الشاشة. عملُها الأهمّ — نقلُ مؤشّر القراءة على الخادم — وقع على أيّ حال.
  int _generation = 0;

  Future<void> load() async {
    // ما في الطريق يبقى في الطريق: إعادة القراءة لا تمسح رسالةً لم تصل بعد.
    final outbox = state.outbox;

    emit(const TicketThreadState.loading());

    final result = await _get(ticketId);

    if (isClosed) return;

    // إغلاقان صريحان لا تمريرُ المُنشئ: تمريرُ مُنشئ اتحاد Freezed كدالةٍ يكسر بناء الإصدار —
    // RULES §٤ القاعدة ٧.
    emit(
      result.fold(
        (failure) => TicketThreadState.failure(failure),
        (ticket) => TicketThreadState.loaded(ticket, outbox: outbox),
      ),
    );
  }

  /// سحبُ الشاشة إلى أسفل: قراءةٌ بلا دائرة تحميل، تنقل مؤشّر القراءة وتُصالح ما على الشاشة.
  Future<void> refresh() => _readQuietly();

  /// يكتب رسالة: تظهر في الحال بساعة، وتُرسل بترتيبها.
  Future<void> send(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty || _loaded == null) return;

    await _enqueue(
      OutgoingMessage(clientToken: _newToken(), body: trimmed, createdAt: DateTime.now()),
    );
  }

  /// يرفع ملفاً — صورةً أو PDF — رسالةً وحده. حلقةُ الرفع على فقاعته حتى يصل.
  Future<void> sendFile(PickedFile file) async {
    final loaded = _loaded;
    if (loaded == null) return;

    // يُرفض هنا قبل أن يُرفع كاملاً ليُرفض في آخره.
    if (file.sizeBytes > ticketAttachmentMaxBytes) {
      emit(
        loaded.copyWith(
          lastFailure: const Failure.unexpected(message: 'حجم الملف يجب ألا يتجاوز 25 ميجابايت'),
        ),
      );

      return;
    }

    await _enqueue(
      OutgoingMessage(clientToken: _newToken(), file: file, createdAt: DateTime.now()),
    );
  }

  /// يعيد رسالةً رُفضت. **بالرمز نفسه**، فإن كانت وصلت الخادمَ قبل أن ينقطع الاتصال أعادها
  /// الخادم نفسها ولم يكتب ثانية.
  Future<void> retry(String clientToken) async {
    final loaded = _loaded;
    if (loaded == null) return;

    emit(
      loaded.copyWith(
        lastFailure: null,
        outbox: [
          for (final message in loaded.outbox)
            message.clientToken == clientToken
                ? message.copyWith(status: OutgoingStatus.sending, failure: null, progress: 0)
                : message,
        ],
      ),
    );

    await _drain();
  }

  /// يحذف رسالةً رُفضت ولم يُرد صاحبها إعادتها.
  void discard(String clientToken) {
    final loaded = _loaded;
    if (loaded == null) return;

    emit(loaded.copyWith(outbox: _without(loaded.outbox, clientToken)));
  }

  /// يوقف رفع ملفٍّ في الطريق — «✕» على حلقة الرفع. الفقاعة تختفي، كما في المرجع.
  void cancelUpload(String clientToken) => _uploads[clientToken]?.cancel();

  Future<void> _enqueue(OutgoingMessage message) async {
    final loaded = _loaded;
    if (loaded == null) return;

    emit(loaded.copyWith(outbox: [...loaded.outbox, message], lastFailure: null));

    await _drain();
  }

  /// يرسل ما في الطريق واحدةً بعد واحدة، الأقدم أولاً، حتى لا يبقى شيء.
  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;

    while (!isClosed) {
      final next = _loaded?.outbox
          .where((message) => message.status == OutgoingStatus.sending)
          .firstOrNull;

      if (next == null) break;

      await _deliver(next);
    }

    _draining = false;
  }

  Future<void> _deliver(OutgoingMessage message) async {
    _generation++;

    final token = message.clientToken;
    final cancel = TransferCancel();
    _uploads[token] = cancel;

    var shown = 0.0;
    final result = await _reply(
      id: ticketId,
      body: message.body,
      file: message.file,
      clientToken: token,
      cancel: cancel,
      onProgress: message.file == null
          ? null
          : (progress) {
              // لا حالةَ جديدة لكل كتلة بايتات: كل نقطتين مئويتين تكفيان لحلقةٍ تُرى تمتلئ.
              if (isClosed || cancel.isCancelled || progress - shown < 0.02) return;

              shown = progress;
              _patch(token, (pending) => pending.copyWith(progress: progress));
            },
    );

    _uploads.remove(token);
    if (isClosed) return;

    final current = _loaded;
    if (current == null) return;

    // الإلغاء ليس فشلاً: من ألغى يعرف أنه ألغى، فتختفي الفقاعة بلا رسالة خطأ.
    if (cancel.isCancelled) {
      emit(current.copyWith(outbox: _without(current.outbox, token)));

      return;
    }

    emit(
      result.fold(
        (failure) => current.copyWith(
          lastFailure: failure,
          outbox: [
            for (final pending in current.outbox)
              pending.clientToken == token
                  ? pending.copyWith(status: OutgoingStatus.failed, failure: failure)
                  : pending,
          ],
        ),
        (ticket) => current.copyWith(
          ticket: _keepingLiveMessages(ticket, current.ticket),
          outbox: _without(current.outbox, token),
          lastFailure: null,
        ),
      ),
    );
  }

  void _patch(String clientToken, OutgoingMessage Function(OutgoingMessage) change) {
    final loaded = _loaded;
    if (loaded == null) return;

    emit(
      loaded.copyWith(
        outbox: [
          for (final message in loaded.outbox)
            message.clientToken == clientToken ? change(message) : message,
        ],
      ),
    );
  }

  static List<OutgoingMessage> _without(List<OutgoingMessage> outbox, String clientToken) => [
    for (final message in outbox)
      if (message.clientToken != clientToken) message,
  ];

  /// خبرٌ حيّ عن هذه التذكرة: حالتُها كما هي الآن، والرسالةُ الجديدة إن كانت.
  ///
  /// **حقولُ التذكرة من الحدث، والخيطُ من الشاشة** — الحدث لا يحمل الخيط، فالرسائل التي على
  /// الشاشة تبقى وتُلحق بها الجديدة مرةً واحدة: ردّي أنا يصل بجواب الطلب وبالمقبس معاً. وفقاعتي
  /// المعلّقة التي صارت هذه الرسالة لا تُرسم مرّتين: الرمز نفسه عليهما — انظر `chatTimeline`.
  void _absorbLive(TicketChange change) {
    final current = _loaded;
    if (current == null) return;

    _generation++;

    final message = change.message;
    final messages = current.ticket.messages;
    final merged = message == null || messages.any((m) => m.id == message.id)
        ? messages
        : ([...messages, message]..sort((a, b) => a.id.compareTo(b.id)));

    emit(current.copyWith(ticket: change.ticket.copyWith(messages: merged)));

    // ردٌّ من المحل والخيطُ أمام العميل: يُقرأ الآن، فينتقل المؤشّر ويرى المحلّ ✓✓.
    if (message != null && !message.isMine) unawaited(_readQuietly());
  }

  /// قراءةٌ بلا دائرة تحميل: تنقل مؤشّر القراءة على الخادم، وتُصالح ما على الشاشة مع ما فيه —
  /// إلا إن تغيّر شيءٌ أثناءها ([_generation]).
  Future<void> _readQuietly() async {
    if (_loaded == null) return;

    final generation = _generation;
    final result = await _get(ticketId);

    if (isClosed) return;

    final current = _loaded;
    if (current == null || generation != _generation) return;

    result.fold(
      (_) {},
      (ticket) => emit(current.copyWith(ticket: _keepingLiveMessages(ticket, current.ticket))),
    );
  }

  /// جوابُ الخادم، ومعه أيُّ رسالةٍ وصلت حيّةً ولم يعرفها الجواب.
  ///
  /// **الطلبُ والمقبس يتسابقان**: المحل يردّ بينما رسالتي في الطريق، فيصل ردُّه من المقبس قبل
  /// جوابي — وجوابي بُني قبله. الرسائل لا تُحذف من خيط، فاتحادُها بالرقم لا يُظهر ما لم يُقل.
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
    _openThread.leave(ticketId);

    for (final upload in _uploads.values) {
      upload.cancel();
    }

    for (final subscription in _live) {
      await subscription.cancel();
    }

    return super.close();
  }

  /// The thread as it stands, for the screen to hand back to the list on its way out.
  SupportTicket? get ticket => _loaded?.ticket;

  TicketThreadLoaded? get _loaded => switch (state) {
    final TicketThreadLoaded loaded => loaded,
    _ => null,
  };

  /// رمزٌ عشوائيّ لا يتكرّر عملياً — ١٢٨ بتّاً من مولّد النظام الآمن.
  static String _randomToken() {
    final random = Random.secure();

    return [
      for (var i = 0; i < 16; i++) random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
  }
}
