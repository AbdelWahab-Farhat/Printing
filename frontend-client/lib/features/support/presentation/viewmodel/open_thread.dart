/// أيُّ خيطِ دعمٍ مفتوحٌ الآن على الشاشة، إن كان.
///
/// **لسؤالٍ واحد يسأله [SupportBadgeFeed]**: ردٌّ حيٌّ من المحل وصل — أيُضيء شارة «الدعم» أم
/// أن العميل يقرؤه الآن؟ الخيطُ المفتوح يقرؤه ويُعلِّمه مقروءاً في الحال، فإضاءةُ الشارة له
/// كانت ستقول «عندك ردٌّ لم تقرأه» عن ردٍّ أمام عينيه.
///
/// يسجّل [TicketThreadCubit] نفسه هنا حين يُبنى ويخرج حين يُغلق — فالحقيقة تتبع عمرَ الشاشة لا
/// ذاكرةَ أحد.
class OpenThread {
  int? _current;

  bool isShowing(int ticketId) => _current == ticketId;

  void enter(int ticketId) => _current = ticketId;

  /// لا يمسح خيطاً آخر فُتح بعده: الشاشةُ الجديدة تُبنى قبل أن تُغلق القديمة أحياناً.
  void leave(int ticketId) {
    if (_current == ticketId) _current = null;
  }
}
