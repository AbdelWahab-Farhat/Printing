import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/cities/models/city.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/line_quote_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_invoice_cubit.dart';
import 'package:dayaa/features/orders/presentation/widgets/additional_cost_sheet.dart';
import 'package:dayaa/features/orders/presentation/widgets/design_picker_sheet.dart';
import 'package:dayaa/features/orders/presentation/widgets/destination_picker_sheet.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_additional_cost.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_designs_section.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_line_row.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_urgent_switch.dart';
import 'package:dayaa/features/orders/presentation/widgets/place_picker_tile.dart';
import 'package:dayaa/features/orders/presentation/widgets/product_picker_sheet.dart';
import 'package:dayaa/features/orders/usecases/update_order_invoice.dart';
import 'package:dayaa/features/vendors/presentation/widgets/vendor_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Everything about one order that can be changed: its lines, its discount, the charge added to
/// it, and its artwork.
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
/// **No catalogue price is typed here.** The rate comes back from the catalogue when the server
/// prices a line, which is what stops an edit quietly undercutting an agreed price; only a
/// product priced «حسب الطلب», added here, asks for its price. The total shown while typing is
/// an *estimate* and says so.
///
/// **Products are added and removed here until the press starts** — the picker and the live
/// quote are «طلبية جديدة»'s own. After «جاهزة للطباعة» the stock has already left, so saving
/// moves it too: a removed product goes back on the shelf, an added one comes off it. See
/// Docs/orders/ORDER-LINES-ADD-REMOVE.md.
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
      context.handBack(true);
      context.showSuccess('تمت إضافة التصميم');
    } else {
      context.showFailure(failure);
    }
  }

  /// Charges the customer for something no line on the order describes.
  ///
  /// **A sheet rather than fields on this form**, because it is a number, a category and a
  /// sentence, and the person filling it in has just agreed it at the counter. The send happens
  /// here and not in the sheet — a form's answer is what was typed, and what to do about a
  /// refusal belongs to the screen that has somewhere to show it.
  ///
  /// **Sent on its own, not with «حفظ التعديلات».** `PUT` replaces the whole order and the
  /// repository re-reads it first, so the fields this sheet never touches go back as they are —
  /// see [OrderRepository.updateInvoice]. Quantities typed and not yet saved live in
  /// [OrderInvoiceCubit] and are untouched by it, exactly as adding a version is.
  Future<void> _editAdditionalCost() async {
    final cubit = context.read<OrderDetailCubit>();
    final order = cubit.state.order;
    if (order == null) return;

    final draft = await showAdditionalCostSheet(
      context: context,
      initial: AdditionalCostDraft.of(order),
    );
    if (draft == null || !mounted) return;

    final result = await sl<UpdateOrderInvoice>()(
      order.id,
      additionalCost: draft.amount,
      additionalCostReason: draft.reason,
      additionalCostNote: draft.note,
    );

    if (!mounted) return;

    result.fold(
      // The server's own Arabic — «سبب التكلفة الإضافية مطلوب» names the field, and «ليس لديك
      // صلاحية…» names the grant. Neither could be written here without guessing.
      context.showFailure,
      (updated) {
        cubit.replace(updated);
        context.handBack(true);
      },
    );
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
      context.handBack(true);
      context.showSuccess(isApproved ? 'تم اعتماد التصميم' : 'تم رفض التصميم');
    } else {
      context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrderDetailCubit>();
    final session = sl<Session>();

    return Scaffold(
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
              // **And, once the stock has left, the grant that took it out** — saving the lines
              // there moves the shelf. The server asks the same; this keeps the screen from
              // offering what it would refuse.
              mayEditItems:
                  order.itemsAreEditable &&
                  session.can(AppPermission.manageOrders) &&
                  (!order.itemEditsMoveStock ||
                      session.can(AppPermission.moveOrderToReadyToPrint)),
              // A third line, and later than the other two: the address stays correctable
              // until somebody is driving to it.
              mayEditDestination: session.can(AppPermission.manageOrders),
              // **`is_closed`, the server's own line, not a status checked here.**
              // `UpdateOrder` refuses a closed order and accepts every other, so a switch
              // drawn on this condition never leads to a refusal — and «استعجل ما وصل» means
              // nothing anyway. The grant is `orders.manage`, the one every other edit costs.
              mayFlagUrgent: session.can(AppPermission.manageOrders) && !order.isClosed,
              // **`is_closed`, which is the server's own line rather than one chosen here.**
              // `UpdateOrder` refuses a closed order and accepts every other, so a button
              // drawn on that condition never leads to a refusal — and the grant is the
              // charge's own, not the discount's, because the two are different acts.
              onEditAdditionalCost:
                  session.can(AppPermission.addOrderAdditionalCost) && !order.isClosed
                  ? _editAdditionalCost
                  : null,
              onSaved: () => context.handBack(true),
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
    required this.mayFlagUrgent,
    required this.onEditAdditionalCost,
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

  /// Whether «مستعجلة» may be switched. False for a reader, and on an order the server would
  /// refuse to edit at all.
  final bool mayFlagUrgent;

  /// Null without `orders.additional_cost`, and on an order the server would refuse to edit —
  /// see the call site for the line, which is the server's own. Its own grant, so a clerk who
  /// may correct a quantity is not thereby allowed to add money to the invoice.
  final Future<void> Function()? onEditAdditionalCost;

  final VoidCallback onSaved;
  final Future<void> Function()? onAddDesign;
  final Future<void> Function(
    OrderDesign design, {
    required bool isApproved,
    String? rejectionReason,
  })?
  onReviewDesign;

  /// «طلبية جديدة»'s own picker, with the sizes already on the order greyed out — the same
  /// size twice would be two lines the shelf and the invoice both have to add up.
  Future<void> _addProduct(BuildContext context, OrderInvoiceState state) async {
    final cubit = context.read<OrderInvoiceCubit>();

    final picked = await showProductPicker(
      context: context,
      addedVariantIds: {for (final line in state.lines) line.variantId},
      // Once work has started the order cannot change road, so the other bench's products
      // could never be saved here — greyed out rather than refused on «حفظ التعديلات».
      bench: state.pickerBench,
    );

    if (picked == null || !context.mounted) return;

    cubit.add(product: picked.product, variant: picked.variant);
  }

  /// The same picker «طلبية جديدة» and the purchase orders use — the vendors still dealt with.
  Future<void> _pickVendor(BuildContext context) async {
    final cubit = context.read<OrderInvoiceCubit>();

    final vendor = await showVendorPicker(context: context);
    if (vendor == null || !context.mounted) return;

    cubit.setVendor(id: vendor.id, name: vendor.name);
  }

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
                // **دائماً، ولا يختفي.** كان يُخفى في الطلبية المقفلة وعند من لا يملك المنح،
                // فكانت الشاشة نفسها تُفتح مرّةً وفيها القسم ومرّةً وليس فيها، ومن لم يجده لا
                // يعرف أاختفى لأنّه ممنوع أم لأنّه غير موجود أصلاً. الحال الآن كحال «البنود»
                // تحته: القسم واقف، والمفتاح وحده يُقفل، والسطر يقول لماذا.
                //
                // **وفوق البنود**، لأنّه أقصر سؤالٍ على هذه الشاشة وأكثر ما تُفتح لأجله — اتّصل
                // العميل فصارت تسبق غيرها — فلا يُدفن تحت قائمةِ بنودٍ قد تمتدّ خارج الشاشة.
                _Section(
                  title: 'الاستعجال',
                  child: Column(
                    children: [
                      if (!mayFlagUrgent)
                        _Note(
                          text: order.isClosed
                              ? 'الاستعجال مقفل بعد إغلاق الطلبية'
                              : 'لا تملك صلاحية تعديل الطلبية',
                        ),
                      OrderUrgentSwitch(
                        value: state.isUrgent,
                        // Null closes the switch itself — the same line the section is drawn
                        // on, so what is shown and what may be tapped cannot disagree.
                        onChanged: mayFlagUrgent ? cubit.setUrgent : null,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                _Section(
                  title: 'البنود',
                  child: Column(
                    children: [
                      if (!mayEditItems)
                        _Note(
                          text: !order.itemsAreEditable
                              ? 'البنود مقفلة بعد بدء الطباعة'
                              : order.itemEditsMoveStock &&
                                    sl<Session>().can(AppPermission.manageOrders)
                              ? 'خرجت بضاعة هذه الطلبية من المخزن، وتعديل بنودها يحرّك المخزن'
                                    ' — يحتاج صلاحية «جاهزة للطباعة»'
                              : 'لا تملك صلاحية تعديل بنود الطلبية',
                        )
                      else if (state.linesMoveStock)
                        // Said before anything is touched, because the save does more here than
                        // anywhere else on this screen: it moves the shelf.
                        const _Note(
                          text:
                              'خرجت البضاعة من المخزن — عند الحفظ يعود المنتج المحذوف إلى الرف،'
                              ' ويُسحب المضاف من نفس المخزن',
                        ),
                      if (state.itemsError case final error?) _Error(text: error),
                      for (final (index, line) in state.lines.indexed)
                        _LineRow(
                          // Keyed by the line, not its position: removing the second of three
                          // must not hand the third line's typed quantity to the second's box.
                          key: ValueKey(line.id),
                          line: line,
                          isEditable: mayEditItems,
                          canRemove: mayEditItems && state.lines.length > 1,
                          movesStock: state.linesMoveStock,
                          weightError: state.weightErrorAt(index),
                          unitCostError: state.unitCostErrorAt(index),
                          showVendorCost: sl<Session>().can(AppPermission.viewProductCost),
                          onUnitCost: (value) => cubit.setUnitCost(line.id, value),
                          onQuantity: (value) => cubit.setQuantity(line.id, value),
                          onQuoted: (price) => cubit.setUnitPrice(line.id, price),
                          onUnitPrice: (price) =>
                              cubit.setUnitPrice(line.id, price, typed: true),
                          onWeight: (value) => cubit.setWeight(line.id, value),
                          onRemove: () => cubit.remove(line.id),
                        ),
                      if (mayEditItems)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: AppButton.tonal(
                            label: 'إضافة منتج',
                            icon: AppIcons.add,
                            onPressed: () => _addProduct(context, state),
                          ),
                        ),
                      // **Drawn once every line is a vendor's work** — a «جديدة» order whose own
                      // products were removed until only the وسيط one was left becomes a وسيط
                      // order on save, and the server refuses one with nobody named to make it.
                      if (mayEditItems && state.vendorIsRequired) ...[
                        SizedBox(height: 12.h),
                        PlacePickerTile(
                          caption: 'المورد',
                          value: state.vendorName ?? 'مطلوب',
                          isChosen: state.vendorId != null,
                          icon: AppIcons.vendors,
                          onTap: () => _pickVendor(context),
                        ),
                        if (state.vendorError case final error?) _Error(text: error),
                      ],
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
                if (mayEditItems && state.dropsBelowPaid) ...[
                  SizedBox(height: 8.h),
                  // Before the save, not discovered on the order screen after it: the
                  // difference is money the customer has paid for goods no longer on the order.
                  _Error(
                    text:
                        'الإجمالي الجديد أقل مما دفعه العميل (${state.paidAmount.grouped} د.ل)'
                        ' — سيصبح على الطلبية مبلغ زائد',
                  ),
                ],

                // **Under the estimate, never above it.** The charge is not part of that
                // arithmetic — it is sent on its own the moment the sheet is answered, and the
                // total it lands in is the server's — so a line for it above «الإجمالي
                // التقريبي» would read as one of the figures being added up there.
                //
                // **Here rather than on the order screen**, which is what «تعديل» means: the
                // order screen prints the charge inside «الحساب» and names it on that line, and
                // every way of changing the invoice is on this one screen.
                if (onEditAdditionalCost case final edit?) ...[
                  SizedBox(height: 16.h),
                  _Section(
                    title: 'التكلفة الإضافية',
                    child: Column(
                      children: [
                        // What is being argued with, in the words the order screen and the
                        // invoice use for it — see [OrderAdditionalCost].
                        if (order.hasAdditionalCost) ...[
                          OrderAdditionalCost(
                            caption: order.additionalCostCaption,
                            amount: order.additionalCost,
                          ),
                          SizedBox(height: 14.h),
                        ],
                        AppButton.tonal(
                          // The word changes with the order, because the two are different
                          // acts: one adds a charge, the other argues with one already on the
                          // invoice.
                          label: order.hasAdditionalCost
                              ? 'تعديل التكلفة الإضافية'
                              : 'إضافة تكلفة إضافية',
                          icon: order.hasAdditionalCost ? AppIcons.edit : AppIcons.add,
                          onPressed: edit,
                        ),
                      ],
                    ),
                  ),
                ],

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
          if (mayEditItems ||
              mayFlagUrgent ||
              (state.destinationIsEditable && mayEditDestination))
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
          // address. The invoice's own total does not move with it — the fee is the courier's,
          // billed to the customer at the door and part of no total of ours.
          'تغيير المدينة يعيد حساب سعر التوصيل وحده',
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


/// One line: what it is, what it costs, and the numbers that may be changed.
///
/// The quantity sits on its own row under the name rather than beside it. It shared that line
/// once, in a box 84 wide, and «500.000» came out as «500.00(» — a number nobody can check
/// against an invoice. Nothing about a three-digit quantity was wrong; the box was.
///
/// **The price under a changed quantity is the catalogue's**, asked again as it is typed — the
/// same [LineQuoteCubit] «طلبية جديدة» uses, created only once a quantity actually changes so an
/// untouched line asks nothing. Its answer moves the estimate; the server prices the line again
/// on save either way.
class _LineRow extends StatefulWidget {
  const _LineRow({
    required this.line,
    required this.isEditable,
    required this.canRemove,
    required this.movesStock,
    required this.onQuantity,
    required this.onQuoted,
    required this.onUnitPrice,
    required this.onWeight,
    required this.onUnitCost,
    required this.onRemove,
    this.weightError,
    this.unitCostError,
    this.showVendorCost = false,
    super.key,
  });

  final InvoiceLine line;
  final bool isEditable;
  final bool canRemove;

  /// The order's stock has left the shelf — see [InvoiceLine.needsWeight].
  final bool movesStock;
  final ValueChanged<String> onQuantity;

  /// The catalogue's rate for the typed quantity, for the estimate.
  final ValueChanged<String> onQuoted;

  /// The clerk's own rate, on a «حسب الطلب» product added here.
  final ValueChanged<String> onUnitPrice;
  final ValueChanged<String> onWeight;

  /// What the vendor charges, on a وسيط line. See OUTSOURCED-PRODUCTS.md §6.1.
  final ValueChanged<String> onUnitCost;
  final VoidCallback onRemove;
  final String? weightError;
  final String? unitCostError;

  /// Whether the reader holds `products.view_cost` — the box is drawn for nobody else.
  final bool showVendorCost;

  @override
  State<_LineRow> createState() => _LineRowState();
}

class _LineRowState extends State<_LineRow> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.line.quantity);
  late final TextEditingController _price = TextEditingController(
    text: widget.line.isNew ? '' : widget.line.unitPrice,
  );
  late final TextEditingController _weight =
      TextEditingController(text: widget.line.warehouseQuantity);
  late final TextEditingController _cost = TextEditingController(text: widget.line.unitCost);

  /// Created on the first changed quantity, never for a line nobody touches.
  LineQuoteCubit? _quote;
  Timer? _debounce;

  /// The same pause «طلبية جديدة» waits: «300» is one request, not three.
  static const Duration _pause = Duration(milliseconds: 400);

  @override
  void dispose() {
    _debounce?.cancel();
    unawaited(_quote?.close());
    _controller.dispose();
    _price.dispose();
    _weight.dispose();
    _cost.dispose();
    super.dispose();
  }

  void _onQuantity(String value) {
    widget.onQuantity(value);

    if (widget.line.isPricedByHand) return;

    _debounce?.cancel();
    _debounce = Timer(_pause, () {
      if (!mounted) return;

      final quote = _quote ??= sl<LineQuoteCubit>();
      setState(() {});

      unawaited(
        quote.quote(
          productId: widget.line.productId,
          variantId: widget.line.variantId,
          quantity: Validators.toWesternDigits(value).replaceAll(',', '.'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final line = widget.line;
    final quote = _quote;

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
            '${line.productName} — ${line.variantLabel}',
            style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          if (quote != null && line.quantityChanged)
            // The catalogue's answer for the new quantity, refusals included — «أقل كمية…» is
            // worth reading while typing.
            BlocConsumer<LineQuoteCubit, LineQuoteState>(
              bloc: quote,
              listener: (context, state) {
                if (state case LineQuotePriced(:final quote)) {
                  widget.onQuoted(quote.unitPrice);
                }
              },
              builder: (context, state) => LineQuotePrice(state: state),
            )
          else if (line.isNew && !line.isPricedByHand)
            Text(
              'أدخل الكمية ليُحسب السعر',
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            )
          else if (!line.isNew)
            Text(
              // The rate is shown, not edited: it comes from the catalogue, and a field here
              // would be a way to undercut an agreed price.
              'السعر: ${line.unitPrice.grouped} · ${line.pricingUnitLabel}',
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
                  onChanged: _onQuantity,
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
          if (line.isNew && line.isPricedByHand) ...[
            SizedBox(height: 8.h),
            AppTextField(
              controller: _price,
              label: 'سعر الوحدة',
              // Said here rather than in a note under the section: this box exists for this
              // product and no other, and the reason belongs beside it.
              helperText: 'هذا المنتج يُسعَّر حسب الطلب',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,]')),
              ],
              onChanged: widget.onUnitPrice,
            ),
          ],
          if (line.needsWeight(movesStock: widget.movesStock) || widget.weightError != null) ...[
            SizedBox(height: 8.h),
            AppTextField(
              controller: _weight,
              label: 'الكمية من المخزن (${line.stockUnitLabel ?? 'وحدة المخزن'})',
              // The question «جاهزة للطباعة» asked, asked again because the line changed after
              // the stock left: bags weighed together have no per-bag weight to multiply out.
              helperText: 'يُباع بال${line.pricingUnitLabel} ويُخزَّن بوحدة أخرى — كم يخرج من الرف؟',
              errorText: widget.weightError,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,]')),
              ],
              onChanged: widget.onWeight,
            ),
          ],
          // Editable while the lines are; past that, «جاهزة» asks for it with the vendor's bill.
          if (widget.showVendorCost && widget.isEditable && line.isOrderedAlone) ...[
            SizedBox(height: 8.h),
            AppTextField(
              controller: _cost,
              label: 'تكلفة المورد لل${line.pricingUnitLabel}',
              helperText: 'ما يتقاضاه المورد عن هذه الطلبية — يُطلب عند «جاهزة» إن تُرك فارغاً',
              errorText: widget.unitCostError,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,]')),
              ],
              onChanged: widget.onUnitCost,
            ),
          ],
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

/// A [_Note] that is a warning: a refusal about the lines, or a total under what was paid.
class _Error extends StatelessWidget {
  const _Error({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        text,
        style: context.textTheme.bodySmall?.copyWith(color: scheme.onErrorContainer),
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


