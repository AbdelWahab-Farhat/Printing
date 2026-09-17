import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_file.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'design_ticket.freezed.dart';
part 'design_ticket.g.dart';

/// Where a design request stands.
///
/// **This enum holds no transition map**, exactly as `ShortageStatus` holds none: every ticket
/// carries `available_transitions`, already the server's answer for this row and this reader. A
/// copy in Dart would be a second rule to keep in step.
///
/// It goes further here, and the difference is worth knowing: on the server *no endpoint sets a
/// status at all*. Each one is written by the action that earns it — accepting, submitting,
/// reviewing, cancelling — so this app never sends a status anywhere. What it draws buttons from
/// is the `can*` flags on the ticket, not this list.
enum DesignTicketStatus {
  @JsonValue('new')
  fresh('new', 'جديد'),
  @JsonValue('in_progress')
  inProgress('in_progress', 'قيد التصميم'),
  @JsonValue('under_review')
  underReview('under_review', 'بانتظار المراجعة'),
  @JsonValue('changes_requested')
  changesRequested('changes_requested', 'تعديل مطلوب'),
  @JsonValue('completed')
  completed('completed', 'مكتمل'),
  @JsonValue('cancelled')
  cancelled('cancelled', 'ملغى'),

  /// A status this build has never heard of. Reached through `unknownEnumValue`, so one new case
  /// on the server does not turn a whole page into a parse failure.
  ///
  /// **Read, never offered.** The filter row lists [offered], which leaves it out: a chip nobody
  /// can name is a chip nobody can use.
  unknown('', '');

  const DesignTicketStatus(this.wire, this.label);

  final String wire;

  /// Mirrors the server's own `label()`. Held here because the filter row has to name all six
  /// before a single ticket has been loaded.
  final String label;

  /// The six a person may filter by — everything this build can name.
  static List<DesignTicketStatus> get offered =>
      values.where((status) => status != DesignTicketStatus.unknown).toList(growable: false);
}

/// One move a ticket may make, as the server offers it.
@freezed
abstract class DesignTicketTransition with _$DesignTicketTransition {
  const factory DesignTicketTransition({required String value, required String label}) =
      _DesignTicketTransition;

  factory DesignTicketTransition.fromJson(Map<String, dynamic> json) =>
      _$DesignTicketTransitionFromJson(json);
}

/// The order a ticket was raised against, as much of it as a card needs.
@freezed
abstract class DesignTicketOrder with _$DesignTicketOrder {
  const factory DesignTicketOrder({
    required int id,
    required String code,
    @JsonKey(name: 'is_archived') @Default(false) bool isArchived,
  }) = _DesignTicketOrder;

  factory DesignTicketOrder.fromJson(Map<String, dynamic> json) =>
      _$DesignTicketOrderFromJson(json);
}

/// A request for artwork — from the employee who asked to the designer who drew it.
///
/// **[customerName] is a snapshot the server keeps on the ticket, not a joined field**, and that
/// is the reason a designer can read this screen at all: `customers.view` opens that customer's
/// orders and money, and a designer holds none of it. Do not reach for the customer here; there
/// may be no permission to fetch one.
///
/// **The five `can*` flags are the server's answer and the only thing that draws a button.** Each
/// is a permission *and* the status *and* this reader's role on this particular ticket, evaluated
/// together. Recomputing any of them here would be a second implementation of the state machine
/// in another language, and it would drift the first time a rule changed — the app would offer a
/// button the API then refuses, which reads to the user as the app being broken.
@freezed
abstract class DesignTicket with _$DesignTicket {
  const factory DesignTicket({
    required int id,

    /// `D7`. Said next to an order or a customer, which is why it carries a letter.
    required String code,

    required String title,
    required String description,
    String? instructions,

    @JsonKey(unknownEnumValue: DesignTicketStatus.unknown) required DesignTicketStatus status,

    /// The status in Arabic, as the server words it. Shown instead of [DesignTicketStatus.label]
    /// wherever a ticket is in hand, so an unknown status still names itself.
    @JsonKey(name: 'status_label') required String statusLabel,

    @JsonKey(name: 'is_open') @Default(true) bool isOpen,
    @JsonKey(name: 'is_closed') @Default(false) bool isClosed,

    @JsonKey(name: 'available_transitions')
    @Default(<DesignTicketTransition>[])
    List<DesignTicketTransition> availableTransitions,

    @JsonKey(name: 'customer_id') required int customerId,

    /// See the note on the class: a snapshot, and the reason this screen needs no grant on
    /// customers.
    @JsonKey(name: 'customer_name') required String customerName,

    @JsonKey(name: 'order_id') int? orderId,
    DesignTicketOrder? order,

    DesignTicketActor? requester,

    /// **Two people, and they answer different questions.** [designer] is who the ticket is
    /// addressed to; [acceptedBy] is who actually took it. A reassignment moves the first and
    /// never the second — «لا تضيع هوية المصمم الذي استلم الطلب» is about the second.
    DesignTicketActor? designer,

    @JsonKey(name: 'accepted_by') DesignTicketActor? acceptedBy,
    @JsonKey(name: 'accepted_at') DateTime? acceptedAt,

    /// Addressed to nobody and taken by nobody — what a designer scrolls to find work.
    @JsonKey(name: 'is_in_shared_pool') @Default(false) bool isInSharedPool,

    @JsonKey(name: 'approved_by') DesignTicketActor? approvedBy,
    @JsonKey(name: 'completed_at') DateTime? completedAt,

    /// What the approval put on the customer's account — the output of the whole flow.
    @JsonKey(name: 'approved_customer_design_id') int? approvedCustomerDesignId,
    @JsonKey(name: 'approved_design') CustomerDesign? approvedDesign,

    @JsonKey(name: 'cancellation_reason') String? cancellationReason,

    @JsonKey(name: 'versions_count') int? versionsCount,

    /// Only the detail endpoint sends these two; a list row carries neither.
    @Default(<DesignTicketFile>[]) List<DesignTicketFile> attachments,
    @Default(<DesignTicketFile>[]) List<DesignTicketFile> versions,

    @JsonKey(name: 'can_accept') @Default(false) bool canAccept,
    @JsonKey(name: 'can_submit') @Default(false) bool canSubmit,
    @JsonKey(name: 'can_review') @Default(false) bool canReview,
    @JsonKey(name: 'can_assign') @Default(false) bool canAssign,
    @JsonKey(name: 'can_manage') @Default(false) bool canManage,

    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _DesignTicket;

  const DesignTicket._();

  factory DesignTicket.fromJson(Map<String, dynamic> json) => _$DesignTicketFromJson(json);

  /// The version sitting with the reviewer, if any. At most one can exist.
  DesignTicketFile? get pendingVersion {
    for (final version in versions) {
      if (version.isAwaitingReview) return version;
    }

    return null;
  }

  /// The most recent version, whatever its verdict — what the header shows.
  DesignTicketFile? get latestVersion => versions.isEmpty ? null : versions.last;

  /// Who is actually doing the work: whoever took it, or failing that whoever it was given to.
  DesignTicketActor? get workingDesigner => acceptedBy ?? designer;

  /// How many versions there are, whichever endpoint answered.
  ///
  /// The list sends `versions_count` and no rows; the detail sends the rows. Reading one or the
  /// other at each call site is how a card ends up showing «0 نسخ» on a ticket with three.
  int get versionCount => versionsCount ?? versions.length;
}
