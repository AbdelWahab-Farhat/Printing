import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_design.freezed.dart';
part 'customer_design.g.dart';

/// What kind of file a design is — decided by the server from the file's own bytes, never from
/// its extension.
///
/// The app reads this to answer one question: *can I draw this myself, or must I hand it to
/// whatever the phone opens PDFs with?*
enum DesignKind {
  image,
  pdf,

  /// A kind this build has no case for.
  ///
  /// Kept rather than thrown, because an app already on a phone has to keep listing a
  /// customer's designs the day the API learns to accept one more format. Nothing draws an
  /// [unknown] inline — that is the point of naming it — and the tile still reads correctly,
  /// because the Arabic name comes from the server as `kind_label`.
  unknown,
}

/// A customer's artwork — the image or PDF that gets printed on their bags.
///
/// Held against the customer rather than against an order, so placing the next order is
/// choosing from a library instead of sending the same file again. See
/// `CustomerDesignResource` for the wire shape.
///
/// **[fileUrl] is not a permanent address.** The backend mints it per request and, on the
/// private bucket production uses, it is a signed link that expires — a design is the
/// customer's property, and a lasting public URL is their print file left in the open. So it is
/// never stored, never put in a shortcut, and a screen holding one for an hour must reload
/// rather than reuse it.
@freezed
abstract class CustomerDesign with _$CustomerDesign {
  const factory CustomerDesign({
    required int id,
    @JsonKey(name: 'customer_id') required int customerId,

    /// What staff read to tell two designs apart. Never null: the server falls back to the
    /// filename, because a row with no name is one nobody dares print from.
    required String label,

    String? notes,

    @JsonKey(unknownEnumValue: DesignKind.unknown) required DesignKind kind,

    /// The kind in Arabic, as the server words it. Shown instead of a switch over [kind] so an
    /// [DesignKind.unknown] still names itself.
    @JsonKey(name: 'kind_label') required String kindLabel,

    @JsonKey(name: 'mime_type') String? mimeType,
    @JsonKey(name: 'original_filename') String? originalFilename,
    @JsonKey(name: 'size_bytes') int? sizeBytes,
    @JsonKey(name: 'width_px') int? widthPx,
    @JsonKey(name: 'height_px') int? heightPx,

    /// Generated per request — see the note on the class.
    @JsonKey(name: 'file_url') String? fileUrl,

    /// A server-rendered first page for a PDF. Always null today; the key exists so that
    /// feature can land without an app release.
    @JsonKey(name: 'preview_url') String? previewUrl,

    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _CustomerDesign;

  const CustomerDesign._();

  factory CustomerDesign.fromJson(Map<String, dynamic> json) => _$CustomerDesignFromJson(json);

  /// Whether this app can draw the file itself.
  bool get isImage => kind == DesignKind.image;

  /// What to draw in the grid, or null when there is nothing to draw and the tile should show
  /// a glyph instead of a broken image.
  ///
  /// [previewUrl] wins: the day the backend starts rendering a PDF's first page, every phone
  /// already out there stops showing a glyph without being updated.
  String? get thumbnailUrl => previewUrl ?? (isImage ? fileUrl : null);

  /// «240 كيلوبايت». Null when the server did not measure it.
  ///
  /// Scaled rather than always in megabytes: a 240 KB logo shown as «0.2 ميجابايت» reads as
  /// nothing at all.
  String? get sizeLabel {
    final bytes = sizeBytes;
    if (bytes == null) return null;
    if (bytes < 1024) return '$bytes بايت';

    final kilobytes = bytes / 1024;
    if (kilobytes < 1024) return '${_round(kilobytes)} كيلوبايت';

    return '${_round(kilobytes / 1024)} ميجابايت';
  }

  /// «1200 × 800», or null unless both were measured — a width beside an empty height is a
  /// measurement that failed, and «1200 × » is worse than saying nothing.
  String? get dimensionsLabel {
    final width = widthPx;
    final height = heightPx;
    if (width == null || height == null) return null;

    return '$width × $height';
  }

  /// One decimal below ten, none above: «2.5 ميجابايت» is worth reading, «245.8 كيلوبايت» is
  /// four characters of noise. A decimal that lands on zero is dropped — «1 ميجابايت», not
  /// «1.0 ميجابايت», which reads as a measurement pretending to a precision it does not have.
  static String _round(double value) {
    final text = value.toStringAsFixed(value < 10 ? 1 : 0);

    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }
}
