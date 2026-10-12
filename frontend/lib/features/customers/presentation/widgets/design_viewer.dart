import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/device_saver.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/customers/usecases/save_design_to_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

// ما يُفعل بملف التصميم نفسه: أن يُرى، وأن يُفتح خارج التطبيق، وأن يُحمَّل.
//
// هنا لا في شاشة المكتبة لأن التصميم يُلقى في موضعين — مكتبة العميل، والطلبية التي تُطبع منه —
// والثاني هو حيث يُسأل «هل أستطيع رؤية ما سنطبعه؟». ونسختان من عارضٍ بملء الشاشة تفترقان يوم
// تتعلّم إحداهما رسم PDF.

/// يعرضه: بملء الشاشة إن كان التطبيق يرسمه، وإلا سُلّم للهاتف.
Future<void> showDesign(BuildContext context, CustomerDesign design) async {
  if (design.isImage && design.fileUrl != null) {
    await showDialog<void>(
      context: context,
      builder: (context) => DesignViewer(design: design),
    );

    return;
  }

  await openDesignExternally(context, design);
}

/// يسلّم الملف لما يفتح به الهاتف ملفات PDF أصلاً.
///
/// **بلا `try`/`catch` وبلا عارض PDF.** كل عارضٍ على pub.dev يحمل محرّكاً أصلياً لمشكلةٍ حلّها
/// النظام، وكل خطوةٍ هنا تجيب ولا ترمي — رابطٌ لا يُقرأ `null`، ورابطٌ لا يفتحه شيء `false` —
/// فلا تُثنى قاعدة الحدّ الوحيدة في التطبيق من أجل راحة.
Future<void> openDesignExternally(BuildContext context, CustomerDesign design) async {
  final url = design.fileUrl;
  final uri = url == null ? null : Uri.tryParse(url);

  if (uri == null) {
    context.showError('لا يوجد رابط لهذا الملف');

    return;
  }

  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                imageUrl: design.fileUrl!,
                cacheKey: 'customer-design-${design.id}',
                fit: BoxFit.contain,
                placeholder: (context, _) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, _, _) => Center(
                  child: Icon(AppIcons.offline, size: 40.sp, color: Colors.white70),
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
          PositionedDirectional(
            top: MediaQuery.paddingOf(context).top + 8.h,
            end: 8.w,
            child: Row(
              children: [
                // التحميل أولاً، في الجهة التي يبلغها الإبهام: هو أكثر ما يريده من فتح التصميم
                // بملء الشاشة بعدها.
                IconButton(
                  tooltip: 'تحميل',
                  onPressed: () => unawaited(saveDesign(context, design)),
                  icon: Icon(AppIcons.download, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.black45),
                ),
                SizedBox(width: 8.w),
                IconButton(
                  tooltip: 'فتح خارج التطبيق',
                  onPressed: () => unawaited(openDesignExternally(context, design)),
                  icon: Icon(AppIcons.openExternal, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.black45),
                ),
              ],
            ),
          ),
          // ما هو، في الأسفل حيث لا يقع على التصميم.
          PositionedDirectional(
            bottom: MediaQuery.paddingOf(context).bottom + 16.h,
            start: 16.w,
            end: 16.w,
            child: Text(
              [design.label, ?design.dimensionsLabel, ?design.sizeLabel].join('  ·  '),
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
