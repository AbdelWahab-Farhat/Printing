import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/vendors/models/vendor.dart';
import 'package:dayaa/features/vendors/presentation/viewmodel/save_vendor_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Adding a supplier, or correcting one.
///
/// **One screen for both**, because it is one form: the only difference is whether a vendor
/// arrived with it.
///
/// **The activation switch is not part of the form, and that is the API's rule showing through.**
/// A save cannot carry `is_active` — it is its own endpoint — so retiring a supplier is its own
/// button here, taking effect the moment it is pressed rather than waiting on «حفظ». That is the
/// honest shape: "I corrected their phone number" and "I stopped dealing with them" are two
/// decisions, and one of them is the kind somebody should not make by accident while editing.
class VendorFormPage extends StatelessWidget {
  const VendorFormPage({this.vendor, super.key});

  /// Null adds a new supplier; anything else corrects that one.
  final Vendor? vendor;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SaveVendorCubit>(
      create: (_) => sl<SaveVendorCubit>(),
      child: _VendorFormView(vendor: vendor),
    );
  }
}

class _VendorFormView extends StatefulWidget {
  const _VendorFormView({this.vendor});

  final Vendor? vendor;

  @override
  State<_VendorFormView> createState() => _VendorFormViewState();
}

class _VendorFormViewState extends State<_VendorFormView> {
  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.vendor?.name ?? '');
  late final _phone = TextEditingController(text: widget.vendor?.phone ?? '');
  late final _contact = TextEditingController(
    text: widget.vendor?.contactPerson ?? '',
  );
  late final _email = TextEditingController(text: widget.vendor?.email ?? '');
  late final _address = TextEditingController(
    text: widget.vendor?.address ?? '',
  );

  /// The vendor as it now stands — replaced whenever the server answers, so the switch below
  /// reflects what was actually written rather than what was tapped.
  late Vendor? _vendor = widget.vendor;

  bool get _isEditing => _vendor != null;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _contact.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<SaveVendorCubit>().submit(
      id: _vendor?.id,
      name: _name.text,
      phone: _phone.text,
      contactPerson: _contact.text,
      email: _email.text,
      address: _address.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SaveVendorCubit, SaveVendorState>(
      listener: (context, state) {
        switch (state) {
          case SaveVendorSuccess(:final vendor):
            // An activation stays on the screen — the switch has just moved and the user is
            // looking at it — while a save is the end of the errand and leaves.
            final wasActivation =
                _isEditing && vendor.isActive != _vendor!.isActive;

            setState(() => _vendor = vendor);

            if (wasActivation) {
              context.showSuccess(
                vendor.isActive
                    ? 'تم تنشيط «${vendor.name}»'
                    : 'تم إيقاف التعامل مع «${vendor.name}»',
              );

              return;
            }

            // The saved supplier goes back with it, so the screen behind redraws its row from
            // what the server stored rather than asking for it again. A dismissed form returns
            // nothing, and nothing behind it moves.
            Navigator.of(context).pop(vendor);
            context.showSuccess(
              _isEditing
                  ? 'تم تحديث «${vendor.name}»'
                  : 'تمت إضافة «${vendor.name}»',
            );

          case SaveVendorFailure(:final failure) when state.hasUnrenderedErrors:
            context.showFailure(failure);

          case _:
            break;
        }
      },
      builder: (context, state) {
        final cubit = context.read<SaveVendorCubit>();

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'تعديل المورد' : 'مورد جديد'),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
                children: [
                  AppTextField(
                    controller: _name,
                    label: 'اسم المورد',
                    hint: 'اسم الشركة أو المصنع',
                    prefixIcon: AppIcons.warehouse,
                    autofocus: !_isEditing,
                    validator: Validators.compose([
                      Validators.required,
                      Validators.minLength(2, label: 'اسم المورد'),
                      Validators.maxLength(255, label: 'اسم المورد'),
                    ]),
                    errorText: state.nameError,
                    onChanged: (_) => cubit.clearFailure(),
                  ),
                  SizedBox(height: 16.h),

                  AppTextField(
                    controller: _phone,
                    label: 'رقم الهاتف',
                    prefixIcon: AppIcons.phone,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    // Required, unlike a carrier's: it is the supplier's only unique mark, and
                    // the server refuses two vendors sharing one.
                    validator: Validators.required,
                    errorText: state.phoneError,
                    onChanged: (_) => cubit.clearFailure(),
                  ),
                  SizedBox(height: 16.h),

                  AppTextField(
                    controller: _contact,
                    label: 'الشخص المسؤول (اختياري)',
                    hint: 'من نتكلم معه في الشركة',
                    prefixIcon: AppIcons.person,
                    onChanged: (_) => cubit.clearFailure(),
                  ),
                  SizedBox(height: 16.h),

                  AppTextField(
                    controller: _email,
                    label: 'البريد الإلكتروني (اختياري)',
                    prefixIcon: AppIcons.email,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    errorText: state.emailError,
                    onChanged: (_) => cubit.clearFailure(),
                  ),
                  SizedBox(height: 16.h),

                  AppTextField(
                    controller: _address,
                    label: 'العنوان (اختياري)',
                    prefixIcon: AppIcons.mapPin,
                    maxLines: 2,
                    onChanged: (_) => cubit.clearFailure(),
                  ),

                  // Only once the vendor exists: there is nothing to switch off before it does,
                  // and a new supplier is one we are about to buy from.
                  if (_vendor case final vendor?) ...[
                    SizedBox(height: 8.h),
                    SwitchListTile.adaptive(
                      value: vendor.isActive,
                      // Locked while any request is in flight, so the switch cannot be flicked
                      // twice into a race whose loser wins.
                      onChanged: state.isSubmitting
                          ? null
                          : (value) =>
                                cubit.setActive(vendor.id, isActive: value),
                      title: const Text('نتعامل معه'),
                      // Said out loud, because "off" is not "deleted" — and this switch takes
                      // effect at once rather than on «حفظ», which is worth knowing before
                      // it is touched.
                      subtitle: const Text(
                        'يُطبَّق فوراً. إن أُطفئ لم يُعرض عند إنشاء أمر شراء، وتبقى أوامره السابقة كما هي',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                  SizedBox(height: 28.h),

                  AppButton(
                    label: _isEditing ? 'حفظ التعديلات' : 'إضافة المورد',
                    isLoading: state.isSubmitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
