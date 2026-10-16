import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/wallet/models/online_top_up_models.dart';
import 'package:dayaa_client/features/wallet/presentation/viewmodel/top_up_cubit.dart';
import 'package:dayaa_client/features/wallet/repositories/top_up_repository.dart';
import 'package:dayaa_client/features/wallet/usecases/top_up_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

/// EzonePay في الذاكرة: يقول ما يُقال له، ويحفظ ما وصله.
class _FakeTopUp implements TopUpRepository {
  bool enabled = true;

  /// ما يجيب به البدء — يُغيَّر لكل اختبار.
  Either<Failure, TopUpAnswer> Function(TopUpRequest request)? onStart;
  Either<Failure, TopUpAnswer> Function(String otp)? onOtp;

  /// ما يجيب به السؤال، بالترتيب، ثم آخره.
  List<TopUpAnswer> shows = [];

  final List<TopUpRequest> started = [];
  final List<String> quoted = [];

  /// يرفض الخادم عرضَ هذا المبلغ — أقلُّ الطريقة.
  String? refusedAmount;

  @override
  Future<Either<Failure, TopUpMethods>> methods() async => Right(
    TopUpMethods(
      enabled: enabled,
      feePayer: 'customer',
      methods: const [
        TopUpMethod(id: 128, label: 'QR', flow: 'qr', feePercentage: '1'),
        TopUpMethod(id: 111, label: 'ليبيانا', flow: 'otp', feePercentage: '2.5'),
        TopUpMethod(id: 101, label: 'بطاقة مصرفية', flow: 'link', feePercentage: '1.5'),
      ],
    ),
  );

  @override
  Future<Either<Failure, TopUpQuote>> quote({required int method, required String amount}) async {
    quoted.add('$method:$amount');

    if (amount == refusedAmount) {
      const least = 'أقل مبلغٍ يُدفع بهذه الطريقة 10.00 د.ل';

      return const Left(
        Failure.server(
          message: least,
          statusCode: 422,
          fieldErrors: {
            'amount': [least],
          },
        ),
      );
    }

    return Right(TopUpQuote(amount: amount, total: '102.50', fee: '2.50'));
  }

  @override
  Future<Either<Failure, TopUpAnswer>> start(TopUpRequest request) async {
    started.add(request);

    return onStart!(request);
  }

  @override
  Future<Either<Failure, TopUpAnswer>> confirmOtp(String attemptId, String otp) async => onOtp!(otp);

  @override
  Future<Either<Failure, TopUpAnswer>> show(String attemptId) async =>
      Right(shows.length > 1 ? shows.removeAt(0) : shows.single);
}

TopUpAnswer _answer(String status, {String flow = 'otp', bool isFinal = false, bool otp = false, String? url}) =>
    TopUpAnswer(
      attempt: TopUpAttempt(
        id: '0b9e',
        methodLabel: 'ليبيانا',
        flow: flow,
        status: status,
        statusLabel: status,
        isFinal: isFinal,
        requiresOtp: otp,
        otpAttemptsLeft: 3,
        paymentUrl: url,
        amount: '100.00',
        total: '102.50',
        fee: '2.50',
      ),
      balance: isFinal && status == 'succeeded' ? '100.00' : '0.00',
    );

/// «اشحن محفظتك» — CUSTOMER-WALLET §٥: النموذج والعرض، والرمز، وانتظار صفحة البطاقة، والنهاية؛
/// ومفتاحُ البدء يبقى على انقطاع الاتصال ويسقط على الرفض.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _FakeTopUp fake;

  const offline = Failure.network(message: FailureMessages.noConnection);
  const refused = Failure.server(message: 'تجاوزت الحد اليومي', statusCode: 422);

  TopUpCubit build({String? amount, int? orderId}) => TopUpCubit(
    getMethods: GetTopUpMethods(fake),
    quote: QuoteTopUp(fake),
    start: StartTopUp(fake),
    confirmOtp: ConfirmTopUpOtp(fake),
    getAttempt: GetTopUpAttempt(fake),
    initialAmount: amount,
    orderId: orderId,
    pollEvery: const Duration(milliseconds: 10),
    quoteDelay: Duration.zero,
  );

  setUp(() => fake = _FakeTopUp());

  test('switched off on the server, there is nothing to fill', () async {
    // Arrange
    fake.enabled = false;
    final cubit = build();

    // Act
    await cubit.load();

    // Assert
    expect(cubit.state, isA<TopUpUnavailable>());
    await cubit.close();
  });

  test('QR methods wait for a scanner; the first usable one is chosen and quoted', () async {
    // Arrange
    final cubit = build(amount: '١٠٠');

    // Act
    await cubit.load();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Assert
    final form = cubit.state as TopUpForm;
    expect(form.usable.map((m) => m.id), [111, 101]);
    expect(form.selected.id, 111);
    expect(fake.quoted, ['111:100']);
    expect(form.quote?.total, '102.50');
    await cubit.close();
  });

  test('an OTP method asks for the code, and the right code ends credited', () async {
    // Arrange
    fake.onStart = (_) => Right(_answer('pending', otp: true));
    fake.onOtp = (_) => Right(_answer('succeeded', isFinal: true));
    final cubit = build(amount: '100', orderId: 1304);
    await cubit.load();

    // Act
    await cubit.start(serviceMobileNumber: '0911111111');
    final onOtp = cubit.state;
    await cubit.confirmOtp('١٢٣٤');

    // Assert
    expect(onOtp, isA<TopUpOtp>());
    expect(fake.started.single.orderId, 1304);
    expect(fake.started.single.amount, '100');
    final done = cubit.state as TopUpDone;
    expect(done.attempt.succeeded, isTrue);
    expect(done.balance, '100.00');
    await cubit.close();
  });

  test('a wrong code stays on the code, with what the server says is left', () async {
    // Arrange
    fake.onStart = (_) => Right(_answer('pending', otp: true));
    fake.onOtp = (_) => const Left(refused);
    fake.shows = [_answer('pending', otp: true)];
    final cubit = build(amount: '100');
    await cubit.load();
    await cubit.start();

    // Act
    final failure = await cubit.confirmOtp('0000');

    // Assert
    expect(failure, refused);
    expect(cubit.state, isA<TopUpOtp>());
    expect((cubit.state as TopUpOtp).isSending, isFalse);
    await cubit.close();
  });

  test('a card link waits, asks again by itself, and ends when the bank confirms', () async {
    // Arrange
    fake.onStart = (_) => Right(_answer('pending', flow: 'link', url: 'https://pay.example/x'));
    fake.shows = [
        _answer('pending', flow: 'link', url: 'https://pay.example/x'),
        _answer('succeeded', flow: 'link', isFinal: true),
      ];
    final cubit = build(amount: '100');
    await cubit.load();
    cubit.select((cubit.state as TopUpForm).usable.last);

    // Act
    await cubit.start();
    final waiting = cubit.state;
    await Future<void>.delayed(const Duration(milliseconds: 80));

    // Assert
    expect(waiting, isA<TopUpWaiting>());
    expect(cubit.state, isA<TopUpDone>());
    await cubit.close();
  });

  test('a dropped connection retries with the same key; a refusal starts afresh', () async {
    // Arrange
    var answers = <Either<Failure, TopUpAnswer>>[const Left(offline), const Left(refused), const Left(refused)];
    fake.onStart = (_) => answers.removeAt(0);
    final cubit = build(amount: '100');
    await cubit.load();

    // Act
    await cubit.start();
    await cubit.start();
    await cubit.start();

    // Assert — the first two share a key: the server may have started the first.
    final keys = fake.started.map((r) => r.clientToken).toList();
    expect(keys[0], keys[1]);
    expect(keys[2], isNot(keys[1]));
    expect(cubit.state, isA<TopUpForm>());
    expect((cubit.state as TopUpForm).isStarting, isFalse);
    answers = [];
    await cubit.close();
  });

  test('an amount the method refuses says so as it is typed, and the next amount clears it', () async {
    // Arrange
    fake.refusedAmount = '5';
    final cubit = build(amount: '5');

    // Act
    await cubit.load();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Assert
    final refused = cubit.state as TopUpForm;
    expect(refused.quote, isNull);
    expect(refused.quoteError, 'أقل مبلغٍ يُدفع بهذه الطريقة 10.00 د.ل');

    cubit.amountChanged('50');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final quoted = cubit.state as TopUpForm;
    expect(quoted.quoteError, isNull);
    expect(quoted.quote?.total, '102.50');
    await cubit.close();
  });

  test('a new amount is a new top-up, with a new key', () async {
    // Arrange
    fake.onStart = (_) => const Left(offline);
    final cubit = build(amount: '100');
    await cubit.load();
    await cubit.start();

    // Act
    cubit.amountChanged('150');
    await cubit.start();

    // Assert
    expect(fake.started[0].clientToken, isNot(fake.started[1].clientToken));
    expect(fake.started[1].amount, '150');
    await cubit.close();
  });
}
