import 'dart:async';

import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/menu_card.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/presentation/widgets/sign_out_sheet.dart';
import 'package:dayaa_client/features/auth/usecases/get_current_customer.dart';
import 'package:dayaa_client/features/auth/usecases/logout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «حسابي»: بطاقةٌ تقول من أنت، وتحتها ما تفعله بحسابك.
///
/// **على شكل الملف الشخصي في المرجع الذي أرسله صاحب العمل:** بطاقةٌ بلون العلامة تحمل الصورة
/// والاسم والهاتف وكود العميل وأين يعمل، وتحتها بطاقة صفوف. **والفرق الذي طلبه أن الكود واضحٌ بما
/// يكفي ليعرفه العميل:** مسمّىً «كود العميل» في شارةٍ بيضاء، ويُنسخ بلمسة لأنه ما يرسله العميل إلى
/// المتجر حين يسأل عن طلبية.
///
/// **بطاقة صفوفٍ واحدة**، لا اثنتان: جُرّبت منفصلتين على الهاتف، وطلب صاحب العمل ضمّهما. فيها
/// «تصاميمي» أولاً، ثم «رمز QR» و«معاينة على الكيس» — **والباب الوحيد إلى الثلاث** منذ خرج
/// تبويب «الخدمات» من الشريط، فلا تُحذف ظنّاً أنها مكرّرة في مكانٍ آخر. ثم «الإعدادات»
/// (و«مظهر التطبيق» داخلها الآن)، و«سياسة الخصوصية» معطّلةً بشارة «قريباً» إلى أن تُكتب، و«تسجيل
/// الخروج» خلف ورقة تأكيد آخرَها. أما «تواصل مع الدعم» فخرج لأنه مكرّرٌ في الرئيسية.
///
/// **بلا Cubit، عمداً.** ما تعرضه حسابٌ واحد لا يتغيّر إلا حين يتغيّر الحساب، أي بتسجيل الخروج.
/// ViewModel لها ستكون تياراً لا يدفع إليه شيء، والقراءة هي `auth/me` نفسها التي تقوم بها الرئيسية.
///
/// **ولا تفترض أنها تبويب.** لا `leading` مخصّص في شريطها، فإن فُتحت فوق الرئيسية ظهر زر الرجوع
/// وحده.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  /// شارة كود العميل، ليجد الاختبار الاسم والرقم داخلها معاً.
  @visibleForTesting
  static const Key codeChipKey = Key('profile_code_chip');

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  CustomerAccount? _customer;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _read();
  }

  Future<void> _read() async {
    final result = await sl<GetCurrentCustomer>()();

    if (!mounted) return;

    // قراءةٌ فشلت تُبقي ما كان معروضاً: البطاقة التي عرفت صاحبها لا تنساه لأن سحباً للتحديث لم
    // يصل إلى الخادم.
    result.fold((_) {}, (customer) => setState(() => _customer = customer));
  }

  Future<void> _signOut() async {
    final confirmed = await showSignOutSheet(context);

    if (!confirmed || !mounted) return;

    setState(() => _isSigningOut = true);

    // **لا يُتفرَّع على النتيجة.** الخروج يمسح التوكن من هذا الجهاز في الحالين. فشل الشبكة يعني
    // أن الخادم لم يُبلَّغ، وتلك مشكلته تنتهي بانتهاء صلاحية التوكن، لا سببٌ لإبقاء أحدٍ داخلاً على
    // هاتفٍ قد يسلّمه لغيره.
    await sl<Logout>()();

    if (!mounted) return;

    context.go(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _read,
          child: ListView(
            // يُسحب حتى حين لا يملأ المحتوى الشاشة، وإلا لم يجد السحب ما يمسك به.
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
            children: [
              _AccountCard(customer: _customer),
              SizedBox(height: 20.h),
              // قائمةٌ واحدة: ما يصنعه العميل أولاً و«تصاميمي» في رأسها، ثم إعدادات حسابه، وتسجيل
              // الخروج آخرها.
              MenuCard(
                rows: [
                  // لا طريق آخر إلى هذه الثلاث في التطبيق. و`push` لا `go`، لتعود كلٌّ منها إلى
                  // هنا بزر الرجوع.
                  MenuRow(
                    icon: AppIcons.designs,
                    label: 'تصاميمي',
                    onTap: () => context.push(Routes.designs),
                  ),
                  // والبطاقة أعلاه تسمّي أول المتاجر، فتُقرأ ثانيةً بعد العودة: قد يكون أُضيف أو
                  // عُدِّل أو حُذف.
                  MenuRow(
                    icon: AppIcons.shops,
                    label: 'متاجري',
                    onTap: () async {
                      await context.push(Routes.shops);
                      await _read();
                    },
                  ),
                  MenuRow(
                    icon: AppIcons.qrCode,
                    label: 'رمز QR',
                    onTap: () => context.push(Routes.qrTool),
                  ),
                  MenuRow(
                    icon: AppIcons.bagPreview,
                    label: 'معاينة على الكيس',
                    onTap: () => context.push(Routes.bagPreview),
                  ),
                  MenuRow(
                    icon: AppIcons.settings,
                    label: 'الإعدادات',
                    // `push` لا `go`: الإعدادات تُفتح فوق «حسابي» وتعود إليها.
                    onTap: () => context.push(Routes.settings),
                  ),
                  // معطّلةٌ لا مخفيّة: من سمع بها يجد مكانها، و«قريباً» تقول لماذا لا تُفتح.
                  MenuRow(
                    icon: AppIcons.privacy,
                    label: 'سياسة الخصوصية',
                    badge: 'قريباً',
                    onTap: null,
                  ),
                  MenuRow(
                    icon: AppIcons.logout,
                    label: 'تسجيل الخروج',
                    isDestructive: true,
                    isBusy: _isSigningOut,
                    onTap: _signOut,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// البطاقة التي تقول من أنت، بلون العلامة كما في المرجع.
///
/// **حبرها أبيض في الوضعين.** البطاقة بلون العلامة لا بلون الصفحة، فلا يتبدّل ما عليها مع المظهر.
/// والتدرّج يمضي من البرتقالي الصريح في الزاوية البعيدة إلى [BrandTone.primaryDeep] تحت النص،
/// ليُقرأ رقم الهاتف بحجمه العادي. انظر تعليق ذلك اللون.
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.customer});

  final CustomerAccount? customer;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final customer = this.customer;
    final shop = customer?.shop;
    final ink = scheme.onPrimary;
    final radius = BorderRadius.circular(24.r);

    // «متجر النور · طرابلس»، أو ما عند الحساب من نصفيها. حسابٌ بلا متجرٍ لا سطر له.
    final where = [?shop?.name, ?shop?.cityName].join(' · ');

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topEnd,
          end: AlignmentDirectional.bottomStart,
          colors: [scheme.primary, scheme.primaryDeep],
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // دائرتان باهتتان في زاويتين متقابلتين، كما في المرجع.
            PositionedDirectional(
              top: -70.w,
              end: -50.w,
              child: _Halo(size: 170.w, color: ink.withValues(alpha: 0.07)),
            ),
            PositionedDirectional(
              bottom: -60.w,
              start: -40.w,
              child: _Halo(size: 140.w, color: ink.withValues(alpha: 0.06)),
            ),
            // اسم العلامة علامةً مائية في الطرف الخالي من النص، حيث يكتب المرجع اسمه. في أعلى
            // البطاقة لا في وسطها: شارة الكود تمتدّ تحت منتصفها، والعلامة خلفها تُقرأ كتراكب.
            PositionedDirectional(
              top: 4.h,
              end: 20.w,
              child: Text(
                'FlyerX',
                textDirection: TextDirection.ltr,
                style: context.textTheme.displaySmall?.copyWith(
                  fontSize: 34.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: ink.withValues(alpha: 0.16),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(18.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _Avatar(ink: ink),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              // علامةٌ لا سطرٌ فارغ أثناء القراءة: البطاقة تحفظ مكان الاسم.
                              customer?.name ?? '…',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: ink,
                              ),
                            ),
                            if (customer != null) ...[
                              SizedBox(height: 8.h),
                              // `Wrap` لا `Row`: على هاتفٍ ضيّق أو بخطٍّ مكبَّر تنزل الشارة إلى سطرٍ
                              // ثانٍ بدل أن تُقصّ.
                              Wrap(
                                spacing: 12.w,
                                runSpacing: 8.h,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _Phone(phone: customer.phone, ink: ink),
                                  // تُرسم حين يصل الكود فقط: شارةٌ برقمٍ مؤقت رقمٌ ليس لصاحبه.
                                  if (customer.code case final code?) _CodeChip(code: code),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (where.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    _Where(where: where, ink: ink),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// حلقةٌ بيضاء حول دائرةٍ أفتح من البطاقة، كما يرسم المرجع صورة من لم يرفع صورة.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.ink});

  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72.w,
      height: 72.w,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ink.withValues(alpha: 0.5), width: 2.w),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: ink.withValues(alpha: 0.2)),
        child: Icon(AppIcons.person, size: 32.sp, color: ink),
      ),
    );
  }
}

class _Phone extends StatelessWidget {
  const _Phone({required this.phone, required this.ink});

  final String phone;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.phone, size: 16.sp, color: ink),
        SizedBox(width: 6.w),
        Text(
          phone,
          // رقمٌ ليبي يُقرأ من اليسار إلى اليمين حتى هنا.
          textDirection: TextDirection.ltr,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: ink,
          ),
        ),
      ],
    );
  }
}

/// «كود العميل B849»، في شارةٍ بيضاء على البطاقة البرتقالية.
///
/// **ما يجعله واضحاً ثلاثة أشياء:** اسمه مكتوبٌ بجانبه، فلا يُحزر من أيقونة؛ وهو الشيء الأبيض
/// الوحيد على البطاقة، فتقع العين عليه أولاً؛ ورقمه أثقل ما في البطاقة بعد الاسم.
///
/// **وتُنسخ بلمسة:** الكود هو ما يرسله العميل إلى المتجر في محادثة، ونسخه أسلم من إعادة كتابته.
///
/// ليست `CopyText` من `core/widgets/`: تلك قيمةٌ بلا اسمٍ على سطح الصفحة، وألوانها ألوان الصفحة،
/// وهنا اسمٌ ورقمٌ على أبيضٍ فوق البرتقالي.
class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final ink = scheme.primaryDeep;
    final radius = BorderRadius.circular(12.r);

    return Material(
      key: ProfilePage.codeChipKey,
      color: scheme.onPrimary,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          unawaited(Clipboard.setData(ClipboardData(text: code)));
          context.showSuccess('تم نسخ كود العميل');
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'كود العميل',
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                code,
                textDirection: TextDirection.ltr,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: ink,
                ),
              ),
              SizedBox(width: 6.w),
              Icon(AppIcons.copy, size: 14.sp, color: ink),
            ],
          ),
        ),
      ),
    );
  }
}

/// أين يعمل العميل، في شريطٍ أفتح من البطاقة كما في المرجع.
class _Where extends StatelessWidget {
  const _Where({required this.where, required this.ink});

  final String where;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(AppIcons.mapPin, size: 18.sp, color: ink),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              where,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
