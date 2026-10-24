import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/device_saver.dart';
import 'package:dayaa/core/widgets/image_viewer.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/customers/models/design_file.dart';
import 'package:dayaa/features/customers/usecases/save_design_to_device.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_file.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/design_ticket_attachments.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/design_version_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSaveDesign extends Mock implements SaveDesignToDevice {}

/// «المرفقات» كما يحتاجها المصمم: تُفتح، وتُحمَّل.
///
/// كانت شريطاً من صورٍ صغيرة لا تفعل شيئاً عند الضغط، والحذف وحده خلف ضغطةٍ مطوّلة — فالمصمم
/// الذي أُرسل له الشعار لم يستطع أن يكبّره ولا أن يأخذه إلى هاتفه.
///
/// Arrange - Act - Assert في كل اختبار.
void main() {
  late _MockSaveDesign save;

  DesignTicketFile brief(int id, {DesignKind fileKind = DesignKind.image}) => DesignTicketFile(
    id: id,
    designTicketId: 1,
    kind: DesignTicketFileKind.brief,
    kindLabel: 'مرفق',
    label: fileKind == DesignKind.pdf ? 'ملف-$id.pdf' : 'صورة-$id.png',
    fileKind: fileKind,
    fileKindLabel: fileKind == DesignKind.pdf ? 'ملف PDF' : 'صورة',
    fileUrl: 'https://files.example/brief-$id?signature=abc',
  );

  setUpAll(() {
    registerFallbackValue(brief(0));
  });

  setUp(() async {
    await Injector.reset();
    save = _MockSaveDesign();
    sl.registerSingleton<SaveDesignToDevice>(save);
  });

  tearDown(Injector.reset);

  Widget host(List<DesignTicketFile> files, {void Function(DesignTicketFile)? onRemove}) =>
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
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: ListView(
                children: [DesignTicketAttachments(files: files, onRemove: onRemove)],
              ),
            ),
          ),
        ),
      );

  // الانتقال إلى العارض يُضخّ ولا يُستقرّ: مكانُ الصورة دوّارةٌ لا تتوقّف.
  Future<void> letTheRouteIn(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  // الإشعار يحمل مؤقّت إخفاءٍ لثلاث ثوانٍ، ومؤقّتٌ باقٍ بعد هدم الشجرة يُفشل الاختبار.
  Future<void> letTheToastGo(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  Future<void> openOptions(WidgetTester tester, {int index = 0}) async {
    await tester.tap(find.byTooltip('خيارات المرفق').at(index));
    await tester.pumpAndSettle();
  }

  testWidgets('كل مرفقٍ يُرى باسمه، والعنوان يعدّها', (tester) async {
    // Arrange
    final files = [brief(1), brief(2)];

    // Act
    await tester.pumpWidget(host(files));
    await tester.pump();

    // Assert
    expect(find.text('المرفقات (2)'), findsOneWidget);
    expect(find.text('صورة-1.png'), findsOneWidget);
    expect(find.text('صورة-2.png'), findsOneWidget);
  });

  testWidgets('الضغط على صورة يفتحها بملء الشاشة بين أخواتها، بلا ملف الـPDF', (tester) async {
    // Arrange — الـPDF في الوسط: لا يُرسم صورةً، فلا مكان له بين ما يُسحب بينه.
    final files = [brief(1), brief(2, fileKind: DesignKind.pdf), brief(3)];
    tester.view
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(files));
    await tester.pump();

    // Act
    await tester.tap(find.byType(DesignTicketFileThumbnail).at(2));
    await letTheRouteIn(tester);

    // Assert
    final viewer = tester.widget<ImageViewerPage>(find.byType(ImageViewerPage));
    expect(viewer.urls, [files[0].fileUrl, files[2].fileUrl]);
    expect(viewer.initialIndex, 1);
    expect(viewer.onSave, isNotNull);
  });

  testWidgets('المصمم يجد «فتح الملف» و«تحميل»، ولا يجد «حذف»', (tester) async {
    // Arrange
    await tester.pumpWidget(host([brief(1)]));
    await tester.pump();

    // Act
    await openOptions(tester);

    // Assert
    expect(find.text('فتح الملف'), findsOneWidget);
    expect(find.text('تحميل'), findsOneWidget);
    expect(find.text('حذف'), findsNothing);
  });

  testWidgets('من يدير التذكرة يحذف المرفق من الخيارات', (tester) async {
    // Arrange
    final files = [brief(1), brief(2)];
    DesignTicketFile? removed;
    await tester.pumpWidget(host(files, onRemove: (file) => removed = file));
    await tester.pump();

    // Act
    await openOptions(tester, index: 1);
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();

    // Assert
    expect(removed?.id, 2);
  });

  testWidgets('«تحميل» يحفظ المرفق على الهاتف ويقول أين', (tester) async {
    // Arrange
    when(() => save(any<DesignFile>())).thenAnswer((_) async => const Right(SavePlace.photos));
    await tester.pumpWidget(host([brief(1)]));
    await tester.pump();

    // Act
    await openOptions(tester);
    await tester.tap(find.text('تحميل'));
    await tester.pumpAndSettle();

    // Assert
    final saved = verify(() => save(captureAny<DesignFile>())).captured.single as DesignFile;
    expect(saved.id, 1);
    expect(find.text('حُفظ المرفق في الصور'), findsOneWidget);

    await letTheToastGo(tester);
  });
}
