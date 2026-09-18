import 'dart:io';

import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/files/picked_file.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/validators.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:dayaa_client/core/widgets/filter_option_chip.dart';
import 'package:dayaa_client/features/designs/models/design_rules.dart';
import 'package:dayaa_client/features/designs/usecases/upload_design.dart';
import 'package:dayaa_client/features/tools/models/qr_code_art.dart';
import 'package:dayaa_client/features/tools/models/qr_ink.dart';
import 'package:dayaa_client/features/tools/presentation/viewmodel/qr_tool_cubit.dart';
import 'package:dayaa_client/features/tools/presentation/widgets/qr_code_view.dart';
import 'package:dayaa_client/features/tools/presentation/widgets/qr_ink_picker.dart';
import 'package:dayaa_client/features/tools/usecases/save_qr_code_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

/// إنشاء رمز QR — نفس أداة `daaya.ly/qr.html`، داخل التطبيق.
///
/// **حقلٌ واحد للمحتوى، لا قائمةَ أنواع.** الموقع يرمّز ما يُكتب كما يُكتب — رابطاً كان أو رقماً
/// أو نصاً أو حساب تواصل — والمطلوب هو الأداة نفسها لا أداةٌ أخرى بسلوك آخر. وقائمةُ أنواعٍ
/// تُلحق `tel:` برقمٍ أو `https://` بنطاق تُغيّر ما يخرج من الماسح دون أن يظهر التغيير في الحقل:
/// موظف كتب رقماً ليقرأه الزبون رقماً يجده يفتح تطبيق الاتصال. انظر
/// `Docs/tools/TOOLS-DESIGN.md §٣`.
///
/// **ما يُنشَأ هو الترميز، وما يُختار بعده طلاء.** ضغطة «إنشاء الرمز» ترمّز النص؛ ثم يبدّل الحبر
/// والشفافية المعاينةَ فوراً بلا ضغطة ثانية، لأن الرمز واحد بحبرين. تعديل النص لا يمسّ المعروض
/// حتى تُضغط الضغطة — انظر [QrToolCubit].
class QrToolPage extends StatelessWidget {
  const QrToolPage({super.key}) : isPicking = false;

  /// نفس الشاشة، ونهايةٌ أخرى: تعيد الرمز **ملفاً** إلى من فتحها بدل أن تسلّمه لورقة النظام.
  ///
  /// هذا ما يجعل الأداة جزءاً من النظام لا تطبيقاً ثانياً بداخله: مكتبةُ تصاميم العميل تفتحها
  /// كما تفتح الكاميرا، وتستقبل منها [PickedFile] فتمرّ في نفس طابور الرفع الذي تمرّ فيه صورةٌ
  /// من الاستوديو — بكل ما فيه من تقدّمٍ وإعادةِ محاولة وحدٍّ أقصى.
  const QrToolPage.picking({super.key}) : isPicking = true;

  final bool isPicking;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QrToolCubit>(
      create: (_) => sl<QrToolCubit>(),
      child: _QrToolView(isPicking: isPicking),
    );
  }
}

/// الاسم الافتراضي حين لا يكتب أحدٌ اسماً.
///
/// **مكتوبٌ مرة واحدة** لأن الطريقين إلى المكتبة — الرفع من «الأدوات» والتسليم إلى «تصاميمي» —
/// كانا يحملان هذا النص حرفياً كلٌّ في موضعه، وهو بالضبط الشكل الذي يتبدّل في أحدهما وحده.
const String kDefaultQrDesignLabel = 'رمز QR';

/// اسمُ ما كُتب في الحقل، أو [kDefaultQrDesignLabel] إن تُرك فارغاً.
String qrDesignLabelFrom(TextEditingController controller) {
  final typed = controller.text.trim();

  return typed.isEmpty ? kDefaultQrDesignLabel : typed;
}

/// يفتح الأداة لالتقاط رمزٍ ملفاً، ويعيد ما أُنشئ — أو `null` إن خرج الموظف بلا رمز.
/// **والاسم يسافر معه.** الأداة لا ترفع في هذا الطريق — الرفع طابور «تصاميمي» — فلو بقي الاسم
/// هنا لضاع عند الباب، وعاد المستخدم يسمّي رمزه بعد حفظه وهو ما جاء هذا الحقل ليُنهيه.
Future<QrCodeFile?> pickQrCodeFile(BuildContext context) =>
    context.push<QrCodeFile>(Routes.qrToolPick);

/// رمزٌ خرج من الأداة: ملفُّه، والاسم الذي اختاره صاحبه له.
@immutable
class QrCodeFile {
  const QrCodeFile({required this.file, required this.label});

  final PickedFile file;

  /// ما سيُسمّى به في المكتبة. لا يكون فارغاً أبداً — انظر [qrDesignLabelFrom].
  final String label;
}

class _QrToolView extends StatefulWidget {
  const _QrToolView({required this.isPicking});

  final bool isPicking;

  @override
  State<_QrToolView> createState() => _QrToolViewState();
}

class _QrToolViewState extends State<_QrToolView> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  /// اسم التصميم في المكتبة.
  ///
  /// **يُقرأ ساعةَ الحفظ لا ساعةَ الإنشاء**، ولذلك يسافر متحكّماً لا نصّاً: المعاينة تُبنى داخل
  /// `BlocBuilder` الذي لا يُعاد بناؤه إلا حين تتبدّل الحالة، ونصٌّ يُمرَّر نسخةً كان سيتجمّد
  /// على ما كُتب لحظةَ الضغط على «إنشاء الرمز» — فمن سمّى رمزه بعدها حفظ اسماً غير الذي يقرأ.
  final _name = TextEditingController();

  /// الحبر والشفافية — حالة بصرية بحتة داخل هذه الشاشة، انظر [QrToolCubit] للسبب.
  Color _ink = QrInk.black;
  bool _transparentBackground = true;

  @override
  void dispose() {
    _controller.dispose();
    _name.dispose();
    super.dispose();
  }

  void _generate() {
    // الحقل الفارغ يُردّ هنا برسالةٍ تحته، لا بتوست فوق الشاشة: النقص في الحقل، والرسالة تُعلَّق
    // حيث وقع.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<QrToolCubit>().generate(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأدوات')),
      body: BlocListener<QrToolCubit, QrToolState>(
        // التوست للفشل وحده. النجاح يُرى: الرمز يظهر مكان الفراغ، وجملة «تم» فوقه تخبر الموظف
        // بما ينظر إليه.
        listenWhen: (_, state) => state is QrToolFailure,
        listener: (context, state) {
          if (state case QrToolFailure(:final failure)) context.showFailure(failure);
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
            children: [
              // The design opens «الأدوات» on two tools. Hidden in picking mode: the screen was
              // opened to hand a file back to a caller, and wandering off to another tool would
              // strand that caller waiting for something that is never coming.
              if (!widget.isPicking) ...[
                const _ToolChips(),
                SizedBox(height: 18.h),
              ],
              AppTextField(
                controller: _controller,
                label: 'الرابط أو النص',
                hint: 'مثال: https://daaya.ly',
                validator: Validators.required,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _generate(),
              ),
              SizedBox(height: 12.h),
              // **اختياريٌّ، وبلا `validator`.** الحقل لا يقف في طريق «إنشاء الرمز»: من فتح
              // الأداة ليحمّل رمزاً ولا يحفظه لا يسمّي شيئاً. وحين يُترك فارغاً يعود «رمز QR»،
              // وهو الاسم الذي كان يُكتب دائماً قبل أن يوجد هذا الحقل.
              //
              // و٢٥٥ هي ما يقبله `label` على الخادم — حدٌّ يُقال هنا بدل أن يُقال في رحلةٍ
              // ذهاباً وإياباً.
              AppTextField(
                controller: _name,
                label: 'اسم التصميم (اختياري)',
                hint: 'مثال: رمز صفحتنا على فيسبوك',
                maxLength: 255,
              ),
              SizedBox(height: 8.h),
              QrInkPicker(
                selected: _ink,
                onSelected: (ink) => setState(() => _ink = ink),
              ),
              SizedBox(height: 4.h),
              SwitchListTile.adaptive(
                value: _transparentBackground,
                onChanged: (value) => setState(() => _transparentBackground = value),
                title: const Text('خلفية شفافة'),
                contentPadding: EdgeInsets.zero,
              ),
              SizedBox(height: 12.h),
              AppButton(
                label: 'إنشاء الرمز',
                icon: AppIcons.qrCode,
                onPressed: _generate,
              ),
              SizedBox(height: 24.h),
              BlocBuilder<QrToolCubit, QrToolState>(
                builder: (context, state) => switch (state) {
                  QrBlank() || QrToolFailure() => const _EmptyPreview(),
                  QrReady(:final art) => _Preview(
                    art: art,
                    ink: _ink,
                    transparentBackground: _transparentBackground,
                    isPicking: widget.isPicking,
                    name: _name,
                  ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// الأداتان، والانتقال بينهما.
///
/// **شريحتان لا تبويبان**، كما يرسمهما التصميم: الأداتان لا تتشاركان حالةً ولا نصّاً، والتبويب
/// يوحي بأنهما وجهان لشيء واحد. والانتقال `pushReplacement` لا `push`: من بدّل الأداة لا يريد
/// الرجوع إلى سابقتها بزرّ الرجوع، يريد الخروج من «الأدوات».
class _ToolChips extends StatelessWidget {
  const _ToolChips();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38.h,
      child: Row(
        children: [
          FilterOptionChip(label: 'مولّد QR', isSelected: true, onTap: () {}),
          SizedBox(width: 9.w),
          FilterOptionChip(
            label: 'معاينة على الكيس',
            isSelected: false,
            onTap: () => context.pushReplacement(Routes.bagPreview),
          ),
        ],
      ),
    );
  }
}

/// مكان الرمز قبل أن يوجد.
///
/// مربّع بنفس نسبة المعاينة لا سطرٌ من كلام: الشاشة لا تقفز حين يصل الرمز، ومكانه معروف قبل أن
/// يُضغط الزر.
class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: context.colorScheme.outlineVariant),
        ),
        child: Center(
          child: Icon(
            AppIcons.qrCode,
            size: 64.w,
            color: context.colorScheme.onSurfaceVariant.withValues(alpha: .35),
          ),
        ),
      ),
    );
  }
}

/// الرمز، وزر تحميله.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.art,
    required this.ink,
    required this.transparentBackground,
    required this.isPicking,
    required this.name,
  });

  final QrCodeArt art;
  final Color ink;
  final bool transparentBackground;

  /// ما سيُسمّى به التصميم في المكتبة — متحكّمٌ لا نصّ، انظر [_QrToolViewState].
  final TextEditingController name;

  /// الشاشة فُتحت لتُعيد ملفاً، فالإجراء الأول «إضافة إلى التصاميم» و«تحميل الصورة» مساندٌ له.
  final bool isPicking;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // **ورقٌ أبيض تحت المعاينة دائماً، حتى والخلفية شفافة.** الشفافية صفةُ الملف لا صفة هذه
        // البطاقة، ورمزٌ بحبر أسود على سطح الوضع الداكن رمزٌ لا يراه أحد. الأبيض هنا هو الورق
        // الذي سيُطبع عليه، فالمعاينة تريه على ما سيصير إليه.
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: QrInk.paper,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: QrCodeView(
            art: art,
            color: ink,
            transparentBackground: transparentBackground,
          ),
        ),
        SizedBox(height: 16.h),
        // إجراءٌ رئيسي واحد في كل حالة (§7): حين فُتحت الشاشة لتُعيد ملفاً فذاك هو الإجراء،
        // و«تحميل الصورة» يهبط إلى المساند — وحين فُتحت من الدرج فالتحميل هو كل ما تفعله.
        if (isPicking) ...[
          _AddToDesignsButton(
            art: art,
            ink: ink,
            transparentBackground: transparentBackground,
            name: name,
          ),
          SizedBox(height: 12.h),
          AppButton.tonal(
            label: 'تحميل الصورة',
            icon: AppIcons.download,
            onPressed: () => shareQrCodeImage(
              context,
              art: art,
              ink: ink,
              transparentBackground: transparentBackground,
            ),
          ),
        ] else
          // فُتحت من «الأدوات» لا من مكتبة التصاميم، فلا مستدعيَ يُسلَّم إليه الملف — والزرّان
          // هنا جنباً إلى جنب: الحفظ في المكتبة، والتحميل عبر ورقة النظام.
          Row(
            children: [
              // ٣:٢ لا ١:١ — «أضف إلى تصاميمي» ضِعفا طول «تحميل»، وقسمةٌ متساوية تقصّ الأولى.
              Expanded(
                flex: 3,
                child: _SaveToDesignsButton(
                  art: art,
                  ink: ink,
                  transparentBackground: transparentBackground,
                  name: name,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 2,
                child: AppButton.tonal(
                  label: 'تحميل',
                  icon: AppIcons.download,
                  onPressed: () => shareQrCodeImage(
                    context,
                    art: art,
                    ink: ink,
                    transparentBackground: transparentBackground,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// «أضف إلى تصاميمي» — يرسم الرمز ملفاً **ويرفعه بنفسه**.
///
/// **وهذا الاستثناء الوحيد من قاعدة [_AddToDesignsButton]، ومقصود.** ذاك الزرّ لا يرفع لأن من
/// فتح الشاشة يملك طابور الرفع؛ أما هنا فالشاشة فُتحت من «الأدوات» ولا مستدعيَ خلفها يُسلَّم
/// إليه الملف. فيُستدعى `UploadDesign` مباشرة — وهو ما تفعله هذه الشاشات أصلاً مع
/// `GetCurrentCustomer` و`Logout`: حالةُ استخدامٍ من شاشة، لا مستودعٌ ولا Dio.
///
/// و[DesignRules] تُطبَّق قبل الإرسال كما في «تصاميمي» تماماً: رمزُ QR صغيرٌ دائماً فلن يُرفض،
/// لكن البوّابة واحدة في الطريقين أو لم تكن بوّابة.
class _SaveToDesignsButton extends StatefulWidget {
  const _SaveToDesignsButton({
    required this.art,
    required this.ink,
    required this.transparentBackground,
    required this.name,
  });

  final QrCodeArt art;
  final Color ink;
  final bool transparentBackground;
  final TextEditingController name;

  @override
  State<_SaveToDesignsButton> createState() => _SaveToDesignsButtonState();
}

class _SaveToDesignsButtonState extends State<_SaveToDesignsButton> {
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final drawn = await sl<SaveQrCodeImage>()(
      art: widget.art,
      color: widget.ink,
      transparentBackground: widget.transparentBackground,
    );

    if (!mounted) return;

    final path = drawn.fold((failure) {
      context.showFailure(failure);

      return null;
    }, (path) => path);

    if (path == null) {
      setState(() => _isSaving = false);

      return;
    }

    // الحجم يُقرأ من القرص لا يُخمَّن — نفس ما يفعله الزرّ الآخر، ولنفس السبب.
    final file = PickedFile(
      path: path,
      name: SaveQrCodeImage.fileName,
      sizeBytes: await File(path).length(),
    );

    if (!mounted) return;

    final reason = DesignRules.reject(file);
    if (reason != null) {
      setState(() => _isSaving = false);
      context.showError(reason);

      return;
    }

    // يُقرأ الآن لا حين بُني هذا الزر: الاسم قد يُكتب بعد ظهور الرمز.
    final result = await sl<UploadDesign>()(
      file: file,
      label: qrDesignLabelFrom(widget.name),
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    result.fold(
      context.showFailure,
      // **لا انتقال إلى «تصاميمي».** من أنشأ رمزاً قد ينشئ ثانياً، وسحبُه من الشاشة بعد كل
      // حفظٍ يجعل الأداة مكاناً يُطرد منه.
      (_) => context.showSuccess('أُضيف إلى تصاميمي'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'أضف إلى تصاميمي',
      icon: AppIcons.designs,
      isLoading: _isSaving,
      onPressed: _save,
    );
  }
}

/// يرسم الرمز ملفاً ويسلّمه لورقة النظام.
///
/// نفس ما يفعله [shareOrderInvoice] بالحرف، ولنفس السبب: «تحميل» على هاتف ليس زرَّ متصفح — لا
/// مجلد تنزيلاتٍ يفتحه الموظف بعدها. ورقة النظام هي التي تحمل صفَّي «حفظ الصورة» و«حفظ في
/// الملفات»، وهي التي تعرف أي تطبيقات على هذا الجهاز.
///
/// **بلا توست «جارٍ التجهيز» خلافاً للفاتورة**: تلك تُحلّل خطَّين TrueType في أول مرة، وهذه حلقةُ
/// مستطيلاتٍ تنتهي قبل الإطار التالي.
Future<void> shareQrCodeImage(
  BuildContext context, {
  required QrCodeArt art,
  required Color ink,
  required bool transparentBackground,
}) async {
  // يُقاس قبل الـ await: ورقة المشاركة على iPad نافذةٌ منبثقة تحتاج أن تُربط بشيء على الشاشة،
  // وهذه آخر لحظةٍ ذلك فيها مؤكَّد.
  final box = context.findRenderObject() as RenderBox?;
  final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;

  final result = await sl<SaveQrCodeImage>()(
    art: art,
    color: ink,
    transparentBackground: transparentBackground,
  );

  if (!context.mounted) return;

  await result.fold(
    (failure) async => context.showFailure(failure),
    (path) async => SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'image/png')],
        fileNameOverrides: const [SaveQrCodeImage.fileName],
        sharePositionOrigin: origin,
      ),
    ),
  );
}

/// «إضافة إلى التصاميم» — يرسم الرمز ملفاً ويعيده إلى الشاشة التي فتحت الأداة.
///
/// **لا يرفع بنفسه**، وهذا هو بيت القصيد: الرفع طابورٌ في [CustomerDesignsCubit] فيه تقدّمٌ
/// وإعادةُ محاولةٍ على اتصالٍ متقطّع وإرسالٌ واحداً واحداً، وهي أشياء دُفع ثمنها مرة. الأداة
/// تُخرج ملفاً، ومن فتحها يعرف أين يذهب به — تماماً كما تفعل الكاميرا.
class _AddToDesignsButton extends StatefulWidget {
  const _AddToDesignsButton({
    required this.art,
    required this.ink,
    required this.transparentBackground,
    required this.name,
  });

  final QrCodeArt art;
  final Color ink;
  final bool transparentBackground;
  final TextEditingController name;

  @override
  State<_AddToDesignsButton> createState() => _AddToDesignsButtonState();
}

class _AddToDesignsButtonState extends State<_AddToDesignsButton> {
  /// الرسم والكتابة على القرص، لا الرفع. بصرية بحتة داخل هذا الزر (§4).
  bool _isWriting = false;

  Future<void> _add() async {
    setState(() => _isWriting = true);

    final result = await sl<SaveQrCodeImage>()(
      art: widget.art,
      color: widget.ink,
      transparentBackground: widget.transparentBackground,
    );

    if (!mounted) return;
    setState(() => _isWriting = false);

    await result.fold(
      (failure) async => context.showFailure(failure),
      (path) async {
        final file = File(path);

        // الحجم يُقرأ من القرص لا يُقدَّر: [DesignRules] ترفض قبل الرفع بناءً عليه، ورقمٌ
        // مخمَّن كان سيجعلها ترفض ما يقبله الخادم أو العكس.
        if (context.mounted) {
          Navigator.of(context).pop(
            QrCodeFile(
              file: PickedFile(
                path: path,
                name: SaveQrCodeImage.fileName,
                sizeBytes: await file.length(),
              ),
              label: qrDesignLabelFrom(widget.name),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'إضافة إلى التصاميم',
      icon: AppIcons.designs,
      isLoading: _isWriting,
      onPressed: _add,
    );
  }
}
