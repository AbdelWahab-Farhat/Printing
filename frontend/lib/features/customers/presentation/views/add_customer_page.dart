import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
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

          // Two number fields and an instruction to copy them out of Google Maps used to live
          // here. Nobody does that, so what it really produced was shops with no pin at all.
          _ShopLocationField(fields: fields, onChanged: onChanged),
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
/// The shop's pin: a row that opens the map, and a way out if the map will not load.
///
/// Wrapped in a [FormField] so `_formKey.currentState!.validate()` still governs it and
/// `_submit()` changes by not one line. A plain `Container` cannot be validated, and this is the
/// entire reason for the wrapper.
///
/// **The two controllers are unchanged.** The picker writes `32.887200` into the same
/// `TextEditingController`s the number fields wrote into, so `_ShopFields.toInput()`,
/// `CreateCustomer`, `NewCustomerShop`, the request body and every existing customer test are
/// untouched by this screen changing completely.
class _ShopLocationField extends StatefulWidget {
  const _ShopLocationField({required this.fields, required this.onChanged});

  final _ShopFields fields;
  final VoidCallback onChanged;

  @override
  State<_ShopLocationField> createState() => _ShopLocationFieldState();
}

class _ShopLocationFieldState extends State<_ShopLocationField> {
  /// Reveals the two number fields again.
  ///
  /// Not a leftover: with no connection the map is a blank grid that still pans and still
  /// answers, so typing two numbers read off somebody else's phone is the honest fallback.
  bool _isManual = false;

  String get _latitude => widget.fields.latitude.text.trim();

  String get _longitude => widget.fields.longitude.text.trim();

  bool get _hasPin => _latitude.isNotEmpty && _longitude.isNotEmpty;

  LatLng? get _point {
    final latitude = double.tryParse(Validators.toWesternDigits(_latitude));
    final longitude = double.tryParse(Validators.toWesternDigits(_longitude));

    if (latitude == null || longitude == null) return null;

    return LatLng(latitude, longitude);
  }

  Future<void> _pick(FormFieldState<void> field) async {
    final picked = await context.push<LatLng>(Routes.pickLocation, extra: _point);
    if (picked == null || !mounted) return;

    setState(() {
      // Six decimals — the column is decimal(10,7), and six is about a tenth of a metre.
      widget.fields.latitude.text = picked.latitude.toStringAsFixed(6);
      widget.fields.longitude.text = picked.longitude.toStringAsFixed(6);
    });

    field.didChange(null);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return FormField<void>(
      validator: (_) {
        if (!_hasPin) return 'حدّد موقع المحل على الخريطة';

        return Validators.decimal(min: -90, max: 90)(_latitude) ??
            Validators.decimal(min: -180, max: 180)(_longitude);
      },
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14.r),
            child: InkWell(
              onTap: () => _pick(field),
              borderRadius: BorderRadius.circular(14.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18.r,
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(
                        AppIcons.mapPin,
                        size: 20.sp,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الموقع على الخريطة',
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            _hasPin ? '$_latitude, $_longitude' : 'لم يُحدَّد',
                            textDirection: _hasPin ? TextDirection.ltr : null,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _hasPin ? 'تعديل' : 'تحديد',
                      style: context.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (field.hasError) ...[
            SizedBox(height: 6.h),
            Text(
              field.errorText!,
              style: context.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ],

          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => setState(() => _isManual = !_isManual),
              child: Text(_isManual ? 'إخفاء الإدخال اليدوي' : 'إدخال الإحداثيات يدوياً'),
            ),
          ),

          if (_isManual)
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: widget.fields.latitude,
                    label: 'خط العرض',
                    hint: '32.8872',
                    textDirection: TextDirection.ltr,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    // The existing validator, unchanged — it already accepts Arabic-Indic
                    // digits and the Arabic decimal mark. No second coordinate parser.
                    validator: Validators.decimal(min: -90, max: 90),
                    onChanged: (_) {
                      field.didChange(null);
                      widget.onChanged();
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: AppTextField(
                    controller: widget.fields.longitude,
                    label: 'خط الطول',
                    hint: '13.1913',
                    textDirection: TextDirection.ltr,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: Validators.decimal(min: -180, max: 180),
                    onChanged: (_) {
                      field.didChange(null);
                      widget.onChanged();
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

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
