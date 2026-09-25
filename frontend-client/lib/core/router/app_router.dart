import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/fade_through_branches.dart';
import 'package:dayaa_client/core/router/pop_result.dart';
import 'package:dayaa_client/features/auth/presentation/views/login_page.dart';
import 'package:dayaa_client/features/auth/presentation/views/profile_page.dart';
import 'package:dayaa_client/features/auth/presentation/views/register_page.dart';
import 'package:dayaa_client/features/auth/usecases/has_stored_session.dart';
import 'package:dayaa_client/features/catalog/presentation/views/product_detail_page.dart';
import 'package:dayaa_client/features/catalog/presentation/views/products_page.dart';
import 'package:dayaa_client/features/designs/presentation/views/designs_page.dart';
import 'package:dayaa_client/features/home/presentation/views/home_page.dart';
import 'package:dayaa_client/features/home/presentation/views/home_shell.dart';
import 'package:dayaa_client/features/orders/presentation/views/order_detail_page.dart';
import 'package:dayaa_client/features/orders/presentation/views/orders_page.dart';
import 'package:dayaa_client/features/orders/presentation/views/place_order_page.dart';
import 'package:dayaa_client/features/settings/presentation/views/settings_page.dart';
import 'package:dayaa_client/features/shops/models/shop.dart';
import 'package:dayaa_client/features/shops/presentation/views/shop_details_page.dart';
import 'package:dayaa_client/features/shops/presentation/views/shop_form_page.dart';
import 'package:dayaa_client/features/shops/presentation/views/shops_page.dart';
import 'package:dayaa_client/features/support/presentation/views/support_page.dart';
import 'package:dayaa_client/features/support/presentation/views/ticket_thread_page.dart';
import 'package:dayaa_client/features/tools/presentation/views/bag_preview_page.dart';
import 'package:dayaa_client/features/tools/presentation/views/qr_tool_page.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// كل مسار في التطبيق، مسمّى مرة واحدة.
///
/// المسار المكتوب نصاً في مكان استعماله مسارٌ لا يستطيع أحد إعادة تسميته، لذلك يأخذ `context.go`
/// و`context.push` ثابتاً من هنا ولا يأخذان نصاً أبداً. وحيث يحمل المسار رقماً تُستعمل دالة لا
/// ثابت: `Routes.order(7)` لا يمكن بناؤه والرقم في غير مكانه.
abstract final class Routes {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';

  static const String products = '/products';

  static String product(int id) => '/products/$id';

  /// «تصاميمي». تُفتح من «حسابي» فوق الشريط، ولم تعد تبويباً.
  static const String designs = '/designs';

  static const String orders = '/orders';

  /// إنشاء طلبية. **مقطع ثابت تحت `/orders`**، ولهذا يُسجَّل قبل `:id` في الأسفل، وإلا قرأ
  /// go_router كلمة «new» على أنها رقم طلبية.
  static const String newOrder = '/orders/new';

  static String order(int id) => '/orders/$id';

  /// «حسابي». تُفتح من شريط الرئيسية العلوي فوق الشريط السفلي، ولم تعد تبويباً.
  static const String profile = '/profile';

  /// «الإعدادات». تُفتح من «حسابي» فوق الشاشة، ولها زر رجوع إليها.
  static const String settings = '/settings';

  /// «متاجري». تُفتح من «حسابي».
  static const String shops = '/shops';

  /// نموذج المتجر، ويعيد المتجر المحفوظ لمن فتحه. **إضافةٌ بلا `extra`، وتعديلٌ حين يُمرَّر فيه
  /// المتجر** — المسار نفسه والفعل يقرّره ما يحمله، كما في نموذج العميل في تطبيق الموظفين. و`extra`
  /// مقبولٌ هنا لأن النموذج يُدفع فوق الـ shell، لا فرعاً يُبدَّل منه وإليه.
  static const String shopForm = '/shops/form';

  /// صفحة متجرٍ واحد: تفاصيله وتعديلها، ومكتبة التصاميم. **المتجر يُمرَّر لا يُطلب** — «متاجري»
  /// جلبته للتوّ — وما يتغيّر فيها يعود إلى القائمة عبر `pushForResult`، فالمسار ثابتٌ بلا مُعرِّف.
  static const String shopDetails = '/shops/details';

  static const String support = '/support';

  /// «الدعم»، ومعه محادثة جديدة موجّهة مسبقاً إلى طلبية.
  ///
  /// **معامل في الرابط (query) لا `extra`.** يسافر داخل الموقع نفسه، فيبقى مهما فعل الموجّه
  /// بالمسار، ويُقرأ في السجل حين يسأل أحدهم لماذا وصلت تذكرة مربوطة بالطلبية الخطأ.
  /// و`int.tryParse` في الطرف الآخر يعني أن القيمة المشوّهة تصير «بلا طلبية» ببساطة، لا انهياراً.
  static String supportAbout(int orderId) => '/support?order=$orderId';

  static String ticket(int id) => '/support/$id';

  /// أداة QR، تُفتح للاستعمال.
  static const String qrTool = '/tools/qr';

  /// «معاينة على الكيس»: التصميم على صورة الكيس الذي سيُطبع عليه.
  static const String bagPreview = '/tools/bag-preview';

  /// **الشاشة نفسها بنهاية أخرى**: تُعيد الرمز *ملفاً* لمن فتحها، بدل أن تعطيه لقائمة المشاركة في
  /// النظام. هذا ما يجعل الأداة جزءاً من التطبيق لا تطبيقاً ثانياً داخله: «تصاميمي» تفتحها كما
  /// تفتح الكاميرا، وما يعود منها يمرّ بالرفع نفسه.
  static const String qrToolPick = '/tools/qr/pick';
}

/// الـ `GoRouter` الوحيد في التطبيق.
///
/// **الترتيب مهم داخل المسار الواحد.** المقطع الثابت يُسجَّل قبل `:id` الذي كان سيبتلعه:
/// `/orders/new` فوق `/orders/:id`، وإلا قرأ go_router كلمة «new» رقمَ طلبية وسلّمها إلى
/// `int.parse`.
///
/// **الأقسام الثلاثة تعيش في shell، والباقي يُفتح فوقه.** العميل الذي ينتقل بين «المنتجات» و«طلباتي»
/// يبدّل ما ينظر إليه ولا يتعمّق، فيحتفظ كل قسم بموضع تمريره ويبقى الشريط السفلي. أما المنتج
/// والطلبية والمحادثة فأماكن تذهب إليها ثم تعود، فتغطي الشريط ولها زر رجوع.
abstract final class AppRouter {
  static final GoRouter instance = GoRouter(
    initialLocation: Routes.home,
    redirect: _guard,
    routes: [
      GoRoute(path: Routes.login, builder: (context, state) => const LoginPage()),
      GoRoute(path: Routes.register, builder: (context, state) => const RegisterPage()),

      // **`StatefulShellRoute` لا `.indexedStack`.** الثاني يعرض الأقسام في `IndexedStack`،
      // فيظهر القسم الجديد فوراً بلا انتقال. [FadeThroughBranches] يحفظ الأقسام بالطريقة نفسها
      // ويضيف التلاشي بينها.
      StatefulShellRoute(
        builder: (context, state, shell) => HomeShell(shell: shell),
        navigatorContainerBuilder: (context, shell, children) =>
            FadeThroughBranches(currentIndex: shell.currentIndex, children: children),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.home, builder: (context, state) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.products,
                builder: (context, state) => const ProductsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.orders, builder: (context, state) => const OrdersPage()),
            ],
          ),
          // **«حسابي» و«تصاميمي» خرجتا من الشريط** (طلب المستخدم، 2026-09-25)، وكذلك «الخدمات»
          // التي جمعت «تصاميمي» والأدوات يوماً واحداً. «حسابي» تُفتح من شريط الرئيسية العلوي بجانب
          // الدعم، و«تصاميمي» والأدوات صفوفٌ فيها. كلتاهما تُدفعان فوق الشريط ويُرجع منهما.
        ],
      ),

      // ── يُفتح فوق الـ shell ──────────────────────────────────────────────────
      GoRoute(path: Routes.profile, builder: (context, state) => const ProfilePage()),
      GoRoute(path: Routes.designs, builder: (context, state) => const DesignsPage()),
      GoRoute(path: Routes.support, builder: (context, state) => const SupportPage()),
      GoRoute(path: Routes.settings, builder: (context, state) => const SettingsPage()),
      GoRoute(path: Routes.shops, builder: (context, state) => const ShopsPage()),
      GoRoute(
        path: Routes.shopForm,
        builder: (context, state) => ShopFormPage(editing: state.payload as Shop?),
      ),
      GoRoute(
        path: Routes.shopDetails,
        // بلا متجرٍ لا صفحة متجر — رابطٌ فُتح بلا ما يُعرض يصل إلى «متاجري» بدل أن ينهار.
        builder: (context, state) => switch (state.payload) {
          final Shop shop => ShopDetailsPage(shop: shop),
          _ => const ShopsPage(),
        },
      ),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) =>
            ProductDetailPage(productId: int.parse(state.pathParameters['id']!)),
      ),

      /// **يُسجَّل قبل `/orders/:id`**، حتى لا يُقرأ `/orders/new` طلبيةً رقمها «new».
      ///
      /// كانت البنود تُنقل في `extra`، وهي قائمة كائنات، والرابط ليس مكاناً لها. صارت تُؤخذ من
      /// السلة الآن، فلا يحمل المسار شيئاً، ويمكن الوصول إلى الشاشة من أي مكان، حتى من رابط يُفتح
      /// والتطبيق مغلق.
      GoRoute(
        path: Routes.newOrder,
        builder: (context, state) => const PlaceOrderPage(),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) =>
            OrderDetailPage(orderId: int.parse(state.pathParameters['id']!)),
      ),

      // **قبل `/tools/qr`**: لو أُضيف تحته يوماً مسار بمعامل، لما وصل أحد إلى المقطع الثابت
      // «pick».
      GoRoute(
        path: Routes.qrToolPick,
        builder: (context, state) => const QrToolPage.picking(),
      ),
      GoRoute(path: Routes.qrTool, builder: (context, state) => const QrToolPage()),
      GoRoute(
        path: Routes.bagPreview,
        builder: (context, state) => const BagPreviewPage(),
      ),

      GoRoute(
        path: '/support/:id',
        builder: (context, state) =>
            TicketThreadPage(ticketId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );

  /// الأماكن المسموحة لمن لا يحمل توكناً.
  static const Set<String> _public = {Routes.login, Routes.register};

  /// يرسل العميل غير المسجَّل إلى شاشة الدخول، ويُبعد المسجَّل عنها.
  ///
  /// **متزامن، ولا يسأل إلا هل يوجد توكن**، لا هل هو صالح. `redirect` لا يستطيع الانتظار،
  /// والحارس الذي يتحقق من التوكن مع الخادم سيوقف كل تنقّل على رحلة ذهاب وإياب إليه. صلاحية
  /// التوكن يجيب عنها أول طلب يستعمله: `AuthInterceptor` يحوّل الـ 401 إلى `onUnauthorized`،
  /// فتُمسح الجلسة ويعود العميل إلى هنا.
  static String? _guard(BuildContext context, GoRouterState state) {
    final signedIn = sl<HasStoredSession>()();
    final isPublic = _public.contains(state.matchedLocation);

    if (!signedIn && !isPublic) return Routes.login;

    // من يحمل توكناً لا شأن له بشاشة الدخول: زر رجوع يعيده إليها بعد الدخول هو ما يجعل العميل
    // يسجّل دخوله مرتين.
    if (signedIn && isPublic) return Routes.home;

    return null;
  }
}
