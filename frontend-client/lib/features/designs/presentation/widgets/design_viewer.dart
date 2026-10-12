import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/files/device_saver.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/usecases/save_design_to_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

// ما يُفعل بملف التصميم نفسه: أن يُرى، وأن يُحمَّل. منقولٌ عن `design_viewer.dart` في تطبيق
// الموظفين، والفرق أن ملف PDF يُفتح داخل التطبيق على آيفون — انظر [openDesign].

/// يفتح التصميم: الصورة ملءَ الشاشة وتُقرَّب، وما سواها لعارض الهاتف.
///
/// **هذا ما يفعله الضغط على البطاقة.** كان الضغط يسمّي التصميم، ورفضه صاحب العمل
/// (٢٠٢٦-٠٩-٢٥): من يضغط صورةً يريد أن يراها.
Future<void> showDesign(BuildContext context, CustomerDesign design) async {
  if (design.kind.isImage && design.fileUrl != null) {
    await showDialog<void>(
      context: context,
      builder: (context) => DesignViewer(design: design),
    );

    return;
  }

  await openDesign(context, design);
}

/// يسلّم الملف لما يفتح به الهاتف ملفات PDF.
///
/// **بالوضع الافتراضي لا `externalApplication` كما في تطبيق الموظفين.** على آيفون يعني ذلك
/// عارض Safari داخل التطبيق: يعرض الملف، وفيه زرّ المشاركة للحفظ في «الملفات» أو الطباعة،
/// و«تم» يعيد إلى المكتبة — بدل القفز إلى Safari وترك التطبيق خلفه. وعلى أندرويد لا فرق: المتصفح
/// أو تطبيق PDF.
///
/// **بلا `try`/`catch` وبلا عارض PDF.** كل عارضٍ على pub.dev يحمل محرّكاً أصلياً لمشكلةٍ حلّها
/// النظام، وكل خطوةٍ هنا تجيب ولا ترمي: رابطٌ لا يُقرأ `null`، ورابطٌ لا يفتحه شيء `false`.
Future<void> openDesign(BuildContext context, CustomerDesign design) async {
  final url = design.fileUrl;
  final uri = url == null ? null : Uri.tryParse(url);

  if (uri == null) {
    context.showError('لا يوجد رابط لهذا الملف');

    return;
  }

  final opened = await launchUrl(uri);
  if (opened || !context.mounted) return;

  context.showError('لا يوجد تطبيق على هذا الجهاز يفتح هذا الملف');
}

/// «تحميل»: يحفظ الملف على الهاتف ويقول أين — **بلا ورقة مشاركة**.
///
/// كان يسلّم الملف لورقة المشاركة، ورُفض ذلك (٢٠٢٦-١٠-١٢): من يضغط «تحميل» يريد الملف على
/// هاتفه، لا أن يختار تطبيقاً. أين يذهب: [SaveDesignToDevice].
///
/// والرابط الموقَّع تنتهي صلاحيته، فيُجلب بما تحمله الشاشة **الآن** — ولذلك يُمرَّر التصميم لا
/// عنوانٌ محفوظ.
Future<void> saveDesign(BuildContext context, CustomerDesign design) async {
  final result = await sl<SaveDesignToDevice>()(design);

  if (!context.mounted) return;

  result.fold(context.showFailure, (place) {
    // `null`: أغلق نافذة «حفظ باسم» — لم يُحفظ شيء، ولا شيء يُقال.
    if (place == null) return;

    context.showSuccess(switch (place) {
      SavePlace.photos => 'حُفظ التصميم في الصور',
      SavePlace.downloads => 'حُفظ التصميم في التنزيلات',
      SavePlace.files => 'حُفظ التصميم في «الملفات»',
      SavePlace.chosen => 'حُفظ التصميم',
    });
  });
}

/// صورةٌ واحدة بأكبر ما تتّسع له الشاشة، تُقرَّب.
class DesignViewer extends StatelessWidget {
  const DesignViewer({required this.design, super.key});

  final CustomerDesign design;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 8.h;

    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              // التصميم يُقرأ عن قرب — تباعد حروف شعار، لونٌ على خلفية — فيُقرَّب أبعد مما
              // يُقرِّب ألبوم صور.
              maxScale: 6,
              child: CachedNetworkImage(
                // الرابط نفسه الذي رسمت به البطاقة مصغّرتها، فالصورة من الذاكرة لا من الشبكة.
                imageUrl: design.fileUrl!,
                fit: BoxFit.contain,
                placeholder: (context, _) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, _, _) => Center(
                  child: Icon(AppIcons.offline, size: 40.sp, color: Colors.white70),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: top,
            start: 8.w,
            child: IconButton(
              tooltip: 'إغلاق',
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(AppIcons.close, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.black45),
            ),
          ),
          PositionedDirectional(
            top: top,
            end: 8.w,
            child: IconButton(
              tooltip: 'تحميل',
              onPressed: () => unawaited(saveDesign(context, design)),
              icon: Icon(AppIcons.download, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.black45),
            ),
          ),
          // ما هو، في الأسفل حيث لا يقع على التصميم.
          PositionedDirectional(
            bottom: MediaQuery.paddingOf(context).bottom + 16.h,
            start: 16.w,
            end: 16.w,
            child: Text(
              [design.label, ?design.metaLine].join('  ·  '),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
