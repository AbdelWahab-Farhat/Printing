import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The verdict on one version — «اعتماد التصميم» or «طلب تعديل».
///
/// **Two buttons, one for each verdict.** It was a segmented control above a single button that
/// renamed itself with the segment, which made two taps of a choice between two things and put
/// the word the reader was aiming at under their own finger.
///
/// **The note is required for a change request and optional for an approval**, which is why
/// this is a sheet rather than two buttons on the ticket screen: the words are the whole content
/// of a revision round. The rule is caught here so the complaint lands under the box; the server
/// refuses an empty one too, and that refusal is the guarantee.
///
/// **Each verdict is confirmed.** Approving closes the ticket and files the artwork on the
/// customer's account and cannot be undone; a change request goes back to a designer who has to
/// redraw. The warning about the first used to sit on the sheet as grey prose above the button —
/// read once, then never again. It is in the confirmation now, where it is read every time.
///
/// Answers with a [ReviewChoice], never a bare verdict: `showModalBottomSheet` returns null when
/// the sheet is **dismissed**, and backing out is not a decision.
Future<ReviewChoice?> showReviewVersionSheet({
  required BuildContext context,
  required DesignTicketFile version,
}) {
  return showModalBottomSheet<ReviewChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _ReviewSheet(version: version),
  );
}

/// The sheet's answer.
@immutable
class ReviewChoice {
  const ReviewChoice({required this.verdict, this.note});

  final DesignSubmissionStatus verdict;
  final String? note;
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.version});

  final DesignTicketFile version;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final TextEditingController _note = TextEditingController();

  /// «اكتب ما المطلوب تعديله», once somebody has asked for a change without saying which.
  String? _noteError;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// Closes the sheet with a verdict, once the reader has said they meant it.
  Future<void> _answer(
    BuildContext context, {
    required DesignSubmissionStatus verdict,
    required String title,
    required String description,
    required String confirmLabel,
  }) async {
    final confirmed = await showCustomDialog(
      context: context,
      title: title,
      description: description,
      confirmLabel: confirmLabel,
    );

    if (!(confirmed ?? false) || !context.mounted) return;

    Navigator.of(context).pop(ReviewChoice(verdict: verdict, note: _note.text));
  }

  Future<void> _approve(BuildContext context) => _answer(
    context,
    verdict: DesignSubmissionStatus.approved,
    title: 'اعتماد التصميم؟',
    description: 'تُغلق التذكرة ويُحفظ التصميم في حساب الزبون. لا يمكن التراجع.',
    confirmLabel: 'اعتماد',
  );

  Future<void> _requestChanges(BuildContext context) async {
    // Caught before the dialog rather than after it: a confirmation for something that is
    // about to be refused anyway is one tap spent on nothing.
    if (_note.text.trim().isEmpty) {
      setState(() => _noteError = 'اكتب ما المطلوب تعديله');

      return;
    }

    setState(() => _noteError = null);

    await _answer(
      context,
      verdict: DesignSubmissionStatus.changesRequested,
      title: 'طلب تعديل؟',
      description: 'تعود التذكرة إلى المصمم مع ملاحظتك، ويرفع نسخة جديدة.',
      confirmLabel: 'إرسال',
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مراجعة ${widget.version.label}',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 14.h),
          AppTextField(
            controller: _note,
            label: 'ملاحظة',
            hint: 'كبّر الشعار وغيّر رقم الهاتف',
            maxLines: 3,
            errorText: _noteError,
          ),
          SizedBox(height: 18.h),
          AppButton(label: 'اعتماد التصميم', onPressed: () => _approve(context)),
          SizedBox(height: 10.h),
          AppButton.tonal(label: 'طلب تعديل', onPressed: () => _requestChanges(context)),
        ],
      ),
    );
  }
}
