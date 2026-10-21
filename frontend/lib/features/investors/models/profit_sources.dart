import 'package:freezed_annotation/freezed_annotation.dart';

part 'profit_sources.freezed.dart';
part 'profit_sources.g.dart';

/// One gate of his profit card, opened — «من أين جاء هذا الرقم؟».
///
/// [total] is the figure the card shows for [gate], and the server builds the list so that its
/// lines add up to it. `awaiting_delivery` is a list of orders; `pending` and `available` are a
/// reconciliation: what came in, and what a close or a withdrawal took out. Money in the wallet
/// is not tied to an order once some of it has left, so no screen pretends it is.
@freezed
abstract class ProfitSources with _$ProfitSources {
  const factory ProfitSources({
    required String gate,
    required String total,
    @Default(<ProfitSourceGroup>[]) List<ProfitSourceGroup> groups,
  }) = _ProfitSources;

  factory ProfitSources.fromJson(Map<String, dynamic> json) => _$ProfitSourcesFromJson(json);
}

/// A period's share of the gate — or the whole list, untitled, when the gate has no periods.
@freezed
abstract class ProfitSourceGroup with _$ProfitSourceGroup {
  const factory ProfitSourceGroup({
    required String key,

    /// «P3», or the old deal's name; null when the list is one plain run.
    String? title,
    @JsonKey(name: 'starts_on') String? startsOn,
    @JsonKey(name: 'ends_on') String? endsOn,

    /// `open` · `closing` · `closed` — the same words as the period register.
    String? status,
    @JsonKey(name: 'status_label') String? statusLabel,
    required String total,
    @Default(<ProfitSourceLine>[]) List<ProfitSourceLine> lines,
  }) = _ProfitSourceGroup;

  factory ProfitSourceGroup.fromJson(Map<String, dynamic> json) =>
      _$ProfitSourceGroupFromJson(json);
}

/// One line: an order and his share of it, a release opening onto its orders, or a named
/// movement — an expense share, a withdrawal, what a close took out.
@freezed
abstract class ProfitSourceLine with _$ProfitSourceLine {
  const factory ProfitSourceLine({
    /// `order` · `release` · `entry`.
    required String kind,
    required String key,

    /// Signed: a release taken out of «معلّقة» and a withdrawal are negative.
    required String amount,

    /// What the line is when it is not an order.
    String? label,

    @JsonKey(name: 'order_id') int? orderId,
    String? code,
    @JsonKey(name: 'customer_name') String? customerName,
    @JsonKey(name: 'order_status_label') String? orderStatusLabel,

    /// `awaiting_delivery` · `awaiting_period_end` · `awaiting_payment` · `awaiting_deal_close`
    /// · `released`.
    String? state,
    @JsonKey(name: 'state_label') String? stateLabel,

    @JsonKey(name: 'occurred_at') String? occurredAt,

    /// A release's orders, and what is not an order in it.
    @Default(<ProfitSourceLine>[]) List<ProfitSourceLine> children,
  }) = _ProfitSourceLine;

  factory ProfitSourceLine.fromJson(Map<String, dynamic> json) =>
      _$ProfitSourceLineFromJson(json);
}

/// The three gates, in the order money passes through them.
enum ProfitGate {
  awaitingDelivery('awaiting_delivery', 'ربح قيد التسليم'),
  pending('pending', 'أرباح معلّقة'),
  available('available', 'أرباح متاحة للسحب');

  const ProfitGate(this.value, this.title);

  /// What the API calls it.
  final String value;

  /// The sheet's heading.
  final String title;
}
