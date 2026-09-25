import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// عرضُ الصورة في المحادثة، وارتفاعها بنسبتها بين حدّين.
double get _imageWidth => 236.w;

double _imageHeightFor(double? aspectRatio) {
  final ratio = (aspectRatio ?? 4 / 3).clamp(0.62, 1.9);

  return (_imageWidth / ratio).clamp(132.h, 320.h);
}

/// مفتاحُ الصورة في الذاكرة المؤقتة: **رقم الرسالة لا الرابط.** الرابط موقَّعٌ يتغيّر مع كل قراءة،
/// والملف خلفه لا يتغيّر أبداً — مفتاحٌ من الرابط كان سيحمّل الصورة نفسها في كل مرة.
String chatImageCacheKey(int messageId) => 'support-attachment-$messageId';

/// صورةٌ وصلت من الخادم: مكانها محجوزٌ بنسبتها قبل أن تصل، فلا تقفز المحادثة، وتقدّمُ تحميلها
/// ظاهرٌ فوقها.
class ChatRemoteImage extends StatelessWidget {
  const ChatRemoteImage({
    required this.messageId,
    required this.url,
    this.aspectRatio,
    this.onTap,
    super.key,
  });

  final int messageId;
  final String? url;
  final double? aspectRatio;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final height = _imageHeightFor(aspectRatio);
    final link = url;

    return Semantics(
      image: true,
      button: onTap != null,
      label: 'صورة',
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13.r),
          child: SizedBox(
            width: _imageWidth,
            height: height,
            child: link == null
                ? const _ImagePlaceholder(failed: true)
                : CachedNetworkImage(
                    imageUrl: link,
                    cacheKey: chatImageCacheKey(messageId),
                    width: _imageWidth,
                    height: height,
                    fit: BoxFit.cover,
                    fadeInDuration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    progressIndicatorBuilder: (context, _, progress) =>
                        _ImagePlaceholder(progress: progress.progress),
                    errorWidget: (context, _, _) => const _ImagePlaceholder(failed: true),
                  ),
          ),
        ),
      ),
    );
  }
}

/// صورةٌ على هذا الهاتف تُرفع الآن: تُرسم من الملف نفسه، وحلقةُ الرفع فوقها وفي وسطها ✕ للإلغاء.
class ChatLocalImage extends StatefulWidget {
  const ChatLocalImage({
    required this.path,
    required this.progress,
    this.failed = false,
    this.onCancel,
    super.key,
  });

  final String path;

  /// من ٠ إلى ١.
  final double progress;
  final bool failed;
  final VoidCallback? onCancel;

  @override
  State<ChatLocalImage> createState() => _ChatLocalImageState();
}

class _ChatLocalImageState extends State<ChatLocalImage> {
  /// نسبةُ الصورة تُقرأ من الملف نفسه قبل الرسم — حالةٌ بصريةٌ بحتة، لا شيء للـViewModel فيها.
  double? _aspectRatio;
  ImageStream? _stream;
  late final ImageStreamListener _listener = ImageStreamListener((info, _) {
    if (!mounted) return;

    setState(() => _aspectRatio = info.image.width / info.image.height);
  });

  @override
  void initState() {
    super.initState();

    _stream = FileImage(File(widget.path)).resolve(ImageConfiguration.empty)
      ..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = _imageHeightFor(_aspectRatio);

    return ClipRRect(
      borderRadius: BorderRadius.circular(13.r),
      child: SizedBox(
        width: _imageWidth,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(widget.path), fit: BoxFit.cover),
            const ColoredBox(color: Colors.black26),
            Center(
              child: _RoundProgress(
                progress: widget.failed ? null : widget.progress,
                icon: widget.failed ? AppIcons.error : AppIcons.close,
                tooltip: widget.failed ? 'لم تُرفع' : 'إلغاء الرفع',
                onTap: widget.failed ? null : widget.onCancel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.progress, this.failed = false});

  final double? progress;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colorScheme.surfaceContainerHigh,
      child: Center(
        child: failed
            ? Icon(AppIcons.offline, size: 30.sp, color: context.colorScheme.onSurfaceVariant)
            : _RoundProgress(progress: progress, icon: AppIcons.photos),
      ),
    );
  }
}

/// زرُّ الملف في فقاعته: ما يفعله اللمس الآن.
enum ChatFileAction {
  /// لم يصل الهاتف بعد — سهمٌ إلى أسفل.
  fetch,

  /// ينتقل الآن، رفعاً أو تنزيلاً — حلقةُ تقدّمٍ و✕ للإلغاء.
  transferring,

  /// على الهاتف — المسُه يفتحه.
  open,

  /// فشل — المسُه يعيد المحاولة.
  retry,
}

/// ملفٌّ في المحادثة — PDF أو ما لا يُرسم صورة: زرٌّ مستدير يقول حاله، واسمُ الملف، وسطرُه.
///
/// **آليةُ التحميل كما في تيليغرام:** سهمٌ إلى أسفل لملفٍّ لم يصل الهاتف، فحلقةٌ تمتلئ مع
/// التنزيل وفي وسطها ✕ للإلغاء، ثم أيقونةُ الملف: لمسةٌ تفتحه بعارض الهاتف نفسه. والرفعُ الحلقةُ
/// نفسها.
class ChatFileRow extends StatelessWidget {
  const ChatFileRow({
    required this.name,
    required this.caption,
    required this.action,
    required this.isMine,
    this.progress = 0,
    this.isPdf = true,
    this.onTap,
    super.key,
  });

  final String name;

  /// «PDF · 1.2 م.ب»، أو أثناء النقل «0.4 من 1.2 م.ب».
  final String caption;
  final ChatFileAction action;
  final bool isMine;
  final double progress;
  final bool isPdf;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final ink = isMine ? scheme.onOutgoingBubble : scheme.onIncomingBubble;
    final metaInk = isMine ? scheme.outgoingMeta : scheme.incomingMeta;

    final (icon, tooltip) = switch (action) {
      ChatFileAction.fetch => (AppIcons.expand, 'تنزيل'),
      ChatFileAction.transferring => (AppIcons.close, 'إلغاء'),
      ChatFileAction.open => (isPdf ? AppIcons.pdf : AppIcons.document, 'فتح'),
      ChatFileAction.retry => (AppIcons.refresh, 'أعد المحاولة'),
    };

    return Semantics(
      button: onTap != null,
      label: '$tooltip: $name',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: SizedBox(
          width: 232.w,
          child: Row(
            children: [
              _RoundProgress(
                progress: action == ChatFileAction.transferring ? progress : null,
                showsRing: action == ChatFileAction.transferring,
                icon: icon,
                isMine: isMine,
                size: 46.w,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      // اسمُ الملف لاتينيٌّ غالباً — يُرسم من اليسار كما كُتب.
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.start,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      caption,
                      style: context.textTheme.bodySmall?.copyWith(color: metaInk),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// دائرةٌ ملوّنة فيها أيقونة، وحولها حلقةُ تقدّمٍ حين يكون هناك ما يُقاس.
class _RoundProgress extends StatelessWidget {
  const _RoundProgress({
    required this.icon,
    this.progress,
    this.showsRing = true,
    this.isMine = false,
    this.tooltip,
    this.onTap,
    double? size,
  }) : _size = size;

  final IconData icon;

  /// `null` حلقةٌ دائرةٌ بلا مقدار — حين لا يُعرف الحجم بعد.
  final double? progress;
  final bool showsRing;
  final bool isMine;
  final String? tooltip;
  final VoidCallback? onTap;
  final double? _size;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final size = _size ?? 52.w;

    // على فقاعتي ليلاً: البرتقالي على البرتقالي المحروق لا يُرى، فيُقلب الزرّ أبيض.
    final nightMine = isMine && scheme.brightness == Brightness.dark;
    final fill = _size == null ? Colors.black45 : (nightMine ? scheme.onOutgoingBubble : scheme.primary);
    final ink = _size == null ? Colors.white : (nightMine ? scheme.outgoingBubble : scheme.onPrimary);

    final circle = SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
            child: const SizedBox.expand(),
          ),
          if (showsRing && (progress == null || progress! < 1))
            Padding(
              padding: EdgeInsets.all(3.w),
              child: CircularProgressIndicator(
                value: progress == null || progress! <= 0 ? null : progress,
                strokeWidth: 2.4.w,
                color: ink,
                backgroundColor: ink.withValues(alpha: 0.25),
              ),
            ),
          Icon(icon, size: size * 0.44, color: ink),
        ],
      ),
    );

    if (onTap == null) return circle;

    return Tooltip(
      message: tooltip ?? '',
      child: InkResponse(onTap: onTap, radius: size / 2, child: circle),
    );
  }
}
