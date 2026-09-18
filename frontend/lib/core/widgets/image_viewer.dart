import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Opens one or more pictures full screen.
///
/// **A URL list, not a model**, which is the whole reason this is in `core/` rather than beside
/// the screen that needed it first. `DesignViewer` in the customers feature takes a
/// `CustomerDesign` and carries that feature's save-and-share, so a ticket's version, a
/// product's photo or a payment's receipt each needed their own copy of the same dialog. They
/// are all a list of URLs and an index.
///
/// **Several, with a swipe between them**, because a ticket's revision rounds and a product's
/// photos are read against each other — going back to the list to open the next one is how
/// somebody loses the comparison they opened the first for.
///
/// [cacheKeys] mirrors [urls] when given, so a picture already fetched for a thumbnail is not
/// downloaded a second time at full size. It is ignored when the two lengths disagree — a
/// mismatched key is worse than none, because it would serve the wrong image out of the cache.
Future<void> openImageViewer(
  BuildContext context, {
  required List<String> urls,
  int initialIndex = 0,
  List<String>? cacheKeys,
}) {
  if (urls.isEmpty) return Future<void>.value();

  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => ImageViewerPage(
        urls: urls,
        initialIndex: initialIndex.clamp(0, urls.length - 1),
        cacheKeys: cacheKeys?.length == urls.length ? cacheKeys : null,
      ),
    ),
  );
}

/// The page [openImageViewer] pushes. Public so a test can pump it without a navigator.
class ImageViewerPage extends StatefulWidget {
  const ImageViewerPage({
    required this.urls,
    this.initialIndex = 0,
    this.cacheKeys,
    super.key,
  });

  final List<String> urls;
  final int initialIndex;
  final List<String>? cacheKeys;

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  late final PageController _pages = PageController(initialPage: widget.initialIndex);
  late int _current = widget.initialIndex;

  /// Watched so the drag-to-close knows when to keep out of the way.
  final TransformationController _zoom = TransformationController();

  /// **Whether the picture is zoomed in, which decides who owns a vertical drag.**
  ///
  /// Zoomed, the drag is how somebody moves around the picture and closing on it would be
  /// maddening. At rest there is nowhere to pan to, so the same drag closes the viewer.
  bool _isZoomed = false;

  /// How far the picture has been dragged down, in logical pixels. Zero at rest.
  double _drag = 0;

  @override
  void initState() {
    super.initState();
    _zoom.addListener(_onZoomChanged);
  }

  void _onZoomChanged() {
    // A hair above 1: the matrix does not land exactly on it after a pinch that ends where it
    // started, and a viewer that thinks it is zoomed refuses to close for no visible reason.
    final zoomed = _zoom.value.getMaxScaleOnAxis() > 1.01;

    if (zoomed != _isZoomed) setState(() => _isZoomed = zoomed);
  }

  @override
  void dispose() {
    _pages.dispose();
    _zoom
      ..removeListener(_onZoomChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Black rather than the theme's surface: a picture is judged against nothing, and a dark
      // grey behind a dark design flatters it into looking better than it is.
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // **Drag it down to close**, the gesture every photo viewer on the phone has.
          //
          // Hand-rolled rather than a `Dismissible`: that widget asserts when the thing it
          // dismissed is still in the tree, which is exactly this case — closing here pops a
          // route rather than removing a row from a list.
          //
          // Off while zoomed, and `panEnabled` on the viewer below is tied to the same flag:
          // `InteractiveViewer` claims a drag whether or not the picture can move, and being
          // deeper in the tree it wins, so leaving it on made the drag do nothing at all.
          GestureDetector(
            onVerticalDragUpdate: _isZoomed
                ? null
                : (details) => setState(() => _drag = math.max(0, _drag + details.delta.dy)),
            onVerticalDragEnd: _isZoomed
                ? null
                : (details) {
                    // A long pull or a quick flick — either is somebody saying «أغلقها». The
                    // rest springs back.
                    if (_drag > 120 || details.velocity.pixelsPerSecond.dy > 700) {
                      Navigator.of(context).pop();

                      return;
                    }

                    setState(() => _drag = 0);
                  },
            child: Transform.translate(
              offset: Offset(0, _drag),
              // The picture fades as it goes, so the drag reads as «this is closing» before it
              // has closed.
              child: Opacity(
                opacity: (1 - _drag / 400).clamp(0.3, 1.0),
                child: PageView.builder(
                  controller: _pages,
                  itemCount: widget.urls.length,
                  onPageChanged: (index) {
                    // The next picture starts unzoomed, or it would open already panned to
                    // wherever the last one was left.
                    _zoom.value = Matrix4.identity();
                    setState(() => _current = index);
                  },
                  itemBuilder: (context, index) => InteractiveViewer(
                    transformationController: _zoom,
                    panEnabled: _isZoomed,
                    // Artwork is read close up — a logo's kerning, a colour against a
                    // background — so it zooms further than a photo viewer would.
                    maxScale: 6,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: widget.urls[index],
                        cacheKey: widget.cacheKeys?[index],
                        fit: BoxFit.contain,
                        placeholder: (context, _) =>
                            const Center(child: CircularProgressIndicator(color: Colors.white)),
                        errorWidget: (context, _, _) => Center(
                          child: Icon(AppIcons.offline, size: 40.sp, color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: MediaQuery.paddingOf(context).top + 8.h,
            start: 8.w,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(AppIcons.close, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.black45),
            ),
          ),
          // «٢ / ٥», and only where there is more than one — a counter over a single picture
          // says nothing and covers part of it.
          if (widget.urls.length > 1)
            PositionedDirectional(
              top: MediaQuery.paddingOf(context).top + 16.h,
              end: 16.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${_current + 1} / ${widget.urls.length}',
                  style: context.textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
