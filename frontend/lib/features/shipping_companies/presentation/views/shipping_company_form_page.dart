import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/shipping_companies/models/shipping_company.dart';
import 'package:dayaa/features/shipping_companies/presentation/viewmodel/save_shipping_company_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Adding a carrier, or correcting one.
///
/// **One screen for both**, because it is one form: the only difference is whether a company
/// arrived with it. Two screens would have meant the same four boxes and the same trimming
/// written twice, and one of the two would eventually have been the one that got fixed.
class ShippingCompanyFormPage extends StatelessWidget {
  const ShippingCompanyFormPage({this.company, super.key});

  /// Null adds a new company; anything else corrects that one.
  final ShippingCompany? company;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SaveShippingCompanyCubit>(
      create: (_) => sl<SaveShippingCompanyCubit>(),
      child: _ShippingCompanyFormView(company: company),
    );
  }
}

class _ShippingCompanyFormView extends StatefulWidget {
  const _ShippingCompanyFormView({this.company});

  final ShippingCompany? company;

  @override
  State<_ShippingCompanyFormView> createState() => _ShippingCompanyFormViewState();
}

class _ShippingCompanyFormViewState extends State<_ShippingCompanyFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name =
      TextEditingController(text: widget.company?.name ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: widget.company?.phone ?? '');
  late final TextEditingController _notes =
      TextEditingController(text: widget.company?.notes ?? '');

  late bool _isActive = widget.company?.isActive ?? true;

  bool get _isEditing => widget.company != null;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<SaveShippingCompanyCubit>().submit(
      id: widget.company?.id,
      name: _name.text,
      phone: _phone.text,
      notes: _notes.text,
      isActive: _isActive,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SaveShippingCompanyCubit, SaveShippingCompanyState>(
      listener: (context, state) {
        switch (state) {
          case SaveShippingCompanySuccess(:final company):
            // The saved company goes back with it, so the list behind redraws that one row from
            // what the server stored rather than re-reading the page. A dismissed form returns
            // nothing, and the list does not move.
            Navigator.of(context).pop(company);
            context.showSuccess(
              _isEditing ? 'تم تحديث «${company.name}»' : 'تمت إضافة «${company.name}»',
            );
          case SaveShippingCompanyFailure(:final failure) when state.hasUnrenderedErrors:
            context.showFailure(failure);
          case _:
            break;
        }
      },
      builder: (context, state) {
        final cubit = context.read<SaveShippingCompanyCubit>();

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'تعديل شركة التوصيل' : 'شركة توصيل جديدة'),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
                children: [
                  AppTextField(
                    controller: _name,
                    label: 'اسم الشركة',
                    hint: 'مثال: درب',
                    prefixIcon: AppIcons.warehouse,
                    autofocus: !_isEditing,
                    validator: Validators.compose([
                      Validators.minLength(2, label: 'اسم الشركة'),
                      Validators.maxLength(100, label: 'اسم الشركة'),
                    ]),
                    errorText: state.nameError,
                    onChanged: (_) => cubit.clearFailure(),
                  ),
                  SizedBox(height: 16.h),

                  AppTextField(
                    controller: _phone,
                    label: 'رقم الهاتف (اختياري)',
                    prefixIcon: AppIcons.phone,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    errorText: state.phoneError,
                    onChanged: (_) => cubit.clearFailure(),
                  ),
                  SizedBox(height: 16.h),

                  AppTextField(
                    controller: _notes,
                    label: 'ملاحظات (اختياري)',
                    prefixIcon: AppIcons.edit,
                    maxLines: 3,
                    onChanged: (_) => cubit.clearFailure(),
                  ),
                  SizedBox(height: 8.h),

                  SwitchListTile.adaptive(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    title: const Text('نتعامل معها'),
                    // Said out loud, because "off" is not "deleted" and the difference is the
                    // whole reason this switch exists rather than a bin.
                    subtitle: const Text('إن أُطفئت لم تُعرض عند إرسال طلبية، وتبقى في الطلبيات السابقة'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SizedBox(height: 28.h),

                  AppButton(
                    label: _isEditing ? 'حفظ التعديلات' : 'إضافة الشركة',
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
