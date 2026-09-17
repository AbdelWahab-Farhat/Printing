import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'design_ticket_file.freezed.dart';
part 'design_ticket_file.g.dart';

/// Which half of the ticket's conversation a file belongs to.
enum DesignTicketFileKind {
  /// What the employee sent with the request — the logo, a photo of a similar bag.
  @JsonValue('brief')
  brief,

  /// What the designer drew. Numbered, and judged.
  @JsonValue('submission')
  submission,

  /// A kind this build has no case for. Kept rather than thrown, so one new value on the server
  /// does not turn a whole ticket into a parse failure.
  unknown,
}

/// Where one version stands with the employee who asked for it.
///
/// **Deliberately not [DesignKind]** and deliberately not the order screen's own verdict enum:
/// its third case is «مرفوض», an ending, while this one is «تعديل مطلوب» — an instruction that
/// keeps the ticket open on the designer's desk.
enum DesignSubmissionStatus {
  @JsonValue('proposed')
  proposed,
  @JsonValue('approved')
  approved,
  @JsonValue('changes_requested')
  changesRequested,
  unknown,
}

/// One file on a design ticket.
///
/// **Shaped to match [CustomerDesign] on purpose**, field for field where the two overlap:
/// `fileKind`, `fileUrl`, `label` and the dimensions all mean exactly what they mean there, so
/// `DesignThumbnail` and `DesignViewer` draw both without a second widget that can drift.
///
/// The version fields are null on a brief — the server's CHECK constraint guarantees it — so one
/// list can be rendered and branched on [kind].
///
/// **[fileUrl] is not a permanent address.** The backend mints it per request and, on the private
/// bucket production uses, it is a signed link that expires. Never store it, never put it in a
/// shortcut, and reload rather than reuse one a screen has held for an hour.
@freezed
abstract class DesignTicketFile with _$DesignTicketFile {
  const factory DesignTicketFile({
    required int id,
    @JsonKey(name: 'design_ticket_id') required int designTicketId,

    @JsonKey(unknownEnumValue: DesignTicketFileKind.unknown)
    required DesignTicketFileKind kind,

    /// The kind in Arabic, as the server words it — shown instead of a switch over [kind], so a
    /// value this build has never heard of still names itself.
    @JsonKey(name: 'kind_label') required String kindLabel,

    /// «النسخة ٣» for a submission, the filename for a brief. Never null: the server falls back.
    required String label,

    /// What the designer said when they sent it.
    String? note,

    /// `image` or `pdf` — whether the app can draw this itself or must hand it to the system
    /// viewer. The same key and the same meaning as `CustomerDesign.kind`.
    @JsonKey(name: 'file_kind', unknownEnumValue: DesignKind.unknown)
    required DesignKind fileKind,

    @JsonKey(name: 'file_kind_label') required String fileKindLabel,
    @JsonKey(name: 'mime_type') String? mimeType,
    @JsonKey(name: 'original_filename') String? originalFilename,
    @JsonKey(name: 'size_bytes') int? sizeBytes,
    @JsonKey(name: 'width_px') int? widthPx,
    @JsonKey(name: 'height_px') int? heightPx,

    /// Generated per request — see the note on the class.
    @JsonKey(name: 'file_url') String? fileUrl,

    /// Reserved. The server renders no first page for a PDF yet; the key is here so that it can
    /// start doing so without an app release.
    @JsonKey(name: 'preview_url') String? previewUrl,

    /// 1, 2, 3 … within the ticket. Null on a brief.
    int? version,

    @JsonKey(unknownEnumValue: DesignSubmissionStatus.unknown)
    DesignSubmissionStatus? status,

    @JsonKey(name: 'status_label') String? statusLabel,

    @JsonKey(name: 'is_awaiting_review') @Default(false) bool isAwaitingReview,

    /// **What has to change.** The whole reason a revision round exists, and the first thing the
    /// designer reads when a ticket comes back to them.
    @JsonKey(name: 'review_note') String? reviewNote,

    @JsonKey(name: 'reviewed_at') DateTime? reviewedAt,
    DesignTicketActor? reviewer,
    DesignTicketActor? uploader,

    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _DesignTicketFile;

  const DesignTicketFile._();

  factory DesignTicketFile.fromJson(Map<String, dynamic> json) =>
      _$DesignTicketFileFromJson(json);

  bool get isSubmission => kind == DesignTicketFileKind.submission;

  /// Whether this version was turned back with instructions.
  bool get needsChanges => status == DesignSubmissionStatus.changesRequested;

  bool get isApproved => status == DesignSubmissionStatus.approved;

  /// What a thumbnail may draw, if anything.
  ///
  /// Null for a PDF until the server renders a first page — the caller falls back to a glyph
  /// rather than a broken image. The same rule `CustomerDesign.thumbnailUrl` follows.
  String? get thumbnailUrl => fileKind == DesignKind.image ? fileUrl : previewUrl;
}

/// A person, as much of one as a ticket screen ever needs.
///
/// One class for all five roles a ticket names — requester, designer, acceptor, reviewer,
/// uploader — because the payload is the same two fields each time and five identical models
/// would be five places to change the day it grows a third.
@freezed
abstract class DesignTicketActor with _$DesignTicketActor {
  const factory DesignTicketActor({required int id, required String name}) = _DesignTicketActor;

  factory DesignTicketActor.fromJson(Map<String, dynamic> json) =>
      _$DesignTicketActorFromJson(json);
}
