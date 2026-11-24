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
import 'package:flutter/services.dart';
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
/// **«أجرة المصمم» هنا لمن يكتبه**، والسعر المقترح مكتوبٌ في الحقل ما لم يُكتب أجر. وما في الحقل
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
  late final TextEditingController _title = TextEditingController(
    text: widget.ticket.title,
  );
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

  /// Opens the description on a page of its own, editing the same controller, so what is
  /// typed there is already in the sheet when it comes back.
  Future<void> _openFullScreen() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _DescriptionEditorPage(
        controller: _description,
        subtitle: '${widget.ticket.code} · ${_title.text.trim()}',
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: what this is, which ticket, and who sees the change.
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 12.w, 12.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'تعديل الطلب',
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            _CodeChip(code: widget.ticket.code),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'يرى المصمم التعديل فور الحفظ',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'إغلاق',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Card(
                      children: [
                        AppTextField(controller: _title, label: 'عنوان الطلب'),
                        SizedBox(height: 12.h),
                        // One box, like the form that raised the ticket — see
                        // `DesignTicketFormPage`. An older ticket may still carry
                        // `instructions`; the detail screen keeps drawing it when it is
                        // there, and nothing writes one any more.
                        AppTextField(
                          controller: _description,
                          label: 'وصف الطلب والتعليمات',
                          minLines: 4,
                          maxLines: 8,
                        ),
                        SizedBox(height: 6.h),
                        _DescriptionFooter(
                          controller: _description,
                          onFullScreen: _openFullScreen,
                        ),
                      ],
                    ),
                    // بترتيب نموذج الطلب نفسه: قبل الألوان.
                    if (widget.ticket.canSetPay) ...[
                      SizedBox(height: 12.h),
                      _Card(
                        children: [
                          OptionalAmountField(
                            controller: _pay,
                            label: 'أجرة المصمم',
                          ),
                          if (widget.ticket.suggestedPay
                              case final suggested?) ...[
                            SizedBox(height: 8.h),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: ActionChip(
                                avatar: const Icon(
                                  Icons.auto_awesome_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  'المقترح: ${trimDecimals(suggested)}',
                                ),
                                onPressed: () =>
                                    _pay.text = trimDecimals(suggested),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    SizedBox(height: 12.h),
                    _Card(
                      children: [
                        PrintColorsField(
                          colors: _colors,
                          onChanged: (colors) =>
                              setState(() => _colors = colors),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Fixed under the scrolling cards, so «حفظ» is reachable without scrolling to it.
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'حفظ التعديلات',
                          // The server validates both required fields again and answers in
                          // Arabic under the field, so nothing is blocked here — an empty box
                          // reaches a 422 that says which one, rather than a disabled button
                          // that says nothing.
                          onPressed: _save,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(88.w, 52.h),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('إلغاء'),
                      ),
                    ],
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

/// A grouped block of the sheet, on the surface one step above the sheet itself.
class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
        child: Text(
          code,
          textDirection: TextDirection.ltr,
          style: context.textTheme.labelMedium?.copyWith(
            color: scheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Under the description: the Return-key hint, the line count, and the way to more room.
class _DescriptionFooter extends StatelessWidget {
  const _DescriptionFooter({
    required this.controller,
    required this.onFullScreen,
  });

  final TextEditingController controller;
  final VoidCallback onFullScreen;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.bodySmall?.copyWith(
      color: context.colorScheme.onSurfaceVariant,
    );

    return Row(
      children: [
        Expanded(child: Text('Return ينزل سطراً جديداً', style: style)),
        _LineCount(controller: controller, style: style),
        SizedBox(width: 4.w),
        TextButton.icon(
          onPressed: onFullScreen,
          icon: const Icon(Icons.open_in_full_rounded, size: 16),
          label: const Text('ملء الشاشة'),
        ),
      ],
    );
  }
}

class _LineCount extends StatelessWidget {
  const _LineCount({required this.controller, this.style});

  final TextEditingController controller;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final lines = controller.text.trim().isEmpty
            ? 0
            : controller.text.split('\n').length;

        return Text(lines == 1 ? 'سطر واحد' : '$lines أسطر', style: style);
      },
    );
  }
}

/// The description with the whole screen to itself.
///
/// **The sheet's own controller, not a copy**, so there is nothing to hand back and nothing
/// to lose: «تم» and the back button both return to the sheet with the text as it now stands,
/// and only the sheet's «حفظ» sends it.
class _DescriptionEditorPage extends StatefulWidget {
  const _DescriptionEditorPage({
    required this.controller,
    required this.subtitle,
  });

  final TextEditingController controller;
  final String subtitle;

  @override
  State<_DescriptionEditorPage> createState() => _DescriptionEditorPageState();
}

class _DescriptionEditorPageState extends State<_DescriptionEditorPage> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  /// Puts [insert] where the cursor is, replacing any selection.
  void _insert(String insert) {
    final controller = widget.controller;
    final value = controller.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);

    final text = value.text.replaceRange(
      selection.start,
      selection.end,
      insert,
    );
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: selection.start + insert.length,
      ),
    );
    _focus.requestFocus();
  }

  void _newPoint() {
    final controller = widget.controller;
    final offset = controller.selection.isValid
        ? controller.selection.start
        : controller.text.length;
    final atLineStart = offset == 0 || controller.text[offset - 1] == '\n';

    _insert(atLineStart ? '- ' : '\n- ');
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pasted = data?.text;
    if (pasted == null || pasted.isEmpty || !mounted) return;

    _insert(pasted);
  }

  void _selectAll() {
    _focus.requestFocus();
    widget.controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final scheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'وصف الطلب والتعليمات',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              widget.subtitle,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 12.w),
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('تم'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                autofocus: true,
                expands: true,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                textAlignVertical: TextAlignVertical.top,
                style: text.bodyLarge?.copyWith(height: 1.8),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'اكتب وصف الطلب والتعليمات…',
                ),
              ),
            ),
          ),
          // Above the keyboard: what is awkward to do with a thumb on a phone keyboard.
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              border: Border(
                top: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: Row(
                  children: [
                    // Scrolls sideways on a narrow phone rather than overflowing.
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _ToolButton(
                              icon: Icons.format_list_bulleted_rounded,
                              label: 'نقطة جديدة',
                              onTap: _newPoint,
                            ),
                            SizedBox(width: 6.w),
                            _ToolButton(
                              icon: Icons.content_paste_rounded,
                              label: 'لصق',
                              onTap: _paste,
                            ),
                            SizedBox(width: 6.w),
                            _ToolButton(
                              icon: Icons.select_all_rounded,
                              label: 'تحديد الكل',
                              onTap: _selectAll,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    _LineCount(
                      controller: widget.controller,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}
