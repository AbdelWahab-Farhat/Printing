import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/carrier/models/nawris_settlement.dart';
import 'package:dayaa/features/carrier/presentation/viewmodel/nawris_settlement_cubit.dart';
import 'package:dayaa/features/carrier/presentation/widgets/nawris_settlement_line_tile.dart';
import 'package:dayaa/features/carrier/repositories/carrier_repository.dart';
import 'package:dayaa/features/carrier/usecases/nawris_settlement.dart';
import 'package:dayaa/features/orders/models/transition_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCarrierRepository extends Mock implements CarrierRepository {}

/// تقرير النورس: المعاينة تعرض ما قاله الخادم، والتنفيذ يعيد ما كتبه الموظف بالرمز نفسه.
///
/// Arrange - Act - Assert throughout.
void main() {
  const file = PickedFile(path: '/tmp/report.xlsx', name: 'report.xlsx', sizeBytes: 100);

  Map<String, dynamic> lineJson({
    String outcome = 'settled',
    String? orderCode = '1203',
    String? reason,
    List<Map<String, dynamic>> warnings = const [],
  }) => {
    'row_number': 1,
    'raw_status': 'تم التسوية',
    'raw_code': '4097115',
    'raw_receiver': '1203',
    'order_id': orderCode == null ? null : 7,
    'order_code': orderCode,
    'previous_status': 'delivered',
    'previous_status_label': 'تم الاستلام',
    'outcome': outcome,
    'outcome_label': 'تُسوّى',
    'reason_code': null,
    'reason': reason,
    'warnings': warnings,
    'held_amount': '100.00',
    'fee_amount': '0.00',
  };

  Map<String, dynamic> previewJson({
    String totalHeld = '100.00',
    String expected = '100.00',
    int settled = 1,
    List<Map<String, dynamic>> fields = const [],
  }) => {
    'summary': {
      'rows_count': 1,
      'orders_count': 1,
      'settled_count': settled,
      'skipped_count': 0,
      'rejected_count': 0,
      'warnings_count': 0,
    },
    'total_held': totalHeld,
    'known_fees': '0.00',
    'expected_received': expected,
    'fingerprint': 'f' * 64,
    'fields': fields,
    'lines': [lineJson()],
  };

  const importJson = {
    'id': 12,
    'file_name': 'report.xlsx',
    'imported_by': {'id': 3, 'name': 'سارة'},
    'summary': {
      'rows_count': 1,
      'orders_count': 1,
      'settled_count': 1,
      'skipped_count': 0,
      'rejected_count': 0,
      'warnings_count': 0,
    },
    'total_held': '100.00',
    'received_amount': '100.00',
    'fee_total': '0.00',
    'difference_reason': null,
    'created_at': '2026-11-05T12:00:00+00:00',
  };

  final accountField = <String, dynamic>{
    'key': 'settlement_bank_account_id',
    'type': 'treasury_account',
    'label': 'حساب المصرف',
    'required': true,
    'options': [
      {'value': '3', 'label': 'مصرف الوحدة'},
    ],
  };

  group('قراءة ردّ الخادم', () {
    test('المعاينة تُقرأ بحقولها وأسطرها', () {
      // Act
      final preview = NawrisSettlementPreview.fromJson(previewJson(fields: [accountField]));

      // Assert
      expect(preview.summary.settledCount, 1);
      expect(preview.lines.single.title, 'طلبية 1203');
      expect(preview.fields.single.type, TransitionFieldType.treasuryAccount);
      expect(preview.fields.single.isRequired, isTrue);
    });

    test('نتيجة لا يعرفها هذا الإصدار لا تُسقط الشاشة', () {
      // Act
      final line = NawrisSettlementLine.fromJson(lineJson(outcome: 'something_new'));

      // Assert
      expect(line.outcome, NawrisSettlementOutcome.unknown);
    });

    test('سطر بلا طلبية يُعرف بما كُتب في الملف', () {
      // Act
      final line = NawrisSettlementLine.fromJson(lineJson(orderCode: null));

      // Assert
      expect(line.title, '1203');
    });

    test('الدفعة تُقرأ بلا أسطر في القائمة', () {
      // Act
      final batch = NawrisSettlementImport.fromJson(importJson);

      // Assert
      expect(batch.importedBy?.name, 'سارة');
      expect(batch.items, isEmpty);
    });
  });

  group('ما يسمح بالضغط على «تنفيذ»', () {
    NawrisSettlementPreview preview({String held = '100.00', String expected = '100.00'}) =>
        NawrisSettlementPreview.fromJson(previewJson(totalHeld: held, expected: expected));

    test('المبلغ المتوقع يكفي بلا سبب', () {
      // Act
      final allowed = preview().canSubmit(received: '100', reason: '', accounts: const {});

      // Assert
      expect(allowed, isTrue);
    });

    test('الفرق لا يمرّ بلا جواب', () {
      // Arrange
      final subject = preview();

      // Act
      final unanswered = subject.canSubmit(received: '90', reason: 'عمولة', accounts: const {});

      // Assert
      expect(subject.hasUnexplainedDifference('90'), isTrue);
      expect(unanswered, isFalse);
    });

    test('الأجرة يلزمها سبب', () {
      // Arrange
      final subject = preview();

      // Act
      final without = subject.canSubmit(
        received: '90',
        reason: ' ',
        accounts: const {},
        difference: NawrisSettlementDifference.fee,
      );
      final withReason = subject.canSubmit(
        received: '90',
        reason: 'عمولة',
        accounts: const {},
        difference: NawrisSettlementDifference.fee,
      );

      // Assert
      expect(without, isFalse);
      expect(withReason, isTrue);
    });

    test('ما زال عند النورس يوقف الزرّ ولو كُتب سبب', () {
      // Act
      final allowed = preview().canSubmit(
        received: '90',
        reason: 'عمولة',
        accounts: const {},
        difference: NawrisSettlementDifference.notArrived,
      );

      // Assert
      expect(allowed, isFalse);
    });

    test('ما تشرحه الأجور المعروفة لا يُسأل عنه', () {
      // Act
      final subject = NawrisSettlementPreview.fromJson({
        ...previewJson(totalHeld: '150.00', expected: '130.00'),
        'known_fees': '20.00',
      });

      // Assert
      expect(subject.hasUnexplainedDifference('130'), isFalse);
      expect(subject.hasUnexplainedDifference('129.99'), isTrue);
    });

    group('ترك الطلبيات', () {
      // 700 عند النورس: 400 و300، وعلى الثانية أجرة معروفة 20.
      Map<String, dynamic> held(int id, String amount, {String fee = '0.00'}) => {
        ...lineJson(),
        'order_id': id,
        'held_amount': amount,
        'fee_amount': fee,
      };

      final subject = NawrisSettlementPreview.fromJson({
        ...previewJson(totalHeld: '700.00', expected: '680.00', settled: 2),
        'known_fees': '20.00',
        'lines': [held(1, '400.00'), held(2, '300.00', fee: '20.00')],
      });

      test('المجموع والمتوقع يتبعان العلامات', () {
        // Assert
        expect(subject.heldFor(), '700.00');
        expect(subject.expectedFor(), '680.00');
        expect(subject.settlingCount(), 2);
        expect(subject.heldFor({2}), '400.00');
        expect(subject.feesFor({2}), '0.00');
        expect(subject.expectedFor({2}), '400.00');
        expect(subject.settlingCount({2}), 1);
      });

      test('ترك ما لم يصل يُزيل الفرق فلا يُسأل عنه', () {
        // Act
        final allowed = subject.canSubmit(
          received: '400',
          reason: '',
          accounts: const {},
          difference: NawrisSettlementDifference.notArrived,
          leftOut: {2},
        );

        // Assert
        expect(subject.hasUnexplainedDifference('400'), isTrue);
        expect(subject.hasUnexplainedDifference('400', {2}), isFalse);
        expect(allowed, isTrue);
      });

      test('المبلغ يُقارن بما بقي', () {
        // Assert
        expect(subject.exceedsHeld('500'), isFalse);
        expect(subject.exceedsHeld('500', {2}), isTrue);
      });

      test('الفرق كما يُعرض في السؤال', () {
        // Assert
        expect(subject.differenceFor('600'), '100.00');
        expect(subject.differenceFor('300', {2}), '100.00');
      });

      test('ترك كل الطلبيات لا يُنفَّذ', () {
        // Act
        final allowed = subject.canSubmit(
          received: '0',
          reason: '',
          accounts: const {},
          leftOut: {1, 2},
        );

        // Assert
        expect(allowed, isFalse);
      });

      test('ترك الطلبية الوحيدة ذات المال: لا مبلغ يُسأل عنه', () {
        // Assert
        expect(subject.holdsMoney({1, 2}), isFalse);
      });
    });

    test('أكثر مما عند النورس لا يُرسل', () {
      // Act
      final allowed = preview().canSubmit(received: '100.01', reason: 'x', accounts: const {});

      // Assert
      expect(allowed, isFalse);
    });

    test('الأرقام العربية تُقرأ كما تُكتب', () {
      // Act
      final subject = preview();

      // Assert
      expect(subject.hasUnexplainedDifference('١٠٠'), isFalse);
      expect(subject.canSubmit(received: '١٠٠', reason: '', accounts: const {}), isTrue);
    });

    test('نصّ ليس مبلغاً لا يُرسل', () {
      // Act
      final allowed = preview().canSubmit(received: '1.2.3', reason: 'x', accounts: const {});

      // Assert
      expect(allowed, isFalse);
    });

    test('حساب إجباري بلا جواب يوقف الزرّ', () {
      // Arrange
      final subject = NawrisSettlementPreview.fromJson(previewJson(fields: [accountField]));

      // Act
      final empty = subject.canSubmit(
        received: '100',
        reason: '',
        accounts: const {'settlement_bank_account_id': null},
      );
      final answered = subject.canSubmit(
        received: '100',
        reason: '',
        accounts: const {'settlement_bank_account_id': '3'},
      );

      // Assert
      expect(empty, isFalse);
      expect(answered, isTrue);
    });

    test('لا مال عند النورس: لا مبلغ يُسأل عنه', () {
      // Arrange
      final subject = preview(held: '0.00', expected: '0.00');

      // Act
      final allowed = subject.canSubmit(received: '', reason: '', accounts: const {});

      // Assert
      expect(subject.holdsMoney(), isFalse);
      expect(allowed, isTrue);
    });

    test('لا طلبية تُسوّى: لا تنفيذ', () {
      // Arrange
      final subject = NawrisSettlementPreview.fromJson(previewJson(settled: 0));

      // Act
      final allowed = subject.canSubmit(received: '100', reason: '', accounts: const {});

      // Assert
      expect(allowed, isFalse);
    });
  });

  group('من الملف إلى الدفعة', () {
    late _MockCarrierRepository repository;
    late List<String> tokens;

    final preview = NawrisSettlementPreview.fromJson(previewJson());
    final batch = NawrisSettlementImport.fromJson(importJson);
    const refusal = Failure.server(
      message: 'تغيّرت الطلبيات',
      fieldErrors: {
        'fingerprint': ['أعد المعاينة'],
      },
    );

    setUpAll(() {
      registerFallbackValue(const NawrisSettlementSubmission(fingerprint: 'x', clientToken: 'y'));
    });

    setUp(() {
      repository = _MockCarrierRepository();
      tokens = ['token-1', 'token-2'];

      when(
        () => repository.previewSettlement(
          path: any(named: 'path'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => Right(preview));
    });

    NawrisSettlementCubit build() => NawrisSettlementCubit(
      preview: PreviewNawrisSettlement(repository),
      import: ImportNawrisSettlement(repository),
      newToken: () => tokens.removeAt(0),
    );

    void importAnswers(Either<Failure, NawrisSettlementImport> answer) {
      when(
        () => repository.importSettlement(
          path: any(named: 'path'),
          fileName: any(named: 'fileName'),
          submission: any(named: 'submission'),
        ),
      ).thenAnswer((_) async => answer);
    }

    NawrisSettlementSubmission lastSubmission() =>
        verify(
              () => repository.importSettlement(
                path: any(named: 'path'),
                fileName: any(named: 'fileName'),
                submission: captureAny(named: 'submission'),
              ),
            ).captured.last
            as NawrisSettlementSubmission;

    blocTest<NawrisSettlementCubit, NawrisSettlementState>(
      'الملف يصير معاينة',
      build: build,
      act: (cubit) => cubit.read(file),
      expect: () => [
        const NawrisSettlementState.reading(file),
        NawrisSettlementState.ready(file: file, preview: preview),
      ],
    );

    blocTest<NawrisSettlementCubit, NawrisSettlementState>(
      'ملف مرفوض يعود إلى البداية برسالة الخادم',
      setUp: () {
        when(
          () => repository.previewSettlement(
            path: any(named: 'path'),
            fileName: any(named: 'fileName'),
          ),
        ).thenAnswer((_) async => const Left(Failure.server(message: 'ملف تالف')));
      },
      build: build,
      act: (cubit) => cubit.read(file),
      expect: () => [
        const NawrisSettlementState.reading(file),
        const NawrisSettlementState.unreadable(Failure.server(message: 'ملف تالف')),
      ],
    );

    test('التنفيذ يرسل البصمة والرمز والمبلغ بالأرقام اللاتينية', () async {
      // Arrange
      importAnswers(Right(batch));
      final cubit = build();
      await cubit.read(file);

      // Act
      await cubit.submit(
        receivedAmount: ' ٩٠ ',
        differenceReason: ' عمولة ',
        accounts: const {'settlement_bank_account_id': '3'},
      );

      // Assert
      final sent = lastSubmission();
      expect(sent.fingerprint, preview.fingerprint);
      expect(sent.clientToken, 'token-1');
      expect(sent.receivedAmount, '90');
      expect(sent.differenceReason, 'عمولة');
      expect(sent.accounts, {'settlement_bank_account_id': '3'});
      expect(cubit.state, NawrisSettlementState.settled(batch));
    });

    test('الإعادة بعد انقطاع ترسل الرمز نفسه فلا تسوّي مرتين', () async {
      // Arrange
      importAnswers(const Left(Failure.network(message: 'انقطع الاتصال')));
      final cubit = build();
      await cubit.read(file);
      await cubit.submit(receivedAmount: '100');
      final first = lastSubmission();

      // Act
      importAnswers(Right(batch));
      await cubit.submit(receivedAmount: '100');

      // Assert
      expect(lastSubmission().clientToken, first.clientToken);
      expect(cubit.state, NawrisSettlementState.settled(batch));
    });

    test('الرفض يُبقي المعاينة، وإعادتها رمزٌ جديد', () async {
      // Arrange
      importAnswers(const Left(refusal));
      final cubit = build();
      await cubit.read(file);
      await cubit.submit(receivedAmount: '100');

      expect(
        cubit.state,
        NawrisSettlementState.refused(file: file, preview: preview, failure: refusal),
      );

      // Act
      await cubit.readAgain();
      importAnswers(Right(batch));
      await cubit.submit(receivedAmount: '100');

      // Assert
      expect(lastSubmission().clientToken, 'token-2');
    });

    test('لا مال عند النورس: لا مبلغ يُرسل', () async {
      // Arrange
      when(
        () => repository.previewSettlement(
          path: any(named: 'path'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer(
        (_) async => Right(
          NawrisSettlementPreview.fromJson(previewJson(totalHeld: '0.00', expected: '0.00')),
        ),
      );
      importAnswers(Right(batch));
      final cubit = build();
      await cubit.read(file);

      // Act
      await cubit.submit(receivedAmount: '');

      // Assert
      expect(lastSubmission().receivedAmount, isNull);
    });

    test('الإلغاء لا يكتب شيئاً', () async {
      // Arrange
      final cubit = build();
      await cubit.read(file);

      // Act
      cubit.reset();

      // Assert
      expect(cubit.state, const NawrisSettlementState.idle());
      verifyNever(
        () => repository.importSettlement(
          path: any(named: 'path'),
          fileName: any(named: 'fileName'),
          submission: any(named: 'submission'),
        ),
      );
    });
  });

  group('سطر الطلبية', () {
    Future<void> pump(WidgetTester tester, NawrisSettlementLine line) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(430, 932),
          builder: (context, _) => MaterialApp(
            home: Scaffold(
              body: Directionality(
                textDirection: TextDirection.rtl,
                child: NawrisSettlementLineTile(line: line),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('السبب والتنبيه كما قالهما الخادم', (tester) async {
      // Arrange
      final line = NawrisSettlementLine.fromJson(
        lineJson(
          outcome: 'rejected',
          reason: 'باقٍ على الطلبية 20 د.ل.',
          warnings: [
            {'code': 'code_mismatch', 'message': 'كود الملف يخالف كود الطرد عندنا.'},
          ],
        ),
      );

      // Act
      await pump(tester, line);

      // Assert
      expect(find.text('باقٍ على الطلبية 20 د.ل.'), findsOneWidget);
      expect(find.text('كود الملف يخالف كود الطرد عندنا.'), findsOneWidget);
    });

    testWidgets('المبلغ على ما سيُسوّى وحده', (tester) async {
      // Act
      await pump(tester, NawrisSettlementLine.fromJson(lineJson()));

      // Assert
      expect(find.text('100 د.ل'), findsOneWidget);
    });

    testWidgets('لا مبلغ على ما لن يتحرك', (tester) async {
      // Act
      await pump(tester, NawrisSettlementLine.fromJson(lineJson(outcome: 'rejected')));

      // Assert
      expect(find.text('100 د.ل'), findsNothing);
    });
  });
}
