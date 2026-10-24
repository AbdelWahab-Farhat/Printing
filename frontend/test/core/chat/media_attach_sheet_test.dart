import 'package:dayaa/core/chat/media_attach_sheet.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePicker implements AttachmentPicker {
  List<PickedFile> answer = const [];
  final asked = <AttachmentSource>[];

  @override
  Future<List<PickedFile>> pick(
    AttachmentSource source, {
    List<String> extensions = AttachmentPicker.defaultExtensions,
  }) async {
    asked.add(source);

    return answer;
  }
}

/// ورقةُ إرفاق الصور — **منقولةٌ من بريمولا**: تُختار الصورُ مرقّمةً بترتيب اختيارها حتى الحدّ،
/// والضغطةُ الثانية تتركها، وزرُّ الإرسال يحمل العدد ويسلّم الصورَ وتعليقها معاً.
///
/// المكتبةُ لا تُقرأ هنا (`galleryGrid: false`): لا مكتبة صورٍ تحت `flutter_test`، فالمعرضُ
/// منتقي النظام — كما على الويب.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _FakePicker picker;
  late List<(List<PickedFile>, String)> sent;

  PickedFile photo(String name) => PickedFile(path: '/nowhere/$name', name: name, sizeBytes: 10);

  setUp(() async {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(view.reset);

    await Injector.reset();
    picker = _FakePicker();
    sent = [];
    sl.registerSingleton<AttachmentPicker>(picker);
  });

  tearDown(Injector.reset);

  Future<void> openSheet(WidgetTester tester, {int maxItems = 10}) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showMediaAttachSheet(
                  context,
                  galleryGrid: false,
                  maxItems: maxItems,
                  onSend: (images, caption) async => sent.add((images, caption)),
                ),
                child: const Text('افتح'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
  }

  testWidgets('nothing chosen: the camera and the gallery, and no send button', (tester) async {
    // Act
    await openSheet(tester);

    // Assert
    expect(find.text('إرسال صور'), findsOneWidget);
    expect(find.text('الكاميرا'), findsWidgets);
    expect(find.text('المعرض'), findsWidgets);
    expect(find.bySemanticsLabel(RegExp(r'^إرسال \d')), findsNothing);
  });

  testWidgets('picked photos are chosen in order and go out together with the caption', (
    tester,
  ) async {
    // Arrange
    picker.answer = [photo('a.jpg'), photo('b.jpg'), photo('c.jpg')];
    await openSheet(tester);

    // Act
    await tester.tap(find.text('المعرض').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'الوجهان والجانب');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('إرسال 3'));
    await tester.pumpAndSettle();

    // Assert
    expect(picker.asked, [AttachmentSource.photos]);
    expect(sent, hasLength(1));
    expect(sent.single.$1.map((file) => file.name), ['a.jpg', 'b.jpg', 'c.jpg']);
    expect(sent.single.$2, 'الوجهان والجانب');
    expect(find.byType(MediaAttachSheet), findsNothing);
  });

  testWidgets('a second tap lets a photo go, and the numbers close up', (tester) async {
    // Arrange
    picker.answer = [photo('a.jpg'), photo('b.jpg')];
    await openSheet(tester);
    await tester.tap(find.text('المعرض').last);
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.bySemanticsLabel('صورة مختارة 1'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('تم اختيار 1'), findsOneWidget);
    expect(find.bySemanticsLabel('صورة مختارة 1'), findsOneWidget);
    expect(find.bySemanticsLabel('صورة مختارة 2'), findsNothing);
  });

  testWidgets('no more than the limit is chosen', (tester) async {
    // Arrange
    picker.answer = [photo('a.jpg'), photo('b.jpg'), photo('c.jpg')];
    await openSheet(tester, maxItems: 2);

    // Act
    await tester.tap(find.text('المعرض').last);
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('تم اختيار 2'), findsOneWidget);
    expect(find.text('يمكنك إرسال 2 صور كحد أقصى'), findsOneWidget);

    // التنبيهُ يذهب وحده — وساعتُه لا تبقى معلّقةً بعد الاختبار.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });
}
