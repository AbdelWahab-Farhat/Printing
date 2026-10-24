import 'dart:async';

import 'package:dayaa/core/chat/chat_message.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/usecases/internal_tickets_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'internal_tickets_home_cubit.freezed.dart';

/// بطاقةُ الرئيسية.
@freezed
sealed class InternalTicketsHomeState with _$InternalTicketsHomeState {
  const factory InternalTicketsHomeState.loading() = InternalTicketsHomeLoading;

  const factory InternalTicketsHomeState.failure(Failure failure) = InternalTicketsHomeFailure;

  const factory InternalTicketsHomeState.loaded({
    required InternalTicketsHome home,

    /// التذكرةُ التي يُرسل إليها ردٌّ سريع الآن.
    int? replyingTo,
    Failure? lastFailure,
  }) = InternalTicketsHomeLoaded;
}

/// «تنتظر ردّك»، كبطاقة بريمولا: حتى عشر تذاكر آخرُ كلامٍ فيها لزميلي، وردٌّ سريعٌ بلا فتحها.
///
/// **حيّة وهي ظاهرة**: إشارةٌ على قناتي تعيد قراءتها بعد ثانية — الإشارةُ رقمٌ فقط، والبطاقةُ تُحسب لي.
/// **وفشلُ إعادة القراءة لا يمسح ما عليها**: بطاقةٌ صحيحةٌ قبل دقيقة خيرٌ من «حدث خطأ».
class InternalTicketsHomeCubit extends Cubit<InternalTicketsHomeState> {
  InternalTicketsHomeCubit({
    required GetInternalTicketsHome get,
    required SendInternalMessage send,
    required WatchInternalTickets watch,
    required int? me,
    String Function()? newToken,
  }) : _get = get,
       _send = send,
       _newToken = newToken ?? _timeToken,
       super(const InternalTicketsHomeState.loading()) {
    _live = [
      if (me != null) watch.mine(me).listen((_) => _schedule()),
      watch.resumed.listen((_) => _schedule()),
    ];
  }

  final GetInternalTicketsHome _get;
  final SendInternalMessage _send;
  final String Function() _newToken;
  late final List<StreamSubscription<Object?>> _live;
  Timer? _timer;

  static const Duration refreshDelay = Duration(seconds: 1);

  Future<void> load() async {
    final result = await _get();

    if (isClosed) return;

    final current = state;

    result.fold(
      (failure) {
        if (current is InternalTicketsHomeLoaded) return;

        emit(InternalTicketsHomeState.failure(failure));
      },
      (home) => emit(
        current is InternalTicketsHomeLoaded
            ? current.copyWith(home: home)
            : InternalTicketsHomeState.loaded(home: home),
      ),
    );
  }

  /// ردٌّ سريعٌ من البطاقة: يُرسل ثم تُقرأ البطاقةُ ثانيةً — الردُّ يُخرج التذكرةَ منها.
  Future<bool> quickReply(int ticketId, String body) async {
    final current = state;
    final text = body.trim();

    if (current is! InternalTicketsHomeLoaded || current.replyingTo != null || text.isEmpty) {
      return false;
    }

    emit(current.copyWith(replyingTo: ticketId, lastFailure: null));

    final result = await _send(
      ticketId,
      OutgoingChatMessage(clientToken: _newToken(), body: text),
    );

    if (isClosed) return false;

    final after = state;
    if (after is! InternalTicketsHomeLoaded) return false;

    return result.fold(
      (failure) {
        emit(after.copyWith(replyingTo: null, lastFailure: failure));

        return false;
      },
      (_) {
        emit(after.copyWith(replyingTo: null));
        unawaited(load());

        return true;
      },
    );
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(refreshDelay, () => unawaited(load()));
  }

  /// يكفي للردّ السريع: ردّان من موظفٍ واحد في الميكروثانية نفسها لا يُكتبان.
  static String _timeToken() => 'home-${DateTime.now().microsecondsSinceEpoch}';

  @override
  Future<void> close() async {
    _timer?.cancel();

    for (final subscription in _live) {
      await subscription.cancel();
    }

    return super.close();
  }
}
