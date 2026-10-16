import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/utils/validators.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:dayaa_client/features/wallet/models/online_top_up_models.dart';
import 'package:dayaa_client/features/wallet/models/top_up_catalog.dart';
import 'package:dayaa_client/features/wallet/presentation/viewmodel/top_up_cubit.dart';
import 'package:dayaa_client/features/wallet/presentation/views/payment_gateway_page.dart';
import 'package:dayaa_client/features/wallet/usecases/top_up_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ما يُفتح به الشحن من شاشة الطلبية: «اشحن وادفع».
class TopUpArgs {
  const TopUpArgs({this.orderId, this.amount, this.phone});

  /// تُدفع من المحفظة بعد الشحن، على الخادم.
  final int? orderId;

  /// ما ينقص المحفظةَ لتغطي الطلبية — يُكتب في الخانة، ويُغيَّر.
  final String? amount;

  /// هاتف الحساب — يُملأ به رقم ليبيانا، كما في بريمولا.
  final String? phone;
}

/// «اشحن محفظتك» — **ورقةٌ من أسفل على نسق بريمولا** (`payment_flow_sheet.dart`): ثلاث صفحات تنزلق
/// أفقياً بارتفاعٍ ثابت — الطرق، ثم البيانات والعمولة، ثم رمز التحقق. البطاقة المصرفية تفتح «بوابة
/// الدفع» فوقها. CUSTOMER-WALLET §٥.
///
/// **المال يمرّ بالمحفظة دائماً**: يُشحن أولاً، ثم تُدفع منه الطلبية في «اشحن وادفع».
///
/// تعود `true` حين شُحنت المحفظة، فيقرأ من فتحها رصيده — وطلبيته.
Future<bool?> showTopUpSheet(BuildContext context, {TopUpArgs? args}) {
  final media = MediaQuery.of(context);
  final maxHeight = (media.size.height - media.padding.top - 12.h).clamp(420.0, media.size.height);

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: BoxConstraints(maxWidth: double.infinity, maxHeight: maxHeight),
    backgroundColor: context.colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => BlocProvider<TopUpCubit>(
      create: (_) => TopUpCubit(
        getMethods: sl(),
        quote: sl(),
        start: sl(),
        confirmOtp: sl(),
        getAttempt: sl(),
        orderId: args?.orderId,
        initialAmount: args?.amount?.asPlainNumber,
      )..load(),
      child: _TopUpSheet(height: (maxHeight * .78).clamp(460.0, maxHeight), args: args),
    ),
  );
}

class _TopUpSheet extends StatefulWidget {
  const _TopUpSheet({required this.height, this.args});

  final double height;
  final TopUpArgs? args;

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _go(int page) async {
    if (!mounted || page == _page) return;

    setState(() => _page = page);
    await _pages.animateToPage(page, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  /// «رجوع»: من البيانات إلى الطرق؛ ومن الرمز محاولةٌ جديدة من أوّلها.
  Future<void> _back() async {
    if (_page == 2) await context.read<TopUpCubit>().again();

    await _go(0);
  }

  void _onState(BuildContext context, TopUpState state) {
    switch (state) {
      case TopUpOtp():
        unawaited(_go(2));
      case TopUpWaiting(attempt: TopUpAttempt(:final paymentUrl?)):
        unawaited(PaymentGatewayPage.open(context, paymentUrl));
      // EzonePay took the code and has not yet said «تم الدفع» — the code page gives way to
      // «نتحقق من الدفع», and the cubit asks until it is clear. No second code: EzonePay would
      // answer it «السجل غير موجود».
      case TopUpWaiting():
        unawaited(_go(2));
      case TopUpDone(:final attempt):
        // «بوابة الدفع» فوق الورقة تُغلق نفسها على الخبر نفسه؛ هنا تُغلق إن لم تفعل بعد، ثم الورقة
        // — ولا `pop()` أعمى يغلق ما ليس له.
        final navigator = Navigator.of(context);
        final sheet = ModalRoute.of(context);

        if (sheet != null && sheet.isActive) navigator.popUntil((r) => r == sheet);

        if (attempt.succeeded) {
          context.showSuccess('تمت تعبئة محفظتك بمبلغ ${attempt.amount.asMoney} د.ل');
          navigator.pop(true);
        } else {
          context.showError(attempt.failureReason ?? 'لم تتم عملية الدفع، ولم يُخصم منك شيء');
          unawaited(context.read<TopUpCubit>().again());
          unawaited(_go(0));
        }
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return BlocConsumer<TopUpCubit, TopUpState>(
      listenWhen: (previous, current) => previous.runtimeType != current.runtimeType,
      listener: _onState,
      builder: (context, state) {
        final form = state is TopUpForm ? state : null;
        final title = switch (_page) {
          0 => widget.args?.orderId == null ? 'حدد طريقة الشحن' : 'اشحن وادفع',
          1 => form?.selected.label ?? '',
          _ => state is TopUpWaiting ? 'تأكيد الدفع' : 'رمز التحقق',
        };

        return Padding(
          padding: EdgeInsets.only(bottom: context.keyboardInset),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            height: widget.height,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48.w,
                          child: _page > 0
                              ? IconButton(
                                  tooltip: 'رجوع',
                                  onPressed: () => unawaited(_back()),
                                  icon: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: scheme.onSurface),
                                )
                              : null,
                        ),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              title,
                              key: ValueKey(title),
                              textAlign: TextAlign.center,
                              style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        SizedBox(width: 48.w),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: .3)),
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _MethodsPage(
                          state: state,
                          onPick: (method) {
                            context.read<TopUpCubit>().select(method);
                            unawaited(_go(1));
                          },
                        ),
                        if (form != null)
                          _DetailsPage(
                            key: ValueKey(form.selected.id),
                            form: form,
                            phone: widget.args?.phone,
                            orderId: widget.args?.orderId,
                          )
                        else
                          const Center(child: CircularProgressIndicator()),
                        switch (state) {
                          final TopUpOtp otp => _OtpPage(otp: otp),
                          TopUpWaiting(attempt: TopUpAttempt(paymentUrl: null)) => const _ConfirmingPage(),
                          _ => const SizedBox.shrink(),
                        },
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── الصفحة الأولى: الطرق ───────────────────────────────────────────────────────────────────

class _MethodsPage extends StatelessWidget {
  const _MethodsPage({required this.state, required this.onPick});

  final TopUpState state;
  final ValueChanged<TopUpMethod> onPick;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      TopUpForm(:final usable) => ListView.separated(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
        itemCount: usable.length,
        separatorBuilder: (_, _) => SizedBox(height: 8.h),
        itemBuilder: (context, i) => _MethodTile(
          key: ValueKey(usable[i].id),
          method: usable[i],
          onTap: () => onPick(usable[i]),
        ),
      ),
      TopUpUnavailable(:final failure) => _Unavailable(failure: failure),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// أصغر ما بقي من حدود المحلّ وحدّ EzonePay — null: بلا حد.
String? _remainingOf(TopUpMethod method) {
  final caps = [?method.maxAmount, ...method.remaining];

  if (caps.isEmpty) return null;

  return caps.reduce((a, b) => thousandths(a) <= thousandths(b) ? a : b);
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.method, required this.onTap, super.key});

  final TopUpMethod method;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final brand = brandOf(method.id);
    final left = method.remaining.isEmpty ? null : _remainingOf(method);
    final exhausted = left != null && thousandths(left) < thousandths('1');

    return Opacity(
      opacity: exhausted ? .5 : 1,
      child: InkWell(
        onTap: exhausted ? null : onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: .35)),
          ),
          child: Row(
            children: [
              _Logo(brand: brand, box: 54.w, image: 40.w, radius: 12.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(method.label, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    if (brand.subtitle case final subtitle?) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: .5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (left != null)
                      _Chip(
                        text: exhausted ? 'تم بلوغ الحد المسموح' : 'المتبقّي: ${left.asMoney} د.ل',
                        color: exhausted ? scheme.error : scheme.primary,
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded, size: 22.sp, color: scheme.onSurface.withValues(alpha: .45)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: 6.h),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Text(
        text,
        style: context.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 11.sp),
      ),
    ),
  );
}

/// شعار الطريقة في مربّعٍ بلون العلامة الباهت — أو أيقونة البطاقة لطريقةٍ بلا شعار.
class _Logo extends StatelessWidget {
  const _Logo({required this.brand, required this.box, required this.image, required this.radius});

  final TopUpBrand brand;
  final double box;
  final double image;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: box,
      height: box,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: switch (brand.asset) {
        final asset? => ClipRRect(
          borderRadius: BorderRadius.circular(6.r),
          child: Image.asset(asset, width: image, height: image, fit: BoxFit.contain),
        ),
        null => Icon(Icons.credit_card_rounded, size: image * .7, color: scheme.primary),
      },
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({this.failure});

  final Failure? failure;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            failure?.message ?? 'الشحن من التطبيق غير متاح الآن — تُشحن المحفظة من المتجر',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge,
          ),
          if (failure != null) ...[
            SizedBox(height: 16.h),
            AppButton.tonal(label: 'إعادة المحاولة', expands: false, onPressed: context.read<TopUpCubit>().load),
          ],
        ],
      ),
    ),
  );
}

// ── الصفحة الثانية: البيانات والعمولة ───────────────────────────────────────────────────────

class _DetailsPage extends StatefulWidget {
  const _DetailsPage({required this.form, this.phone, this.orderId, super.key});

  final TopUpForm form;
  final String? phone;

  /// «اشحن وادفع» — يقال تحت العمولة أين يذهب المال.
  final int? orderId;

  @override
  State<_DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<_DetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(text: context.read<TopUpCubit>().amount);
  final _card = TextEditingController();
  late final _mobile = TextEditingController(
    text: widget.form.selected.id == libyana ? (widget.phone ?? '') : '',
  );
  final _birthYear = TextEditingController();

  Map<String, List<String>> _fieldErrors = const {};

  @override
  void dispose() {
    _amount.dispose();
    _card.dispose();
    _mobile.dispose();
    _birthYear.dispose();
    super.dispose();
  }

  String? _errorOf(String field) => _fieldErrors[field]?.firstOrNull;

  bool get _asksMobile => widget.form.selected.needsServiceMobileNumber || widget.form.selected.id == libyana;

  @override
  Widget build(BuildContext context) {
    final form = widget.form;
    final method = form.selected;
    final brand = brandOf(method.id);
    final scheme = context.colorScheme;
    final cap = _remainingOf(method);
    final digitsOnly = [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩]'))];

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 12.h),
            Center(child: _Logo(brand: brand, box: 72.w, image: 44.w, radius: 20.r)),
            SizedBox(height: 16.h),
            if (method.needsCardNumber) ...[
              AppTextField(
                controller: _card,
                hint: brand.cardLabel ?? 'رقم البطاقة',
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                inputFormatters: digitsOnly,
                errorText: _errorOf('card_number'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'الرجاء إدخال ${brand.cardLabel ?? 'رقم البطاقة'}' : null,
              ),
              SizedBox(height: 16.h),
            ],
            if (_asksMobile) ...[
              AppTextField(
                controller: _mobile,
                hint: brand.mobileLabel ?? 'رقم الهاتف',
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                maxLength: 10,
                inputFormatters: digitsOnly,
                errorText: _errorOf('service_mobile_number'),
                helperText: method.id == libyana ? 'فارغاً: رقم حسابك' : null,
                validator: method.id == libyana ? null : Validators.libyanPhone,
              ),
              SizedBox(height: 16.h),
            ],
            if (method.needsBirthYear) ...[
              AppTextField(
                controller: _birthYear,
                hint: 'سنة الميلاد',
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                maxLength: 4,
                inputFormatters: digitsOnly,
                errorText: _errorOf('birth_year'),
                validator: Validators.integer(min: 1900, max: DateTime.now().year),
              ),
              SizedBox(height: 16.h),
            ],
            AppTextField(
              controller: _amount,
              hint: 'قيمة الشحن (د.ل)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textDirection: TextDirection.ltr,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.,٫]'))],
              errorText: _errorOf('amount'),
              validator: (v) {
                final error = Validators.decimal(allowZero: false, min: 1)(v);

                if (error != null || cap == null) return error;

                return thousandths(topUpAmount(v!)) > thousandths(cap)
                    ? 'المبلغ يتجاوز المتبقّي لك (${cap.asMoney} د.ل)'
                    : null;
              },
              onChanged: (text) {
                context.read<TopUpCubit>().amountChanged(text);
                if (_fieldErrors.isNotEmpty) setState(() => _fieldErrors = const {});
              },
            ),
            if (cap != null) ...[
              SizedBox(height: 8.h),
              Text(
                'المتبقّي لك: ${cap.asMoney} د.ل',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: scheme.primary),
              ),
            ],
            _FeeBox(form: form),
            if (widget.orderId case final order?) ...[
              SizedBox(height: 8.h),
              Text(
                'تُشحن محفظتك أولاً، ثم يُدفع منها ما على الطلبية #$order — وما زاد يبقى فيها.',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: scheme.onSurface.withValues(alpha: .5)),
              ),
            ],
            SizedBox(height: 24.h),
            AppButton(
              label: form.isStarting ? 'جاري التحميل ...' : 'تأكيد البيانات',
              isLoading: form.isStarting,
              onPressed: _start,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _start() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final method = widget.form.selected;
    final failure = await context.read<TopUpCubit>().start(
      cardNumber: method.needsCardNumber ? _card.text : null,
      serviceMobileNumber: _asksMobile ? _mobile.text : null,
      birthYear: method.needsBirthYear ? _birthYear.text : null,
    );

    if (failure == null || !mounted) return;

    if (failure case ServerFailure(:final fieldErrors?) when fieldErrors.isNotEmpty) {
      setState(() => _fieldErrors = fieldErrors);
    }

    context.showFailure(failure);
  }
}

/// «العمولة (2.5%) / المبلغ المدخل / سيتم خصم» — عرضُ الخادم، و«—» قبل أن يُكتب مبلغ.
class _FeeBox extends StatelessWidget {
  const _FeeBox({required this.form});

  final TopUpForm form;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final quote = form.quote;
    final onCustomer = form.methods.feeOnCustomer;

    if (form.isQuoting && quote == null) {
      return Padding(
        padding: EdgeInsets.only(top: 10.h),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 14.sp,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: scheme.primary.withValues(alpha: .6)),
            ),
            SizedBox(width: 8.w),
            Text(
              'جاري حساب العمولة...',
              style: TextStyle(fontSize: 12.sp, color: scheme.onSurface.withValues(alpha: .5)),
            ),
          ],
        ),
      );
    }

    if (form.quoteError case final error?) {
      return Padding(
        padding: EdgeInsets.only(top: 10.h),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, size: 15.sp, color: scheme.error),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                error,
                key: const Key('quote-error'),
                style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: scheme.error),
              ),
            ),
          ],
        ),
      );
    }

    String money(String? value) => value == null ? '—' : '${value.asMoney} د.ل';

    final label =TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w500, color: scheme.onSurface.withValues(alpha: .65));
    final value = TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: scheme.onSurface.withValues(alpha: .8));

    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: scheme.primary.withValues(alpha: .15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 15.sp, color: scheme.primary.withValues(alpha: .7)),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  onCustomer ? 'العمولة (${form.selected.feePercentage}%)' : 'العمولة — على المتجر',
                  style: label,
                ),
              ),
              Text(onCustomer ? money(quote?.fee) : money('0'), style: value),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(child: Text('المبلغ المدخل', style: label)),
              Text(money(quote?.amount), style: value),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Divider(height: 1, color: scheme.primary.withValues(alpha: .15)),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'سيتم خصم',
                  style: label.copyWith(fontWeight: FontWeight.w800, color: scheme.onSurface),
                ),
              ),
              Text(
                money(quote?.total),
                style: value.copyWith(fontWeight: FontWeight.w800, color: scheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── الصفحة الثالثة: رمز التحقق ──────────────────────────────────────────────────────────────

class _OtpPage extends StatefulWidget {
  const _OtpPage({required this.otp});

  final TopUpOtp otp;

  @override
  State<_OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<_OtpPage> {
  final _code = TextEditingController();
  final _focus = FocusNode();

  int get _length => brandOf(widget.otp.attempt.methodId).otpLength;

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final attempt = widget.otp.attempt;
    final faint = scheme.onSurface.withValues(alpha: .4);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      child: Column(
        children: [
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: .08),
              border: Border.all(color: scheme.primary.withValues(alpha: .12), width: 1.5),
            ),
            child: Icon(Icons.sms_outlined, size: 48.w, color: scheme.primary),
          ),
          SizedBox(height: 20.h),
          Text('أدخل رمز التحقق', style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          SizedBox(height: 8.h),
          Text(
            'تم إرسال رمز تحقق مكوّن من $_length أرقام\nعبر ${attempt.methodLabel}',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: .55), height: 1.6),
          ),
          SizedBox(height: 28.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: .6),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: .25)),
                  boxShadow: [
                    BoxShadow(color: scheme.primary.withValues(alpha: .06), blurRadius: 24, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  children: [
                    _CodeBoxes(controller: _code, focus: _focus, length: _length, onFull: _confirm),
                    SizedBox(height: 24.h),
                    AppButton(
                      label: widget.otp.isSending ? 'جاري التحقق ...' : 'تأكيد رمز التحقق',
                      isLoading: widget.otp.isSending,
                      onPressed: _confirm,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded, size: 16.w, color: faint),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  'تحقق من هاتفك لاستلام الرمز — بقيت ${attempt.otpAttemptsLeft} محاولات',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(color: faint),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    if (_code.text.trim().length < _length) {
      context.showError('يرجى إدخال رمز التحقق');

      return;
    }

    final failure = await context.read<TopUpCubit>().confirmOtp(_code.text);

    if (failure == null || !mounted) return;

    _code.clear();
    context.showFailure(failure);
  }
}

/// «نتحقق من الدفع» — EzonePay أخذت الرمز، والتطبيق يسأل كل بضع ثوانٍ حتى تقول «تم الدفع». لا زرّ
/// يرسل رمزاً ثانياً: الدفعُ تمّ أو يكاد، والورقةُ تُغلق نفسها على الخبر.
class _ConfirmingPage extends StatelessWidget {
  const _ConfirmingPage();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 32.h, 16.w, 16.h),
      child: Column(
        children: [
          Container(
            width: 100.w,
            height: 100.w,
            padding: EdgeInsets.all(30.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: .08),
              border: Border.all(color: scheme.primary.withValues(alpha: .12), width: 1.5),
            ),
            child: CircularProgressIndicator(strokeWidth: 3, color: scheme.primary),
          ),
          SizedBox(height: 20.h),
          Text('نتحقق من الدفع', style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          SizedBox(height: 8.h),
          Text(
            'قُبل رمز التحقق، وننتظر تأكيد مزوّد الدفع.\nيصل الرصيد محفظتك خلال لحظات — لا ترسل الرمز مرة أخرى.',
            key: const Key('confirming'),
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: .55), height: 1.6),
          ),
        ],
      ),
    );
  }
}

/// مربّعات الرمز، على نسق بريمولا — **فوق حقلٍ حقيقيٍّ شفاف** يكتب فيه الزبون، فلا حزمة: لوحةُ
/// المفاتيح تقترح الرمز من الرسالة بـ`oneTimeCode`، واللصق يعمل، والمربعات ترسم ما في الحقل.
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({required this.controller, required this.focus, required this.length, required this.onFull});

  final TextEditingController controller;
  final FocusNode focus;
  final int length;
  final VoidCallback onFull;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final digits = controller.text;

    return Stack(
      children: [
        Directionality(
          // الرمز يُقرأ من اليسار، كما في الرسالة.
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              for (var i = 0; i < length; i++) ...[
                if (i > 0) SizedBox(width: 10.w),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: .9,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: .04),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: i == digits.length ? .8 : .3),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        i < digits.length ? digits[i] : '',
                        style: context.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: AppTextField(
              key: const Key('otp-field'),
              controller: controller,
              focusNode: focus,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: length,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [WesternDigitsCodeFormatter(), LengthLimitingTextInputFormatter(length)],
              onChanged: (value) {
                if (value.length == length) onFull();
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// «١٢٣٤» يُكتب «1234» — الرمز يُرسل أرقاماً لاتينية.
class WesternDigitsCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = Validators.toWesternDigits(newValue.text).replaceAll(RegExp('[^0-9]'), '');

    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
