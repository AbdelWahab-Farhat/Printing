import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investment_settings/models/investment_settings.dart';
import 'package:dayaa/features/investment_settings/presentation/views/investment_settings_page.dart';
import 'package:dayaa/features/investment_settings/repositories/investment_settings_repository.dart';
import 'package:dayaa/features/investment_settings/usecases/investment_settings_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// شاشةُ قواعد الصندوق.
///
/// **ما يُثبَّت هنا أن الشاشة لا تحسب شيئاً.** الأرقامُ تصل من الخادم وتُعرض، وما يُكتب يُرسَل
/// كما هو، والرفضُ يُعرض بنصّ الخادم — فلا تعريفَ ثانياً للقاعدة في Dart يفترق عن الأول أوّلَ ما
/// تتغيّر.
///
/// Arrange - Act - Assert في كلٍّ منها.
class _FakeRepository implements InvestmentSettingsRepository {
  _FakeRepository({required this.stored, this.updateFails});

  InvestmentSettings stored;
  final Failure? updateFails;

  InvestmentSettings? sent;

  @override
  Future<Either<Failure, InvestmentSettings>> settings() async => Right(stored);

  @override
  Future<Either<Failure, InvestmentSettings>> update(InvestmentSettings settings) async {
    sent = settings;

    if (updateFails case final failure?) return Left(failure);

    stored = settings;

    return Right(settings);
  }
}

const _stored = InvestmentSettings(
  investorProfitSharePercent: '50.00',
  periodMonths: 1,
  subscriptionWindowDays: 7,
  settlementMonths: 6,
  capitalLockMonths: 12,
);

void main() {
  late _FakeRepository repository;

  Future<void> register({Failure? updateFails}) async {
    await sl.reset();
    repository = _FakeRepository(stored: _stored, updateFails: updateFails);
    sl
      ..registerLazySingleton<GetInvestmentSettings>(() => GetInvestmentSettings(repository))
      ..registerLazySingleton<UpdateInvestmentSettings>(
        () => UpdateInvestmentSettings(repository),
      );
  }

  Widget host() {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: [Locale('ar')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: InvestmentSettingsPage(),
        ),
      ),
    );
  }

  testWidgets('the four durations open on what the server holds', (tester) async {
    // Arrange
    await register();

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — الوحدة في التسمية لا في سطرٍ تحتها.
    expect(find.text('مدة الفترة (شهر)'), findsOneWidget);
    expect(find.text('نافذة الاكتتاب (يوم)'), findsOneWidget);
    expect(find.text('مدة التسوية (شهر)'), findsOneWidget);
    expect(find.text('حجز رأس المال بعد إيداعه (شهر)'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('50.00'), findsOneWidget);
  });

  testWidgets('what is typed is what is sent, untouched', (tester) async {
    // Arrange
    await register();
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act — يُغيَّر رقمٌ واحد، وتُرسَل الخمسةُ معاً.
    await tester.enterText(find.widgetWithText(TextField, '12'), '24');
    await tester.tap(find.text('حفظ'));
    await tester.pump();

    // Assert
    expect(repository.sent?.capitalLockMonths, 24);
    expect(repository.sent?.periodMonths, 1);
    expect(repository.sent?.investorProfitSharePercent, '50.00');

    // الـsnackbar يترك مؤقّتاً حيّاً وحركةً جارية؛ يُصرَّفان صراحةً وإلا اشتكى الإطارُ في
    // التفكيك عن شيءٍ لا علاقة له بما يختبره هذا الاختبار.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('a refusal is shown in the server words, not rewritten here', (tester) async {
    // Arrange — القاعدةُ الوحيدة التي قد تُرفَض يقولها الخادم، ولا تُعاد صياغتُها في Dart.
    const message = 'مدة التسوية يجب أن تكون مضاعفاً لمدة الفترة (3 شهر)';
    await register(updateFails: const Failure.server(message: message));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('حفظ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Assert
    expect(find.text(message), findsOneWidget);

    // يُترك الـsnackbar يمضي إلى نهايته: مؤقّتُه ثم حركةُ خروجه. بلا هذا يُهدَم الشجرُ وفيه
    // مؤقّتٌ حيٌّ وحركةٌ جارية، فيشتكي الإطارُ في التفكيك لا في التوكيد.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
