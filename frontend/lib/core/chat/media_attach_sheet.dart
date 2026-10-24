import 'dart:async';

import 'package:dayaa/core/chat/chat_message.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/local_files.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_snackbar.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

/// يسلّم الصورَ المختارة وتعليقَها لمن فتح الورقة.
typedef ChatImagesSendCallback = Future<void> Function(List<PickedFile> images, String caption);

/// ورقةُ إرفاق الصور — **منقولةٌ من بريمولا كما هي** (`media_attach_sheet.dart`): صورُ الهاتف
/// الأخيرة شبكةً تحت المحادثة، **مرقّمةً بترتيب اختيارها**، وحقلُ تعليقٍ وزرُّ إرسالٍ يحمل العدد
/// ما إن يُختار شيء. والضغطةُ المطوّلة على صورةٍ تكبّرها، وتُختار من هناك.
///
/// **الصورُ كلُّها رسالةٌ واحدة بتعليقها** — حتى [OutgoingChatMessage.maxImages]، حدِّ الخادم.
///
/// [galleryGrid] `false` لا يقرأ مكتبة الصور ويعرض منتقي النظام مكانها — **على الويب**، حيث لا
/// مكتبة. والكاميرا ومنتقي النظام من [AttachmentPicker] كبقية التطبيق.
Future<void> showMediaAttachSheet(
  BuildContext context, {
  required ChatImagesSendCallback onSend,
  bool galleryGrid = !kIsWeb,
  int maxItems = OutgoingChatMessage.maxImages,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (_) => MediaAttachSheet(onSend: onSend, galleryGrid: galleryGrid, maxItems: maxItems),
  );
}

class MediaAttachSheet extends StatefulWidget {
  const MediaAttachSheet({
    required this.onSend,
    this.galleryGrid = !kIsWeb,
    this.maxItems = OutgoingChatMessage.maxImages,
    this.picker,
    super.key,
  });

  final ChatImagesSendCallback onSend;
  final bool galleryGrid;
  final int maxItems;

  /// للاختبار؛ وإلا فمنتقي التطبيق.
  final AttachmentPicker? picker;

  @override
  State<MediaAttachSheet> createState() => _MediaAttachSheetState();
}

enum _Access { loading, granted, limited, denied, unavailable }

class _MediaAttachSheetState extends State<MediaAttachSheet> {
  static const int _pageSize = 80;

  late final AttachmentPicker _picker = widget.picker ?? sl<AttachmentPicker>();
  final TextEditingController _caption = TextEditingController();

  _Access _access = _Access.loading;
  List<AssetPathEntity> _albums = const [];
  AssetPathEntity? _album;
  final List<AssetEntity> _assets = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loadingPage = false;

  /// ما التُقط أو اختير من خارج الشبكة — يظهر أولاً، ومختاراً.
  final List<PickedFile> _picked = [];

  /// الاختيارُ بالترتيب الذي جرى به — وهو ترتيبُ الصور في الرسالة.
  final List<Object> _selection = [];

  bool _sending = false;

  @override
  void initState() {
    super.initState();

    if (widget.galleryGrid) {
      unawaited(_openLibrary());
    } else {
      _access = _Access.unavailable;
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  // ───────────────────────────── المكتبة ─────────────────────────────

  Future<void> _openLibrary() async {
    try {
      final state = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(type: RequestType.image, mediaLocation: false),
        ),
      );
      if (!mounted) return;

      if (!state.hasAccess) {
        setState(() => _access = _Access.denied);
        return;
      }

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(
          orders: [const OrderOption(type: OrderOptionType.createDate)],
        ),
      );
      if (!mounted) return;

      setState(() {
        _access = state == PermissionState.limited ? _Access.limited : _Access.granted;
        _albums = albums;
        _album = albums.isEmpty ? null : albums.first;
      });
      await _loadPage(reset: true);
    } on Object {
      // منصّةٌ بلا مكتبة، أو نسخةٌ بلا الإضافة — منتقي النظام يعمل.
      if (mounted) setState(() => _access = _Access.unavailable);
    }
  }

  Future<void> _loadPage({bool reset = false}) async {
    final album = _album;
    if (album == null || _loadingPage) return;
    if (!reset && !_hasMore) return;

    _loadingPage = true;
    try {
      final page = reset ? 0 : _page;
      final items = await album.getAssetListPaged(page: page, size: _pageSize);
      if (!mounted) return;

      setState(() {
        if (reset) _assets.clear();
        _assets.addAll(items);
        _page = page + 1;
        _hasMore = items.length == _pageSize;
      });
    } on Object {
      if (mounted) setState(() => _hasMore = false);
    } finally {
      _loadingPage = false;
    }
  }

  Future<void> _switchAlbum(AssetPathEntity album) async {
    if (album == _album) return;

    setState(() {
      _album = album;
      _hasMore = true;
    });
    await _loadPage(reset: true);
  }

  // ───────────────────────────── الاختيار ─────────────────────────────

  void _toggle(Object item) {
    if (_selection.contains(item)) {
      setState(() => _selection.remove(item));
      return;
    }
    if (_selection.length >= widget.maxItems) return _limitReached();

    unawaited(HapticFeedback.selectionClick());
    setState(() => _selection.add(item));
  }

  void _limitReached() => unawaitedSnack(
    context: context,
    title: 'يمكنك إرسال ${widget.maxItems} صور كحد أقصى',
    type: SnackType.warning,
  );

  /// نظرةُ تيليجرام: الصورةُ كبيرةً فوق ورقةٍ معتمة، تُختار أو تُترك من هناك.
  Future<void> _preview(Object item) async {
    unawaited(HapticFeedback.mediumImpact());

    final image = item is AssetEntity
        ? AssetEntityImage(
            item,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize(1080, 1080),
            fit: BoxFit.contain,
          )
        : Image(image: LocalFiles.image((item as PickedFile).path), fit: BoxFit.contain);
    final chosen = _selection.contains(item);
    final want = await Navigator.of(context).push<bool>(_PreviewRoute(image: image, chosen: chosen));

    if (want == null || want == chosen || !mounted) return;
    _toggle(item);
  }

  Future<void> _fromCamera() async {
    final shot = await _picker.pick(AttachmentSource.camera);
    if (shot.isEmpty || !mounted) return;

    _adopt(shot);
  }

  Future<void> _fromSystemPicker() async {
    final room = widget.maxItems - _selection.length;
    if (room <= 0) return _limitReached();

    final picked = await _picker.pick(AttachmentSource.photos);
    if (picked.isEmpty || !mounted) return;

    if (picked.length > room) _limitReached();
    _adopt(picked.take(room).toList());
  }

  void _adopt(List<PickedFile> files) {
    setState(() {
      _picked.insertAll(0, files);
      for (final file in files) {
        if (_selection.length < widget.maxItems) _selection.add(file);
      }
    });
  }

  Future<void> _send() async {
    if (_selection.isEmpty || _sending) return;

    setState(() => _sending = true);

    final files = <PickedFile>[];
    for (final item in _selection) {
      if (item is PickedFile) {
        files.add(item);
      } else if (item is AssetEntity) {
        // قد تُجلب من iCloud — والزرُّ يدور في أثنائها.
        final file = await _jpegOf(item);
        if (file != null) files.add(file);
      }
    }
    if (!mounted) return;

    if (files.isEmpty) {
      setState(() => _sending = false);
      unawaitedSnack(context: context, title: 'تعذّر قراءة الصور المختارة', type: SnackType.error);
      return;
    }

    final caption = _caption.text;

    // تُغلق أولاً: المحادثةُ تظهر، والرفعُ يجري خلفها وزرُّ الإرسال يدور.
    Navigator.of(context).pop();
    await widget.onSend(files, caption);
  }

  /// صورةُ المكتبة JPEG بمقاس قراءة الهاتف. الخادمُ يأخذ JPG وPNG وWEBP، وHEIC آيفون ليس منها —
  /// والأصلُ احتياطٌ إن لم تعد صورةٌ مصغّرة.
  Future<PickedFile?> _jpegOf(AssetEntity asset) async {
    try {
      final bytes = await asset.thumbnailDataWithSize(
        const ThumbnailSize(1600, 1600),
        format: ThumbnailFormat.jpeg,
        quality: 82,
      );

      if (bytes != null && bytes.isNotEmpty) {
        final name = 'photo_${asset.id.hashCode}_${DateTime.now().microsecondsSinceEpoch}.jpg';
        final path = await LocalFiles.writeTemporary(name, bytes, mimeType: 'image/jpeg');

        return PickedFile(path: path, name: name, sizeBytes: bytes.length);
      }
    } on Object {
      // إلى الأصل.
    }

    final original = await asset.originFile;
    if (original == null) return null;

    return PickedFile(
      path: original.path,
      name: original.uri.pathSegments.last,
      sizeBytes: await original.length(),
    );
  }

  // ───────────────────────────── الرسم ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final insets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .62,
        minChildSize: .32,
        maxChildSize: .94,
        snap: true,
        snapSizes: const [.62],
        builder: (context, scrollController) => Material(
          color: scheme.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              _Header(
                album: _album,
                albums: _albums,
                count: _selection.length,
                onAlbum: (album) => unawaited(_switchAlbum(album)),
              ),
              if (_access == _Access.limited)
                _LimitedStrip(
                  onManage: () async {
                    await PhotoManager.presentLimited(type: RequestType.image);
                    await _loadPage(reset: true);
                  },
                ),
              Expanded(child: _body(scrollController)),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                alignment: Alignment.bottomCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _selection.isEmpty
                      ? _SourceBar(
                          key: const ValueKey('sources'),
                          onCamera: () => unawaited(_fromCamera()),
                          onPicker: () => unawaited(_fromSystemPicker()),
                        )
                      : _CaptionBar(
                          key: const ValueKey('caption'),
                          controller: _caption,
                          count: _selection.length,
                          sending: _sending,
                          onSend: () => unawaited(_send()),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(ScrollController scrollController) {
    if (_access == _Access.denied) {
      return _NoAccess(
        scrollController: scrollController,
        onSettings: () => unawaited(PhotoManager.openSetting()),
        onPicker: () => unawaited(_fromSystemPicker()),
      );
    }

    final library = _access == _Access.granted || _access == _Access.limited;
    // الكاميرا أولاً، ثم منتقي النظام حين لا مكتبة، ثم ما التُقط أو اختير، ثم المكتبة نفسها.
    final leading = library ? 1 : 2;
    final count = leading + _picked.length + (library ? _assets.length : 0);

    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: _access == _Access.loading ? leading + 12 : count,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _ActionTile(
            icon: AppIcons.camera,
            label: 'الكاميرا',
            onTap: () => unawaited(_fromCamera()),
          );
        }
        if (!library && index == 1) {
          return _ActionTile(
            icon: AppIcons.photos,
            label: 'المعرض',
            onTap: () => unawaited(_fromSystemPicker()),
          );
        }
        if (_access == _Access.loading) return const _LoadingTile();

        final i = index - leading;
        if (i < _picked.length) {
          final file = _picked[i];

          return _MediaTile(
            image: Image(
              image: ResizeImage(LocalFiles.image(file.path), width: 300),
              fit: BoxFit.cover,
              errorBuilder: (context, _, _) => Icon(
                AppIcons.photos,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            order: _orderOf(file),
            onTap: () => _toggle(file),
            onLongPress: () => unawaited(_preview(file)),
          );
        }

        final assetIndex = i - _picked.length;
        if (assetIndex >= _assets.length - 20 && _hasMore) {
          // قبل أن يبلغ الإصبعُ آخرها، لا عند آخرها.
          WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_loadPage()));
        }
        final asset = _assets[assetIndex];

        return _MediaTile(
          image: AssetEntityImage(
            asset,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize.square(240),
            fit: BoxFit.cover,
          ),
          order: _orderOf(asset),
          onTap: () => _toggle(asset),
          onLongPress: () => unawaited(_preview(asset)),
        );
      },
    );
  }

  /// موضعُها في الاختيار من ١، أو ٠ إن لم تُختر.
  int _orderOf(Object item) => _selection.indexOf(item) + 1;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.album,
    required this.albums,
    required this.count,
    required this.onAlbum,
  });

  final AssetPathEntity? album;
  final List<AssetPathEntity> albums;
  final int count;
  final ValueChanged<AssetPathEntity> onAlbum;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final current = album;
    final title = count > 0
        ? 'تم اختيار $count'
        : current == null
        ? 'إرسال صور'
        : _albumName(current);
    final style = context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);

    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 6.h, 4.w, 4.h),
      child: Column(
        children: [
          Container(
            width: 38.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'إغلاق',
                onPressed: () => unawaited(Navigator.of(context).maybePop()),
                icon: Icon(AppIcons.close),
              ),
              Expanded(
                child: Center(
                  child: albums.length > 1 && count == 0
                      ? PopupMenuButton<AssetPathEntity>(
                          tooltip: 'الألبومات',
                          onSelected: onAlbum,
                          itemBuilder: (_) => [
                            for (final each in albums)
                              PopupMenuItem(value: each, child: Text(_albumName(each))),
                          ],
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(title, style: style),
                              Icon(AppIcons.expand),
                            ],
                          ),
                        )
                      : Text(title, style: style),
                ),
              ),
              SizedBox(width: 48.w),
            ],
          ),
        ],
      ),
    );
  }

  static String _albumName(AssetPathEntity album) => album.isAll ? 'الأحدث' : album.name;
}

/// النظرةُ بالضغطة المطوّلة: تعتيمٌ بلا ضباب — الضبابُ فوق شبكة صورٍ أثقلُ إطارٍ يُطلب من هاتفٍ
/// ضعيف.
class _PreviewRoute extends PopupRoute<bool> {
  _PreviewRoute({required this.image, required this.chosen});

  final Widget image;
  final bool chosen;

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: .78);

  @override
  bool get barrierDismissible => true;

  @override
  String get barrierLabel => 'إغلاق';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);

    return SafeArea(
      child: FadeTransition(
        opacity: curve,
        child: ScaleTransition(
          scale: Tween<double>(begin: .92, end: 1).animate(curve),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: size.width * .92,
                    maxHeight: size.height * .68,
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(16.r), child: image),
                ),
                SizedBox(height: 16.h),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(!chosen),
                  icon: Icon(chosen ? AppIcons.close : AppIcons.sentMark),
                  label: Text(chosen ? 'إلغاء الاختيار' : 'اختيار'),
                  style: FilledButton.styleFrom(
                    // فوق التعتيم، لا فوق سطحٍ من الثيم.
                    backgroundColor: chosen ? scheme.surface : scheme.primary,
                    foregroundColor: chosen ? scheme.onSurface : scheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LimitedStrip extends StatelessWidget {
  const _LimitedStrip({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(16.w, 0, 8.w, 6.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'تظهر الصور التي سمحت بها فقط',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(onPressed: onManage, child: const Text('إدارة')),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30.sp, color: scheme.onSurfaceVariant),
            SizedBox(height: 6.h),
            Text(
              label,
              style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: context.colorScheme.surfaceContainerLow);
}

/// صورةٌ مصغّرة بدائرة تيليجرام المرقّمة؛ والمختارةُ تصغر قليلاً في خانتها فيُقرأ الاختيار بنظرة.
class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.image,
    required this.order,
    required this.onTap,
    this.onLongPress,
  });

  final Widget image;

  /// ٠ حين لم تُختر.
  final int order;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final chosen = order > 0;

    return Semantics(
      button: true,
      selected: chosen,
      excludeSemantics: true,
      label: chosen ? 'صورة مختارة $order' : 'صورة',
      onTap: onTap,
      onLongPress: onLongPress,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: ColoredBox(
          color: scheme.surfaceContainerLow,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedScale(
                scale: chosen ? .88 : 1,
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                child: image,
              ),
              PositionedDirectional(
                top: 6.h,
                end: 6.w,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 24.w,
                  height: 24.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // ألوانٌ ثابتة عمداً: الخلفيةُ صورة.
                    color: chosen ? scheme.primary : Colors.black26,
                    border: Border.all(color: Colors.white, width: 1.6),
                  ),
                  child: chosen
                      ? Text(
                          '$order',
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoAccess extends StatelessWidget {
  const _NoAccess({
    required this.scrollController,
    required this.onSettings,
    required this.onPicker,
  });

  final ScrollController scrollController;
  final VoidCallback onSettings;
  final VoidCallback onPicker;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(28.w),
      children: [
        Icon(AppIcons.photos, size: 44.sp, color: scheme.outline),
        SizedBox(height: 12.h),
        Text(
          'اسمح بالوصول إلى الصور لتظهر هنا',
          textAlign: TextAlign.center,
          style: context.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: 16.h),
        Center(
          child: FilledButton.tonal(onPressed: onSettings, child: const Text('فتح الإعدادات')),
        ),
        Center(
          child: TextButton(onPressed: onPicker, child: const Text('اختيار من المعرض')),
        ),
      ],
    );
  }
}

/// تيليجرام: شريطُ المصدرين العائم ما دام لم يُختر شيء.
class _SourceBar extends StatelessWidget {
  const _SourceBar({required this.onCamera, required this.onPicker, super.key});

  final VoidCallback onCamera;
  final VoidCallback onPicker;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 10.h),
        child: Container(
          // بالعرض لا بالارتفاع، كزرّ الإرسال: شاشةٌ قصيرة كانت ستعصر الأيقونةَ واسمها.
          height: 60.w,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              _SourceItem(icon: AppIcons.photos, label: 'المعرض', active: true, onTap: onPicker),
              _SourceItem(icon: AppIcons.camera, label: 'الكاميرا', onTap: onCamera),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceItem extends StatelessWidget {
  const _SourceItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final color = active ? scheme.primary : scheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(30.r),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(height: 2.h),
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// حقلُ التعليق وزرُّ الإرسال، والعددُ على الزرّ. **الزرُّ أوّلُ السطر** كصندوق المحادثة.
class _CaptionBar extends StatelessWidget {
  const _CaptionBar({
    required this.controller,
    required this.count,
    required this.sending,
    required this.onSend,
    super.key,
  });

  final TextEditingController controller;
  final int count;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Semantics(
              button: true,
              excludeSemantics: true,
              label: 'إرسال $count',
              onTap: sending ? null : onSend,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox.square(
                    dimension: 52.w,
                    child: Material(
                      color: scheme.primary,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: sending ? null : onSend,
                        child: Center(
                          child: sending
                              ? SizedBox.square(
                                  dimension: 22.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2.w,
                                    color: scheme.onPrimary,
                                  ),
                                )
                              : Icon(AppIcons.send, size: 22.sp, color: scheme.onPrimary),
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: -4.h,
                    end: -4.w,
                    child: Container(
                      constraints: BoxConstraints(minWidth: 20.w, minHeight: 20.w),
                      padding: EdgeInsets.symmetric(horizontal: 5.w),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: scheme.primary, width: 1.5),
                      ),
                      child: Text(
                        '$count',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: AppTextField(
                controller: controller,
                hint: 'أضف تعليقاً…',
                minLines: 1,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
