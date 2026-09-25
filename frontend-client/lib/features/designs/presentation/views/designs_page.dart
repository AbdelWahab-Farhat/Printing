import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_speed_dial.dart';
import 'package:dayaa_client/core/widgets/search_field.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/presentation/viewmodel/designs_cubit.dart';
import 'package:dayaa_client/features/designs/presentation/widgets/design_library.dart';
import 'package:dayaa_client/features/tools/presentation/views/qr_tool_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «تصاميمي» — الميزة التي وُجد هذا التطبيق ليجعلها ممكنة.
///
/// **يُرفع التصميم مرةً وتشير إليه كل طلبية.** قبلها كان العميل يرسل الملف نفسه مع كل طلبية،
/// وعلى أحدٍ في المحل أن يتبيّن أهو الملف نفسه. `order_designs` تحمل إشارةً لا نسخة، فتسميةُ
/// تصميمٍ هنا تسمّيه في كل مكانٍ استُعمل فيه، وهذا مقصود.
class DesignsPage extends StatelessWidget {
  const DesignsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DesignsCubit>(
      create: (_) => sl<DesignsCubit>()..load(),
      child: const _DesignsView(),
    );
  }
}

class _DesignsView extends StatefulWidget {
  const _DesignsView();

  @override
  State<_DesignsView> createState() => _DesignsViewState();
}

class _DesignsViewState extends State<_DesignsView> {
  /// نصّ البحث.
  ///
  /// **للشاشة لا للحقل.** السحب للتحديث يمرّ بحالة التحميل فيزول الحقل ثم يُبنى من جديد،
  /// ومتحكّمٌ يملكه الحقل كان سيعود فارغاً والشبكةُ ما زالت مصفّاةً بما كان فيه.
  final _search = TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// يصنع رمز QR ويضعه في المكتبة مباشرة.
  ///
  /// **الأداة لا ترفع**، وهذا المقصود: الرفع عمل هذا الـ Cubit بكل ما يعرفه عنه. الأداة ترسم
  /// ملفاً وتعيده — كما تفعل الكاميرا.
  Future<void> _addQrCode(BuildContext context) async {
    final cubit = context.read<DesignsCubit>();

    final qr = await pickQrCodeFile(context);

    if (qr == null) return;

    // **الاسم يعود مع الملف.** الأداة تسأل عنه وما سُئل عنه يسافر؛ على هذه الشاشة ألّا تُسقطه.
    await cubit.add(file: qr.file, label: qr.label);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تصاميمي'),
        // «أنشئ رمز QR» يبقى في الشريط لأنه عملٌ آخر: ذاك *يصنع* تصميماً من لا شيء، والزر
        // العائم يضع في المكتبة ملفاً موجوداً أصلاً.
        actions: [
          IconButton(
            icon: Icon(AppIcons.qrCode),
            tooltip: 'أنشئ رمز QR',
            onPressed: () => _addQrCode(context),
          ),
        ],
      ),
      // **الإضافة زرٌّ عائم** بطلب صاحب العمل (٢٠٢٦-٠٩-٢٥)، مكانَ الخانة التي كانت بعد آخر
      // تصميم والزرّ الذي كان على الشاشة الفارغة: زرٌّ واحد لعملٍ واحد، في مكانه دائماً.
      //
      // ولا يظهر قبل أن تُحمَّل المكتبة، فلا قائمةَ يُضاف إليها بعد.
      floatingActionButtonLocation: AppSpeedDial.location,
      floatingActionButton: BlocBuilder<DesignsCubit, DesignsState>(
        buildWhen: (previous, current) =>
            (previous is DesignsLoaded) != (current is DesignsLoaded),
        builder: (_, state) => AppSpeedDial(
          actions: [
            if (state is DesignsLoaded)
              AppAction(
                label: 'أضف تصميماً',
                icon: AppIcons.add,
                tone: AppActionTone.primary,
                onTap: (_) => addDesign(context),
              ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: BlocConsumer<DesignsCubit, DesignsState>(
          listener: (context, state) {
            // كتابةٌ فشلت، تُبلَّغ بجانب مكتبةٍ ما زالت على الشاشة.
            if (state case DesignsLoaded(:final lastFailure?)) {
              context.showFailure(lastFailure);
            }
          },
          builder: (context, state) => switch (state) {
            DesignsLoading() => const Center(child: CircularProgressIndicator()),

            DesignsFailure(:final failure) => Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(failure.message, textAlign: TextAlign.center),
                    SizedBox(height: 16.h),
                    AppButton.outlined(
                      label: 'أعد المحاولة',
                      onPressed: context.read<DesignsCubit>().load,
                    ),
                  ],
                ),
              ),
            ),

            // لا بحث في مكتبةٍ فارغة: حقلٌ فوق «لا توجد تصاميم بعد» وعدٌ بما ليس موجوداً.
            DesignsLoaded(:final designs) when designs.isEmpty => const _Empty(),

            DesignsLoaded(:final designs, :final isBusy) => Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                  // **في الهاتف لا على الخادم**: المكتبة خمسون تصميماً على الأكثر وكلها هنا،
                  // فلا طلبَ ولا تأخيرَ مع كل حرف. والمطابقة في [CustomerDesignX.matches].
                  child: SearchField(
                    controller: _search,
                    hint: 'ابحث في تصاميمي',
                    onChanged: (query) => setState(() => _query = query),
                  ),
                ),
                Expanded(
                  child: Opacity(
                    // تُعتَّم أثناء الكتابة والشبكة باقية، فلا تبدو التسمية كأن المكتبة اختفت.
                    opacity: isBusy ? 0.6 : 1,
                    child: RefreshIndicator(
                      onRefresh: context.read<DesignsCubit>().load,
                      child: _Library(
                        designs: [
                          for (final design in designs)
                            if (design.matches(_query)) design,
                        ],
                        query: _query.trim(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          },
        ),
      ),
    );
  }
}

class _Library extends StatelessWidget {
  const _Library({required this.designs, required this.query});

  /// ما يطابق البحث وحده.
  final List<CustomerDesign> designs;

  final String query;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return CustomScrollView(
      // دائماً، كي يبقى السحب للتحديث ممكناً وإن لم يكن ما يُمرَّر.
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (designs.isEmpty)
          // الجملة نفسها التي تقولها قوائم التطبيق حين لا يطابق البحث شيئاً.
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(32.w, 96.h, 32.w, 0),
              child: Column(
                children: [
                  Icon(AppIcons.empty, size: 52.sp, color: scheme.outline),
                  SizedBox(height: 14.h),
                  Text(
                    'لا توجد نتائج لـ «$query»',
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            // ٩٦ من الأسفل كي يصعد آخر صفٍّ فوق الزر العائم، وإلا وقع زرّ خيارات البطاقة
            // اليسرى تحته.
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 96.h),
            sliver: SliverDesignGrid(designs: designs),
          ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      children: [
        SizedBox(height: 140.h),
        Icon(
          AppIcons.designs,
          size: 48.sp,
          color: context.colorScheme.onSurfaceVariant,
        ),
        SizedBox(height: 14.h),
        Text(
          'لا توجد تصاميم بعد',
          textAlign: TextAlign.center,
          style: context.textTheme.titleSmall,
        ),
      ],
    );
  }
}
