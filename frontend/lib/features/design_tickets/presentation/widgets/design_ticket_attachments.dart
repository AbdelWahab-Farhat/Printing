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
/// **بطاقتان في الصف، كـ«تصاميم العميل».** كانت شريطاً من صورٍ بعرض ٧٢ لا يفعل الضغط عليها
/// شيئاً، والحذف وحده خلف ضغطةٍ مطوّلة — فالمصمم الذي أُرسل له الشعار لم يستطع أن يكبّره ولا
/// أن يأخذه إلى هاتفه، وهما كل ما يريده منه.
///
/// الضغطة تفتح الملف، و«⋯» (أو الضغطة المطوّلة) فيها فتحٌ وتحميلٌ وحذف — القاعدة نفسها التي
/// في مكتبة العميل: ما على البطاقة يُرى، وما يغيّره في الخيارات.
class DesignTicketAttachments extends StatelessWidget {
  const DesignTicketAttachments({required this.files, this.onRemove, super.key});

  final List<DesignTicketFile> files;

  /// `null` حين لا يملك القارئ الحذف — فلا يُرسم «حذف» يرفضه الخادم.
  final void Function(DesignTicketFile file)? onRemove;

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
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 8.h),
        // صفوفٌ من اثنين لا `GridView`: الشبكة تُثبّت نسبة البطاقة، والاسم تحت الصورة يطول بخطّ
        // النظام المكبَّر فيفيض. هنا الصورة مربّعة والاسم يأخذ ما يحتاجه.
        for (var row = 0; row < files.length; row += 2) ...[
          if (row > 0) SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _tile(context, files[row])),
              SizedBox(width: 12.w),
              // نصفٌ فارغ لا بطاقةٌ ممدودة: المرفق الوحيد في آخر صفّ يبقى بعرض أخواته.
              Expanded(
                child: row + 1 < files.length
                    ? _tile(context, files[row + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }

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
          style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
