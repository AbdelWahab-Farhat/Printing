import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/cities/models/city.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_invoice_cubit.dart';
import 'package:dayaa/features/orders/presentation/widgets/design_picker_sheet.dart';
import 'package:dayaa/features/orders/presentation/widgets/destination_picker_sheet.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_designs_section.dart';
import 'package:dayaa/features/orders/presentation/widgets/place_picker_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Everything about one order that can be changed: its lines, its discount, and its artwork.
///
/// **A screen, not a sheet.** It was a sheet while it held two numbers; it now holds a design
/// picker that opens a sheet of its own, and a sheet stacked on a sheet under a keyboard is
/// three things fighting for the same 300 pixels.
///
/// **Each section obeys its own rule, and they are different rules.** The lines close from «قيد
/// الطباعة» onwards — the invoice is agreed by then — while the artwork stays open for as long
/// as the order does, because the correction path (طباعة ← تصميم) exists precisely so a design
/// can be redone after printing has started. A single "is this editable" flag over the whole
/// screen would have to pick one of those and be wrong about the other.
///
/// **No price is typed anywhere here.** Quantity is the only number a clerk changes; the rate
/// comes back from the catalogue when the server re-prices the line, which is what stops an
/// edit quietly undercutting an agreed price. The total shown while typing is an *estimate* and
/// says so.
///
/// **What is deliberately not here: adding a product.** That needs the catalogue picker — a
/// product, then one of its sizes, then a quantity priced live — which is the same machinery
/// «طلبية جديدة» needs and is its own slice, recorded in BACKLOG.md.
///
/// Pops with `true` when anything was saved, so the screen behind re-reads.
class OrderEditPage extends StatelessWidget {
  const OrderEditPage({required this.orderId, super.key});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    // The same Cubit the detail screen uses, and for the same two jobs: reading the order and
    // owning the artwork conversation on it. Its own instance, because this screen has its own
    // lifetime — see the note on `sl.registerFactoryParam`.
    return BlocProvider<OrderDetailCubit>(
      create: (_) => sl<OrderDetailCubit>(param1: orderId)..load(),
      child: const _OrderEditView(),
    );
  }
}

class _OrderEditView extends StatefulWidget {
  const _OrderEditView();

  @override
  State<_OrderEditView> createState() => _OrderEditViewState();
}

class _OrderEditViewState extends State<_OrderEditView> {
  /// Whether anything at all was written — a saved invoice or an added version — so `pop` can
  /// tell the screen behind whether to re-read.
  bool _changed = false;

  Future<void> _addDesigns() async {
    final cubit = context.read<OrderDetailCubit>();
    final order = cubit.state.order;
    if (order == null) return;

    final picked = await showDesignPicker(
      context: context,
      customerId: order.customerId,
      selected: const [],
    );

    if (picked == null || picked.isEmpty || !mounted) return;

    final failure = await cubit.addDesigns([for (final design in picked) design.id]);
    if (!mounted) return;

    if (failure == null) {
      setState(() => _changed = true);
      context.showSuccess('تمت إضافة التصميم');
    } else {
      context.showFailure(failure);
    }
  }

  Future<void> _reviewDesign(
    OrderDesign design, {
    required bool isApproved,
    String? rejectionReason,
  }) async {
    final cubit = context.read<OrderDetailCubit>();

    final failure = await cubit.reviewDesign(
      design.id,
      isApproved: isApproved,
      rejectionReason: rejectionReason,
    );

    if (!mounted) return;

    if (failure == null) {
      setState(() => _changed = true);
      context.showSuccess(isApproved ? 'تم اعتماد التصميم' : 'تم رفض التصميم');
    } else {
      context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrderDetailCubit>();
    final session = sl<Session>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Always through here, so the back button and the app bar's arrow return the same thing.
        context.pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('تعديل الطلبية')),
        body: BlocBuilder<OrderDetailCubit, OrderDetailState>(
          builder: (context, state) {
            final order = state.order;

            if (order == null) {
              return switch (state) {
                OrderDetailFailure(:final failure) => _FailureView(
                  message: failure.message,
                  onRetry: cubit.load,
                ),
                _ => const Center(child: CircularProgressIndicator()),
              };
            }

            // Built once and kept: this provider is not re-created when the order is read
            // again after a version is added, so quantities typed and not yet saved survive
            // that reload.
            return BlocProvider<OrderInvoiceCubit>(
              create: (_) => sl<OrderInvoiceCubit>(param1: order),
              child: _Form(
                order: order,
                isWorking: state.isWorking,
                mayDiscount: session.can(AppPermission.discountOrders),
                mayEditItems:
                    order.itemsAreEditable && session.can(AppPermission.manageOrders),
                // A third line, and later than the other two: the address stays correctable
                // until somebody is driving to it.
                mayEditDestination: session.can(AppPermission.manageOrders),
                onSaved: () => setState(() => _changed = true),
                // Both lines come from the server — `designs_are_editable` closes when the
                // press starts, which `items_are_editable` deliberately does not.
                onAddDesign:
                    order.designsAreEditable &&
                        session.can(AppPermission.manageOrderDesigns)
                    ? _addDesigns
                    : null,
                onReviewDesign:
                    order.designsAreEditable &&
                        session.can(AppPermission.manageOrderDesigns)
                    ? _reviewDesign
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.order,
    required this.isWorking,
    required this.mayDiscount,
    required this.mayEditItems,
    required this.mayEditDestination,
    required this.onSaved,
    required this.onAddDesign,
    required this.onReviewDesign,
  });

  final Order order;
  final bool isWorking;
  final bool mayDiscount;

  /// The lines close once printing starts, and the server enforces it. False also for somebody
  /// who may read the order and not change it.
  final bool mayEditItems;

  /// The address closes later than the lines do — only when somebody is driving to it — so it
  /// gets its own permission check rather than riding on [mayEditItems].
  final bool mayEditDestination;

  final VoidCallback onSaved;
  final Future<void> Function()? onAddDesign;
  final Future<void> Function(
    OrderDesign design, {
    required bool isApproved,
    String? rejectionReason,
  })?
  onReviewDesign;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrderInvoiceCubit>();

    return BlocConsumer<OrderInvoiceCubit, OrderInvoiceState>(
      listener: (context, state) {
        if (state.failure case final failure?) context.showFailure(failure);
        if (state.isSaved) {
          onSaved();
          context.showSuccess('تم حفظ التعديلات');
        }
      },
      builder: (context, state) => Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
              children: [
                // First, as it is on the order screen — and because on an order past «جاهزة»
                // it is the only section with anything to do in it.
                if (state.destinationIsEditable && mayEditDestination) ...[
                  _Section(
                    title: 'مكان الاستلام',
                    child: _Destination(
                      state: state,
                      onCity: (city) => cubit.setCity(id: city.id, name: city.name),
                      onRegion: (region) =>
                          cubit.setRegion(id: region.id, name: region.name),
                      onPhone: cubit.setRecipientPhone,
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
                _Section(
                  title: 'البنود',
                  child: Column(
                    children: [
                      if (!mayEditItems)
                        _Note(
                          text: order.itemsAreEditable
                              ? 'لا تملك صلاحية تعديل بنود الطلبية'
                              : 'البنود مقفلة بعد بدء الطباعة',
                        ),
                      for (final line in state.lines)
                        _LineRow(
                          line: line,
                          isEditable: mayEditItems,
                          canRemove: mayEditItems && state.lines.length > 1,
                          onQuantity: (value) => cubit.setQuantity(line.id, value),
                          onRemove: () => cubit.remove(line.id),
                        ),
                    ],
                  ),
                ),
                if (mayDiscount && mayEditItems) ...[
                  SizedBox(height: 16.h),
                  _Section(
                    title: 'الخصم',
                    child: _DiscountField(
                      initial: state.discount,
                      onChanged: cubit.setDiscount,
                    ),
                  ),
                ],
                SizedBox(height: 16.h),
                _Estimate(total: state.estimatedTotal),

                // **Only in «قيد التصميم», and absent everywhere else.** The status is named
                // after this work: outside it there is nothing to do here — a «جديدة» order
                // gets its first version *with* the move into design, and one being printed is
                // running against a file that was approved. A section that could only be read
                // would be a section asking to be tried.
                //
                // `designs_are_editable` is the server's answer, not a status this screen
                // checks for itself.
                if (order.designsAreEditable && order.designs != null) ...[
                  SizedBox(height: 16.h),
                  _Section(
                    title: 'التصاميم',
                    child: OrderDesignsSection(
                      designs: order.designs!,
                      isWorking: isWorking,
                      onAdd: onAddDesign,
                      onApprove: onReviewDesign == null
                          ? null
                          : (design) => onReviewDesign!(design, isApproved: true),
                      onReject: onReviewDesign == null
                          ? null
                          : (design, reason) => onReviewDesign!(
                              design,
                              isApproved: false,
                              rejectionReason: reason,
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (mayEditItems || (state.destinationIsEditable && mayEditDestination))
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                child: AppButton(
                  label: 'حفظ التعديلات',
                  // Busy, not unavailable: AppButton refuses the tap itself while loading, and
                  // a greyed button reads as "you may not" rather than "in progress".
                  isLoading: state.isSaving,
                  onPressed: state.isDirty && state.isValid ? cubit.save : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Where the order goes: the city, and the neighbourhood inside it.
///
/// **The office branches are in the same list as the delivery cities**, so choosing
/// «إستلام مكتب(قرجي)» is how an order becomes a collection — the server reads the fulfilment
/// type off whichever city is chosen, and there is no second switch here to disagree with it.
class _Destination extends StatefulWidget {
  const _Destination({
    required this.state,
    required this.onCity,
    required this.onRegion,
    required this.onPhone,
  });

  final OrderInvoiceState state;
  final ValueChanged<City> onCity;
  final ValueChanged<Region> onRegion;
  final ValueChanged<String> onPhone;

  @override
  State<_Destination> createState() => _DestinationState();
}

/// Stateful for the phone's [TextEditingController] alone — a widget-lifecycle resource that
/// has to be disposed, which is not something a Cubit can do for it.
class _DestinationState extends State<_Destination> {
  late final TextEditingController _phone = TextEditingController(
    text: widget.state.recipientPhone ?? '',
  );

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  OrderInvoiceState get state => widget.state;

  ValueChanged<City> get onCity => widget.onCity;

  ValueChanged<Region> get onRegion => widget.onRegion;

  Future<void> _pickCity(BuildContext context) async {
    final city = await showCityPicker(context: context, selectedId: state.cityId);

    if (city != null) onCity(city);
  }

  Future<void> _pickRegion(BuildContext context) async {
    final region = await showRegionPicker(
      context: context,
      cityId: state.cityId,
      selectedId: state.regionId,
    );

    if (region != null) onRegion(region);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Side by side, because they are one address read left to right: «زليتن، وسط المدينة».
        // Stacked full-width buttons made two lines of a single fact and took a third of the
        // screen to say it — and the region, which is optional, arrived looking like the more
        // important half.
        Row(
          children: [
            Expanded(
              child: PlacePickerTile(
                caption: 'المدينة',
                value: state.cityName,
                isChosen: true,
                onTap: () => _pickCity(context),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: PlacePickerTile(
                caption: 'المنطقة',
                // Named when there is one, invited when there is not — «بلا منطقة» would read
                // as a choice somebody made rather than as a box still to fill.
                value: state.regionName ?? 'اختياري',
                isChosen: state.regionName != null,
                onTap: () => _pickRegion(context),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          // Said out loud, because it is the part that surprises people: the rate follows the
          // address, and the total on the invoice moves with it.
          'تغيير المدينة يعيد حساب سعر التوصيل والإجمالي',
          style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: 10.h),
        // **Here rather than in a section of its own**, because it closes when the address does
        // and for the same reason: past «جاري التوصيل» the courier is carrying both, and the
        // server refuses a change to either. This whole block is already hidden then.
        AppTextField(
          controller: _phone,
          label: 'هاتف الاستلام',
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          errorText: state.recipientPhoneError,
          onChanged: widget.onPhone,
        ),
      ],
    );
  }
}


/// One line: what it is, what it costs, and the only number that may be changed.
///
/// The quantity sits on its own row under the name rather than beside it. It shared that line
/// once, in a box 84 wide, and «500.000» came out as «500.00(» — a number nobody can check
/// against an invoice. Nothing about a three-digit quantity was wrong; the box was.
class _LineRow extends StatefulWidget {
  const _LineRow({
    required this.line,
    required this.isEditable,
    required this.canRemove,
    required this.onQuantity,
    required this.onRemove,
  });

  final InvoiceLine line;
  final bool isEditable;
  final bool canRemove;
  final ValueChanged<String> onQuantity;
  final VoidCallback onRemove;

  @override
  State<_LineRow> createState() => _LineRowState();
}

class _LineRowState extends State<_LineRow> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.line.quantity);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.line.productName} — ${widget.line.variantLabel}',
            style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          Text(
            // The rate is shown and never edited: it comes from the catalogue, and a field
            // here would be a way to undercut an agreed price.
            'السعر: ${widget.line.unitPrice.grouped} · ${widget.line.pricingUnitLabel}',
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _controller,
                  label: 'الكمية',
                  enabled: widget.isEditable,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  // Arabic-Indic digits are what the keyboard produces, so they are allowed
                  // through and normalised on the way out — see OrderInvoiceCubit.
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,]')),
                  ],
                  onChanged: widget.onQuantity,
                ),
              ),
              if (widget.canRemove)
                IconButton(
                  tooltip: 'حذف البند',
                  onPressed: widget.onRemove,
                  icon: Icon(AppIcons.delete, size: 20.sp, color: scheme.error),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiscountField extends StatefulWidget {
  const _DiscountField({required this.initial, required this.onChanged});

  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_DiscountField> createState() => _DiscountFieldState();
}

class _DiscountFieldState extends State<_DiscountField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      label: 'الخصم',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,]')),
      ],
      onChanged: widget.onChanged,
    );
  }
}

class _Estimate extends StatelessWidget {
  const _Estimate({required this.total});

  final String total;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'الإجمالي التقريبي',
                style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                total.grouped,
                textDirection: TextDirection.ltr,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            // Said out loud rather than left to be discovered: the app multiplies to show
            // something while typing, and the server re-prices every line from the catalogue
            // on save. The two can differ, and the server's answer is the invoice.
            'الرقم النهائي يُحسب على الخادم بعد الحفظ',
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        text,
        style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: 48.sp, color: scheme.error),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            SizedBox(height: 20.h),
            AppButton.tonal(label: 'إعادة المحاولة', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
