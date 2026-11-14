import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_snackbar.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/core/widgets/dismiss_keyboard.dart';
import 'package:dayaa/features/customer_messages/models/customer_messages.dart';
import 'package:dayaa/features/customer_messages/presentation/viewmodel/customer_messages_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «رسائل الزبائن» — the admin words the four messages staff copy to customers: the ready
/// message for pickup and for delivery, and the return message for the courier and the carrier.
///
/// Each field opens on the wording in force. «استعادة النص الافتراضي» puts the built-in text
/// back; a text saved equal to it is sent as null, so it keeps following the built-in wording.
/// Read-only for a reader with `settings.view` alone.
class CustomerMessagesPage extends StatelessWidget {
  const CustomerMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerMessagesCubit(getMessages: sl(), updateMessages: sl())..load(),
      child: const _CustomerMessagesView(),
    );
  }
}

class _CustomerMessagesView extends StatelessWidget {
  const _CustomerMessagesView();

  @override
  Widget build(BuildContext context) {
    return DismissKeyboard(
      child: Scaffold(
        appBar: AppBar(title: const Text('رسائل الزبائن')),
        body: BlocBuilder<CustomerMessagesCubit, CustomerMessagesState>(
          builder: (context, state) => switch (state) {
            CustomerMessagesLoading() => const Center(child: CircularProgressIndicator()),
            CustomerMessagesFailure(:final failure) => _Failure(message: failure.message),
            CustomerMessagesLoaded(:final messages) => _Form(
              // Keyed on the answer, so a save that comes back rebuilds the fields from it.
              key: ObjectKey(messages),
              messages: messages,
              canEdit: sl<Session>().can(AppPermission.manageCompanySettings),
            ),
          },
        ),
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: context.textTheme.bodyMedium),
            SizedBox(height: 16.h),
            AppButton(
              label: 'إعادة المحاولة',
              onPressed: () => context.read<CustomerMessagesCubit>().load(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.messages, required this.canEdit, super.key});

  final CustomerMessages messages;
  final bool canEdit;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final Map<String, TextEditingController> _controllers = {
    for (final message in widget.messages.messages)
      message.key: TextEditingController(text: message.body),
  };

  bool _saving = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    // A text equal to the built-in one, or left empty, is sent as null: the message then keeps
    // following the built-in wording instead of freezing today's copy of it.
    final bodies = <String, String?>{
      for (final message in widget.messages.messages)
        message.key: switch (_controllers[message.key]!.text) {
          final text when text.trim().isEmpty || text == message.defaultBody => null,
          final text => text,
        },
    };

    final failure = await context.read<CustomerMessagesCubit>().save(bodies);

    if (!mounted) return;

    setState(() => _saving = false);

    await showCustomSnackBar(
      context: context,
      title: failure?.message ?? 'تم حفظ رسائل الزبائن',
      type: failure == null ? SnackType.success : SnackType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      children: [
        Text(
          'اكتب ${widget.messages.placeholder} حيث تريد أن يظهر رقم الفاتورة.',
          style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: 16.h),
        for (final message in widget.messages.messages) ...[
          _MessageField(
            message: message,
            controller: _controllers[message.key]!,
            enabled: widget.canEdit && !_saving,
          ),
          SizedBox(height: 20.h),
        ],
        if (widget.canEdit) ...[
          SizedBox(height: 12.h),
          AppButton(label: 'حفظ', isLoading: _saving, onPressed: _saving ? null : _save),
        ],
      ],
    );
  }
}

class _MessageField extends StatelessWidget {
  const _MessageField({required this.message, required this.controller, required this.enabled});

  final CustomerMessageTemplate message;
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                message.label,
                style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (enabled)
              TextButton(
                onPressed: () => controller.text = message.defaultBody,
                child: const Text('استعادة النص الافتراضي'),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        AppTextField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          minLines: 4,
          maxLines: 10,
          maxLength: 2000,
        ),
      ],
    );
  }
}
