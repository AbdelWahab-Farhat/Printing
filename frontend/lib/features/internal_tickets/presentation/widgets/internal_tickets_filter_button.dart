import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket_query.dart';
import 'package:dayaa/features/internal_tickets/usecases/internal_tickets_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// كلُّ ما تُضيَّق به قائمة «الموظفين» عدا الحالة، خلف زرٍّ واحد — طلبُ المالك ٢٠٢٦-١٠-٢٣.
///
/// **الحالتان وحدهما على الصفحة** («قيد المعالجة» / «مغلقة»): هما ما يُبدَّل بينه وهو يقرأ. وفي
/// الورقة ما يُضبط مرّةً: «تذاكري / الكل» للمدير وحده، و«غير المقروءة»، ونوعُ المشكلة، والترتيب.
///
/// **مملوءٌ حين يُختار شيءٌ ومحايدٌ حين لا شيء**، كأزرار التصفية الأخرى في التطبيق — فيُعرف أنّ
/// القائمة مضيّقة قبل أن تُفتح الورقة.
class InternalTicketsFilterButton extends StatelessWidget {
  const InternalTicketsFilterButton({
    required this.query,
    required this.offersAll,
    required this.onApplied,
    super.key,
  });

  final InternalTicketQuery query;

  /// «تذاكري / الكل» — للمدير، وما لم تكن القائمةُ مقصورةً على طلبيةٍ أو عميل.
  final bool offersAll;

  final ValueChanged<InternalTicketQuery> onApplied;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<InternalTicketQuery>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(query: query, offersAll: offersAll),
    );

    // السحبُ لإغلاق الورقة ليس جواباً؛ «تطبيق» وحده جواب.
    if (picked != null) onApplied(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isActive = _isNarrowed(query);

    return Tooltip(
      message: 'تصفية التذاكر',
      child: Material(
        color: isActive ? scheme.primaryContainer : scheme.surfaceContainerLowest,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () => unawaited(_open(context)),
          customBorder: const CircleBorder(),
          child: Padding(
            padding: EdgeInsets.all(13.w),
            child: Icon(
              AppIcons.filter,
              size: 22.sp,
              color: isActive ? scheme.onPrimaryContainer : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// ما تضبطه الورقة — والحالةُ ليست منه.
bool _isNarrowed(InternalTicketQuery query) =>
    query.allTickets || query.unreadOnly || query.categoryId != null || query.oldestFirst;

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.query, required this.offersAll});

  final InternalTicketQuery query;
  final bool offersAll;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

/// يُطبَّق عند «تطبيق» لا عند الضغطة، كبقية أوراق التصفية: فلـ«مسح الفلاتر» ما يمسحه، والضغطةُ
/// الخاطئة تُصحَّح بلا فتحٍ ثانٍ.
class _FilterSheetState extends State<_FilterSheet> {
  late InternalTicketQuery _draft = widget.query;

  /// الأنواعُ تُسأل عند فتح الورقة؛ وقائمتُها التي لم تصل تُخفي قسمها ولا تمنع الباقي.
  List<InternalCategory> _categories = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadCategories());
  }

  Future<void> _loadCategories() async {
    final result = await sl<GetInternalCategories>()();

    if (!mounted) return;

    result.fold((_) {}, (list) => setState(() => _categories = list));
  }

  void _clear() => setState(
    () => _draft = _draft.copyWith(
      allTickets: false,
      unreadOnly: false,
      categoryId: null,
      oldestFirst: false,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 8.w, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'تصفية التذاكر',
                      style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (_isNarrowed(_draft))
                    TextButton(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: _clear,
                      child: const Text('مسح الفلاتر'),
                    ),
                ],
              ),
            ),
            if (widget.offersAll)
              _Section(
                title: 'التذاكر',
                children: [
                  FilterOptionChip(
                    label: 'تذاكري',
                    isSelected: !_draft.allTickets,
                    onTap: () => setState(() => _draft = _draft.copyWith(allTickets: false)),
                  ),
                  FilterOptionChip(
                    label: 'الكل',
                    isSelected: _draft.allTickets,
                    onTap: () => setState(() => _draft = _draft.copyWith(allTickets: true)),
                  ),
                ],
              ),
            _Section(
              title: 'الرسائل',
              children: [
                FilterOptionChip(
                  label: 'غير المقروءة',
                  isTicked: true,
                  isSelected: _draft.unreadOnly,
                  onTap: () =>
                      setState(() => _draft = _draft.copyWith(unreadOnly: !_draft.unreadOnly)),
                ),
              ],
            ),
            if (_categories.isNotEmpty)
              _Section(
                title: 'نوع المشكلة',
                children: [
                  // اختيارٌ واحد، والضغطُ على المختار يلغيه — كورقة بريمولا.
                  for (final category in _categories)
                    FilterOptionChip(
                      label: category.name,
                      isSelected: _draft.categoryId == category.id,
                      onTap: () => setState(
                        () => _draft = _draft.copyWith(
                          categoryId: _draft.categoryId == category.id ? null : category.id,
                        ),
                      ),
                    ),
                ],
              ),
            _Section(
              title: 'الترتيب',
              children: [
                FilterOptionChip(
                  label: 'الأحدث نشاطاً',
                  isSelected: !_draft.oldestFirst,
                  onTap: () => setState(() => _draft = _draft.copyWith(oldestFirst: false)),
                ),
                FilterOptionChip(
                  label: 'الأقدم نشاطاً',
                  isSelected: _draft.oldestFirst,
                  onTap: () => setState(() => _draft = _draft.copyWith(oldestFirst: true)),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
              child: AppButton(
                label: 'تطبيق',
                onPressed: () => Navigator.of(context).pop(_draft),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterSectionTitle(title: title),
          SizedBox(height: 10.h),
          Wrap(spacing: 8.w, runSpacing: 8.h, children: children),
        ],
      ),
    );
  }
}
