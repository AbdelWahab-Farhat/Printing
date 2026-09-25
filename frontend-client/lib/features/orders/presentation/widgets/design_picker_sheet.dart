import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/presentation/widgets/design_thumbnail.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/place_order_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// اختيار التصاميم التي تحملها الطلبية، من مكتبة العميل (طلب صاحب العمل: ورقةٌ من الأسفل، في كل صفٍّ
/// شكل التصميم واسمه — الاسم يميناً والصورة يساراً).
///
/// **تختار ولا تضيف.** التصاميم تُدار من «تصاميمي» وصفحة المتجر، والسلة تختار مما هناك — كما قرّر
/// صاحب العمل للمتاجر.
///
/// **كلُّ لمسةٍ اختيارٌ في الـ Cubit مباشرةً**، فالقائمة خلف الورقة تتبدّل معها، و«تم» يغلقها فقط.
Future<void> showDesignPicker(BuildContext context) {
  final cubit = context.read<PlaceOrderCubit>();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // الحافة العليا مستديرة كبقية أوراق التطبيق.
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => BlocProvider<PlaceOrderCubit>.value(
      value: cubit,
      child: const _DesignPicker(),
    ),
  );
}

class _DesignPicker extends StatelessWidget {
  const _DesignPicker();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return BlocBuilder<PlaceOrderCubit, PlaceOrderState>(
      builder: (context, state) {
        final (designs, chosen) = switch (state) {
          PlaceOrderReady(:final designs, :final designIds) => (designs, designIds),
          _ => (const <CustomerDesign>[], const <int>[]),
        };

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'اختيار التصاميم',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 12.h),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: designs.length,
                    separatorBuilder: (_, _) => SizedBox(height: 8.h),
                    itemBuilder: (context, index) {
                      final design = designs[index];

                      return DesignOptionRow(
                        design: design,
                        isChosen: chosen.contains(design.id),
                        onTap: () => context.read<PlaceOrderCubit>().toggleDesign(design.id),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16.h),
                // لا شيء مختاراً جوابٌ مقبول: هكذا يتراجع العميل عن اختيارٍ قبل لحظة.
                AppButton(
                  label: 'تم (${chosen.length})',
                  lifted: false,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// تصميمٌ واحد: **اسمه يميناً وصورته يساراً**، وعلامة الاختيار بينهما حين يُختار.
///
/// الصورة نفسها لا رمزٌ عنها: نسختان من شعارٍ واحد لا يُفرَّق بينهما بالاسم وحده، والخطأ هنا تصميمٌ
/// آخر يُطبع. ويُرسم الصفّ نفسه في السلة لما اختير، فيُعرف هناك بما عُرف به هنا.
class DesignOptionRow extends StatelessWidget {
  const DesignOptionRow({
    required this.design,
    required this.onTap,
    this.isChosen = false,
    super.key,
  });

  final CustomerDesign design;
  final bool isChosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(14.r);

    return Material(
      color: isChosen ? scheme.primaryContainer : scheme.surfaceContainerHigh,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(14.w, 8.h, 8.w, 8.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  design.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isChosen ? scheme.onPrimaryContainer : scheme.onSurface,
                  ),
                ),
              ),
              if (isChosen) ...[
                SizedBox(width: 8.w),
                Icon(AppIcons.check, size: 20.sp, color: scheme.onPrimaryContainer),
              ],
              SizedBox(width: 12.w),
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  width: 56.w,
                  height: 56.w,
                  color: scheme.surfaceContainerHighest,
                  child: DesignThumbnail(design: design, glyphSize: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
