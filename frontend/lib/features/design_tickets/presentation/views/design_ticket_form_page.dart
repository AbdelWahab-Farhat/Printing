import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/usecases/design_ticket_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Raising a design request.
///
/// **The customer is read, never chosen, when the form is opened from a customer's screen** — the
/// same shape «طلبية جديدة» uses. Opened from the section's own door it has to be picked, and
/// that is the one field this form refuses to submit without.
///
/// **The designer is deliberately not on this form.** Routing work is `design_tickets.assign`, a
/// different grant held by a different person, and a picker that half the shop may not use is a
/// field that mostly teaches people they are not allowed to touch it. A ticket raised here goes
/// to the shared pool, every designer is told, and the first to accept takes it — which is the
/// behaviour the business asked for anyway. Assigning is a tap on the ticket itself.
class DesignTicketFormPage extends StatefulWidget {
  const DesignTicketFormPage({required this.customer, super.key});

  /// Whose artwork this is. The form cannot be opened without one.
  final Customer customer;

  @override
  State<DesignTicketFormPage> createState() => _DesignTicketFormPageState();
}

class _DesignTicketFormPageState extends State<DesignTicketFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _instructions = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final result = await sl<CreateDesignTicket>()(
      customerId: widget.customer.id,
      title: _title.text,
      description: _description.text,
      instructions: _instructions.text,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    result.fold(
      (failure) => context.showFailure(failure),
      (ticket) {
        context.showSuccess('تم إرسال طلب التصميم');
        Navigator.of(context).pop<DesignTicket>(ticket);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mayManage = sl<Session>().can(AppPermission.manageDesignTickets);

    return Scaffold(
      appBar: AppBar(title: const Text('طلب تصميم')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
          children: [
            Text(
              widget.customer.name,
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 16.h),
            AppTextField(
              controller: _title,
              label: 'عنوان الطلب',
              hint: 'تصميم كيس شحن — أسود',
              validator: Validators.required,
            ),
            SizedBox(height: 14.h),
            AppTextField(
              controller: _description,
              label: 'وصف الطلب',
              hint: 'ضع الشعار في المنتصف وأضف رقم الهاتف أسفله',
              maxLines: 4,
              validator: Validators.required,
            ),
            SizedBox(height: 14.h),
            // Optional, and separate from the description on purpose: the description is what a
            // designer reads on the card, the instructions are what they read once they open it.
            AppTextField(
              controller: _instructions,
              label: 'الملاحظات والتعليمات (اختياري)',
              maxLines: 4,
            ),
            SizedBox(height: 14.h),
            Text(
              'المرفقات تُضاف بعد إنشاء التذكرة، حتى لا يضيع الطلب إن فشل الرفع.',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 24.h),
            AppButton(
              label: 'إرسال الطلب',
              isLoading: _isSaving,
              onPressed: mayManage ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}
