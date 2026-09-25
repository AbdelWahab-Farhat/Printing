import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/files/attachment_picker.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/validators.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/core/widgets/app_dialog.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:dayaa_client/core/widgets/attachment_sheet.dart';
import 'package:dayaa_client/core/widgets/menu_card.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/models/design_rules.dart';
import 'package:dayaa_client/features/designs/presentation/viewmodel/designs_cubit.dart';
import 'package:dayaa_client/features/designs/presentation/widgets/design_thumbnail.dart';
import 'package:dayaa_client/features/designs/presentation/widgets/design_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// يضيف ملفاً إلى المكتبة: من أين، ثم أيّ ملف، ثم اسمه — ثم الرفع.
///
/// **الاسم قبل الرفع، وهو مطلوب.** ما يُرفع بلا اسمٍ يأخذ اسم ملفه، واسمُ صورةٍ من الاستوديو
/// «image_picker_5D16…» — ومن هذه المكتبة يُختار التصميم في كل طلبية. لذلك يُفتح الحقل فارغاً
/// ولا يُقترح فيه اسم الملف.
///
/// **ملفٌ واحد في كل مرة**، انظر [AttachmentPicker.pickOne].
///
/// عامّةٌ لأن المكتبة تُعرض في غير «تصاميمي»، وكل شاشةٍ تضع زرّها حيث يناسبها. كل ما تحتاجه
/// [DesignsCubit] فوق [context].
Future<void> addDesign(BuildContext context) async {
  final cubit = context.read<DesignsCubit>();

  // كتابةٌ جارية تعني قائمةً لم تستقرّ بعد: رفعٌ يبدأ الآن يبني على نسخةٍ منها ينقصها ما
  // يُرفع. كانت خانة الإضافة معطّلةً في هذه الحال، والحارس هنا يقوم مقامها أيّاً كان الزر.
  if (cubit.state.isBusy) return;

  // الورقة تعرض المستندات **والاستوديو** معاً، لأن «أرسله لي على واتساب» يهبط في الثاني،
  // وتطبيق «الملفات» في iOS لا يراه أصلاً. وهي لا تنتقي شيئاً: تجيب «من أين» فقط.
  final source = await showAttachmentSheet(context: context);

  if (source == null) return;

  final file = await sl<AttachmentPicker>().pickOne(source);

  // الخروج من منتقي النظام نهايةٌ عادية، ولا يُقال عنها شيء.
  if (file == null || !context.mounted) return;

  // **يُردّ هنا لا عند الخادم**، وهذا ما وُجدت له [DesignRules]: دفعُ ٢٦ م.ب على اتصالٍ محمول
  // ليُقال إن الحدّ ٢٥ يكلّف دقيقةً ورصيداً لمعرفة ما يُعرف قبل أن يغادر أول بايتٍ الهاتف.
  // ويُردّ قبل أن يُسأل عن اسمه: تسميةُ ملفٍ لن يُقبل تعبٌ بلا ثمرة.
  final reason = DesignRules.reject(file);

  if (reason != null) {
    context.showError(reason);
    return;
  }

  final label = await showDialog<String>(
    context: context,
    builder: (_) => const _NameDialog(title: 'تصميم جديد', confirmLabel: 'إنشاء'),
  );

  if (label == null) return;

  await cubit.add(file: file, label: label);
}

/// التصاميم شبكةً من عمودين، تُوضع داخل `CustomScrollView`.
///
/// الضغط على البطاقة يفتح الملف ([showDesign])، وزرّ خياراتها يحمّله أو يسمّيه أو يحذفه — عبر
/// [DesignsCubit] الأقرب فوقها، فتعمل تحت أيّ مزوّدٍ له. أما التحميل والفشل والمكتبة الفارغة
/// والبحث والتعتيم أثناء الكتابة فللشاشة التي تعرضها.
class SliverDesignGrid extends StatelessWidget {
  const SliverDesignGrid({required this.designs, super.key});

  final List<CustomerDesign> designs;

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 0.78,
      ),
      itemCount: designs.length,
      itemBuilder: (context, index) => _DesignCard(
        design: designs[index],
        onOpen: () => showDesign(context, designs[index]),
        onOptions: () => _showOptions(context, designs[index]),
      ),
    );
  }
}

enum _DesignAction { save, rename, remove }

/// ما يُفعل بالتصميم غير فتحه: تحميله وتسميته وحذفه، في ورقةٍ واحدة من زرّ البطاقة.
Future<void> _showOptions(BuildContext context, CustomerDesign design) async {
  final choice = await showModalBottomSheet<_DesignAction>(
    context: context,
    // الحافة العليا مستديرة كبقية أوراق التطبيق.
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => _OptionsSheet(design: design),
  );

  if (choice == null || !context.mounted) return;

  switch (choice) {
    case _DesignAction.save:
      await saveDesign(context, design);
    case _DesignAction.rename:
      await _rename(context, design);
    case _DesignAction.remove:
      await _remove(context, design);
  }
}

class _OptionsSheet extends StatelessWidget {
  const _OptionsSheet({required this.design});

  final CustomerDesign design;

  @override
  Widget build(BuildContext context) {
    void choose(_DesignAction action) => Navigator.of(context).pop(action);

    return SafeArea(
      // مؤشّر الشاشة الرئيسية في آيفون يجلس حيث يجلس الصف الأخير.
      top: false,
      // **يُمرَّر ولا يفيض.** الورقة لا تتجاوز ٩/١٦ من الشاشة، وعلى هاتفٍ قصير أو بخطِّ نظامٍ
      // مكبَّر يقع «حذف» خارج ما يُرسم — وصفٌّ لا يُرى في ورقةٍ لا تُمرَّر لا يُوصل إليه أصلاً.
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: context.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                design.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            SizedBox(height: 12.h),
            MenuCard(
              rows: [
                MenuRow(
                  icon: AppIcons.download,
                  label: 'تحميل',
                  onTap: () => choose(_DesignAction.save),
                ),
                MenuRow(
                  icon: AppIcons.edit,
                  label: 'إعادة التسمية',
                  onTap: () => choose(_DesignAction.rename),
                ),
                MenuRow(
                  icon: AppIcons.delete,
                  label: 'حذف',
                  isDestructive: true,
                  onTap: () => choose(_DesignAction.remove),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _rename(BuildContext context, CustomerDesign design) async {
  final cubit = context.read<DesignsCubit>();

  final label = await showDialog<String>(
    context: context,
    builder: (_) => _NameDialog(
      title: 'تسمية التصميم',
      confirmLabel: 'حفظ',
      initial: design.label,
    ),
  );

  if (label == null || label == design.label) return;

  await cubit.renameTo(id: design.id, label: label);
}

Future<void> _remove(BuildContext context, CustomerDesign design) async {
  final cubit = context.read<DesignsCubit>();

  final confirmed = await showDestructiveDialog(
    context: context,
    title: 'حذف «${design.label}»؟',
    // **صريحٌ فيما لا يفعله.** الحذف هنا لا ينزع التصميم من طلبياتٍ سبقت — تلك تحتفظ بالملف
    // الذي طُبعت منه.
    description: 'لن يظهر في مكتبتك بعد الآن. الطلبيات السابقة تحتفظ بالملف الذي طُبعت منه.',
  );

  if (confirmed != true) return;

  await cubit.removeAt(design.id);
}

/// اسمُ تصميمٍ، ومخرجاه — للتصميم الجديد قبل رفعه، وللتسمية من جديد.
///
/// **الاسم مطلوبٌ في الحالين**: الفارغ يُردّ برسالةٍ تحت الحقل والنافذة باقية، وما يُعاد
/// مقصوصُ الأطراف.
///
/// ذاتُ حالةٍ لسببٍ واحد: تملك [TextEditingController]، ومكانُ التخلّص منه `dispose()` هنا
/// حين تُزال النافذة فعلاً، لا السطر التالي لـ`showDialog` في المستدعي. ذاك السطر لحظةَ يتقرّر
/// الإغلاق لا لحظةَ تزول النافذة: حركة الخروج ما زالت تجري وحقلها ما زال يسمع للمتحكّم.
class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.confirmLabel,
    this.initial = '',
  });

  final String title;
  final String confirmLabel;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: AppTextField(
          controller: _controller,
          label: 'الاسم',
          autofocus: true,
          validator: Validators.required,
          // ما يقبله `label` على الخادم.
          maxLength: 255,
          textInputAction: TextInputAction.done,
          // زرّ الإدخال هو زرّ التأكيد: لوحة المفاتيح مفتوحةٌ أصلاً على هذا الحقل.
          onSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(onPressed: _save, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

class _DesignCard extends StatelessWidget {
  const _DesignCard({
    required this.design,
    required this.onOpen,
    required this.onOptions,
  });

  final CustomerDesign design;
  final VoidCallback onOpen;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard(
      onTap: onOpen,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                DesignThumbnail(design: design),
                // «صورة» / «PDF» — كلمة الخادم نفسه للنوع، على الصورة حيث لا تكلّف البطاقة
                // سطراً.
                if (design.kindLabel case final kind?)
                  PositionedDirectional(
                    top: 8.h,
                    end: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Text(
                        kind,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(11.w, 9.h, 4.w, 4.h),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        design.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      // «PNG · 1.2 م.ب» — يرسمه التصميم، والرقمان في ردّ القائمة أصلاً.
                      if (design.metaLine case final meta?) ...[
                        SizedBox(height: 2.h),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // **الخيارات مكانَ السلّة.** التسمية كانت الضغط على البطاقة نفسها، والبطاقة الآن
                // تفتح الملف؛ فاجتمعت التسمية والتحميل والحذف هنا، هادئةً في زاويتها.
                IconButton(
                  icon: Icon(AppIcons.more, size: 18.sp, color: scheme.onSurfaceVariant),
                  tooltip: 'خيارات التصميم',
                  visualDensity: VisualDensity.compact,
                  onPressed: onOptions,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
