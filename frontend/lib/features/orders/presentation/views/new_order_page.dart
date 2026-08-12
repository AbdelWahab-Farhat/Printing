import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/permissions/app_permission.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/app_button.dart';
import 'package:printing/core/widgets/app_text_field.dart';
import 'package:printing/features/cities/models/city.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/models/customer_design.dart';
import 'package:printing/features/customers/presentation/viewmodel/customer_detail_cubit.dart';
import 'package:printing/features/customers/presentation/widgets/design_thumbnail.dart';
import 'package:printing/features/orders/presentation/viewmodel/line_quote_cubit.dart';
import 'package:printing/features/orders/presentation/viewmodel/take_order_cubit.dart';
import 'package:printing/features/orders/presentation/widgets/design_picker_sheet.dart';
import 'package:printing/features/orders/presentation/widgets/destination_picker_sheet.dart';
import 'package:printing/features/orders/presentation/widgets/order_line_row.dart';
import 'package:printing/features/orders/presentation/widgets/place_picker_tile.dart';
import 'package:printing/features/orders/presentation/widgets/product_picker_sheet.dart';
import 'package:printing/features/orders/usecases/take_order.dart';

/// طلبية جديدة — taking an order for a customer already known.
///
/// **The customer is read, never chosen.** This screen is only ever opened from inside one, and
/// there is no field here to name another: `customer_id` is read on create and ignored on
/// update, so the only correction for the wrong customer is to cancel the order and take it
/// again. A form that cannot name a customer cannot name the wrong one — the whole reason
/// «طلبية جديدة» lives on the customer's screen. See NEW-ORDER-DESIGN.md §١.
///
/// **No price is typed here** — except for the one category the catalogue prices «حسب الطلب».
/// A quantity is asked about as it is typed and the server answers; the total under the lines
/// is an estimate and says so, because the numbers that count are the ones that come back with
/// the order.
///
/// **The artwork is attached here, and that reverses an earlier decision.** It used to be a
/// second request against an order that already existed — see NEW-ORDER-DESIGN.md §٧ س٣, and the
/// revision under it. The reason was that `POST /orders` took no designs; the reason that
/// mattered was that an order still «جديدة» could not hold one at all, so the customer who
/// walked in with their finished file had it recorded by sending the order to the designer's
/// queue and pulling it straight back out. Both halves are gone: «جديدة» accepts artwork, and
/// the ids ride along with the order in one transaction — a file belonging to somebody else
/// refuses the order rather than leaving one behind without it.
class NewOrderPage extends StatelessWidget {
  const NewOrderPage({required this.customerId, this.customer, super.key});

  final int customerId;

  /// The customer the caller was already looking at, so the form opens with their name in place
  /// instead of a spinner. Null on a cold deep link, where it is fetched.
  final Customer? customer;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CustomerDetailCubit>(
          // Loaded even when `customer` was handed over: the shops decide whether that section
          // exists at all, and the caller may have been holding a customer without them.
          create: (_) => sl<CustomerDetailCubit>(param1: customerId)..load(),
        ),
        BlocProvider<TakeOrderCubit>(
          create: (_) => sl<TakeOrderCubit>(param1: customerId),
        ),
      ],
      child: _NewOrderView(fallback: customer),
    );
  }
}

class _NewOrderView extends StatefulWidget {
  const _NewOrderView({this.fallback});

  final Customer? fallback;

  @override
  State<_NewOrderView> createState() => _NewOrderViewState();
}

class _NewOrderViewState extends State<_NewOrderView> {
  /// **The form owns its draft**, as every other form in this app does: controllers are
  /// widget-lifecycle resources that must be disposed, and a Cubit is not a disposal mechanism.
  /// What the Cubit holds is the one fact this form must not be able to change — the customer.
  final List<OrderLineDraft> _lines = [];

  final TextEditingController _designFee = TextEditingController();
  final TextEditingController _discount = TextEditingController();
  final TextEditingController _recipientPhone = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  /// Whether the phone box has been filled from the customer yet.
  ///
  /// The customer arrives asynchronously, and this screen rebuilds on every keystroke — without
  /// this the prefill would run again on each rebuild and overwrite the number being typed.
  bool _phoneSeeded = false;

  City? _city;
  Region? _region;
  int? _shopId;

  _DesignSource _designSource = _DesignSource.none;

  /// The files chosen from the customer's library, in the order they were picked — which is the
  /// order the server numbers the versions in, so «التصميم الأول» means the first one here.
  ///
  /// Held as models rather than ids so the chips can show the thumbnail and the label without a
  /// second read of the library.
  List<CustomerDesign> _designs = const [];

  /// Hidden without the grant — and refused by the server either way, which is the half that
  /// is a rule.
  bool get _mayDiscount => sl<Session>().can(AppPermission.discountOrders);

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    _designFee.dispose();
    _discount.dispose();
    _recipientPhone.dispose();
    _notes.dispose();
    super.dispose();
  }

  // ── the draft ──────────────────────────────────────────────────────────────────────────

  Future<void> _addLine() async {
    // **One line per size, and the picker is where that is enforced.** Two lines of the same
    // size are quoted separately — 100 and 200 are priced as 100 and as 200, never as the 300
    // the customer is buying — so the size already on the form is greyed out where it is chosen
    // rather than refused after the fact.
    final picked = await showProductPicker(
      context: context,
      addedVariantIds: {for (final line in _lines) line.variant.id},
    );
    if (picked == null || !mounted) return;

    setState(() {
      _lines.add(
        OrderLineDraft(
          product: picked.product,
          variant: picked.variant,
          quote: sl<LineQuoteCubit>(),
        ),
      );
    });
  }

  void _removeLine(OrderLineDraft line) {
    setState(() => _lines.remove(line));
    line.dispose();
  }

  /// Opens the customer's library, where a file may also be uploaded into it.
  ///
  /// The same sheet the order screen uses, so uploading during the order is uploading into the
  /// customer's library — the file is their property and the next order points at the same one.
  Future<void> _pickDesigns() async {
    final picked = await showDesignPicker(
      context: context,
      // From the Cubit, which is the one place this form cannot change the customer.
      customerId: context.read<TakeOrderCubit>().customerId,
      selected: _designs,
    );

    if (picked == null || !mounted) return;

    setState(() => _designs = picked);
    // A refusal about the artwork disappears as the selection changes, rather than lingering
    // under a picker that no longer holds what was refused.
    context.read<TakeOrderCubit>().clearFailure();
  }

  Future<void> _pickCity() async {
    final city = await showCityPicker(context: context, selectedId: _city?.id);
    if (city == null || !mounted) return;

    setState(() {
      _city = city;
      // The region belonged to the previous city. Keeping it would send the server a pair it
      // refuses — and «سوق الجمعة» under «زليتن» is wrong on screen long before that.
      _region = null;
    });
  }

  Future<void> _pickRegion() async {
    final city = _city;
    if (city == null) {
      context.showError('اختر المدينة أولاً');

      return;
    }

    final region = await showRegionPicker(
      context: context,
      cityId: city.id,
      selectedId: _region?.id,
    );

    if (region != null && mounted) setState(() => _region = region);
  }

  /// Every line has a quantity, every hand-priced line has a price, and there is a city.
  ///
  /// The button is disabled rather than the boxes marked red: nothing has been submitted yet,
  /// and an error under a field somebody has not reached is an accusation.
  bool get _isComplete =>
      _lines.isNotEmpty &&
      _city != null &&
      _lines.every(
        (line) =>
            line.quantity.text.trim().isNotEmpty &&
            (!line.isPricedByHand || line.unitPrice.text.trim().isNotEmpty),
      );

  void _submit() {
    final city = _city;
    if (city == null) return;

    context.read<TakeOrderCubit>().submit(
      cityId: city.id,
      regionId: _region?.id,
      customerShopId: _shopId,
      designSource: _designSource.value,
      designFee: _designFee.text,
      // Dropped by the use case when the source is «بدون تصميم», the same way the fee is —
      // the picker being hidden is the suggestion, and that is the rule.
      designIds: [for (final design in _designs) design.id],
      // Not merely hidden: a clerk without the grant sends no discount at all, so the server
      // has nothing to refuse.
      discount: _mayDiscount ? _discount.text : null,
      recipientPhone: _recipientPhone.text,
      notes: _notes.text,
      lines: [
        for (final line in _lines)
          DraftOrderLine(
            productId: line.product.id,
            productVariantId: line.variant.id,
            quantity: line.quantity.text,
            // Only for the category the API honours a typed price on; absent everywhere else.
            unitPrice: line.isPricedByHand ? line.unitPrice.text : null,
          ),
      ],
    );
  }

  // ── the screen ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<TakeOrderCubit, TakeOrderState>(
      listener: (context, state) {
        if (state case TakeOrderSuccess(:final order)) {
          context.showSuccess('تم إنشاء الطلبية رقم ${order.code}');
          // Replaced, not pushed: back from the order must not return to a form that has
          // already been sent, where a second tap would take a second order.
          context.pushReplacement(Routes.order(order.id));

          return;
        }

        // Anything with nowhere on the form to sit — a deactivated customer, a shop that
        // belongs to somebody else, a dropped connection. What is rendered inline is not
        // repeated here.
        if (state case TakeOrderFailure(:final failure) when state.hasUnrenderedErrors) {
          context.showFailure(failure);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('طلبية جديدة')),
        body: BlocBuilder<CustomerDetailCubit, CustomerDetailState>(
          builder: (context, customerState) {
            final customer = customerState.customer ?? widget.fallback;

            if (customer == null) {
              return switch (customerState) {
                CustomerDetailFailure(:final failure) => _Failure(
                  message: failure.message,
                  onRetry: context.read<CustomerDetailCubit>().load,
                ),
                _ => const Center(child: CircularProgressIndicator()),
              };
            }

            return BlocBuilder<TakeOrderCubit, TakeOrderState>(
              builder: (context, submission) => _body(customer, submission),
            );
          },
        ),
      ),
    );
  }

  /// Fills the phone box with the customer's number, once.
  ///
  /// Guarded by [_phoneSeeded] rather than by «is the box empty»: a clerk who deliberately
  /// clears the field would otherwise have it filled back in under them on the next rebuild —
  /// and this screen rebuilds on every keystroke elsewhere on the form.
  void _seedPhone(Customer customer) {
    if (_phoneSeeded) return;

    _phoneSeeded = true;
    _recipientPhone.text = customer.phone;
  }

  Widget _body(Customer customer, TakeOrderState submission) {
    final shops = customer.shops ?? const <CustomerShop>[];

    _seedPhone(customer);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
            children: [
              _CustomerBanner(customer: customer),

              if (shops.isNotEmpty) ...[
                SizedBox(height: 14.h),
                _Section(title: 'المحل', child: _shops(shops)),
              ],

              SizedBox(height: 14.h),
              _Section(title: 'مكان الاستلام', child: _destination(submission)),

              SizedBox(height: 14.h),
              _Section(title: 'البنود', child: _linesSection(submission)),

              SizedBox(height: 14.h),
              _Section(title: 'التصميم', child: _design(submission)),

              SizedBox(height: 14.h),
              _Section(title: 'الاستلام', child: _recipient(submission)),

              if (_mayDiscount) ...[
                SizedBox(height: 14.h),
                _Section(
                  title: 'الخصم',
                  child: AppTextField(
                    controller: _discount,
                    label: 'قيمة الخصم',
                    hint: '0',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.deny(RegExp('[-+ ]'))],
                    errorText: submission.discountError,
                    onChanged: (_) => context.read<TakeOrderCubit>().clearFailure(),
                  ),
                ),
              ],

              SizedBox(height: 14.h),
              _Section(
                title: 'ملاحظات',
                child: AppTextField(
                  controller: _notes,
                  hint: 'أي شيء يخص هذه الطلبية',
                  maxLines: 3,
                ),
              ),

              SizedBox(height: 14.h),
              _Estimate(lines: _lines),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: AppButton(
              label: 'إنشاء الطلبية',
              // Busy, not unavailable: AppButton refuses the tap itself while loading.
              isLoading: submission.isSubmitting,
              onPressed: _isComplete ? _submit : null,
            ),
          ),
        ),
      ],
    );
  }

  /// Which branch the bags are for. Optional, and absent for a customer with no shops.
  Widget _shops(List<CustomerShop> shops) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        ChoiceChip(
          label: const Text('بدون تحديد'),
          selected: _shopId == null,
          onSelected: (_) => setState(() => _shopId = null),
        ),
        for (final shop in shops)
          ChoiceChip(
            label: Text(shop.name),
            selected: _shopId == shop.id,
            onSelected: (_) => setState(() => _shopId = shop.id),
          ),
      ],
    );
  }

  /// Where the order goes.
  ///
  /// **The office branches are in the same list as the delivery cities**, so choosing
  /// «إستلام مكتب(قرجي)» is how an order becomes a collection — the server reads the fulfilment
  /// type off whichever city is chosen, and there is no second switch here to disagree with it.
  Widget _destination(TakeOrderState submission) {
    final scheme = context.colorScheme;
    final city = _city;
    final error = submission.cityError ?? submission.regionError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: PlacePickerTile(
                caption: 'المدينة',
                value: city?.name ?? 'مطلوبة',
                isChosen: city != null,
                onTap: _pickCity,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: PlacePickerTile(
                caption: 'المنطقة',
                // Named when there is one, invited when there is not — «بلا منطقة» would read
                // as a choice somebody made rather than as a box still to fill.
                value: _region?.name ?? 'اختياري',
                isChosen: _region != null,
                onTap: _pickRegion,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          error ??
              (city != null && city.hasDeliveryPrice
                  ? 'سعر التوصيل ${city.deliveryPrice} د.ل، يضيفه الخادم إلى الإجمالي'
                  : 'سعر التوصيل يأتي من المدينة المختارة'),
          style: context.textTheme.bodySmall?.copyWith(
            color: error != null ? scheme.error : scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _linesSection(TakeOrderState submission) {
    final scheme = context.colorScheme;
    final itemsError = submission.itemsError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_lines.isEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Text(
              'لم يُضَف أي منتج بعد',
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        for (final (index, line) in _lines.indexed)
          OrderLineRow(
            // Keyed by the line itself, so removing the middle one does not hand its
            // controllers — and its price — to the row below it.
            key: ObjectKey(line),
            line: line,
            quantityError: submission.quantityError(index),
            unitPriceError: submission.unitPriceError(index),
            onChanged: () {
              context.read<TakeOrderCubit>().clearFailure();
              // The button's «is this complete» reads the controllers directly.
              setState(() {});
            },
            onRemove: () => _removeLine(line),
          ),
        AppButton.tonal(label: 'إضافة منتج', icon: AppIcons.add, onPressed: _addLine),
        if (itemsError != null) ...[
          SizedBox(height: 6.h),
          Text(itemsError, style: context.textTheme.bodySmall?.copyWith(color: scheme.error)),
        ],
      ],
    );
  }

  /// Whose work the artwork was, the fee that only our own work may carry — and the files.
  ///
  /// **The picker is hidden under «بدون تصميم» and shown under the other two.** That source
  /// means a repeat print of something already agreed, or plain bags with nothing on them:
  /// there is no file, and offering to pick one would invite a selection the use case then
  /// drops on the way out.
  ///
  /// It is shown under «من عندنا» as well as «تصميم العميل», and deliberately. The two answer
  /// *whose work it was* — the question that moves money — not whether a file exists yet. Our
  /// own designer often finishes before the order is taken, and an order whose fee we charge is
  /// no less able to carry the file it was charged for.
  Widget _design(TakeOrderState submission) {
    final designsError = submission.designsError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<_DesignSource>(
          segments: [
            for (final option in _DesignSource.values)
              ButtonSegment<_DesignSource>(value: option, label: Text(option.label)),
          ],
          selected: {_designSource},
          showSelectedIcon: false,
          onSelectionChanged: (choice) => setState(() => _designSource = choice.first),
        ),
        if (_designSource == _DesignSource.inHouse) ...[
          SizedBox(height: 10.h),
          AppTextField(
            controller: _designFee,
            label: 'أجرة التصميم',
            hint: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp('[-+ ]'))],
            errorText: submission.designFeeError,
          ),
        ],
        if (_designSource == _DesignSource.none) ...[
          SizedBox(height: 6.h),
          Text(
            'طلبية بلا تصميم — إعادة طباعة لما اتُّفق عليه، أو أكياس سادة',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ] else ...[
          SizedBox(height: 10.h),
          if (_designs.isNotEmpty) ...[
            for (final design in _designs)
              _ChosenDesign(
                design: design,
                onRemove: () => setState(
                  () => _designs = [
                    for (final kept in _designs)
                      if (kept.id != design.id) kept,
                  ],
                ),
              ),
            SizedBox(height: 4.h),
          ],
          AppButton.tonal(
            label: _designs.isEmpty ? 'اختيار التصميم' : 'تعديل الاختيار (${_designs.length})',
            icon: AppIcons.add,
            onPressed: _pickDesigns,
          ),
          SizedBox(height: 6.h),
          Text(
            designsError ??
                'من مكتبة العميل، أو ارفع ملفاً جديداً — ويمكن تركها وإضافتها لاحقاً',
            style: context.textTheme.bodySmall?.copyWith(
              color: designsError != null
                  ? context.colorScheme.error
                  : context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  /// **One field, and it is the only thing here the customer's record does not already say.**
  ///
  /// The name is the customer's and the address is their shop's — both are on the order from
  /// the moment it is taken, through `customer_id` and `customer_shop_id`. Asking for them
  /// again was asking the clerk to copy out what the screen behind them was already showing,
  /// and every copy is a chance to mistype.
  ///
  /// The number is the exception: it is the one the courier rings, and it is *sometimes*
  /// somebody else — a brother at the shop, a driver. So it is offered already filled with the
  /// customer's own number and left open to be changed.
  Widget _recipient(TakeOrderState submission) {
    return AppTextField(
      controller: _recipientPhone,
      label: 'هاتف الاستلام',
      helperText: 'رقم العميل — غيّره إن كان الاستلام على رقم آخر',
      keyboardType: TextInputType.phone,
      textDirection: TextDirection.ltr,
      errorText: submission.recipientPhoneError,
    );
  }
}

/// One file the order is about to carry, and the way to take it back off.
///
/// **The thumbnail, not a glyph standing for it.** Two versions of one logo are «الشعار الأزرق»
/// and «الشعار الأزرق — نسخة معدّلة»; told apart by their names alone they are two identical
/// rows of text, and the wrong one goes to the press. The picker shows them the same way.
///
/// Removing here unpicks the file from this order. Nothing leaves the customer's library — it
/// is their property, and this screen never had the right to delete it.
class _ChosenDesign extends StatelessWidget {
  const _ChosenDesign({required this.design, required this.onRemove});

  final CustomerDesign design;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 4.w, 8.h),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: [
            DesignThumbnail(design: design, size: 40),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                design.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: Icon(AppIcons.close, size: 20.sp),
              color: scheme.onSurfaceVariant,
              tooltip: 'إزالة من الطلبية',
            ),
          ],
        ),
      ),
    );
  }
}

/// Who this order is for — stated, not asked.
class _CustomerBanner extends StatelessWidget {
  const _CustomerBanner({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: scheme.primary,
            child: Text(
              customer.name.characters.firstOrNull ?? '؟',
              style: context.textTheme.titleMedium?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  customer.code,
                  textDirection: TextDirection.ltr,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What the lines add up to — **an estimate, and it says so.**
///
/// Delivery is not in it: the server reads that off the city, and a number the app added up is
/// a second answer to a question the invoice already answers. Nothing here is shown at all
/// until every line has a price from the server, because a partial sum labelled «الإجمالي» is
/// the kind of number somebody reads out down a phone.
class _Estimate extends StatelessWidget {
  const _Estimate({required this.lines});

  final List<OrderLineDraft> lines;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final totals = [
      for (final line in lines) ?line.quote.state.quote?.total,
    ];

    final isComplete = lines.isNotEmpty && totals.length == lines.length;
    final sum = totals.fold<num>(0, (running, total) => running + (num.tryParse(total) ?? 0));

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'إجمالي البنود (تقديري)',
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Text(
            isComplete ? '$sum د.ل' : '—',
            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// The three answers to «من صمّم؟», with the wire value each sends.
enum _DesignSource {
  none('none', 'بدون تصميم'),
  customer('customer', 'تصميم العميل'),
  inHouse('in_house', 'من عندنا');

  const _DesignSource(this.value, this.label);

  final String value;
  final String label;
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 8.h),
        child,
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: 12.h),
            AppButton.outlined(label: 'إعادة المحاولة', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
