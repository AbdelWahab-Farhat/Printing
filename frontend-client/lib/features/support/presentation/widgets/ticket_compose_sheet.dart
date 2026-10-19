import 'package:dartz/dartz.dart' show Either;
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What sends the ticket. The order, when there is one, is the caller's to attach — the sheet
/// only writes the words.
typedef SubmitTicket =
    Future<Either<Failure, SupportTicket>> Function({
      required String subject,
      required String body,
    });

/// «تذكرة جديدة» — the subject and the question, from «الدعم» or straight from an order.
///
/// **The sending is handed in, not looked up.** «الدعم» sends through its list's Cubit, so the
/// new row lands at the head of the list it is showing; the order screen has no list, and sends
/// through `OpenTicket` alone. Either way the sheet closes with the server's ticket, or stays
/// open with the failure on screen and the customer's words still in it.
///
/// **From an order the subject is written for them** — «استفسار عن الطلبية 1304» — and stays
/// theirs to change: what they came to write is the question, not a title for it. The order
/// itself is shown above, fixed: the ticket is about it whatever the subject says.
class TicketComposeSheet extends StatefulWidget {
  const TicketComposeSheet({required this.submit, this.order, super.key});

  final SubmitTicket submit;
  final TicketOrderRef? order;

  /// Opens the sheet; the ticket it sent, or null when it was closed without sending.
  static Future<SupportTicket?> show(
    BuildContext context, {
    required SubmitTicket submit,
    TicketOrderRef? order,
  }) => showModalBottomSheet<SupportTicket>(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => TicketComposeSheet(submit: submit, order: order),
  );

  @override
  State<TicketComposeSheet> createState() => _TicketComposeSheetState();
}

class _TicketComposeSheetState extends State<TicketComposeSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _subject = TextEditingController(
    text: switch (widget.order) {
      final order? => 'استفسار عن الطلبية ${order.code}',
      null => '',
    },
  );
  final _body = TextEditingController();

  bool _isSending = false;

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    final result = await widget.submit(
      subject: _subject.text.trim(),
      body: _body.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isSending = false);

    result.fold(
      context.showFailure,
      (ticket) => Navigator.of(context).pop(ticket),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Padding(
      // Lifted above the keyboard, so the send button is never behind it.
      padding: EdgeInsets.only(bottom: context.keyboardInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  order == null ? 'تذكرة جديدة' : 'تذكرة عن الطلبية',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 16.h),

                if (order != null) ...[
                  _AboutOrder(order: order),
                  SizedBox(height: 16.h),
                ],

                AppTextField(
                  controller: _subject,
                  label: 'الموضوع',
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'اكتب موضوعاً' : null,
                ),
                SizedBox(height: 12.h),
                AppTextField(
                  controller: _body,
                  label: 'اشرح لنا',
                  maxLines: 5,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'اكتب رسالتك' : null,
                ),
                SizedBox(height: 20.h),

                AppButton(label: 'أرسل', isLoading: _isSending, onPressed: _send),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// «بخصوص الطلبية» فوق رقمها، بالشريط نفسه الذي تُثبَّت به في أعلى المحادثة بعد الإرسال — فما
/// يراه العميل هنا هو ما سيراه هناك. لا يُلمس: التذكرة عن هذه الطلبية، ولا تُغيَّر من هنا.
class _AboutOrder extends StatelessWidget {
  const _AboutOrder({required this.order});

  final TicketOrderRef order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      children: [
        Container(
          width: 3.w,
          height: 34.h,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'بخصوص الطلبية',
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                order.code,
                style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
