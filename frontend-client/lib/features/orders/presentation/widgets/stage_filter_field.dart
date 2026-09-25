import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/presentation/views/stage_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// اختيار الحالة في «طلباتي»: حقلٌ واحد يقول ما اختير، ويفتح ورقةً سفلية فيها الحالات كلها.
///
/// **حقلٌ وورقة، لا شرائح ولا قائمة منسدلة** (طلب المستخدم، 2026-09-25، «عرضهم سيء»). إحدى عشرة
/// شريحةً أكلت أربعة أسطر من أعلى الشاشة قبل أول طلبية. والقائمة المنسدلة (`AppDropdown`) حقلُ
/// نموذج تنسدل قائمته من أعلى الشاشة، بعيدةً عن الإبهام، بأيقوناتٍ رمادية. الورقة تفتح حيث
/// الإبهام، وتتّسع للحالات كلها بأيقوناتها وألوانها التي على البطاقات — كما تفعل ورقة التصفية في
/// تطبيق الموظفين.
///
/// **والحقل يقول الحالة المختارة باسمها وأيقونتها**، فيُعرف ما تعرضه القائمة بلا فتح شيء.
class StageFilterField extends StatelessWidget {
  const StageFilterField({required this.selected, required this.onChanged, super.key});

  final OrdersFilter selected;
  final ValueChanged<OrdersFilter> onChanged;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<OrdersFilter>(
      context: context,
      // **فوق الشريط السفلي لا تحته.** «طلباتي» تعيش في فرعٍ من الـ shell، وورقةٌ على ملّاحه
      // تغطّي الصفحة وحدها وتترك الشريط حيّاً تحتها: لمسةٌ عليه تنقل القسم والورقةُ معلّقةٌ فيه.
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => _StageSheet(selected: selected),
    );

    if (picked != null && picked != selected) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(16.r);

    return Material(
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              _Glyph(filter: selected, size: 36),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  selected.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(AppIcons.expand, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// الورقة: عنوانها، ثم الحالات صفّاً صفّاً بترتيب ما تمرّ به الطلبية، والمختارة معلَّمة.
///
/// **بطول ما فيها، وتُمرَّر على هاتفٍ أقصر منها**: `Column` بحجم محتواه داخل حدٍّ أعلى، فلا
/// تبتلع الشاشة كلها لإحدى عشرة كلمة.
class _StageSheet extends StatelessWidget {
  const _StageSheet({required this.selected});

  final OrdersFilter selected;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 12.h),
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
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
              child: Text(
                'حالة الطلبية',
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 16.h),
                children: [
                  for (final filter in OrdersFilter.values)
                    _StageRow(filter: filter, isSelected: filter == selected),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({required this.filter, required this.isSelected});

  final OrdersFilter filter;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Semantics(
      selected: isSelected,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(filter),
        borderRadius: BorderRadius.circular(14.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          child: Row(
            children: [
              _Glyph(filter: filter, size: 40),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  filter.label,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              // العلامة وحدها تقول المختارة، والصفّ لا يتغيّر مقاسه بها ولا بدونها.
              SizedBox(
                width: 24.w,
                child: isSelected
                    ? Icon(AppIcons.check, size: 22.sp, color: scheme.primary)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// أيقونة الحالة في دائرةٍ بلونها — لون الشارة التي على بطاقتها — و«كل الحالات» بأيقونة التصفية
/// على لونٍ محايد، لأنها ليست حالةً تستعير لونها.
class _Glyph extends StatelessWidget {
  const _Glyph({required this.filter, required this.size});

  final OrdersFilter filter;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final stage = filter.stage;
    final (background, foreground) = stage == null
        ? (scheme.surfaceContainerHigh, scheme.onSurfaceVariant)
        : switch (stageTone(scheme, stage)) {
            final tone => (tone.background, tone.foreground),
          };

    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(
        stage == null ? AppIcons.filter : stageIcon(stage),
        size: (size * 0.5).sp,
        color: foreground,
      ),
    );
  }
}
