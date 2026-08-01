import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/validators.dart';
import 'package:printing/core/widgets/app_button.dart';
import 'package:printing/core/widgets/app_text_field.dart';
import 'package:printing/features/customers/presentation/viewmodel/add_customer_cubit.dart';

/// Register a customer: a name and a number, and they exist.
///
/// The form asks for the two things the API requires and nothing else. `is_active` is not here
/// because a customer being created is one you have just started working with — the server
/// defaults them to active, and a toggle that is always left alone is a question the user has
/// to read and answer for no reason.
class AddCustomerPage extends StatelessWidget {
  const AddCustomerPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Created here rather than injected app-wide: the Cubit belongs to this screen and is
    // closed with it. A screen-scoped Cubit registered as a singleton keeps emitting into a
    // dead stream after the first customer is added.
    return BlocProvider<AddCustomerCubit>(
      create: (_) => sl<AddCustomerCubit>(),
      child: const _AddCustomerView(),
    );
  }
}

class _AddCustomerView extends StatefulWidget {
  const _AddCustomerView();

  @override
  State<_AddCustomerView> createState() => _AddCustomerViewState();
}

/// Stateful for one reason: it owns a [GlobalKey] and two [TextEditingController]s.
///
/// Those are widget-lifecycle resources, not application state — they must be disposed, and a
/// Cubit is not a disposal mechanism. Everything that decides anything lives in
/// [AddCustomerCubit].
class _AddCustomerViewState extends State<_AddCustomerView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    // Dismissed first so the button the user just pressed is not hidden behind the keyboard
    // while the request runs.
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    context.read<AddCustomerCubit>().submit(name: _name.text, phone: _phone.text);
  }

  /// Back to wherever this was opened from. `canPop` because the screen has its own route: a
  /// deep link straight to it has nothing beneath to return to, and `pop` on an empty stack
  /// leaves the user on a dead end.
  void _leave(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(Routes.home);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة عميل')),
      body: SafeArea(
        child: BlocConsumer<AddCustomerCubit, AddCustomerState>(
          listener: (context, state) {
            switch (state) {
              case AddCustomerSuccess(:final customer):
                // The code is the server's answer and the number staff look the customer up by
                // afterwards, so it is read back rather than left to be discovered later.
                context.showSuccess(
                  'تم إضافة العميل ${customer.name}',
                  details: 'رمز العميل: ${customer.code}',
                );
                _leave(context);

              case AddCustomerFailure(:final failure):
                // Field-level errors are rendered under their inputs, so showing them again in
                // a snackbar would say the same thing twice.
                if (state.nameError == null && state.phoneError == null) {
                  context.showFailure(failure);
                }

              default:
                break;
            }
          },
          builder: (context, state) {
            final isSubmitting = state.isSubmitting;

            return AbsorbPointer(
              // Locks the whole form while the request is in flight — including the fields, so
              // what is on screen always matches what was sent.
              absorbing: isSubmitting,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 32.h),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _name,
                        label: 'اسم العميل',
                        hint: 'مثال: مطبعة النور',
                        prefixIcon: AppIcons.person,
                        autofocus: true,
                        validator: Validators.compose([
                          Validators.minLength(2, label: 'اسم العميل'),
                          Validators.maxLength(255, label: 'اسم العميل'),
                        ]),
                        errorText: state.nameError,
                        onChanged: (_) => context.read<AddCustomerCubit>().clearFailure(),
                      ),
                      SizedBox(height: 18.h),

                      AppTextField(
                        controller: _phone,
                        label: 'رقم الهاتف',
                        hint: '09XXXXXXXX',
                        helperText: 'رقم واحد لا يتكرر بين عميلين',
                        prefixIcon: AppIcons.phone,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        // A phone number is digits: anything else is a typo, so the keyboard
                        // refuses it rather than the form complaining afterwards. Fifteen, not
                        // ten — the API's ceiling, wide enough for a landline.
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                        // Latin digits read left-to-right even inside this RTL form.
                        textDirection: TextDirection.ltr,
                        validator: Validators.contactPhone,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        // The server's own complaint about this field — "مستخدم مسبقاً لعميل
                        // آخر" is the one that actually happens.
                        errorText: state.phoneError,
                        onChanged: (_) => context.read<AddCustomerCubit>().clearFailure(),
                        onSubmitted: (_) => _submit(),
                      ),
                      SizedBox(height: 32.h),

                      // `isLoading`, not `onPressed: null`: the button keeps its colour and
                      // shows the wait inside itself instead of greying out halfway through
                      // the request. Refusing the tap is its own job.
                      AppButton(
                        label: 'إضافة العميل',
                        isLoading: isSubmitting,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
