import 'package:flutter/foundation.dart' show listEquals;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'paginated.freezed.dart';
part 'paginated.g.dart';

/// The `meta` block the API puts beside a paginated `data` array.
@freezed
abstract class PageMeta with _$PageMeta {
  const factory PageMeta({
    @JsonKey(name: 'current_page') required int currentPage,
    @JsonKey(name: 'per_page') required int perPage,
    @JsonKey(name: 'last_page') required int lastPage,
    required int total,
  }) = _PageMeta;

  const PageMeta._();

  factory PageMeta.fromJson(Map<String, dynamic> json) => _$PageMetaFromJson(json);

  /// Whether asking for `currentPage + 1` would return anything — the only question an
  /// infinite list ever has about a page.
  bool get hasMore => currentPage < lastPage;
}

/// One page of anything.
///
/// Deliberately a plain class rather than a Freezed one: it is generic over `T`, and Freezed's
/// JSON generation for a generic type needs a converter threaded through every use site for no
/// gain — the page is assembled by hand in the data source, which already knows how to parse a
/// `T`. It is still immutable, which is the property that actually matters.
@immutable
class Paginated<T> {
  const Paginated({required this.items, required this.meta});

  final List<T> items;
  final PageMeta meta;

  bool get isEmpty => items.isEmpty;

  bool get hasMore => meta.hasMore;

  /// Appends the next page — what a "load more" handler does with the result.
  Paginated<T> merge(Paginated<T> next) =>
      Paginated<T>(items: [...items, ...next.items], meta: next.meta);

  /// Two pages holding equal items at the same position in the same list *are* the same page.
  ///
  /// Written by hand because this class is not Freezed. Without it, equality is identity: a
  /// state carrying a page would differ from an identical one, so Bloc could never drop a
  /// duplicate emission, and every list test would have to compare field by field instead of
  /// saying what it means. The items themselves are Freezed models, which is what makes the
  /// element comparison meaningful.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Paginated<T> && other.meta == meta && listEquals(other.items, items);
  }

  @override
  int get hashCode => Object.hash(meta, Object.hashAll(items));
}
