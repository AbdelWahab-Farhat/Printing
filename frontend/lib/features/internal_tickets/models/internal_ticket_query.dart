import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'internal_ticket_query.freezed.dart';

/// ما تُسأل عنه قائمة «الموظفين» — كقائمة بريمولا الداخلية.
///
/// **[allTickets] تبويبُ «الكل» عند المدير**؛ لغيره يقرؤه الخادمُ «تذاكري» مهما أُرسل.
@freezed
abstract class InternalTicketQuery with _$InternalTicketQuery {
  const factory InternalTicketQuery({
    @Default(false) bool allTickets,

    /// تفتح القائمة على «قيد المعالجة»، ولا «الكل» في الرقاقتين — كبريمولا.
    @Default(InternalTicketStatus.inProgress) InternalTicketStatus status,
    int? categoryId,

    /// تذاكرُ زميلٍ بعينه، أيَّ طرفٍ كان.
    int? userId,
    @Default(false) bool unreadOnly,

    /// تذاكرُ طلبيةٍ أو عميل — القائمةُ مفتوحةً من صفحتهما.
    int? orderId,
    int? customerId,
    @Default(false) bool oldestFirst,
  }) = _InternalTicketQuery;

  const InternalTicketQuery._();

  /// القيمُ كما يقرؤها الخادم — والفارغُ يُحذف ولا يُرسل `null` (RULES §٦).
  Map<String, dynamic> toQuery({String? search, required int page}) => {
    'page': page,
    if (allTickets) 'scope': 'all',
    'status': ?status.wire,
    if (search != null && search.isNotEmpty) 'search': search,
    'category_id': ?categoryId,
    'user_id': ?userId,
    if (unreadOnly) 'unread': 1,
    'order_id': ?orderId,
    'customer_id': ?customerId,
    if (oldestFirst) 'sort': 'oldest_activity',
  };
}

/// ما تُفتح عليه القائمة من صفحة طلبيةٍ أو عميل: «تذاكر الطلبية #N»، كبريمولا — وزرُّ «تذكرة
/// جديدة» فيها يحمل الطلبية أو العميل نفسه.
@freezed
abstract class InternalTicketSubject with _$InternalTicketSubject {
  const factory InternalTicketSubject({
    int? orderId,
    String? orderCode,
    int? customerId,
    String? customerName,
  }) = _InternalTicketSubject;

  const InternalTicketSubject._();

  /// عنوانُ القائمة المقصورة.
  String get listTitle => switch (this) {
    InternalTicketSubject(:final orderCode?) => 'تذاكر الطلبية $orderCode',
    InternalTicketSubject(:final customerName?) => 'تذاكر الموظفين عن $customerName',
    _ => 'تذاكر الموظفين',
  };

  /// سطرُ «عن ماذا» في نموذج التذكرة الجديدة.
  String? get label => orderCode != null
      ? 'الطلبية $orderCode'
      : customerName != null
      ? 'العميل $customerName'
      : null;
}

/// «تذكرة جديدة» كما ملأها الموظف.
@freezed
abstract class InternalTicketDraft with _$InternalTicketDraft {
  const factory InternalTicketDraft({
    required int assigneeId,
    required String title,
    required String description,
    @Default(InternalTicketPriority.medium) InternalTicketPriority priority,
    int? categoryId,
    int? customerId,
    int? orderId,
  }) = _InternalTicketDraft;
}
