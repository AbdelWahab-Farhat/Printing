import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_snackbar.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/access/models/role.dart';
import 'package:dayaa/features/access/presentation/viewmodel/roles_cubit.dart';
import 'package:dayaa/features/notifications/usecases/send_announcement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// إشعار عام — the one screen in this application that writes to every phone at once.
///
/// **No drafts, no scheduling, no recall.** The backend offers none of the three, and a screen
/// that implied any of them would be lying about what pressing the button does.
///
/// The sender is excluded from their own announcement server-side, so a successful send shows a
/// confirmation here and **no new notification in their own bell**. That is correct, not a
/// refresh that failed.
class ComposeAnnouncementPage extends StatefulWidget {
  const ComposeAnnouncementPage({super.key});

  @override
  State<ComposeAnnouncementPage> createState() => _ComposeAnnouncementPageState();
}

class _ComposeAnnouncementPageState extends State<ComposeAnnouncementPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();

  late final RolesCubit _roles = sl<RolesCubit>()..load();

  /// Null means «الجميع» — which is both the default and the common case.
  Role? _audience;

  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _roles.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _roles,
      child: Scaffold(
        appBar: AppBar(title: const Text('إشعار عام')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppTextField(
                controller: _title,
                label: 'العنوان',
                maxLength: 100,
                validator: (value) =>
                    (value ?? '').trim().length < 2 ? 'اكتب عنواناً' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _body,
                label: 'النص',
                maxLines: 5,
                maxLength: 500,
                textInputAction: TextInputAction.newline,
                validator: (value) =>
                    (value ?? '').trim().length < 2 ? 'اكتب نص الإشعار' : null,
              ),
              const SizedBox(height: 12),
              BlocBuilder<RolesCubit, RolesState>(
                builder: (context, state) {
                  final roles = state is RolesLoaded ? state.roles : const <Role>[];

                  return AppDropdown<Role?>(
                    label: 'المستلمون',
                    value: _audience,
                    // The null entry is «الجميع» and sits first because it is the default.
                    items: <Role?>[null, ...roles],
                    labelOf: (role) => role?.label ?? 'الجميع',
                    keyOf: (role) => role?.id ?? -1,
                    onChanged: (role) => setState(() => _audience = role),
                  );
                },
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'إرسال',
                isLoading: _sending,
                // Disabled while in flight. The server throttles a rapid second send and answers
                // 429, but a double-tapped button should never reach that point.
                onPressed: _sending ? null : _confirmThenSend,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// **The confirmation is the feature, not friction.** This is the only action in the
  /// application that interrupts every employee at once, and it cannot be recalled — so the
  /// dialog names who is about to be interrupted.
  Future<void> _confirmThenSend() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final audience = _audience == null ? 'كل الموظفين' : 'دور «${_audience!.label}»';
    // `showDestructiveDialog` rather than the plain one: this cannot be undone, so the confirm
    // button carries the error colour and a tap outside will not dismiss it.
    final confirmed = await showDestructiveDialog(
      context: context,
      title: 'إرسال الإشعار؟',
      description: 'سيصل هذا إلى $audience، ولا يمكن التراجع عنه.',
      confirmLabel: 'إرسال',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _sending = true);

    final result = await sl<SendAnnouncement>()(
      title: _title.text.trim(),
      body: _body.text.trim(),
      roleId: _audience?.id,
    );
    if (!mounted) return;

    setState(() => _sending = false);

    await result.fold(
      // A 429 is a rapid second send, and `Failure` already carries the server's Arabic
      // sentence for it — relaying that is more use than a generic «تعذّر الإرسال».
      (failure) => showCustomSnackBar(
        context: context,
        title: failure.message,
        type: SnackType.error,
      ),
      (message) async {
        await showCustomSnackBar(
          context: context,
          title: message,
          type: SnackType.success,
        );
        if (mounted) context.pop();
      },
    );
  }
}
