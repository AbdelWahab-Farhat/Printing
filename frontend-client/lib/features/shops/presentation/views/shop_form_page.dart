import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/validators.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_dropdown.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:dayaa_client/features/delivery/models/city.dart';
import 'package:dayaa_client/features/shops/models/shop.dart';
import 'package:dayaa_client/features/shops/presentation/viewmodel/shop_form_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «متجر جديد» و«تعديل المتجر» — شاشةٌ واحدة، و[editing] يقرّر الفعل.
///
/// **حقول بطاقة المحل في تطبيق الموظفين، بترتيبها وأسمائها:** اسم المكان، ثم مجال العمل تحته لأنه
/// يجيب عمّا يلمّح إليه الاسم، ثم المدينة والمنطقة، ثم رابط الصفحة. كي يرى العميل متجره كما يراه من
/// يسجّله له.
///
/// تعيد المتجر المحفوظ لمن فتحها — «متاجري» تضعه في مكانه، وصفحة المتجر تعرضه.
class ShopFormPage extends StatelessWidget {
  const ShopFormPage({this.editing, super.key});

  final Shop? editing;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ShopFormCubit>(
      create: (_) => sl<ShopFormCubit>(param1: editing)..load(),
      child: _ShopFormView(editing: editing),
    );
  }
}

class _ShopFormView extends StatefulWidget {
  const _ShopFormView({required this.editing});

  final Shop? editing;

  @override
  State<_ShopFormView> createState() => _ShopFormViewState();
}

/// ذات حالةٍ من أجل المتحكّمَين وحدهما: الكتابة هنا، والاختيارات في الـ Cubit.
class _ShopFormViewState extends State<_ShopFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.editing?.name);
  late final _pageUrl = TextEditingController(text: widget.editing?.pageUrl);

  bool get _isEditing => widget.editing != null;

  @override
  void dispose() {
    _name.dispose();
    _pageUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final shop = await context.read<ShopFormCubit>().save(
      name: _name.text,
      pageUrl: _pageUrl.text,
    );

    if (!mounted || shop == null) return;

    context.showSuccess(_isEditing ? 'تم تعديل المتجر' : 'تمت إضافة المتجر');
    context.pop(shop);
  }

  @override
  Widget build(BuildContext context) {
    final title = Text(_isEditing ? 'تعديل المتجر' : 'متجر جديد');

    return BlocConsumer<ShopFormCubit, ShopFormState>(
      // ما له حقلٌ يُعلَّق تحته، وما تبقّى رسالة — ولا شيء منه يُبتلع.
      listenWhen: (previous, current) => current.hasUnplacedFailure,
      listener: (context, state) {
        if (state case ShopFormReady(:final lastFailure?)) context.showFailure(lastFailure);
      },
      builder: (context, state) => switch (state) {
        ShopFormLoading() => Scaffold(
          appBar: AppBar(title: title),
          body: const Center(child: CircularProgressIndicator()),
        ),
        ShopFormFailure(:final failure) => Scaffold(
          appBar: AppBar(title: title),
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(failure.message, textAlign: TextAlign.center),
                  SizedBox(height: 16.h),
                  AppButton.outlined(
                    label: 'أعد المحاولة',
                    onPressed: context.read<ShopFormCubit>().load,
                  ),
                ],
              ),
            ),
          ),
        ),
        final ShopFormReady ready => Scaffold(
          appBar: AppBar(title: title),
          body: AbsorbPointer(
            absorbing: ready.isSaving,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                children: [
                  AppTextField(
                    controller: _name,
                    label: 'اسم المكان',
                    hint: 'مثال: فرع سوق الجمعة',
                    prefixIcon: AppIcons.shops,
                    validator: Validators.compose([
                      Validators.required,
                      Validators.maxLength(255, label: 'اسم المكان'),
                    ]),
                    errorText: ready.nameError,
                  ),
                  SizedBox(height: 16.h),

                  // تحت الاسم مباشرةً، لأنه يجيب عمّا يلمّح إليه الاسم: «فرع سوق الجمعة» يقول أين،
                  // وهذا يقول ماذا يبيعون. واختياريٌّ صراحةً: متجرٌ بلا مجالٍ متجرٌ حقيقي.
                  AppDropdown<BusinessField>(
                    label: 'مجال العمل',
                    prefixIcon: AppIcons.businessField,
                    items: ready.businessFields,
                    value: ready.selectedBusinessField,
                    keyOf: (field) => field.id,
                    labelOf: (field) => field.name,
                    placeholder: 'غير محدد',
                    onChanged: (field) =>
                        context.read<ShopFormCubit>().chooseBusinessField(field?.id),
                    errorText: ready.businessFieldError,
                  ),
                  SizedBox(height: 16.h),

                  _PlaceFields(state: ready),
                  SizedBox(height: 16.h),

                  AppTextField(
                    controller: _pageUrl,
                    label: 'رابط الصفحة',
                    hint: 'https://facebook.com/...',
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    // اختياري، ولا يُفحص إلا حين يُكتب فيه شيء: الخانة الفارغة جوابٌ لا خطأ.
                    validator: Validators.optional(Validators.url),
                    errorText: ready.pageUrlError,
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
              child: AppButton(
                label: _isEditing ? 'احفظ التعديل' : 'أضف المتجر',
                isLoading: ready.isSaving,
                onPressed: ready.canSave ? _save : null,
              ),
            ),
          ),
        ),
      },
    );
  }
}

/// أين المتجر: **المدينة والمنطقة جنباً إلى جنب، والصندوقان ظاهران دائماً** (طلب صاحب العمل) — كصفّهما
/// في السلة، فلا يتبدّل شكل الصفّ كلما تبدّلت المدينة.
///
/// بلا أيقونتين، كما في السلة: نصف العرض لا يتّسع لأيقونةٍ وسهمٍ ومعهما «اختر المدينة أولاً»، والعنوان
/// فوق كل صندوقٍ يقول ما هو.
class _PlaceFields extends StatelessWidget {
  const _PlaceFields({required this.state});

  final ShopFormReady state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ShopFormCubit>();
    final city = state.selectedCity;

    Region? region;
    for (final candidate in city?.regions ?? const <Region>[]) {
      if (candidate.id == state.regionId) region = candidate;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppDropdown<City>(
            label: 'المدينة',
            items: state.cities,
            value: city,
            keyOf: (option) => option.id,
            labelOf: (option) => option.name,
            onChanged: (option) => option == null ? null : cubit.chooseCity(option.id),
            validator: (option) => option == null ? 'اختر المدينة' : null,
            errorText: state.cityError,
          ),
        ),

        SizedBox(width: 12.w),

        // تُفتح حين يكون للمدينة مناطق، وتقول لماذا هي فارغة حين لا.
        Expanded(
          child: AppDropdown<Region>(
            // مفتاحٌ بالمدينة: منتقٍ بُني لمدينةٍ لا يُعاد استعماله لغيرها بقيمةٍ من هناك.
            key: ValueKey('shop-region-${city?.id}'),
            // «المنطقة» وحدها: «(اختياري)» في نصف العرض تنزل إلى سطرٍ ثانٍ فيهبط صندوقها عن صندوق
            // المدينة، وخيار «بدون تحديد» يقول ذلك أصلاً.
            label: 'المنطقة',
            items: city?.regions ?? const <Region>[],
            value: region,
            keyOf: (option) => option.id,
            labelOf: (option) => option.name,
            enabled: city != null && city.regions.isNotEmpty,
            hint: switch (city) {
              null => 'اختر المدينة أولاً',
              City(regions: []) => 'لا توجد مناطق',
              _ => 'اختر المنطقة',
            },
            placeholder: city == null || city.regions.isEmpty || city.needsRegion
                ? null
                : 'بدون تحديد',
            onChanged: (option) => cubit.chooseRegion(option?.id),
            validator: (option) =>
                (city?.needsRegion ?? false) && option == null ? 'اختر المنطقة' : null,
            errorText: state.regionError,
          ),
        ),
      ],
    );
  }
}
