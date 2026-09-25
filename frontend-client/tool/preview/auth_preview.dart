// أداةٌ لا اختبار: ترسم شاشتي الدخول وإنشاء الحساب صوراً PNG كي يُنظر فيهما بلا هاتف. خارج
// `test/` كي لا يجمعها `flutter test`.
//
//   PREVIEW_OUT=<مجلد الصور> flutter test tool/preview/auth_preview.dart
//
// **على مقاس التصميم نفسه:** ٣٩٠×٨٤٤ بكثافة ٢، بشريط حالةٍ ومؤشرٍ سفليّ كالآيفون الذي رُسم عليه،
// فتُقارَن الصورة بلقطة التصميم بكسلاً ببكسل.
//
// **الخطوط كما في التطبيق:** Cairo بأوزانه الستة من `assets/fonts/`، والثيم من `createTextTheme`
// نفسها. وخط أيقونات Material يُحمَّل من ذاكرة الـ SDK، وإلا رُسمت كل أيقونةٍ مربعاً فارغاً.
//
// **والظلال بتمويهها:** بيئة الاختبار ترسمها كتلاً صلبة (`debugDisableShadows`) كي تثبت صور
// المقارنة؛ هنا تُطفأ تلك الحماية أثناء الرسم وتُعاد بعده، لأن ظلّ البطاقة جزءٌ مما يُقارَن.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/theme/text_theme.dart';
import 'package:dayaa_client/core/theme/theme.dart';
import 'package:dayaa_client/features/auth/presentation/viewmodel/login_cubit.dart';
import 'package:dayaa_client/features/auth/presentation/viewmodel/register_cubit.dart';
import 'package:dayaa_client/features/auth/presentation/views/login_page.dart';
import 'package:dayaa_client/features/auth/presentation/views/register_page.dart';
import 'package:dayaa_client/features/auth/repositories/auth_repository.dart';
import 'package:dayaa_client/features/auth/usecases/login.dart';
import 'package:dayaa_client/features/auth/usecases/register.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

Future<void> _load(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = await File(path).readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final out = Platform.environment['PREVIEW_OUT'] ?? '.';

  setUpAll(() async {
    await _load('Cairo', [
      for (final face in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold', 'Black'])
        'assets/fonts/Cairo-$face.ttf',
    ]);
    // flutter_tester يعيش في <flutter>/bin/cache/artifacts/engine/<منصة>/، والخط في
    // <flutter>/bin/cache/artifacts/material_fonts/.
    final artifacts = File(Platform.resolvedExecutable).parent.parent.parent.path;
    final icons = '$artifacts/material_fonts/MaterialIcons-Regular.otf';
    if (File(icons).existsSync()) await _load('MaterialIcons', [icons]);
  });

  Future<void> draw(
    WidgetTester tester, {
    required String name,
    required Brightness brightness,
    required String location,
  }) async {
    await sl.reset();
    final repository = _MockAuthRepository();
    sl
      ..registerFactory<LoginCubit>(() => LoginCubit(login: Login(repository)))
      ..registerFactory<RegisterCubit>(() => RegisterCubit(register: Register(repository)));

    // آيفون بجزيرة: ٣٩٠×٨٤٤، شريط الحالة ٥٩، والمؤشر السفلي ٣٤.
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    tester.view.padding = const FakeViewPadding(top: 118, bottom: 68);
    tester.view.viewPadding = const FakeViewPadding(top: 118, bottom: 68);
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
      ],
    );
    final key = GlobalKey();

    debugDisableShadows = false;
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ScreenUtilInit(
          designSize: const Size(430, 932),
          // كما في `app.dart`: الثيم يُبنى من سياقٍ فوق التطبيق.
          builder: (context, _) {
            final theme = MaterialTheme(createTextTheme(context, 'Cairo', 'Cairo'));

            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              routerConfig: router,
              theme: brightness == Brightness.light ? theme.light() : theme.dark(),
              locale: const Locale('ar'),
              supportedLocales: const [Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    if (location != '/login') {
      unawaited(router.push(location));
      await tester.pumpAndSettle();
    }

    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$out/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    });
    debugDisableShadows = true;
  }

  for (final brightness in Brightness.values) {
    testWidgets('draw sign-in, ${brightness.name}', (tester) async {
      await draw(
        tester,
        name: 'login-${brightness.name}',
        brightness: brightness,
        location: '/login',
      );
    });

    testWidgets('draw sign-up, ${brightness.name}', (tester) async {
      await draw(
        tester,
        name: 'register-${brightness.name}',
        brightness: brightness,
        location: '/register',
      );
    });
  }
}
