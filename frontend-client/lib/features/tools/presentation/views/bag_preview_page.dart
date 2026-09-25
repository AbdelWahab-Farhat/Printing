import 'dart:async';
import 'dart:ui' as ui;

import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/files/attachment_picker.dart';
import 'package:dayaa_client/core/files/picked_file.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_dropdown.dart';
import 'package:dayaa_client/core/widgets/attachment_sheet.dart';
import 'package:dayaa_client/core/widgets/filter_option_chip.dart';
import 'package:dayaa_client/features/tools/models/bag_type.dart';
import 'package:dayaa_client/features/tools/models/design_placement.dart';
import 'package:dayaa_client/features/tools/presentation/viewmodel/bag_preview_cubit.dart';
import 'package:dayaa_client/features/tools/presentation/widgets/bag_canvas.dart';
import 'package:dayaa_client/features/tools/usecases/save_bag_preview_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

/// معاينة التصميم على الكيس.
///
/// **ليست وضعَ صورةٍ فوق صورةِ كيس.** الكيس ثلاث مناطق: حدوده، ومنطقةٌ تُطبع، وهامشٌ حولها لا
/// يُطبع؛ والتصميم محبوسٌ في الوسطى منها — لا يدخل الهامش بالتحريك ولا بالتكبير، وما خرج عنها
/// لا يُرسم أصلاً. القاعدة كلها في [DesignPlacement]، والقصّ في `BagPreviewPainter`.
///
/// وذلك هو الغرض: أن يرى الموظف والزبون **ما سيُطبع فعلاً**، لا تصميماً يغطّي الكيس كله بينما
/// الطباعة الحقيقية لا تسمح بذلك.
class BagPreviewPage extends StatelessWidget {
  const BagPreviewPage({super.key, this.initialDesign});

  /// تصميمٌ تفتح عليه الشاشة، حين تُفتح من ملفٍ موجود بدل أن يُرفع واحدٌ من الصفر.
  final PickedFile? initialDesign;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BagPreviewCubit>(
      create: (_) {
        final cubit = sl<BagPreviewCubit>()..load();
        if (initialDesign case final design?) unawaited(cubit.loadDesign(design));

        return cubit;
      },
      child: const _BagPreviewView(),
    );
  }
}

class _BagPreviewView extends StatefulWidget {
  const _BagPreviewView();

  @override
  State<_BagPreviewView> createState() => _BagPreviewViewState();
}

class _BagPreviewViewState extends State<_BagPreviewView> {
  /// وضع التصميم — حالة بصرية بحتة تتغيّر مع كل إطار من السحب، انظر [BagPreviewCubit].
  DesignPlacement _placement = const DesignPlacement.initial();

  /// خطوط الإرشاد ظاهرة أثناء العمل.
  ///
  /// **وتُخفى بضغطة واحدة لا في شاشةٍ ثانية.** «كيف ستبدو نظيفة؟» سؤالٌ يُسأل كل عشر ثوانٍ
  /// أثناء الضبط، وجوابه يجب أن يكون بعرض إبهامٍ لا برحلة.
  bool _showGuides = true;

  /// ملفٌ يُرسم ويُكتب على القرص الآن.
  bool _isExporting = false;

  Future<void> _upload() async {
    final cubit = context.read<BagPreviewCubit>();

    final source = await showAttachmentSheet(context: context, title: 'رفع التصميم');
    if (source == null || !mounted) return;

    final files = await sl<AttachmentPicker>().pick(source);
    // الخروج من المنتقي ليس فشلاً ولا يُقال عنه شيء.
    if (files.isEmpty) return;

    // تصميمٌ جديد يبدأ من وضعٍ جديد: إبقاء إزاحة الشعار السابق تضع الجديد في ركنٍ بلا سبب.
    setState(() => _placement = const DesignPlacement.initial());

    await cubit.loadDesign(files.first);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأدوات'),
        actions: [
          BlocBuilder<BagPreviewCubit, BagPreviewState>(
            builder: (context, state) => state.design == null
                ? const SizedBox.shrink()
                : IconButton(
                    onPressed: () => setState(() => _showGuides = !_showGuides),
                    tooltip: _showGuides ? 'إخفاء حدود الطباعة' : 'إظهار حدود الطباعة',
                    icon: Icon(_showGuides ? AppIcons.hideGuides : AppIcons.showGuides),
                  ),
          ),
        ],
      ),
      body: BlocConsumer<BagPreviewCubit, BagPreviewState>(
        listenWhen: (_, state) => state is BagPreviewFailure,
        listener: (context, state) {
          if (state case BagPreviewFailure(:final failure)) context.showFailure(failure);
        },
        builder: (context, state) => ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          children: [
            // The other half of «الأدوات»'s chip row — see `_ToolChips` in `qr_tool_page.dart`.
            // Drawn here too rather than lifted into a shared shell: the two tools have no state
            // and no scaffolding in common, and a shell for two screens is a third thing to keep
            // in step with both.
            SizedBox(
              height: 38.h,
              child: Row(
                children: [
                  FilterOptionChip(
                    label: 'مولّد QR',
                    isSelected: false,
                    onTap: () => context.pushReplacement(Routes.qrTool),
                  ),
                  SizedBox(width: 9.w),
                  FilterOptionChip(
                    label: 'معاينة على الكيس',
                    isSelected: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            SizedBox(height: 18.h),
            AppDropdown<BagType>(
              items: BagType.values,
              value: state.bag,
              labelOf: (bag) => bag.label,
              keyOf: (bag) => bag.name,
              // مساحة الطباعة تحت اسم الكيس: هي الرقم الذي يفرّق بين مقاسين، وهي ما يسأل عنه
              // الموظف حين يختار.
              subtitleOf: (bag) =>
                  'مساحة الطباعة ${_cm(bag.printableWidth)}×${_cm(bag.printableHeight)} سم',
              label: 'نوع الكيس',
              onChanged: (bag) {
                if (bag != null) unawaited(context.read<BagPreviewCubit>().selectBag(bag));
              },
            ),
            SizedBox(height: 20.h),
            // مربّعٌ ثابت بنسبة صور الأكياس (كلها ١٢٠٠×١٢٠٠)، فلا تقفز الشاشة حين يُبدَّل
            // النوع ولا حين تصل صورته.
            AspectRatio(
              aspectRatio: 1,
              child: BagCanvas(
                bag: state.bag,
                mockup: state.mockup,
                design: state.design,
                placement: _placement,
                showGuides: _showGuides,
                onPlacementChanged: (placement) => setState(() => _placement = placement),
              ),
            ),
            SizedBox(height: 20.h),
            if (state is BagPreviewLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              AppButton(
                label: state.design == null ? 'رفع التصميم' : 'تبديل التصميم',
                icon: AppIcons.designs,
                variant: state.design == null
                    ? AppButtonVariant.primary
                    : AppButtonVariant.tonal,
                onPressed: _upload,
              ),
              if (state.design case final design?) ...[
                SizedBox(height: 12.h),
                if (state.mockup case final mockup?)
                  _ShareButton(
                    bag: state.bag,
                    mockup: mockup,
                    placement: _placement,
                    design: design,
                    isExporting: _isExporting,
                    onExporting: (value) => setState(() => _isExporting = value),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// السنتيمترات بلا كسرٍ لا معنى له: «٣١ سم» لا «٣١.٠ سم».
  static String _cm(double value) =>
      value == value.roundToDouble() ? value.round().toString() : value.toStringAsFixed(1);
}

/// ما يُفعل بالمعاينة بعد ضبطها: تُرسَل.
///
/// **ولا تُحفَظ في مكتبة تصاميم العميل، وهذا منعٌ مقصود لا نقص.** المكتبة تحمل **ما يُطبع**،
/// ومنها تأخذ الطلبيةُ نسختها؛ ومعاينةُ الكيس صورةُ كيسٍ لا فنٌّ يُطبع. لو دخلت هناك لأمكن أن
/// تُختار يوماً تصميماً لطلبية فتُرسل إلى المطبعة صورةُ كيسٍ عليه كيس. رمز QR يدخل المكتبة لأنه
/// يُطبع فعلاً؛ وهذه لا.
///
/// وجهتها الصحيحة هي الزبون: «قبل اعتماده أو إرساله للزبون» — وورقة النظام هي ما يوصلها إليه.
class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.bag,
    required this.mockup,
    required this.placement,
    required this.design,
    required this.isExporting,
    required this.onExporting,
  });

  final BagType bag;
  final ui.Image mockup;
  final DesignPlacement placement;
  final ui.Image design;
  final bool isExporting;
  final ValueChanged<bool> onExporting;

  Future<void> _share(BuildContext context) async {
    // تُقاس قبل الـ await: ورقة المشاركة على iPad نافذةٌ تحتاج أن تُربط بشيء على الشاشة.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;

    onExporting(true);

    final result = await sl<SaveBagPreviewImage>()(
      bag: bag,
      mockup: mockup,
      placement: placement,
      design: design,
    );

    if (!context.mounted) return;
    onExporting(false);

    await result.fold(
      (failure) async => context.showFailure(failure),
      (path) async => SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'image/png')],
          fileNameOverrides: const [SaveBagPreviewImage.fileName],
          sharePositionOrigin: origin,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'مشاركة المعاينة',
      icon: AppIcons.download,
      isLoading: isExporting,
      onPressed: () => _share(context),
    );
  }
}
