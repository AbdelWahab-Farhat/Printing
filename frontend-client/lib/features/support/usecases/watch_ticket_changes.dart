import 'package:dayaa_client/features/support/models/ticket_change.dart';
import 'package:dayaa_client/features/support/repositories/support_repository.dart';

/// تذاكري حيّةً: كلُّ تغيّرٍ ساعةَ يقع، و[resumed] حين يعود الاتصال بعد انقطاع.
class WatchTicketChanges {
  const WatchTicketChanges(this._repository);

  final SupportRepository _repository;

  Stream<TicketChange> call() => _repository.watchChanges();

  /// ما تغيّر في الانقطاع فات — من يرسم تذكرةً يعيد قراءتها هنا.
  Stream<void> get resumed => _repository.liveResumed;
}
