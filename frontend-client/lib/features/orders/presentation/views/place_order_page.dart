import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:dayaa_client/core/widgets/product_thumbnail.dart';
import 'package:dayaa_client/features/delivery/models/city.dart';
import 'package:dayaa_client/features/orders/models/order_draft.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/place_order_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Sending an order.
///
/// **No total is drawn here, and that is deliberate.** The shop prices every line and reviews
/// the order before accepting it; a figure on this screen would be a promise the app made on
/// the shop's behalf. What the customer is told is what actually happens next — «نراجعها
/// ونؤكّد السعر».
class PlaceOrderPage extends StatelessWidget {
  const PlaceOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PlaceOrderCubit>(
      create: (_) => sl<PlaceOrderCubit>()..load(),
      child: const _PlaceOrderView(),
    );
  }
}

class _PlaceOrderView extends StatefulWidget {
  const _PlaceOrderView();

  @override
  State<_PlaceOrderView> createState() => _PlaceOrderViewState();
}

/// Stateful for the four controllers alone.
///
/// **The typing lives here, the choices live in the Cubit.** A ViewModel that emitted on every
/// keystroke would rebuild the whole form to redraw one field — see `PlaceOrderCubit`.
class _PlaceOrderViewState extends State<_PlaceOrderView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final order = await context.read<PlaceOrderCubit>().submit(
      recipientName: _name.text,
      recipientPhone: _phone.text,
      addressDetails: _address.text,
      note: _note.text,
    );

    if (!mounted || order == null) return;

    // **Not «تم بنجاح».** Nothing has been accepted yet, and a message that says otherwise is
    // the app promising what the shop has not.
    context.showSuccess('وصلتنا طلبيتك — سنراجعها ونتواصل معك');

    // `pushReplacement`, so the back button does not return to a form that would send the same
    // order a second time.
    context.pushReplacement(Routes.order(order.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlaceOrderCubit, PlaceOrderState>(
      listener: (context, state) {
        if (state case PlaceOrderReady(:final lastFailure?)) {
          context.showFailure(lastFailure);
        }
      },
      builder: (context, state) => switch (state) {
        PlaceOrderLoading() => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),

        // The server requires a `city_id`, so a destination picker that did not load is a
        // screen that genuinely cannot proceed — better said here than discovered at submit.
        PlaceOrderFailure(:final failure) => Scaffold(
          appBar: AppBar(title: const Text('سلتك')),
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(failure.message, textAlign: TextAlign.center),
                  SizedBox(height: 16.h),
                  OutlinedButton(
                    onPressed: context.read<PlaceOrderCubit>().load,
                    child: const Text('أعد المحاولة'),
                  ),
                ],
              ),
            ),
          ),
        ),

        final PlaceOrderReady ready => _Form(
          state: ready,
          formKey: _formKey,
          name: _name,
          phone: _phone,
          address: _address,
          note: _note,
          onSubmit: _submit,
        ),
      },
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.state,
    required this.formKey,
    required this.name,
    required this.phone,
    required this.address,
    required this.note,
    required this.onSubmit,
  });

  final PlaceOrderReady state;
  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController address;
  final TextEditingController note;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlaceOrderCubit>();
    final scheme = context.colorScheme;
    final city = state.selectedCity;

    return Scaffold(
      appBar: AppBar(title: const Text('سلتك')),
      body: AbsorbPointer(
        absorbing: state.isSubmitting,
        child: Form(
          key: formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
            children: [
              const _SectionTitle('المنتجات'),
              SizedBox(height: 8.h),
              if (state.lines.isEmpty)
                Text(
                  'لا توجد منتجات في هذه الطلبية.',
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.error),
                )
              else
                for (var index = 0; index < state.lines.length; index++) ...[
                  if (index > 0) SizedBox(height: 10.h),
                  _CartLine(
                    line: state.lines[index],
                    onRemove: () => cubit.removeLineAt(index),
                  ),
                ],

              SizedBox(height: 20.h),
              const _SectionTitle('الوجهة'),
              SizedBox(height: 8.h),

              DropdownButtonFormField<int>(
                initialValue: state.cityId,
                decoration: const InputDecoration(labelText: 'المدينة'),
                items: [
                  for (final option in state.cities)
                    DropdownMenuItem(value: option.id, child: Text(option.name)),
                ],
                onChanged: (value) => value == null ? null : cubit.chooseCity(value),
                validator: (value) => value == null ? 'اختر المدينة' : null,
              ),

              // The neighbourhoods of the chosen city, and none before one is chosen.
              if (city != null && city.regions.isNotEmpty) ...[
                SizedBox(height: 12.h),
                DropdownButtonFormField<int>(
                  initialValue: state.regionId,
                  decoration: InputDecoration(
                    labelText: city.isRegionRequired ? 'المنطقة' : 'المنطقة (اختياري)',
                  ),
                  items: [
                    for (final region in city.regions)
                      DropdownMenuItem(value: region.id, child: Text(region.name)),
                  ],
                  onChanged: cubit.chooseRegion,
                  validator: (value) =>
                      city.needsRegion && value == null ? 'اختر المنطقة' : null,
                ),
              ],

              if (city != null) ...[
                SizedBox(height: 8.h),
                _DeliveryNote(city: city),
              ],

              SizedBox(height: 20.h),
              const _SectionTitle('المستلم'),
              SizedBox(height: 8.h),
              AppTextField(
                controller: name,
                label: 'اسم المستلم (اختياري)',
                prefixIcon: AppIcons.person,
              ),
              SizedBox(height: 12.h),
              AppTextField(
                controller: phone,
                label: 'هاتف المستلم (اختياري)',
                prefixIcon: AppIcons.phone,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              SizedBox(height: 12.h),
              AppTextField(
                controller: address,
                label: 'تفاصيل العنوان (اختياري)',
                maxLines: 2,
              ),

              if (state.designs.isNotEmpty) ...[
                SizedBox(height: 20.h),
                const _SectionTitle('التصاميم'),
                SizedBox(height: 4.h),
                Text(
                  'اختر من مكتبتك — لا حاجة لإرسال الملف مرة أخرى.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    for (final design in state.designs)
                      FilterChip(
                        label: Text(design.label),
                        selected: state.designIds.contains(design.id),
                        onSelected: (_) => cubit.toggleDesign(design.id),
                      ),
                  ],
                ),
              ],

              SizedBox(height: 20.h),
              const _SectionTitle('ملاحظاتك'),
              SizedBox(height: 8.h),
              AppTextField(
                controller: note,
                label: 'أي شيء تريد أن نعرفه (اختياري)',
                maxLines: 3,
              ),

              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'بعد الإرسال نراجع الطلبية ونؤكّد التفاصيل والسعر قبل البدء.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
          child: AppButton(
            label: 'أرسل الطلبية',
            isLoading: state.isSubmitting,
            onPressed: state.canSubmit ? onSubmit : null,
          ),
        ),
      ),
    );
  }
}

/// What delivery to this city costs, when a rate has been agreed.
///
/// **Null is not «مجاناً».** A city with no agreed rate and a city that delivers for nothing are
/// different answers, and quoting the second for the first would be a price the shop never
/// promised.
class _DeliveryNote extends StatelessWidget {
  const _DeliveryNote({required this.city});

  final City city;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final text = switch (city) {
      City(isOfficePickup: true) => 'الاستلام من المكتب',
      City(deliveryPrice: final price?) => 'التوصيل: $price د.ل',
      _ => 'سعر التوصيل يُحدَّد عند المراجعة',
    };

    return Row(
      children: [
        Icon(
          city.isOfficePickup ? AppIcons.officePickup : AppIcons.city,
          size: 16.sp,
          color: scheme.onSurfaceVariant,
        ),
        SizedBox(width: 6.w),
        Text(
          text,
          style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
  );
}

/// One product in the basket, as something a customer can actually check.
///
/// **It used to be a `dense` `ListTile` with no padding**, which is the shape of a settings row:
/// two lines of grey text of the same weight, flush against the page, with nothing to say where
/// one product ended and the next began. The basket is the last screen before an order is sent
/// and these rows are the whole of what is being sent — the picture, the size and the quantity
/// are what somebody re-reads before they commit, so each one is drawn as a thing rather than as
/// a line of a list.
///
/// **The quantity is pulled out of the subtitle** and given the shop's own colour. It is the one
/// number on this screen the customer chose themselves, and the one a mistake hides in.
class _CartLine extends StatelessWidget {
  const _CartLine({required this.line, required this.onRemove});

  final OrderDraftLine line;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard(
      padding: EdgeInsets.all(10.w),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: SizedBox(
              width: 56.w,
              height: 56.w,
              child: ProductThumbnail(image: line.imageUrl),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  line.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (line.subtitle case final subtitle?) ...[
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // **The delete stays quiet.** It is the only control on the row and a full-strength
          // icon beside two lines of text reads as the thing to press, on a screen whose one
          // action is «أرسل الطلبية».
          IconButton(
            icon: Icon(AppIcons.delete, size: 20.sp, color: scheme.onSurfaceVariant),
            tooltip: 'احذف',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
