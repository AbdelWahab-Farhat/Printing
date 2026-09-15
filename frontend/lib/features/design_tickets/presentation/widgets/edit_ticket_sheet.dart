import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Correcting what was asked for, while the ticket is still open.
///
/// **Three fields, and the absences are the decision.** The customer cannot be changed — files
/// and a conversation hang off a ticket by the time anybody notices the wrong one was picked, so
/// a mis-addressed ticket is cancelled and raised again, which leaves an honest record. The
/// designer is its own sheet behind its own grant, because routing work is a different job from
/// describing it.
///
/// A sheet rather than the form screen: the ticket is already open behind it, and pushing a page
/// to change one line loses the thing being corrected from view.
Future<TicketEdit?> showEditTicketSheet({
  required BuildContext context,
  required DesignTicket ticket,
}) {
  return showModalBottomSheet<TicketEdit>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _EditSheet(ticket: ticket),
  );
}

@immutable
class TicketEdit {
  const TicketEdit({required this.title, required this.description, this.instructions});

  final String title;
  final String description;
  final String? instructions;
}

class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.ticket});

  final DesignTicket ticket;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _title = TextEditingController(text: widget.ticket.title);
  late final TextEditingController _description = TextEditingController(
    text: widget.ticket.description,
  );
  late final TextEditingController _instructions = TextEditingController(
    text: widget.ticket.instructions ?? '',
  );

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.w,
        0,
        16.w,
        MediaQuery.viewInsetsOf(context).bottom + 16.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تعديل الطلب', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            SizedBox(height: 14.h),
            AppTextField(controller: _title, label: 'عنوان الطلب'),
            SizedBox(height: 12.h),
            AppTextField(controller: _description, label: 'وصف الطلب', maxLines: 4),
            SizedBox(height: 12.h),
            AppTextField(
              controller: _instructions,
              label: 'الملاحظات والتعليمات (اختياري)',
              maxLines: 4,
            ),
            SizedBox(height: 18.h),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'حفظ',
                // The server validates both required fields again and answers in Arabic under
                // the field, so nothing is blocked here — an empty box reaches a 422 that says
                // which one, rather than a disabled button that says nothing.
                onPressed: () => Navigator.of(context).pop(
                  TicketEdit(
                    title: _title.text,
                    description: _description.text,
                    instructions: _instructions.text,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
