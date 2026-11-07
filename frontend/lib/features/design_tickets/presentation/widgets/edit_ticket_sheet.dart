// `show`، لأن dartz تصدّر `State` يصطدم بـ`State` في Flutter.
import 'package:dartz/dartz.dart' show None, Option, Some;
import 'package:dayaa/core/print_colors/print_color.dart';
import 'package:dayaa/core/print_colors/print_colors_editor.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/amount_sheet.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Correcting what was asked for, while the ticket is still open.
///
/// **Three fields and the print colors, and the absences are the decision.** The customer cannot be changed — files
/// and a conversation hang off a ticket by the time anybody notices the wrong one was picked, so
/// a mis-addressed ticket is cancelled and raised again, which leaves an honest record. The
/// designer is its own sheet behind its own grant, because routing work is a different job from
/// describing it.
///
/// A sheet rather than the form screen: the ticket is already open behind it, and pushing a page
/// to change one line loses the thing being corrected from view.
///
/// **«أجر التصميم» هنا لمن يكتبه**، والسعر المقترح مكتوبٌ في الحقل ما لم يُكتب أجر. وما في الحقل
/// عند «حفظ» هو ما يُحفظ. يخرج بطلبٍ غير طلب الكلمات، فحارساهما في الخادم مختلفان.
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
  const TicketEdit({
    required this.title,
    required this.description,
    required this.printColors,
    this.instructions,
    this.pay = const None(),
  });

  final String title;
  final String description;
  final String? instructions;

  /// «ألوان الطباعة» the brief asks for — the whole list, empty to clear them.
  final List<PrintColor> printColors;

  /// [Some] حين تغيّر عمّا على التذكرة، و`Some(null)` يمحوه. وتعديل الكلمات وحدها لا يمسّه.
  final Option<String?> pay;
}

class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.ticket});

  final DesignTicket ticket;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title = TextEditingController(text: widget.ticket.title);
  late final TextEditingController _description = TextEditingController(
    text: widget.ticket.description,
  );
  late final TextEditingController _pay = TextEditingController(
    text: switch (widget.ticket.designerPay ?? widget.ticket.suggestedPay) {
      final pay? => trimDecimals(pay),
      null => '',
    },
  );
  late List<PrintColor> _colors = widget.ticket.printColors;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _pay.dispose();
    super.dispose();
  }

  /// الأجر إن تغيّر عمّا على التذكرة، مهما كان سبب ما في الحقل.
  Option<String?> get _changedPay {
    if (!widget.ticket.canSetPay) return const None();

    final typed = Validators.toWesternDigits(_pay.text.trim());
    final stored = switch (widget.ticket.designerPay) {
      final pay? => trimDecimals(pay),
      null => '',
    };

    if (typed == stored) return const None();

    return Some(typed.isEmpty ? null : typed);
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      TicketEdit(
        title: _title.text,
        description: _description.text,
        printColors: _colors,
        pay: _changedPay,
      ),
    );
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تعديل الطلب', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              SizedBox(height: 14.h),
              AppTextField(controller: _title, label: 'عنوان الطلب'),
              SizedBox(height: 12.h),
              // One box, like the form that raised the ticket — see `DesignTicketFormPage`. An
              // older ticket may still carry `instructions`; the detail screen keeps drawing it
              // when it is there, and nothing writes one any more.
              AppTextField(
                controller: _description,
                label: 'وصف الطلب والتعليمات',
                maxLines: 6,
              ),
              // بترتيب نموذج الطلب نفسه: قبل الألوان.
              if (widget.ticket.canSetPay) ...[
                SizedBox(height: 12.h),
                OptionalAmountField(controller: _pay, label: 'أجر التصميم'),
              ],
              SizedBox(height: 16.h),
              PrintColorsField(
                colors: _colors,
                onChanged: (colors) => setState(() => _colors = colors),
              ),
              SizedBox(height: 18.h),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'حفظ',
                  // The server validates both required fields again and answers in Arabic under
                  // the field, so nothing is blocked here — an empty box reaches a 422 that says
                  // which one, rather than a disabled button that says nothing.
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
