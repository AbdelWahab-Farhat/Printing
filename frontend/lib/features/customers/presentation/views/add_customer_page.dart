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
import 'package:printing/features/business_fields/models/business_field.dart';
import 'package:printing/features/business_fields/presentation/viewmodel/business_fields_cubit.dart';
import 'package:printing/features/business_fields/presentation/widgets/business_field_picker.dart';
import 'package:printing/features/cities/models/city.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/presentation/viewmodel/add_customer_cubit.dart';
import 'package:printing/features/customers/usecases/create_customer.dart';
import 'package:printing/features/orders/presentation/widgets/destination_picker_sheet.dart';
import 'package:printing/features/orders/presentation/widgets/place_picker_tile.dart';

/// Register a customer: who they are, how to reach them, and where they sell from.
///
/// The form asks for everything `POST /customers` accepts, which is name, phone and any number
/// of shops. `is_active` is the one field left out on purpose: a customer being created is one
/// you have just started working with, the server defaults them to active, and a toggle that is
/// always left alone is a question the user has to read and answer for no reason.
///
/// **Shops are optional as a group and all-or-nothing as a row.** The API requires a name and a
/// city for every shop it is given — a place nobody can put on the map is not worth recording —
/// so a row that has been started must be finished or removed. That is what the validators on
/// each row enforce, before a round trip.
class AddCustomerPage extends StatelessWidget {
  const AddCustomerPage({this.customer, super.key});

  /// The customer being edited, or null to register a new one.
  ///
  /// **One screen for both verbs, and that is not laziness.** The expensive parts of this file
  /// are not the two text boxes — they are the shop rows: a `FormField` wrapper so a chosen
  /// place can be validated, the picker round trip, the controller lifecycle, and the 422
  /// mapping that turns `shops.1.city_id` into an error on the second card. A separate edit
  /// screen means writing all of that twice and then keeping two copies of it in step.
  ///
  /// It also comes out right for free: the server *syncs* shops — a row with an id is updated,
  /// one without is created, one left out is deleted — so this editor's existing add-and-remove
  /// behaviour already **is** the update semantics.
  final Customer? customer;

  @override
  Widget build(BuildContext context) {
    // Created here rather than injected app-wide: the Cubit belongs to this screen and is
    // closed with it. A screen-scoped Cubit registered as a singleton keeps emitting into a
    // dead stream after the first customer is added.
    return MultiBlocProvider(
      providers: [
        // Created here rather than injected app-wide: the Cubit belongs to this screen and is
        // closed with it. A screen-scoped Cubit registered as a singleton keeps emitting into a
        // dead stream after the first customer is added.
        BlocProvider<AddCustomerCubit>(create: (_) => sl<AddCustomerCubit>()),
        // The «مجال العمل» list, loaded once for the whole form: three shop rows offer the same
        // trades, and one request answers all three. `active-only`, because a stopped trade is
        // one nobody should be able to pick today — a shop already on one keeps it, which
        // BusinessFieldPicker handles itself.
        BlocProvider<BusinessFieldsCubit>(
          create: (_) => sl<BusinessFieldsCubit>(instanceName: 'active-only')..load(),
        ),
      ],
      child: _AddCustomerView(customer: customer),
    );
  }
}

class _AddCustomerView extends StatefulWidget {
  const _AddCustomerView({this.customer});

  final Customer? customer;

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

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();

    final customer = widget.customer;
    if (customer == null) return;

    _name.text = customer.name;
    _phone.text = customer.phone;

    // Each existing shop keeps its id, which is what makes saving an *edit* rather than a
    // replacement: without it the server would delete all three and create three new ones,
    // and every order pointing at the old rows would be pointing at nothing.
    for (final shop in customer.shops ?? const []) {
      _shops.add(_ShopFields.from(shop));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    for (final shop in _shops) {
      shop.dispose();
    }
    super.dispose();
  }

  /// A new row, starting in the city of the row above it.
  ///
  /// Not an invented default: a customer with three shops nearly always has them in one city,
  /// and the value being copied is one the user chose seconds ago on this same screen — it is
  /// still on the card above, and one tap changes it. The neighbourhood is *not* inherited: two
  /// branches in Tripoli are two different districts far more often than not, and a wrong
  /// district that looks answered is worse than an empty one that asks.
  void _addShop() => setState(() {
    final fields = _ShopFields();
    fields.city = _shops.isEmpty ? null : _shops.last.city;
    _shops.add(fields);
  });

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
      customerId: widget.customer?.id,
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
      appBar: AppBar(title: Text(_isEditing ? 'تعديل بيانات العميل' : 'إضافة عميل')),
      body: SafeArea(
        child: BlocConsumer<AddCustomerCubit, AddCustomerState>(
          listener: (context, state) {
            switch (state) {
              case AddCustomerSuccess(:final customer):
                // The code is the server's answer and the number staff look the customer up by
                // afterwards, so it is read back rather than left to be discovered later.
                if (_isEditing) {
                  context.showSuccess('تم حفظ تعديلات ${customer.name}');
                } else {
                  // The code is the server's answer and the number staff look the customer up
                  // by afterwards, so a new one is read back rather than discovered later. An
                  // edit does not repeat it — it has not changed and cannot.
                  context.showSuccess(
                    'تم إضافة العميل ${customer.name}',
                    details: 'رمز العميل: ${customer.code}',
                  );
                }
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
                        label: _isEditing ? 'حفظ التعديلات' : 'إضافة العميل',
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
          'المكان الذي يبيع منه العميل، ومدينته والمنطقة التي يقع فيها.',
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

          // Right under the name, because it answers the same question the name only hints at:
          // «فرع سوق الجمعة» says where, and this says what they sell.
          BusinessFieldPicker(
            value: fields.businessFieldId,
            current: fields.businessField,
            errorText: state.shopError(index, 'business_field_id'),
            onChanged: (fieldId) {
              fields.businessFieldId = fieldId;
              onChanged();
            },
          ),
          SizedBox(height: 14.h),

          // A map pin used to live here — first as two number boxes to copy out of Google Maps,
          // then as a picker on a real map. Both asked the clerk to *find* a place they can
          // already name, so this asks for the name: the city, and the neighbourhood inside it.
          _ShopPlaceField(fields: fields, index: index, state: state, onChanged: onChanged),
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
/// unit — a row is added and removed as one thing, and loose controllers would be as many
/// chances to forget one.
/// Where the shop is: the city, and the neighbourhood inside it.
///
/// Wrapped in a [FormField] so `_formKey.currentState!.validate()` still governs it and
/// `_submit()` changes by not one line. A plain `Row` cannot be validated, and this is the
/// entire reason for the wrapper.
///
/// **Both sheets are the order screen's own.** `showCityPicker` and `showRegionPicker` are
/// searchable, paginated lists of the same delivery map an order is addressed from — writing a
/// second pair here would be two lists to keep in step with one API. The only difference this
/// caller asks for is `deliveryOnly`: our own branches are places to collect *from*, not places
/// a customer sells.
class _ShopPlaceField extends StatefulWidget {
  const _ShopPlaceField({
    required this.fields,
    required this.index,
    required this.state,
    required this.onChanged,
  });

  final _ShopFields fields;
  final int index;
  final AddCustomerState state;
  final VoidCallback onChanged;

  @override
  State<_ShopPlaceField> createState() => _ShopPlaceFieldState();
}

class _ShopPlaceFieldState extends State<_ShopPlaceField> {
  Future<void> _pickCity(FormFieldState<void> field) async {
    final city = await showCityPicker(
      context: context,
      selectedId: widget.fields.city?.id,
      deliveryOnly: true,
    );

    if (city == null || !mounted) return;

    setState(() {
      widget.fields.city = city;
      // The neighbourhood belonged to the previous city. Keeping it would send the server a
      // pair it refuses — and rightly: «طرابلس / سوق الخميس الزاوية» is not a place.
      widget.fields.region = null;
    });

    field.didChange(null);
    widget.onChanged();
  }

  Future<void> _pickRegion() async {
    final city = widget.fields.city;

    if (city == null) {
      context.showInfo('اختر المدينة أولاً');

      return;
    }

    final region = await showRegionPicker(
      context: context,
      cityId: city.id,
      selectedId: widget.fields.region?.id,
    );

    if (region == null || !mounted) return;

    setState(() => widget.fields.region = region);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final city = widget.fields.city;

    return FormField<void>(
      validator: (_) => widget.fields.city == null ? 'اختر مدينة المحل' : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: PlacePickerTile(
                  caption: 'المدينة',
                  value: city?.name ?? 'مطلوبة',
                  isChosen: city != null,
                  onTap: () => _pickCity(field),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                // Shown only when there is something to choose. A city with no neighbourhoods
                // opens an empty sheet, and a tile that leads to nothing is worse than no tile:
                // `regionsCount` comes from the list endpoint, so this costs no request.
                child: city == null || city.hasRegions
                    ? PlacePickerTile(
                        caption: 'المنطقة',
                        value: widget.fields.region?.name ?? 'اختياري',
                        isChosen: widget.fields.region != null,
                        onTap: _pickRegion,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),

          // The form's own complaint and the server's, in that order — they cannot both be
          // wrong about the same field at the same time, and `city_id` is the one the API
          // names when a stale id from a cached map is sent.
          if (field.hasError || widget.state.shopError(widget.index, 'city_id') != null) ...[
            SizedBox(height: 6.h),
            Text(
              field.errorText ?? widget.state.shopError(widget.index, 'city_id')!,
              style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShopFields {
  _ShopFields();

  /// Seeds a row from a shop the server already has, id included.
  factory _ShopFields.from(CustomerShop shop) {
    final fields = _ShopFields()
      ..id = shop.id
      ..businessFieldId = shop.businessFieldId
      // Kept whole, not just its id: it is what keeps a trade that is no longer offered
      // selectable on the shop that is already recorded under it.
      ..businessField = shop.businessField
      // Whole for the same reason the trade is: the tile shows a name, and holding only the id
      // would mean fetching the map to render a row the server already described.
      ..city = shop.city
      ..region = shop.region;
    fields.name.text = shop.name;
    fields.pageUrl.text = shop.pageUrl ?? '';

    return fields;
  }

  final name = TextEditingController();
  final pageUrl = TextEditingController();

  /// Null id for a row the user just added. An existing shop keeps its id so the server updates
  /// it instead of deleting it and creating a new one.
  int? id;

  /// مجال العمل as picked, or null for «غير محدد». Not a controller: it comes from a list, so
  /// there is no text to hold and nothing to dispose.
  int? businessFieldId;

  /// The trade this shop arrived with, kept so the picker can still offer it after the business
  /// stops offering it to everybody else.
  BusinessField? businessField;

  /// المدينة والمنطقة as picked. Not controllers either, and for a stronger reason than the
  /// trade: these are only ever *chosen*, never typed, so there is no text state for the two of
  /// them to disagree about.
  City? city;
  Region? region;

  /// What the use case takes. The city is non-null by the time this is called: `_submit()` runs
  /// the form's validators first, and the place field refuses a row without one.
  ShopInput toInput() => (
    id: id,
    name: name.text,
    cityId: city!.id,
    regionId: region?.id,
    pageUrl: pageUrl.text,
    businessFieldId: businessFieldId,
  );

  void dispose() {
    name.dispose();
    pageUrl.dispose();
  }
}
