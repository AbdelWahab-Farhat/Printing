part of 'customer_designs_cubit.dart';

/// Everything the designs screen can be.
///
/// **[loaded] is never left once it is reached.** Uploading, renaming and deleting all keep the
/// library on screen and mark the one thing that is moving — a grid that blanks to a spinner
/// because one file is being renamed has thrown away the page the user was working in.
/// [failure] is only for the first read, when there is nothing to keep.
@freezed
sealed class CustomerDesignsState with _$CustomerDesignsState {
  const factory CustomerDesignsState.loading() = CustomerDesignsLoading;

  const factory CustomerDesignsState.loaded({
    required List<CustomerDesign> designs,

    /// Files on their way up, in the order they were chosen. Shown at the top of the grid, so
    /// the thing that just happened is where the eye already is.
    @Default(<DesignUpload>[]) List<DesignUpload> uploads,

    /// Ids of designs being renamed or removed right now. A set rather than a single id
    /// because two rows can be worked on at once and each has to show its own state.
    @Default(<int>{}) Set<int> busy,
  }) = CustomerDesignsLoaded;

  const factory CustomerDesignsState.failure(Failure failure) = CustomerDesignsFailure;
}

/// One file on its way to the server.
///
/// Kept in state rather than awaited quietly, because an upload over a Libyan mobile
/// connection is long enough that a screen with no sign of it looks broken — and long enough
/// that the user will leave and come back.
@freezed
abstract class DesignUpload with _$DesignUpload {
  const factory DesignUpload({
    required PickedFile file,

    /// Bytes acknowledged as sent.
    @Default(0) int sent,

    /// True for the one upload currently in flight. They go up one at a time: three at once
    /// over a slow connection means three bars that all crawl and none that finishes.
    @Default(false) bool isUploading,

    /// Why it stopped, if it did. The row then offers «إعادة المحاولة» — free to take, because
    /// the endpoint is idempotent on the file's checksum.
    Failure? failure,
  }) = _DesignUpload;

  const DesignUpload._();

  /// The path, which is unique per pick and is what identifies this row.
  String get id => file.path;

  /// 0…1. Zero rather than a division by zero for a file the picker reported as empty.
  double get progress => file.sizeBytes <= 0 ? 0 : (sent / file.sizeBytes).clamp(0.0, 1.0);

  bool get hasFailed => failure != null;

  /// Chosen, not yet started, and not stopped by anything.
  bool get isWaiting => !isUploading && !hasFailed;
}

extension CustomerDesignsStateX on CustomerDesignsState {
  /// The library, whenever there is one — including while something is being uploaded.
  List<CustomerDesign>? get designs => switch (this) {
    CustomerDesignsLoaded(:final designs) => designs,
    _ => null,
  };

  /// True while anything at all is in flight, which is what stops the screen being popped out
  /// from under an upload without a word.
  bool get isWorking => switch (this) {
    CustomerDesignsLoaded(:final uploads, :final busy) =>
      busy.isNotEmpty || uploads.any((upload) => !upload.hasFailed),
    _ => false,
  };
}
