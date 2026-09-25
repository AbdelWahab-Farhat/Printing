import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/utils/validators.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/core/widgets/app_dropdown.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:dayaa_client/core/widgets/product_thumbnail.dart';
import 'package:dayaa_client/features/delivery/models/city.dart';
import 'package:dayaa_client/features/orders/models/order_draft.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/place_order_cubit.dart';
import 'package:dayaa_client/features/orders/presentation/widgets/design_picker_sheet.dart';
import 'package:dayaa_client/features/orders/presentation/widgets/empty_basket.dart';
import 'package:dayaa_client/features/shops/presentation/widgets/shop_card.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// السلة — معالجٌ من خطوتين يرسمهما شريطٌ أفقيٌّ أعلاها: «المنتجات» ثم «بيانات الطلب».
///
/// **الخطوة الأولى ما في السلة وحده**، و«إتمام الطلب» تحتها. **والثانية تُملأ من الحساب:** أول متاجر
/// العميل مختارٌ ومدينته ومنطقته معه، ورقم هاتفه في «هاتف الاستلام». لا اسمَ مستلمٍ — المستلم هو
/// العميل نفسه — ولا «تفاصيل عنوان»: الوجهة مدينةٌ ومنطقةٌ ومتجر. **والمتاجر تُضاف من «حسابي» ←
/// «متاجري» لا من هنا** (طلب صاحب العمل): السلة تختار مما هناك، وتُخفي القسم لحسابٍ بلا متاجر.
///
/// **ولا مجموع يُرسم هنا، عمداً.** المتجر يسعّر كل سطرٍ ويراجع الطلبية قبل قبولها، ورقمٌ على هذه
/// الشاشة وعدٌ يقطعه التطبيق عن المتجر. ما يُقال للعميل هو ما سيحدث فعلاً: «نراجعها ونؤكّد السعر».
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

/// ذات حالةٍ من أجل المتحكّمين وحدهما.
///
/// **الكتابة هنا، والاختيارات في الـ Cubit.** ViewModel يبعث مع كل حرفٍ يعيد بناء النموذج كله ليرسم
/// حقلاً واحداً — انظر `PlaceOrderCubit`.
class _PlaceOrderViewState extends State<_PlaceOrderView> {
  /// **فوق الخطوتين لا داخل الثانية.** الانتقال بينهما يُبقي الخطوة الخارجة على الشاشة لحظةً وهي
  /// تتلاشى، ومفتاحٌ عامٌّ داخلها كان سيوجد مرتين حين يعود العميل إلى «بيانات الطلب» قبل أن تكتمل.
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _note = TextEditingController();

  bool _phoneSeeded = false;

  @override
  void dispose() {
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  /// رقم الحساب في «هاتف الاستلام»، مرةً واحدة: ما يكتبه العميل بعدها له، ولا تمسحه إعادةُ تحميل.
  void _seedPhone(PlaceOrderReady ready) {
    if (_phoneSeeded) return;

    _phoneSeeded = true;

    if (ready.customerPhone case final phone?) _phone.text = phone;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final order = await context.read<PlaceOrderCubit>().submit(
      recipientPhone: _phone.text,
      note: _note.text,
    );

    if (!mounted || order == null) return;

    // **لا «تم بنجاح».** لم يُقبل شيءٌ بعد، ورسالةٌ تقول غير ذلك وعدٌ من التطبيق بما لم يَعِد به المتجر.
    context.showSuccess('وصلتنا طلبيتك — سنراجعها ونتواصل معك');

    // `pushReplacement` كي لا يعيد زرّ الرجوع إلى سلةٍ ترسل الطلبية نفسها مرةً ثانية.
    context.pushReplacement(Routes.order(order.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlaceOrderCubit, PlaceOrderState>(
      // أول مرةٍ تجهز فيها الشاشة يُملأ الهاتف، وكلُّ رفضٍ جديد يُقال مرةً واحدة — لا مع كل حالةٍ تحمله.
      listenWhen: (previous, current) => switch ((previous, current)) {
        (PlaceOrderReady(lastFailure: final before), PlaceOrderReady(lastFailure: final after)) =>
          after != null && after != before,
        (_, PlaceOrderReady()) => true,
        _ => false,
      },
      listener: (context, state) {
        if (state is! PlaceOrderReady) return;

        _seedPhone(state);

        // رفض الرقم يُعلَّق تحت حقله، وما عداه رسالة.
        if (state.lastFailure case final failure? when state.phoneError == null) {
          context.showFailure(failure);
        }
      },
      builder: (context, state) => switch (state) {
        PlaceOrderLoading() => Scaffold(
          appBar: AppBar(title: const Text('سلتك')),
          body: const Center(child: CircularProgressIndicator()),
        ),

        // الخادم يطلب `city_id`، والمتاجر هي ما تُختار منه الوجهة — فشاشةٌ لم يصلها أحدهما لا
        // تستطيع المتابعة، وقولُ ذلك هنا خيرٌ من اكتشافه عند الإرسال.
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
                  AppButton.outlined(
                    label: 'أعد المحاولة',
                    onPressed: context.read<PlaceOrderCubit>().load,
                  ),
                ],
              ),
            ),
          ),
        ),

        final PlaceOrderReady ready => _Checkout(
          state: ready,
          formKey: _formKey,
          phone: _phone,
          note: _note,
          onSubmit: _submit,
        ),
      },
    );
  }
}

class _Checkout extends StatelessWidget {
  const _Checkout({
    required this.state,
    required this.formKey,
    required this.phone,
    required this.note,
    required this.onSubmit,
  });

  final PlaceOrderReady state;
  final GlobalKey<FormState> formKey;
  final TextEditingController phone;
  final TextEditingController note;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlaceOrderCubit>();
    final onDetails = state.step == CheckoutStep.details;

    // الرجوع من «بيانات الطلب» يعود إلى المنتجات ولا يغادر السلة — للإيماءة ولسهم الشريط معاً، فكلاهما
    // يمرّ بـ `maybePop`.
    return PopScope(
      canPop: !onDetails,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) cubit.back();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('سلتك')),
        body: AbsorbPointer(
          absorbing: state.isSubmitting,
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                  child: _CheckoutStepper(
                    step: state.step,
                    canProceed: state.canProceed,
                    onStepReached: (index) => index == CheckoutStep.products.index
                        ? cubit.back()
                        : cubit.proceed(),
                  ),
                ),
                Expanded(
                  child: _StepSwitcher(
                    step: state.step,
                    child: onDetails
                        ? _DetailsStep(
                            key: const ValueKey(CheckoutStep.details),
                            state: state,
                            phone: phone,
                            note: note,
                          )
                        : _ProductsStep(
                            key: const ValueKey(CheckoutStep.products),
                            state: state,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // **سلةٌ فارغة بلا شريط:** رسمها يحمل زرّه «تصفّح المنتجات»، و«إتمام الطلب» معطّلاً تحته زرٌّ
        // ثانٍ لا يفعل شيئاً.
        bottomNavigationBar: state.lines.isEmpty
            ? null
            : SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // الرقم بجانب الزرّ كما في تطبيقات التسوّق: البضاعة في الخطوة الأولى، ومعها التوصيل
                      // في الثانية حين عُرفت المدينة.
                      _TotalRow(
                        label: onDetails ? 'الإجمالي' : 'المجموع',
                        value: _amountText(
                          state.pricing,
                          onDetails ? state.quote?.totalWithDelivery : state.quote?.itemsTotal,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      if (onDetails)
                        Row(
                          children: [
                            Expanded(
                              child: AppButton.outlined(
                                label: 'السابق',
                                onPressed: state.isSubmitting ? null : cubit.back,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              flex: 2,
                              child: AppButton(
                                label: 'أرسل الطلبية',
                                isLoading: state.isSubmitting,
                                onPressed: state.canSubmit ? onSubmit : null,
                              ),
                            ),
                          ],
                        )
                      else
                        AppButton(
                          label: 'إتمام الطلب',
                          onPressed: state.canProceed ? cubit.proceed : null,
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// الشريط أعلى السلة: دائرتان وخطٌّ بينهما، والخطوة الحالية بلون العلامة.
///
/// **بإعدادات معالج بريمولا نفسها**، ومنها اثنان لا يُمسّان: `showLoadingAnimation: false` —
/// وإلا دار رسمُ Lottie داخل الخطوة النشطة بلا توقّف — و`disableScroll: true`، وإلا مرّر الشريط نفسه
/// إلى الخطوة بحركة. الحركة الوحيدة المسموحة إزاحةٌ وشفافية (RULES §7)، وبهذين لا يعمل فيه أيُّ Ticker.
///
/// الخطوة الثانية تُلمس حين تكون السلة غير فارغة، والأولى تُلمس دائماً.
class _CheckoutStepper extends StatelessWidget {
  const _CheckoutStepper({
    required this.step,
    required this.canProceed,
    required this.onStepReached,
  });

  final CheckoutStep step;
  final bool canProceed;
  final ValueChanged<int> onStepReached;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final active = step.index;

    // ما مضى وما هو الآن بلون العلامة، وما لم يُبلغ بعد باهت.
    TextStyle? titleStyle(int index) => context.textTheme.labelLarge?.copyWith(
      fontWeight: index == active ? FontWeight.w700 : FontWeight.w600,
      color: index <= active ? scheme.primary : scheme.onSurfaceVariant,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // الخطّ يملأ ما تتركه الدائرتان، فيمتدّ الشريط على عرض الشاشة كما في بريمولا — **ناقصاً
        // ما يكفي لعنوانَي الطرفين.** كلُّ عنوانٍ يتوسّط دائرته فيتجاوزها إلى الخارج، وبخصم بريمولا
        // (٧٨) كان «بيانات الطلب» يلامس حافة الهاتف على عرض ٣٩٠.
        final lineLength = (constraints.maxWidth - 120.w).clamp(120.w, 300.w).toDouble();

        return EasyStepper(
          activeStep: active,
          enableStepTapping: true,
          disableScroll: true,
          fitWidth: false,
          showLoadingAnimation: false,
          showStepBorder: false,
          stepRadius: 15.r,
          internalPadding: 4.w,
          padding: EdgeInsets.zero,
          lineStyle: LineStyle(
            lineLength: lineLength,
            lineThickness: 1.5,
            lineType: LineType.normal,
            finishedLineColor: scheme.primary,
            activeLineColor: scheme.outlineVariant,
            unreachedLineColor: scheme.outlineVariant,
          ),
          activeStepBackgroundColor: scheme.primary,
          activeStepIconColor: scheme.onPrimary,
          activeStepTextColor: scheme.primary,
          finishedStepBackgroundColor: scheme.primaryContainer,
          finishedStepIconColor: scheme.onPrimaryContainer,
          finishedStepTextColor: scheme.primary,
          unreachedStepBackgroundColor: scheme.surfaceContainerHighest,
          unreachedStepIconColor: scheme.onSurfaceVariant,
          unreachedStepTextColor: scheme.onSurfaceVariant,
          onStepReached: onStepReached,
          steps: [
            EasyStep(
              icon: Icon(AppIcons.products),
              finishIcon: Icon(AppIcons.check),
              customTitle: Text(
                'المنتجات',
                textAlign: TextAlign.center,
                style: titleStyle(CheckoutStep.products.index),
              ),
            ),
            EasyStep(
              enabled: canProceed,
              icon: Icon(AppIcons.mapPin),
              customTitle: Text(
                'بيانات الطلب',
                textAlign: TextAlign.center,
                style: titleStyle(CheckoutStep.details.index),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// الانتقال بين الخطوتين: الخطوة تنزلق قليلاً وتتلاشى، ولا شيء يكبر أو يصغر.
///
/// **الجهة جهة القراءة.** في العربية ما بعدُ إلى اليسار: «بيانات الطلب» تدخل من اليسار والمنتجات
/// تخرج إلى اليمين، والرجوع عكس ذلك. ومع «تقليل الحركة» تتبدّل الخطوة في إطارٍ واحد.
class _StepSwitcher extends StatelessWidget {
  const _StepSwitcher({required this.step, required this.child});

  final CheckoutStep step;
  final Widget child;

  /// كم تنزلق الخطوة من عرضها.
  static const double _shift = 0.14;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final forward = step == CheckoutStep.details;
    final nextSide = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;

    return ClipRect(
      child: AnimatedSwitcher(
        duration: still ? Duration.zero : const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) => Stack(
          fit: StackFit.expand,
          children: [...previous, ?current],
        ),
        transitionBuilder: (child, animation) {
          // الداخلة تأتي من جهة وجهتها، والخارجة تمضي إلى الجهة الأخرى.
          final isIncoming = child.key == ValueKey(step);
          final dx = _shift * nextSide * (isIncoming == forward ? 1 : -1);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(dx, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: child,
      ),
    );
  }
}

/// الخطوة الأولى: ما في السلة، ويُحذف منه.
class _ProductsStep extends StatelessWidget {
  const _ProductsStep({required this.state, super.key});

  final PlaceOrderReady state;

  @override
  Widget build(BuildContext context) {
    // تأخذ الخطوة كلّها، لا صفّاً في قائمة: سلةٌ فارغة حالةٌ عادية لا خطأ.
    if (state.lines.isEmpty) return const EmptyBasket();

    final cubit = context.read<PlaceOrderCubit>();

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      children: [
        for (var index = 0; index < state.lines.length; index++) ...[
          if (index > 0) SizedBox(height: 10.h),
          _CartLine(
            line: state.lines[index],
            price: _amountText(state.pricing, state.quoteForLine(index)?.lineTotal),
            // صفحة المنتج، لتُراجَع الكمية أو يُبدَّل المقاس. ما يتغيّر هناك يصل إلى هنا عبر السلة.
            onOpen: () => context.push(Routes.product(state.lines[index].line.productId)),
            onRemove: () => cubit.removeLineAt(index),
          ),
        ],
      ],
    );
  }
}

/// الخطوة الثانية: إلى أيّ متجرٍ، وأين تُسلَّم، ومن يُتصل به — ممتلئةً من الحساب.
class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.state,
    required this.phone,
    required this.note,
    super.key,
  });

  final PlaceOrderReady state;
  final TextEditingController phone;
  final TextEditingController note;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlaceOrderCubit>();
    final scheme = context.colorScheme;
    final city = state.selectedCity;

    Region? region;
    for (final candidate in city?.regions ?? const <Region>[]) {
      if (candidate.id == state.regionId) region = candidate;
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      children: [
        // من متاجر العميل يُختار، ولا يُضاف هنا — تلك «متاجري» في «حسابي». وحسابٌ بلا متاجر لا يرى
        // قسماً فارغاً: الوجهة تحته تكفيه.
        if (state.shops.isNotEmpty) ...[
          const _SectionTitle('المتجر'),
          SizedBox(height: 8.h),
          for (final shop in state.shops) ...[
            ShopCard(
              shop: shop,
              isSelected: shop.id == state.shopId,
              onTap: () => cubit.chooseShop(shop.id),
            ),
            SizedBox(height: 10.h),
          ],
          SizedBox(height: 10.h),
        ],
        const _SectionTitle('الاستلام'),
        SizedBox(height: 8.h),
        // **المدينة والمنطقة جنباً إلى جنب** (طلب صاحب العمل)، وسعر التوصيل داخل صندوق المدينة التي
        // يخصّها، كما في صندوق المدينة عند الموظفين. بلا أيقونتين: نصف العرض لا يتّسع لأيقونةٍ واسمٍ
        // وسعر، والعنوان فوق كل صندوقٍ يقول ما هو.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppDropdown<City>(
                label: 'المدينة',
                items: state.cities,
                value: city,
                keyOf: (option) => option.id,
                labelOf: (option) => option.name,
                trailingOf: _deliveryTag,
                onChanged: (option) => option == null ? null : cubit.chooseCity(option.id),
                validator: (option) => option == null ? 'اختر المدينة' : null,
              ),
            ),

            SizedBox(width: 12.w),

            // **المنطقة ظاهرةٌ دائماً** (طلب صاحب العمل)، كصندوقها في تطبيق الموظفين: الصفّ لا يتبدّل
            // شكله كلما تبدّلت المدينة. تُفتح حين يكون للمدينة مناطق، وتقول لماذا هي فارغة حين لا.
            Expanded(
              child: AppDropdown<Region>(
                // مفتاحٌ بالمدينة: منتقٍ بُني لمدينةٍ لا يُعاد استعماله لغيرها بقيمةٍ من هناك.
                key: ValueKey('order-region-${city?.id}'),
                // «المنطقة» وحدها: «(اختياري)» في نصف العرض تنزل إلى سطرٍ ثانٍ مع خطٍّ مكبَّر فيهبط
                // صندوقها عن صندوق المدينة، وخيار «بدون تحديد» يقول ذلك أصلاً.
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
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),
        // **حقلٌ واحدٌ من المستلم، وهو ما لا يقوله الحساب وحده.** الاسم اسم العميل والوجهة متجره، أما
        // الرقم فهو ما يتصل به المندوب، وقد يكون أحياناً رقمَ غيره — فيُعرض ممتلئاً برقمه ويبقى له.
        AppTextField(
          controller: phone,
          label: 'هاتف الاستلام',
          prefixIcon: AppIcons.phone,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          validator: Validators.libyanPhone,
          errorText: state.phoneError,
        ),

        // المختار من المكتبة بشكله واسمه، والاختيار نفسه في ورقةٍ من الأسفل (طلب صاحب العمل). ولمس
        // المختار يفتح الورقة أيضاً: هناك يُترك كما يُختار.
        if (state.designs.isNotEmpty) ...[
          SizedBox(height: 20.h),
          const _SectionTitle('التصاميم'),
          SizedBox(height: 8.h),
          for (final design in state.designs)
            if (state.designIds.contains(design.id)) ...[
              DesignOptionRow(design: design, onTap: () => showDesignPicker(context)),
              SizedBox(height: 8.h),
            ],
          AppButton.tonal(
            label: state.designIds.isEmpty
                ? 'اختيار التصاميم'
                : 'تعديل الاختيار (${state.designIds.length})',
            icon: AppIcons.designs,
            onPressed: () => showDesignPicker(context),
          ),
        ],

        SizedBox(height: 20.h),
        // «ملاحظات» وحدها (طلب صاحب العمل): الاسم فوق الصندوق يكفي، بلا جملةٍ تشرح ما يُكتب فيه.
        AppTextField(
          controller: note,
          label: 'ملاحظات',
          maxLines: 3,
          textInputAction: TextInputAction.newline,
        ),

        SizedBox(height: 20.h),
        _CostBreakdown(state: state),

        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            'بعد الإرسال نراجع الطلبية ونؤكّد التفاصيل والسعر قبل البدء.',
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSecondaryContainer),
          ),
        ),
      ],
    );
  }
}

/// سعر التوصيل في طرف صندوق المدينة وفي كل صفٍّ من قائمتها.
///
/// **`null` ليس «مجاناً»،** فلا يُكتب له شيء: مدينةٌ لم يُتّفق على سعرها بعد جوابها «يُحدَّد بعد
/// المراجعة» في ملخّص التكلفة، لا صفرٌ هنا. والاستلام من المكتب اسمه يقول إنه لا توصيل.
String? _deliveryTag(City city) => switch (city) {
  City(isOfficePickup: true) => null,
  City(deliveryPrice: final price?) => _money(price),
  _ => null,
};

/// «٥٠٠ د.ل» — مبلغٌ من الخادم كما يُكتب في كل شاشةٍ من التطبيق.
String _money(String amount) => '${amount.asMoney} د.ل';

/// ما يُكتب مكان مبلغٍ من التسعير: الرقم حين وصل، وإلا ما يقول لماذا لا رقم.
///
/// **`null` بعد التسعير ليس صفراً:** سطرٌ «حسب الطلب» أو مدينةٌ بلا سعرٍ متّفقٍ عليه — والرقم يُحدَّد
/// حين يراجع المتجر الطلبية. أما قبل وصول التسعير فنقاطٌ ثابتة، بلا دائرةٍ تدور بجانب كل رقم.
String _amountText(BasketPricing pricing, String? amount) => switch (pricing) {
  BasketPricingPending() => '…',
  BasketPricingFailed() => 'تعذّر الحساب',
  BasketPriced() => amount == null ? awaitingQuoteLabel : _money(amount),
};

/// الرقم بجانب زرّ الخطوة، كما في تطبيقات التسوّق: المجموع في الأولى، والإجمالي في الثانية.
class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isFigure = value.endsWith('د.ل');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          label,
          style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        Text(
          value,
          style: isFigure
              ? context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: context.colorScheme.primary,
                )
              : context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colorScheme.onSurfaceVariant,
                ),
        ),
      ],
    );
  }
}

/// ما يتكوّن منه الإجمالي: البضاعة، والتوصيل إلى المدينة المختارة. والإجمالي نفسه بجانب زرّ الإرسال.
///
/// **التوصيل هنا ويدخل الإجمالي،** وليس في إجمالي الطلبية على شاشتها: رسم المندوب يُدفع له عند الباب
/// لا لنا، لكنه مالٌ يخرج من جيب العميل، و«التكلفة النهائية» التي طلبها صاحب العمل تجمعهما.
class _CostBreakdown extends StatelessWidget {
  const _CostBreakdown({required this.state});

  final PlaceOrderReady state;

  @override
  Widget build(BuildContext context) {
    final city = state.selectedCity;

    final delivery = switch (city) {
      null => 'اختر المدينة',
      City(isOfficePickup: true) => 'الاستلام من المكتب',
      _ => _amountText(state.pricing, state.quote?.deliveryPrice),
    };

    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Column(
        children: [
          _CostRow(
            label: 'المنتجات',
            value: _amountText(state.pricing, state.quote?.itemsTotal),
          ),
          SizedBox(height: 8.h),
          _CostRow(label: 'التوصيل', value: delivery),
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      children: [
        Text(
          label,
          style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const Spacer(),
        Text(
          value,
          style: context.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
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

/// منتجٌ في السلة، مرسومٌ شيئاً يُراجَع لا سطراً في قائمة.
///
/// **كان `ListTile` كثيفاً بلا حشو** — شكل صفّ إعدادات: سطران رماديان بالوزن نفسه، ملتصقان بالصفحة،
/// ولا شيء يفصل منتجاً عن الذي يليه. وهذه الخطوة آخر ما يُرى قبل إرسال الطلبية، والصورة والمقاس
/// والكمية بوحدتها وما يكلّفه السطر هي ما يُعاد قراءته قبل الالتزام — فكلُّ سطرٍ يُرسم شيئاً قائماً
/// بذاته، ولمسُه يفتح منتجه.
class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.line,
    required this.price,
    required this.onOpen,
    required this.onRemove,
  });

  final OrderDraftLine line;

  /// ما يكلّفه السطر كما سعّره الخادم، أو ما يقول لماذا لا رقم بعد.
  final String price;

  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isFigure = price.endsWith('د.ل');

    return AppCard(
      padding: EdgeInsets.all(10.w),
      onTap: onOpen,
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
                // المقاس والكمية بوحدتها — «١٬٠٠٠ قطعة» أو «٥٠ كجم» — بحجم نصّ الصفّ لا بحاشيةٍ صغيرة.
                if (line.subtitle case final subtitle?) ...[
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                SizedBox(height: 4.h),
                Text(
                  price,
                  style: isFigure
                      ? context.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        )
                      : context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          // **الحذف هادئ.** هو الزرّ الوحيد في الصف، وأيقونةٌ بكامل قوّتها بجانب سطرين من النص تُقرأ
          // كأنها ما يُضغط، على شاشةٍ فعلُها الوحيد «إتمام الطلب».
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
