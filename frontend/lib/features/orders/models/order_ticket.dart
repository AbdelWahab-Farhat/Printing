import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_ticket.freezed.dart';
part 'order_ticket.g.dart';

/// أيُّ الأنواع الثلاثة — وهو ما يقرّر أيّ شاشةٍ تفتحها.
enum OrderTicketKind {
  /// تذكرةٌ بين موظفَين.
  @JsonValue('internal')
  internal,

  /// طلبُ تصميمٍ إلى المصمّمين.
  @JsonValue('design')
  design,

  /// ما سأله العميل من تطبيقه.
  @JsonValue('support')
  support,

  /// نوعٌ أضافه الخادم بعد هذا الإصدار: يُرسم باسمه ولا يُفتح، بدل أن تسقط القائمة كلّها.
  unknown,
}

/// صفٌّ في «التذاكر المرتبطة» بالطلبية — `GET /orders/{id}/tickets`.
///
/// **[kind] و[id] معاً عنوانُ فتحها**: المعرّفُ يتكرّر بين الجداول الثلاثة. و[kindLabel] الكلمةُ
/// بجانبها — «موظفين»، «تصميم»، «عميل» — من الخادم كبقية التسميات.
@freezed
abstract class OrderTicket with _$OrderTicket {
  const factory OrderTicket({
    @JsonKey(unknownEnumValue: OrderTicketKind.unknown) required OrderTicketKind kind,
    @JsonKey(name: 'kind_label') required String kindLabel,
    required int id,

    /// «T24» و«D6». فارغٌ لتذكرة العميل: صفُّها بلا كود — انظر [label].
    String? code,

    required String title,
    required String status,
    @JsonKey(name: 'status_label') required String statusLabel,
    @JsonKey(name: 'is_open') @Default(false) bool isOpen,
    @JsonKey(name: 'activity_at') DateTime? activityAt,
  }) = _OrderTicket;

  const OrderTicket._();

  factory OrderTicket.fromJson(Map<String, dynamic> json) => _$OrderTicketFromJson(json);

  /// ما يُكتب في رأس الصف: الكودُ، أو رقمُها حين لا كود.
  String get label => (code ?? '').isNotEmpty ? code! : '#$id';
}
