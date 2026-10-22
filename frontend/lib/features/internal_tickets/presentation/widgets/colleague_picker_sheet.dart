import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ورقةُ «مع مَن؟»، كورقة بريمولا: الزملاءُ النشطون، مَن بيني وبينه تذاكرُ مفتوحة أوّلاً — ترتيبُ
/// الخادم — وبحثٌ بالاسم أو الكود. تُرجع الزميل المختار، أو `null` لمن أغلقها.
///
/// [excluding] من لا يُختار هنا: في التحويل، صاحبُها والزميلُ الذي وُجّهت إليه.
Future<Colleague?> showColleaguePicker({
  required BuildContext context,
  required List<Colleague> colleagues,
  String title = 'مع مَن؟',
  Set<int> excluding = const {},
}) {
  return showModalBottomSheet<Colleague>(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
    builder: (context) => _ColleagueSheet(
      title: title,
      colleagues: [
        for (final colleague in colleagues)
          if (!excluding.contains(colleague.id)) colleague,
      ],
    ),
  );
}

class _ColleagueSheet extends StatefulWidget {
  const _ColleagueSheet({required this.title, required this.colleagues});

  final String title;
  final List<Colleague> colleagues;

  @override
  State<_ColleagueSheet> createState() => _ColleagueSheetState();
}

class _ColleagueSheetState extends State<_ColleagueSheet> {
  /// بصريٌّ بحت: ما كُتب في البحث، يُصفّى به ما في الورقة — القائمةُ كلّها هنا أصلاً.
  String _term = '';

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final term = _term.trim();
    final shown = term.isEmpty
        ? widget.colleagues
        : widget.colleagues
              .where((c) => c.name.contains(term) || (c.employeeCode ?? '').contains(term))
              .toList(growable: false);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: Text(
                widget.title,
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: SearchField(
                hint: 'ابحث باسم الزميل أو كوده',
                onChanged: (value) => setState(() => _term = value),
              ),
            ),
            SizedBox(height: 8.h),
            Expanded(
              child: shown.isEmpty
                  ? Center(
                      child: Text(
                        'لا يوجد زميلٌ بهذا الاسم',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 16.h),
                      itemCount: shown.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final colleague = shown[index];

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: scheme.primaryContainer,
                            child: Text(
                              colleague.name.characters.firstOrNull ?? '؟',
                              style: TextStyle(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          title: Text(colleague.name),
                          subtitle: colleague.employeeCode == null
                              ? null
                              : Text(colleague.employeeCode!),
                          trailing: colleague.openTicketsWithMe > 0
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      AppIcons.internalTickets,
                                      size: 16.sp,
                                      color: scheme.primary,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text('${colleague.openTicketsWithMe}'),
                                  ],
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(colleague),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
