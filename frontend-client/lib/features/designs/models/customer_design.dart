import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_design.freezed.dart';
part 'customer_design.g.dart';

/// What kind of file a design is — which decides whether this app can draw it or must hand it
/// to the system's viewer.
///
/// **The server decides, from the bytes.** `kind` is sniffed with finfo on upload and never
/// taken from the filename or the client's claim, so this enum is reading a decision rather than
/// making one. `unknown` exists only so a value this build has not heard of cannot crash the
/// list — see [DesignKind.fromWire].
enum DesignKind {
  image,
  pdf,

  /// A kind added to the API after this build shipped. Drawn as a generic file.
  unknown,
}

extension DesignKindX on DesignKind {
  static DesignKind fromWire(String? value) => switch (value) {
    'image' => DesignKind.image,
    'pdf' => DesignKind.pdf,
    _ => DesignKind.unknown,
  };

  bool get isImage => this == DesignKind.image;
}

/// One piece of the customer's artwork.
///
/// **Uploaded once and pointed at by every order** — that is the whole feature, and it is why
/// `order_designs` holds a reference rather than the file. The staff app calls this the same
/// thing and reads a wider version of it: this one has no `notes`, because that field is what
/// staff write to each other about a design and does not leave for the app.
@freezed
abstract class CustomerDesign with _$CustomerDesign {
  const factory CustomerDesign({
    required int id,

    /// Never null: the server falls back to the filename, because a design with no name is one
    /// nobody dares print from.
    required String label,

    /// `image` or `pdf`, already decided. Sent alongside [kindLabel] so this app keeps no
    /// translation table of its own.
    @JsonKey(name: 'kind', unknownEnumValue: DesignKind.unknown)
    @Default(DesignKind.unknown)
    DesignKind kind,

    @JsonKey(name: 'kind_label') String? kindLabel,
    @JsonKey(name: 'mime_type') String? mimeType,
    @JsonKey(name: 'original_filename') String? originalFilename,
    @JsonKey(name: 'size_bytes') int? sizeBytes,
    @JsonKey(name: 'width_px') int? widthPx,
    @JsonKey(name: 'height_px') int? heightPx,

    /// **Built per request and never stored.** The designs disk is private, so on production
    /// this is a signed link that expires — caching it in this app would produce a thumbnail
    /// that works until it silently stops.
    @JsonKey(name: 'file_url') String? fileUrl,

    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _CustomerDesign;

  factory CustomerDesign.fromJson(Map<String, dynamic> json) =>
      _$CustomerDesignFromJson(json);
}

extension CustomerDesignX on CustomerDesign {
  /// هل في اسمه ما كُتب في البحث — جزءاً منه، بعد طيّ الحروف في الطرفين.
  ///
  /// **يُطوى ما يُكتب بأكثر من شكل**: الهمزة على الألف (أ إ آ ٱ ← ا)، والتاء المربوطة والهاء،
  /// والألف المقصورة والياء، ويسقط التشكيل والتطويل، وتصغر اللاتينية. فمن كتب «اعلان» وجد
  /// «إعلان»، ومن كتب «logo» وجد «Logo». والبحث الفارغ يطابق كل تصميم.
  bool matches(String query) {
    final needle = _foldedForSearch(query);

    return needle.isEmpty || _foldedForSearch(label).contains(needle);
  }

  /// «PNG · 1.2 م.ب» — the line the design draws under a design's name.
  ///
  /// **Built from the two facts the server already sent**, so the grid costs no extra request.
  /// The extension comes off [originalFilename] rather than [mimeType]: «PNG» is what somebody
  /// recognises from their own file manager, «image/png» is not. Falls back to [kindLabel] — the
  /// server's own word — when the filename carries no extension.
  String? get metaLine {
    final parts = [?_extension, ?_size];

    return parts.isEmpty ? null : parts.join(' · ');
  }

  String? get _extension {
    final name = originalFilename;

    if (name == null || !name.contains('.')) return kindLabel;

    final extension = name.split('.').last;

    // A «.» with twelve characters after it is not an extension, it is a filename with a full
    // stop in it — and «CATALOGUE FINAL» in the corner of a thumbnail helps nobody.
    return extension.length > 5 ? kindLabel : extension.toUpperCase();
  }

  /// **Rounded the way a file manager rounds**, not the way the uploader validated. `DesignRules`
  /// counts in kibibytes because that is what the server compares against; this is a label, and
  /// «1.2 م.ب» is what somebody is looking for.
  String? get _size {
    final bytes = sizeBytes;

    if (bytes == null || bytes <= 0) return null;

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).round()} ك.ب';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} م.ب';
  }
}

/// النصّ كما يُقارَن في البحث — انظر [CustomerDesignX.matches].
String _foldedForSearch(String text) => text
    .trim()
    .toLowerCase()
    // التشكيل (ً إلى ْ، والألف الخنجرية) والتطويل: زينةٌ على الحرف لا حرف.
    .replaceAll(RegExp('[\u064B-\u0652\u0670\u0640]'), '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي');
