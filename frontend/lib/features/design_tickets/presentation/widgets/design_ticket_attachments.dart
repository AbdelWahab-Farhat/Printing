import 'dart:async';

import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/image_viewer.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/customers/presentation/widgets/design_viewer.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_file.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/design_version_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «المرفقات»: ما أرسله الموظف مع الطلب — الشعار، رمز QR، صورة كيسٍ مشابه — وهو ما يرسم منه
/// المصمم.
///
/// **One horizontal strip of 120-wide tiles** (design ب, 2026-11-15), each with its name under
/// it — the name is what tells two PDFs apart. The «add» tile closes the strip for whoever
/// manages the ticket. An older strip of 72-wide pictures did nothing when tapped, so the
/// designer sent the logo could neither enlarge it nor take it to the phone; these tiles open.
///
/// الضغطة تفتح الملف، و«⋯» (أو الضغطة المطوّلة) فيها فتحٌ وتحميلٌ وحذف — القاعدة نفسها التي
/// في مكتبة العميل: ما على البطاقة يُرى، وما يغيّره في الخيارات.
class DesignTicketAttachments extends StatelessWidget {
  const DesignTicketAttachments({required this.files, this.onRemove, this.onAdd, super.key});

  final List<DesignTicketFile> files;

  /// `null` حين لا يملك القارئ الحذف — فلا يُرسم «حذف» يرفضه الخادم.
  final void Function(DesignTicketFile file)? onRemove;

  /// Adds a file. Null draws no «add» tile, for a reader the server would refuse.
  final VoidCallback? onAdd;

  /// يفتح الملف: الصورة بملء الشاشة **بين أخواتها**، وما سواها لما يفتح به الهاتف ملفات PDF.
  ///
  /// تُسلَّم الصور كلها لا الصورة وحدها، فيسحب المصمم من الشعار إلى صورة الكيس دون أن يغلق
  /// ويفتح. والـPDF ليس بينها: العارض يرسم صوراً، وصفحةٌ سوداء في وسط السحب أسوأ من غيابه.
  Future<void> _open(BuildContext context, DesignTicketFile file) async {
    final pictures = [
      for (final candidate in files)
        if (candidate.fileKind == DesignKind.image && candidate.fileUrl != null) candidate,
    ];

    final index = pictures.indexWhere((picture) => picture.id == file.id);

    if (index == -1) {
      await openDesignExternally(context, file);

      return;
    }

    await openImageViewer(
      context,
      urls: [for (final picture in pictures) picture.fileUrl!],
      initialIndex: index,
      // مفتاح الصورة المصغّرة نفسه: الملف الذي جُلب للبطاقة لا يُجلب ثانيةً بملء الشاشة.
      cacheKeys: [for (final picture in pictures) 'design-ticket-file-${picture.id}'],
      onSave: (current) => unawaited(_save(context, pictures[current])),
    );
  }

  Future<void> _save(BuildContext context, DesignTicketFile file) =>
      saveDesign(context, file, what: 'المرفق');

  Future<void> _showOptions(BuildContext context, DesignTicketFile file) async {
    final choice = await showModalBottomSheet<_AttachmentAction>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        // يُمرَّر ولا يفيض: ورقةٌ سفلية لا تتجاوز نصف الشاشة، وعلى هاتفٍ قصير أو بخطٍّ مكبَّر
        // يقع «حذف» خارج ما يُرسم.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8.h),
              ListTile(
                title: Text(
                  file.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(file.fileKindLabel),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(AppIcons.openExternal),
                title: const Text('فتح الملف'),
                onTap: () => Navigator.of(sheetContext).pop(_AttachmentAction.open),
              ),
              ListTile(
                leading: Icon(AppIcons.download),
                title: const Text('تحميل'),
                onTap: () => Navigator.of(sheetContext).pop(_AttachmentAction.save),
              ),
              if (onRemove != null)
                ListTile(
                  leading: Icon(AppIcons.delete, color: context.colorScheme.error),
                  title: Text('حذف', style: TextStyle(color: context.colorScheme.error)),
                  onTap: () => Navigator.of(sheetContext).pop(_AttachmentAction.remove),
                ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );

    if (choice == null || !context.mounted) return;

    switch (choice) {
      case _AttachmentAction.open:
        await _open(context, file);
      case _AttachmentAction.save:
        await _save(context, file);
      case _AttachmentAction.remove:
        onRemove?.call(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المرفقات (${files.length})',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 10.h),
        // A scrolling row rather than a `ListView`: the strip takes the height of its tallest
        // tile, so a name drawn in an enlarged system font grows the strip instead of clipping.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < files.length; index++) ...[
                if (index > 0) SizedBox(width: 10.w),
                SizedBox(width: _tileSide.w, child: _tile(context, files[index])),
              ],
              if (onAdd case final add?) ...[
                if (files.isNotEmpty) SizedBox(width: 10.w),
                _AddTile(onTap: add),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// One side of a tile's square picture.
  static const double _tileSide = 120;

  Widget _tile(BuildContext context, DesignTicketFile file) => _AttachmentTile(
    file: file,
    onOpen: () => unawaited(_open(context, file)),
    onOptions: () => unawaited(_showOptions(context, file)),
  );
}

enum _AttachmentAction { open, save, remove }

/// مرفقٌ واحد: صورته مربّعةً، واسمه تحتها.
class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.file, required this.onOpen, required this.onOptions});

  final DesignTicketFile file;
  final VoidCallback onOpen;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final corner = BorderRadius.circular(14.r);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DesignTicketFileThumbnail(file: file, radius: 14.r),
              Material(
                color: Colors.transparent,
                child: InkWell(borderRadius: corner, onTap: onOpen, onLongPress: onOptions),
              ),
              // أسفل اليسار في القراءة العربية، بعيداً عن الصورة — كبطاقة «تصاميم العميل».
              PositionedDirectional(
                bottom: 6.h,
                end: 6.w,
                child: Tooltip(
                  message: 'خيارات المرفق',
                  child: Material(
                    color: scheme.surface.withValues(alpha: 0.85),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onOptions,
                      child: Padding(
                        padding: EdgeInsets.all(6.w),
                        child: Icon(AppIcons.more, size: 18.sp, color: scheme.onSurface),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          file.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// The last tile of the strip: adds a file to the brief.
class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final corner = BorderRadius.circular(16.r);
    final side = DesignTicketAttachments._tileSide.w;

    return SizedBox(
      width: side,
      height: side,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: corner,
          side: BorderSide(color: scheme.outlineVariant, width: 1.5),
        ),
        child: InkWell(
          borderRadius: corner,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.add, size: 22.r, color: scheme.primary),
              SizedBox(height: 6.h),
              Text(
                'إضافة مرفق',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
