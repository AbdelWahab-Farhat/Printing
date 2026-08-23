import 'dart:async';

import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/appear.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Renders a [PagedState] — every one of its cases — for any `T`.
///
/// The counterpart to `PagedCubit`: that one owns the five behaviours a paged list needs, this
/// one owns the five things it looks like. A screen supplies its state, how to draw one row, and
/// what to call when the bottom is near; it does not re-decide what an empty search looks like,
/// where the "loading more" spinner goes, or whether a failed page wipes the list.
///
/// **What it settles, once:**
///   * a skeleton on first load, so the layout does not jump when rows arrive,
///   * infinite scroll that asks *early* — 400 logical pixels from the end, so the list rarely
///     stops at the bottom to wait, **and asks at all** when a page came back too short to fill
///     the screen, which leaves nothing to scroll and used to end the list there,
///   * pull to refresh on every state that has content,
///   * an empty message that names the search term, because "nothing found" and "nothing found
///     **for this**" tell the user different things,
///   * the server's own Arabic on failure, with a retry — never a generic apology.
class PagedListView<T> extends StatefulWidget {
  const PagedListView({
    required this.state,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.onRefresh,
    this.emptyMessage = 'لا توجد نتائج',
    this.skeletonHeight,
    this.padding,
    super.key,
  });

  final PagedState<T> state;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRefresh;

  /// Shown when the list is empty *and* nothing was searched for.
  final String emptyMessage;

  /// The height of one placeholder row. Defaults to a card-sized block.
  final double? skeletonHeight;

  final EdgeInsetsGeometry? padding;

  @override
  State<PagedListView<T>> createState() => _PagedListViewState<T>();
}

/// Stateful for its [ScrollController] alone — a widget-lifecycle resource that has to be
/// disposed, which is not something a Cubit can do for it.
class _PagedListViewState<T> extends State<PagedListView<T>> {
  final _controller = ScrollController();

  /// How close to the end is close enough to ask for the next page.
  static const double _loadMoreThreshold = 400;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;

    final remaining = _controller.position.maxScrollExtent - _controller.position.pixels;
    // `onLoadMore` is expected to be idempotent — `PagedCubit` ignores the call while a page is
    // already in flight, which is what makes it safe to fire this on every scroll frame.
    if (remaining < _loadMoreThreshold) unawaited(widget.onLoadMore());
  }

  /// A page that does not fill the screen leaves nothing to scroll — and scrolling is the only
  /// thing that asks for the next page, so the list stops there with more waiting behind it.
  ///
  /// Unreachable while every row was one API row and fifteen of them were taller than a phone.
  /// A screen that *groups* its rows reaches it easily: fifteen shelves of one bag are two
  /// cards. Asked once per frame that ends unscrollable, and it stops when the last page lands.
  void _fillViewport() {
    if (!mounted || !_controller.hasClients) return;
    if (_controller.position.maxScrollExtent > 0) return;

    unawaited(widget.onLoadMore());
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.padding ?? EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h);

    // After the frame, because whether the rows overflow the viewport is not known until they
    // have been laid out.
    if (widget.state case PagedLoaded<T>(:final page, isLoadingMore: false) when page.hasMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fillViewport());
    }

    return switch (widget.state) {
      PagedInitial<T>() ||
      PagedLoading<T>() => _Skeleton(padding: padding, rowHeight: widget.skeletonHeight ?? 106.h),
      PagedFailure<T>(:final failure) => _FailureView(
        message: failure.message,
        onRetry: widget.onRefresh,
      ),
      PagedLoaded<T>(:final page, :final isLoadingMore, :final search) =>
        page.isEmpty
            ? _EmptyView(search: search, message: widget.emptyMessage, onRefresh: widget.onRefresh)
            : RefreshIndicator(
                onRefresh: widget.onRefresh,
                child: ListView.separated(
                  controller: _controller,
                  padding: padding,
                  // One extra row while a page is on its way: the footer is part of the list, so
                  // it scrolls with it instead of floating over the last card.
                  itemCount: page.items.length + (isLoadingMore ? 1 : 0),
                  separatorBuilder: (context, index) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    if (index >= page.items.length) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }

                    return Appear(
                      index: index,
                      child: widget.itemBuilder(context, page.items[index], index),
                    );
                  },
                ),
              ),
    };
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.padding, required this.rowHeight});

  final EdgeInsetsGeometry padding;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: 6,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) => Container(
        height: rowHeight,
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.search, required this.message, required this.onRefresh});

  final String? search;
  final String message;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final hasSearch = search != null && search!.isNotEmpty;

    // Scrollable despite having nothing to scroll: without it, pull-to-refresh is unavailable
    // on exactly the screen where the user most wants to try again.
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 120.h),
          Icon(AppIcons.empty, size: 52.sp, color: context.colorScheme.outline),
          SizedBox(height: 14.h),
          Text(
            hasSearch ? 'لا توجد نتائج لـ «$search»' : message,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: 48.sp, color: context.colorScheme.error),
            SizedBox(height: 16.h),
            Text(
              // The server's own Arabic: it usually says what to do about it.
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 20.h),
            FilledButton.icon(
              onPressed: () => unawaited(onRetry()),
              icon: Icon(AppIcons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
