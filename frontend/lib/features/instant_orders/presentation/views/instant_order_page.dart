import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/cities/models/city.dart';
import 'package:dayaa/features/instant_orders/models/instant_models.dart';
import 'package:dayaa/features/instant_orders/presentation/viewmodel/instant_order_cubit.dart';
import 'package:dayaa/features/instant_orders/presentation/widgets/instant_product_sheet.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/destination_picker_sheet.dart';
import 'package:dayaa/features/orders/presentation/widgets/place_picker_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «طلب فوري» — a counter sale on one screen (INSTANT-ORDERS-PLAN.md §3, §12).
///
/// **The customer is typed, not picked.** The phone is looked up as it is typed; a customer on
/// file is linked and their stored details kept (the server fills only what is blank), and a new
/// one is created with the order in one step — never by a sale that failed.
///
/// **The customer's address is theirs**, never the branch's: the pickup branch is chosen apart,
/// and its warehouse is shown, not chosen.
///
/// Opened with [editing] it edits a «جديدة» instant order: the branch and the customer are fixed,
/// the lines, discount and notes move.
class InstantOrderPage extends StatelessWidget {
  const InstantOrderPage({this.editing, super.key});

  final Order? editing;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InstantOrderCubit>(
      create: (_) => sl<InstantOrderCubit>(param1: editing)..load(),
      child: _InstantOrderView(editing: editing),
    );
  }
}

class _InstantOrderView extends StatefulWidget {
  const _InstantOrderView({required this.editing});

  final Order? editing;

  @override
  State<_InstantOrderView> createState() => _InstantOrderViewState();
}

class _InstantOrderViewState extends State<_InstantOrderView> {
  final _phone = TextEditingController();
  final _name = TextEditingController();
  late final _discount = TextEditingController(text: _wholeDiscount(widget.editing));
  late final _notes = TextEditingController(text: widget.editing?.notes ?? '');

  /// The customer's own address — never the branch's. Ids and names only: the pickers hand
  /// back the full models, a customer on file only its ids and names.
  ({int id, String name})? _city;
  ({int id, String name})? _region;

  Timer? _debounce;

  bool get _isEdit => widget.editing != null;

  @override
  void dispose() {
    _debounce?.cancel();
    _phone.dispose();
    _name.dispose();
    _discount.dispose();
    _notes.dispose();
    super.dispose();
  }

  static String _wholeDiscount(Order? order) {
    final value = double.tryParse(order?.discount ?? '') ?? 0;

    return value > 0 ? value.toStringAsFixed(0) : '';
  }

  int get _discountValue => int.tryParse(Validators.toWesternDigits(_discount.text.trim())) ?? 0;

  void _onPhoneChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => context.read<InstantOrderCubit>().lookUp(Validators.toWesternDigits(value)),
    );
  }

  Future<void> _pickCity() async {
    final City? city = await showCityPicker(
      context: context,
      selectedId: _city?.id,
      deliveryOnly: true,
    );
    if (city == null || !mounted) return;

    setState(() {
      _city = (id: city.id, name: city.name);
      _region = null;
    });
  }

  Future<void> _pickRegion() async {
    final city = _city;
    if (city == null) {
      context.showError('اختر المدينة أولاً');

      return;
    }

    final Region? region = await showRegionPicker(
      context: context,
      cityId: city.id,
      selectedId: _region?.id,
    );
    if (region != null && mounted) setState(() => _region = (id: region.id, name: region.name));
  }

  Future<void> _addProduct(InstantOrderCubit cubit) async {
    final catalogue = cubit.state.catalogue;
    if (catalogue == null) return;

    final asked = <int, double>{};
    for (final line in cubit.state.lines) {
      asked[line.variantId] = (asked[line.variantId] ?? 0) + line.quantity;
    }

    final picked = await showInstantProductSheet(
      context: context,
      catalogue: catalogue,
      availableFor: cubit.availableFor,
      alreadyAsked: asked,
    );

    if (picked != null && mounted) cubit.addLine(picked.product, picked.variant, picked.quantity);
  }

  bool _isComplete(InstantOrderState state, InstantOrderCubit cubit) {
    if (state.branchId == null || state.lines.isEmpty || cubit.hasShortfall) return false;
    if (_isEdit) return true;

    // A customer on file is the name; a deactivated one takes no order at all.
    if (state.customer case final customer?) return customer.isActive;

    return _phone.text.trim().length >= 9 && _name.text.trim().length >= 2;
  }

  /// Whether the address tiles are asked: always for a new customer, and for one on file only
  /// while their record has no address — the stored one is never replaced.
  bool _asksAddress(FoundCustomer? customer) => customer == null || customer.cityId == null;

  void _submit(InstantOrderCubit cubit) {
    final notes = _notes.text.trim();
    final customer = cubit.state.customer;
    final asksAddress = _asksAddress(customer);

    cubit.submit(
      phone: Validators.toWesternDigits(_phone.text.trim()),
      // The stored name for a customer on file — the server keeps it anyway.
      name: customer?.name ?? _name.text.trim(),
      cityId: asksAddress ? _city?.id : null,
      regionId: asksAddress ? _region?.id : null,
      discount: _discountValue,
      notes: notes.isEmpty ? null : notes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InstantOrderCubit, InstantOrderState>(
      listenWhen: (before, after) =>
          before.result != after.result ||
          before.updated != after.updated ||
          before.submitFailure != after.submitFailure,
      listener: (context, state) {
        if (state.result case final result?) {
          if (result.customerNotice case final notice?) context.showSuccess(notice);
          context.pushReplacement(Routes.order(result.order.id));

          return;
        }

        if (state.updated != null) {
          // The order screen re-reads the order; it only needs to know something changed.
          context
            ..handBack(true)
            ..pop();

          return;
        }

        final failure = state.submitFailure;
        if (failure != null && !state.isSubmitting) {
          context.showError(failure.message);
        }
      },
      builder: (context, state) {
        final cubit = context.read<InstantOrderCubit>();

        return Scaffold(
          appBar: AppBar(title: Text(_isEdit ? 'تعديل الطلب الفوري' : 'طلب فوري جديد')),
          body: switch (state) {
            InstantOrderState(isLoading: true) => const Center(child: CircularProgressIndicator()),
            InstantOrderState(loadFailure: final failure?) => Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Text(failure.message, textAlign: TextAlign.center),
              ),
            ),
            _ => _body(state, cubit),
          },
        );
      },
    );
  }

  /// The same shape as «طلبية جديدة»: sections under bold titles, the lines as cards, the
  /// estimate at the foot, and the button pinned under the list. What a counter sale never asks
  /// — the shop, the delivery and who pays it, the recipient's phone, the vendor, the design,
  /// compensation, an extra cost, urgency — is simply not here.
  Widget _body(InstantOrderState state, InstantOrderCubit cubit) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
            children: [
              if (!_isEdit) ...[
                _Section(title: 'العميل', child: _customer(state)),
                SizedBox(height: 14.h),
              ],
              _Section(title: 'الاستلام', child: _branch(state, cubit)),
              SizedBox(height: 14.h),
              _Section(
                title: 'البنود',
                // On the heading, as on «طلبية جديدة».
                action: TextButton.icon(
                  onPressed:
                      state.branchId != null && state.catalogue != null && !state.isLoadingCatalogue
                      ? () => _addProduct(cubit)
                      : null,
                  icon: Icon(AppIcons.add, size: 18.sp),
                  label: const Text('إضافة منتج'),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
                child: _lines(state, cubit),
              ),
              if (sl<Session>().can(AppPermission.discountOrders)) ...[
                SizedBox(height: 14.h),
                _Section(
                  title: 'الخصم',
                  child: AppTextField(
                    controller: _discount,
                    label: 'قيمة الخصم',
                    hint: '0',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹]'))],
                    errorText: state.errorFor('discount'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
              SizedBox(height: 14.h),
              _Section(
                title: 'ملاحظات',
                child: AppTextField(controller: _notes, hint: 'أي شيء يخص هذا الطلب', maxLines: 3),
              ),
              SizedBox(height: 14.h),
              _Estimate(before: cubit.estimatedTotal, discount: _discountValue.toDouble()),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: AppButton(
              label: _isEdit ? 'حفظ التعديل' : 'إنشاء الطلب',
              isLoading: state.isSubmitting,
              onPressed: _isComplete(state, cubit) ? () => _submit(cubit) : null,
            ),
          ),
        ),
      ],
    );
  }

  /// The phone first — it finds a customer on file.
  ///
  /// **A customer on file is the banner, not a form.** Their stored name and address are the
  /// ones kept (§3), so there is nothing to type: the name box goes, and the address tiles are
  /// asked only while their record has no address. A new number brings the boxes back.
  Widget _customer(InstantOrderState state) {
    final scheme = context.colorScheme;
    final customer = state.customer;
    final addressError = state.errorFor('customer.city_id') ?? state.errorFor('customer.region_id');
    final asksAddress = _asksAddress(customer);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _phone,
          label: 'رقم الهاتف',
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          errorText: state.errorFor('customer.phone'),
          suffix: state.isLookingUp
              ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onChanged: (value) {
            _onPhoneChanged(value);
            setState(() {});
          },
        ),
        SizedBox(height: 10.h),
        if (customer != null)
          _CustomerBanner(customer: customer)
        else
          AppTextField(
            controller: _name,
            label: 'الاسم',
            errorText: state.errorFor('customer.name'),
            onChanged: (_) => setState(() {}),
          ),
        if (asksAddress && customer != null) ...[
          SizedBox(height: 10.h),
          Text(
            'لا يوجد عنوان مسجّل لهذا العميل — أضفه إن عرفته',
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        if (asksAddress) ...[
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: PlacePickerTile(
                  caption: 'المدينة',
                  value: _city?.name ?? 'اختياري',
                  isChosen: _city != null,
                  onTap: _pickCity,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: PlacePickerTile(
                  caption: 'المنطقة',
                  value: _region?.name ?? 'اختياري',
                  isChosen: _region != null,
                  onTap: _pickRegion,
                ),
              ),
            ],
          ),
        ],
        if (addressError != null) ...[
          SizedBox(height: 6.h),
          Text(addressError, style: context.textTheme.bodySmall?.copyWith(color: scheme.error)),
        ],
      ],
    );
  }

  /// Which branch the customer collects from, and the warehouse that follows from it.
  Widget _branch(InstantOrderState state, InstantOrderCubit cubit) {
    final scheme = context.colorScheme;
    final branches = state.branches;
    final error = state.errorFor('branch_id');
    final warehouse = state.catalogue?.warehouseName ?? state.branch?.warehouseName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (branches.isEmpty)
          Text(
            'لا يوجد فرع مُسنَد لك — راجع الإدارة',
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.error),
          )
        else
          // Chips, like the shop chips on «طلبية جديدة». On an edit the branch is fixed, so only
          // its own chip is drawn.
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final branch in branches)
                if (!_isEdit || branch.id == state.branchId)
                  ChoiceChip(
                    label: Text(branch.name),
                    selected: branch.id == state.branchId,
                    onSelected: _isEdit ? null : (_) => cubit.chooseBranch(branch.id),
                  ),
            ],
          ),
        if (warehouse != null) ...[
          SizedBox(height: 8.h),
          Text(
            'المخزن: $warehouse (تلقائي)',
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        if (error != null) ...[
          SizedBox(height: 6.h),
          Text(error, style: context.textTheme.bodySmall?.copyWith(color: scheme.error)),
        ],
      ],
    );
  }

  Widget _lines(InstantOrderState state, InstantOrderCubit cubit) {
    final scheme = context.colorScheme;
    final itemsError = state.errorFor('items');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.isLoadingCatalogue)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: const LinearProgressIndicator(),
          ),
        if (state.lines.isEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Text(
              state.branchId == null ? 'اختر مكان الاستلام أولاً' : 'لم يُضَف أي منتج بعد',
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        for (final (index, line) in state.lines.indexed)
          _LineCard(
            key: ValueKey('instant-line-${line.variantId}'),
            line: line,
            unitPrice: state.catalogue?.find(line.variantId)?.variant.unitPriceFor(line.quantity),
            problem:
                state.errorFor('items.$index.product_id') ??
                state.errorFor('items.$index.quantity') ??
                cubit.shortfallFor(line),
            onQuantity: (value) => cubit.setQuantity(index, value),
            onRemove: () => cubit.removeLine(index),
          ),
        if (itemsError != null) ...[
          SizedBox(height: 6.h),
          Text(itemsError, style: context.textTheme.bodySmall?.copyWith(color: scheme.error)),
        ],
      ],
    );
  }
}

/// A bold title, an optional control at its far end, and the section under it — the same
/// heading «طلبية جديدة» uses.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            ?action,
          ],
        ),
        SizedBox(height: action == null ? 8.h : 4.h),
        child,
      ],
    );
  }
}

/// The customer the phone found — drawn like the banner on «طلبية جديدة». Their stored details
/// are the ones kept; a deactivated customer is said so in red.
class _CustomerBanner extends StatelessWidget {
  const _CustomerBanner({required this.customer});

  final FoundCustomer customer;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final active = customer.isActive;
    final ink = active ? scheme.onPrimaryContainer : scheme.onErrorContainer;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: active ? scheme.primaryContainer : scheme.errorContainer,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28.r,
                backgroundColor: active ? scheme.primary : scheme.error,
                child: Text(
                  customer.name.characters.firstOrNull ?? '؟',
                  style: context.textTheme.headlineSmall?.copyWith(
                    color: active ? scheme.onPrimary : scheme.onError,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      active ? 'عميل مسجّل' : 'هذا العميل معطَّل ولا تُسجَّل له طلبات',
                      style: context.textTheme.bodyMedium?.copyWith(color: ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // The stored details, each with its own caption — kept as they are; nothing on this
          // screen replaces them.
          if (active) ...[
            SizedBox(height: 12.h),
            Divider(height: 1, color: ink.withValues(alpha: 0.2)),
            SizedBox(height: 10.h),
            _Detail(caption: 'الهاتف', value: customer.phone, ink: ink, ltr: true),
            _Detail(caption: 'المدينة', value: customer.cityName ?? 'غير مسجّلة', ink: ink),
            _Detail(caption: 'المنطقة', value: customer.regionName ?? 'غير مسجّلة', ink: ink),
          ],
        ],
      ),
    );
  }
}

/// One stored detail on the banner: its caption, then its value.
class _Detail extends StatelessWidget {
  const _Detail({required this.caption, required this.value, required this.ink, this.ltr = false});

  final String caption;
  final String value;
  final Color ink;

  /// A phone number reads left-to-right.
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          SizedBox(
            width: 72.w,
            child: Text(
              caption,
              style: context.textTheme.bodyMedium?.copyWith(color: ink.withValues(alpha: 0.75)),
            ),
          ),
          Expanded(
            // Aligned to the row's own start, so a left-to-right number still sits where the
            // Arabic values do.
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                textDirection: ltr ? TextDirection.ltr : null,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One line as a card, like [OrderLineRow] on «طلبية جديدة»: the product, its size, a red
/// delete, the quantity, and under it the price and the line total — or what is wrong with it.
class _LineCard extends StatefulWidget {
  const _LineCard({
    required this.line,
    required this.onQuantity,
    required this.onRemove,
    this.unitPrice,
    this.problem,
    super.key,
  });

  final InstantLine line;
  final double? unitPrice;
  final String? problem;
  final ValueChanged<double> onQuantity;
  final VoidCallback onRemove;

  @override
  State<_LineCard> createState() => _LineCardState();
}

class _LineCardState extends State<_LineCard> {
  late final _quantity = TextEditingController(text: _figure(widget.line.quantity));

  @override
  void didUpdateWidget(covariant _LineCard old) {
    super.didUpdateWidget(old);

    // A second pick of the same size adds to this line; show the new figure.
    final typed = double.tryParse(Validators.toWesternDigits(_quantity.text));
    if (typed != widget.line.quantity) _quantity.text = _figure(widget.line.quantity);
  }

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  static String _figure(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final line = widget.line;
    final price = widget.unitPrice;
    final small = context.textTheme.bodySmall;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 8.w, 12.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: widget.problem == null ? scheme.outlineVariant : scheme.error),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.productName,
                      style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    // A measurement: kept left-to-right so 35×40 never reads as 40×35.
                    Text(
                      line.variantLabel,
                      textDirection: TextDirection.ltr,
                      style: small?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onRemove,
                icon: Icon(AppIcons.delete, size: 20.r),
                tooltip: 'حذف البند',
                color: scheme.error,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          AppTextField(
            controller: _quantity,
            label: 'الكمية (${line.unitLabel})',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp('[-+ ]'))],
            onChanged: (value) {
              final parsed = double.tryParse(
                Validators.toWesternDigits(value).replaceAll(',', '.'),
              );
              if (parsed != null && parsed > 0) widget.onQuantity(parsed);
            },
          ),
          SizedBox(height: 8.h),
          if (widget.problem case final problem?)
            Text(problem, style: small?.copyWith(color: scheme.error))
          else if (price != null)
            Text(
              'سعر الوحدة ${groupedDecimal(price.toStringAsFixed(2))} د.ل · '
              'الإجمالي ${groupedDecimal((price * line.quantity).toStringAsFixed(2))} د.ل',
              style: small?.copyWith(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

/// What the lines add up to — an estimate, and it says so, as on «طلبية جديدة». The server
/// prices the order itself when it is taken.
class _Estimate extends StatelessWidget {
  const _Estimate({required this.before, required this.discount});

  final double before;
  final double discount;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final after = (before - discount).clamp(0, double.infinity);

    Widget row(String label, double value, {bool strong = false}) => Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Text(
          before > 0 ? '${groupedDecimal(value.toStringAsFixed(2))} د.ل' : '—',
          style: strong
              ? context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
              : context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          row('إجمالي البنود (تقديري)', before, strong: discount <= 0),
          if (discount > 0) ...[
            SizedBox(height: 6.h),
            row('بعد الخصم', after.toDouble(), strong: true),
          ],
        ],
      ),
    );
  }
}
