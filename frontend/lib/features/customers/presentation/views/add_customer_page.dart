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
import 'package:printing/features/customers/usecases/create_customer.dart';

/// Register a customer: who they are, how to reach them, and where they sell from.
///
/// The form asks for everything `POST /customers` accepts, which is name, phone and any number
/// of shops. `is_active` is the one field left out on purpose: a customer being created is one
/// you have just started working with, the server defaults them to active, and a toggle that is
/// always left alone is a question the user has to read and answer for no reason.
///
/// **Shops are optional as a group and all-or-nothing as a row.** The API requires a name and
/// both coordinates for every shop it is given — a place the driver cannot find is not worth
/// recording — so a row that has been started must be finished or removed. That is what the
/// validators on each row enforce, before a round trip.
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

/// Stateful for one reason: it owns a [GlobalKey] and every [TextEditingController] on the
/// screen, including the ones that come and go with a shop row.
///
/// Those are widget-lifecycle resources, not application state — they must be disposed, and a
/// Cubit is not a disposal mechanism. Adding or removing a row is `setState` for the same
/// reason: it is the *form's* shape, not a decision about a customer. Everything that decides
/// anything lives in [AddCustomerCubit].
class _AddCustomerViewState extends State<_AddCustomerView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _shops = <_ShopFields>[];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    for (final shop in _shops) {
      shop.dispose();
    }
    super.dispose();
  }

  void _addShop() => setState(() => _shops.add(_ShopFields()));

  void _removeShop(int index) {
    // Disposed on the way out rather than left to `dispose()`: the row is gone from the tree
    // immediately, and a controller nobody will ever read again is a leak for as long as this
    // screen stays open.
    final removed = _shops.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  void _submit() {
    // Dismissed first so the button the user just pressed is not hidden behind the keyboard
    // while the request runs.
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    context.read<AddCustomerCubit>().submit(
      name: _name.text,
      phone: _phone.text,
      shops: [for (final shop in _shops) shop.toInput()],
    );
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
                // a snackbar would say the same thing twice. A complaint about a *shop* still
                // needs the toast: that row may be scrolled off the screen.
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
                        textInputAction: TextInputAction.next,
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
                      ),
                      SizedBox(height: 28.h),

                      _ShopsSection(
                        shops: _shops,
                        state: state,
                        onAdd: _addShop,
                        onRemove: _removeShop,
                        onChanged: () => context.read<AddCustomerCubit>().clearFailure(),
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

/// المحلات — none, one, or several.
class _ShopsSection extends StatelessWidget {
  const _ShopsSection({
    required this.shops,
    required this.state,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  final List<_ShopFields> shops;
  final AddCustomerState state;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(AppIcons.city, size: 18.sp, color: context.colorScheme.onSurfaceVariant),
            SizedBox(width: 8.w),
            Text(
              'المحلات',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              // Said once, here, rather than as a hint under every empty row.
              'اختياري',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          'المكان الذي يبيع منه العميل، وموقعه على الخريطة.',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 12.h),

        for (final (index, shop) in shops.indexed) ...[
          _ShopCard(
            key: ObjectKey(shop),
            index: index,
            fields: shop,
            state: state,
            onRemove: () => onRemove(index),
            onChanged: onChanged,
          ),
          SizedBox(height: 12.h),
        ],

        AppButton(
          label: shops.isEmpty ? 'إضافة محل' : 'إضافة محل آخر',
          variant: AppButtonVariant.outlined,
          icon: AppIcons.add,
          onPressed: onAdd,
        ),
      ],
    );
  }
}

/// One shop's four boxes, in a card that can be taken away again.
class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.index,
    required this.fields,
    required this.state,
    required this.onRemove,
    required this.onChanged,
    super.key,
  });

  final int index;
  final _ShopFields fields;
  final AddCustomerState state;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 16.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'محل ${index + 1}',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: Icon(AppIcons.delete, color: scheme.error),
                tooltip: 'حذف المحل',
              ),
            ],
          ),

          AppTextField(
            controller: fields.name,
            label: 'اسم المكان',
            hint: 'مثال: فرع سوق الجمعة',
            prefixIcon: AppIcons.city,
            validator: Validators.compose([
              Validators.required,
              Validators.maxLength(255, label: 'اسم المكان'),
            ]),
            errorText: state.shopError(index, 'name'),
            onChanged: (_) => onChanged(),
          ),
          SizedBox(height: 14.h),

          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: fields.latitude,
                  label: 'خط العرض',
                  hint: '32.8872',
                  textDirection: TextDirection.ltr,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  // Required, not `Validators.latitude`: that one is the optional flavour, and
                  // the API refuses a shop that is missing either half of its pin.
                  validator: Validators.decimal(min: -90, max: 90),
                  errorText: state.shopError(index, 'latitude'),
                  onChanged: (_) => onChanged(),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: AppTextField(
                  controller: fields.longitude,
                  label: 'خط الطول',
                  hint: '13.1913',
                  textDirection: TextDirection.ltr,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: Validators.decimal(min: -180, max: 180),
                  errorText: state.shopError(index, 'longitude'),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            // Says where the two numbers come from. Until a map picker lands, copying them out
            // of Google Maps is what people will actually do, and this is the difference
            // between that being obvious and being a support call.
            'انسخ الإحداثيات من خرائط جوجل: اضغط مطولاً على الموقع ثم انسخ الرقمين.',
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          SizedBox(height: 14.h),

          AppTextField(
            controller: fields.pageUrl,
            label: 'رابط الصفحة',
            hint: 'https://facebook.com/...',
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            // Optional, and only checked once something is in it — an empty box is a fact, not
            // a mistake.
            validator: Validators.optional(Validators.url),
            errorText: state.shopError(index, 'page_url'),
            onChanged: (_) => onChanged(),
          ),
        ],
      ),
    );
  }
}

/// The controllers behind one shop row, kept together so they are created and disposed as a
/// unit — a row is added and removed as one thing, and four loose controllers would be four
/// chances to forget one.
class _ShopFields {
  final name = TextEditingController();
  final latitude = TextEditingController();
  final longitude = TextEditingController();
  final pageUrl = TextEditingController();

  /// What the use case takes: text, exactly as typed. Nothing is parsed here — see
  /// [CreateCustomer], which is the one place in this feature that converts anything.
  ShopInput toInput() => (
    name: name.text,
    latitude: latitude.text,
    longitude: longitude.text,
    pageUrl: pageUrl.text,
  );

  void dispose() {
    name.dispose();
    latitude.dispose();
    longitude.dispose();
    pageUrl.dispose();
  }
}
