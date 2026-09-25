import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/attachment_picker.dart';
import 'package:dayaa_client/core/files/picked_file.dart';
import 'package:dayaa_client/core/utils/validators.dart';
import 'package:dayaa_client/core/widgets/dismiss_keyboard.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/presentation/viewmodel/designs_cubit.dart';
import 'package:dayaa_client/features/designs/presentation/views/designs_page.dart';
import 'package:dayaa_client/features/designs/repositories/design_repository.dart';
import 'package:dayaa_client/features/designs/usecases/list_designs.dart';
import 'package:dayaa_client/features/designs/usecases/remove_design.dart';
import 'package:dayaa_client/features/designs/usecases/rename_design.dart';
import 'package:dayaa_client/features/designs/usecases/upload_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// «أضف تصميماً»: زرٌّ عائم، واسمٌ يُسأل عنه قبل أن يُرفع أي شيء.
///
/// **الاسم قبل الرفع** لأن ما يُرفع بلا اسم يأخذ اسم ملفه، واسمُ صورةٍ من الاستوديو
/// «image_picker_5D16…». هكذا ظهر في المكتبة، ومن هذه المكتبة يُختار التصميم في كل طلبية.
///
/// Arrange - Act - Assert throughout.
class _MockDesignRepository extends Mock implements DesignRepository {}

/// منتقٍ بلا منصّة يعيد ملفاً واحداً جاهزاً.
///
/// **ويرفض أن يُسأل عن عدّة ملفات.** كل ملفٍ يُرفع يُسمّى وحده، فلو طلبت الشاشة عدّة ملفات
/// لسقط الاختبار هنا بدل أن يمرّ على شاشةٍ تسأل عن اسمٍ واحد لخمس صور.
class _FakePicker implements AttachmentPicker {
  PickedFile? answer;

  @override
  Future<PickedFile?> pickOne(AttachmentSource source) async => answer;

  @override
  Future<List<PickedFile>> pick(AttachmentSource source) =>
      throw UnimplementedError('المكتبة تسمّي ملفاً واحداً في كل مرة');
}

void main() {
  late _MockDesignRepository repository;
  late _FakePicker picker;

  const logo = CustomerDesign(id: 1, label: 'شعار المتجر', kind: DesignKind.image);
  const created = CustomerDesign(id: 2, label: 'كيس العيد', kind: DesignKind.image);

  // الاسم الذي يعطيه iOS لصورةٍ من الاستوديو — وهو ما لا يجب أن يصل إلى المكتبة.
  const photo = PickedFile(
    path: '/tmp/image_picker_5D16.jpg',
    name: 'image_picker_5D16.jpg',
    sizeBytes: 414 * 1024,
  );

  setUpAll(() {
    registerFallbackValue(const PickedFile(path: '', name: '', sizeBytes: 0));
  });

  Future<void> arrange({List<CustomerDesign> designs = const [logo]}) async {
    await Injector.reset();

    repository = _MockDesignRepository();
    picker = _FakePicker()..answer = photo;

    when(() => repository.list()).thenAnswer((_) async => Right(designs));
    when(
      () => repository.upload(file: any(named: 'file'), label: any(named: 'label')),
    ).thenAnswer((_) async => const Right(created));

    sl
      ..registerSingleton<AttachmentPicker>(picker)
      ..registerFactory<DesignsCubit>(
        () => DesignsCubit(
          list: ListDesigns(repository),
          upload: UploadDesign(repository),
          rename: RenameDesign(repository),
          remove: RemoveDesign(repository),
        ),
      );
  }

  /// التطبيق كما يجمعه `DayaaApp` — و`DismissKeyboard` ملفوفٌ حول كل مسار، النوافذ معها.
  /// انظر `designs_page_rename_test.dart` لسبب ألّا يُترك.
  Widget host() => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) =>
          DismissKeyboard(child: child ?? const SizedBox.shrink()),
      home: const DesignsPage(),
    ),
  );

  tearDown(Injector.reset);

  Future<void> openPage(WidgetTester tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
  }

  /// من الزر العائم إلى ما بعد المنتقي: الزر، ثم «صور»، ثم ما يعيده المنتقي.
  Future<void> addFromPhotos(WidgetTester tester) async {
    await openPage(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('صور'));
    await tester.pumpAndSettle();
  }

  /// حقل الاسم في النافذة — وفي الشاشة حقلٌ آخر، حقل البحث.
  Finder nameField() =>
      find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextFormField));

  void verifyNothingUploaded() => verifyNever(
    () => repository.upload(file: any(named: 'file'), label: any(named: 'label')),
  );

  group('الزر العائم', () {
    testWidgets('الإضافة زرٌّ عائم، لا خانةٌ في آخر الشبكة', (tester) async {
      // Arrange
      await arrange();

      // Act
      await openPage(tester);

      // Assert — «أضف تصميماً» مرةً واحدة في الشاشة كلها، وهي على الزر العائم.
      expect(find.widgetWithText(FloatingActionButton, 'أضف تصميماً'), findsOneWidget);
      expect(find.text('أضف تصميماً'), findsOneWidget);
    });

    testWidgets('لا جملةَ شرحٍ فوق المكتبة', (tester) async {
      // Arrange
      await arrange();

      // Act
      await openPage(tester);

      // Assert
      expect(find.textContaining('ارفع شعارك'), findsNothing);
      expect(find.text('شعار المتجر'), findsOneWidget);
    });

    testWidgets('المكتبة الفارغة تحمل الزر العائم وحده، بلا زرٍّ ثانٍ ولا شرح', (tester) async {
      // Arrange
      await arrange(designs: const []);

      // Act
      await openPage(tester);

      // Assert
      expect(find.text('لا توجد تصاميم بعد'), findsOneWidget);
      expect(find.widgetWithText(FloatingActionButton, 'أضف تصميماً'), findsOneWidget);
      expect(find.text('أضف تصميماً'), findsOneWidget);
      expect(find.textContaining('ارفع شعارك'), findsNothing);
    });

    testWidgets('لا زرّ قبل أن تُحمَّل المكتبة', (tester) async {
      // Arrange — مكتبةٌ لم تصل: لا قائمةَ يُضاف إليها بعد.
      await arrange();
      when(
        () => repository.list(),
      ).thenAnswer((_) async => const Left(NetworkFailure(message: 'لا يوجد اتصال')));

      // Act
      await openPage(tester);

      // Assert
      expect(find.text('أعد المحاولة'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('لا يبدأ إضافةً ثانية ورفعُ الأولى لم ينتهِ', (tester) async {
      // Arrange — رفعٌ معلّق، لا يعود حتى يُكمله الاختبار بيده.
      await arrange();
      final pending = Completer<Either<Failure, CustomerDesign>>();
      when(
        () => repository.upload(file: any(named: 'file'), label: any(named: 'label')),
      ).thenAnswer((_) => pending.future);

      await addFromPhotos(tester);
      await tester.enterText(nameField(), 'كيس العيد');
      await tester.tap(find.text('إنشاء'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Assert — لم تُفتح ورقة «من أين؟».
      expect(find.text('إضافة تصميم'), findsNothing);

      pending.complete(const Right(created));
      await tester.pumpAndSettle();
    });
  });

  group('الاسم قبل الرفع', () {
    testWidgets('يُسأل عن الاسم بعد اختيار الملف، ولا يُرفع شيءٌ قبل الجواب', (tester) async {
      // Arrange
      await arrange();

      // Act
      await addFromPhotos(tester);

      // Assert — والحقل فارغ: اسم الملف لا يُقترح، فهو ما جاء هذا السؤال ليمنعه.
      expect(find.text('تصميم جديد'), findsOneWidget);
      expect(find.text('image_picker_5D16'), findsNothing);
      expect(find.text('image_picker_5D16.jpg'), findsNothing);
      verifyNothingUploaded();
    });

    testWidgets('«إنشاء» يرفع الملف بالاسم المكتوب، والتصميم يظهر به', (tester) async {
      // Arrange
      await arrange();
      await addFromPhotos(tester);

      // Act
      await tester.enterText(nameField(), '  كيس العيد ');
      await tester.tap(find.text('إنشاء'));
      await tester.pumpAndSettle();

      // Assert
      verify(() => repository.upload(file: photo, label: 'كيس العيد')).called(1);
      expect(find.text('تصميم جديد'), findsNothing);
      expect(find.text('كيس العيد'), findsOneWidget);
    });

    testWidgets('«إلغاء» يُغلق النافذة ولا يرفع شيئاً', (tester) async {
      // Arrange
      await arrange();
      await addFromPhotos(tester);

      // Act
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('تصميم جديد'), findsNothing);
      verifyNothingUploaded();
    });

    testWidgets('الاسم الفارغ يُردّ برسالةٍ تحت الحقل، والنافذة باقية', (tester) async {
      // Arrange
      await arrange();
      await addFromPhotos(tester);

      // Act
      await tester.tap(find.text('إنشاء'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(ValidationMessages.required), findsOneWidget);
      expect(find.text('تصميم جديد'), findsOneWidget);
      verifyNothingUploaded();
    });

    testWidgets('ملفٌ مرفوض لا يُسأل عن اسمه ولا يُرفع', (tester) async {
      // Arrange — صيغةٌ لا يقبلها الخادم، فتسميتها تعبٌ في شيءٍ لن يُحفظ.
      await arrange();
      picker.answer = const PickedFile(path: '/tmp/brief.docx', name: 'brief.docx', sizeBytes: 2048);

      // Act
      await addFromPhotos(tester);

      // Assert
      expect(find.text('الملف يجب أن يكون بصيغة PDF أو JPG أو PNG أو WEBP'), findsOneWidget);
      expect(find.text('تصميم جديد'), findsNothing);
      verifyNothingUploaded();

      // التوست يبقى ثلاث ثوانٍ ثم ينسحب؛ يُنتظر حتى يغيب، مؤقّته وحركة خروجه، كي لا يبقى
      // شيءٌ منهما معلّقاً بعد الاختبار.
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('الخروج من المنتقي بلا ملف لا يسأل عن شيء', (tester) async {
      // Arrange
      await arrange();
      picker.answer = null;

      // Act
      await addFromPhotos(tester);

      // Assert
      expect(find.text('تصميم جديد'), findsNothing);
      verifyNothingUploaded();
    });
  });
}
