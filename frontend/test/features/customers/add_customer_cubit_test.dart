import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/models/new_customer.dart';
import 'package:printing/features/customers/presentation/viewmodel/add_customer_cubit.dart';
import 'package:printing/features/customers/repositories/customer_repository.dart';
import 'package:printing/features/customers/usecases/create_customer.dart';
import 'package:printing/features/customers/usecases/update_customer.dart';

/// The repository is faked, nothing touches Dio, and the assertions are on the sequence of
/// states the screen would have rendered.
///
/// Arrange - Act - Assert throughout.
class _MockCustomerRepository extends Mock implements CustomerRepository {}

void main() {
  late _MockCustomerRepository repository;
  late AddCustomerCubit cubit;

  // What the API answers with: the `code` is allocated by the server and is the one piece of
  // the reply the screen actually reads back to the user.
  const created = Customer(
    id: 7,
    code: 'C7',
    name: 'مطبعة النور',
    phone: '0913334444',
    isActive: true,
    shops: [],
  );

  // mocktail needs something to hand back for `any()` on a non-nullable custom type. It is
  // never read — only passed around while matching.
  setUpAll(() => registerFallbackValue(const NewCustomer(name: '', phone: '')));

  setUp(() {
    repository = _MockCustomerRepository();
    cubit = AddCustomerCubit(
      createCustomer: CreateCustomer(repository),
      updateCustomer: UpdateCustomer(repository),
    );
  });

  tearDown(() => cubit.close());

  void arrangeCreate(Either<Failure, Customer> result) {
    when(() => repository.create(any())).thenAnswer((_) async => result);
  }

  /// The payload the repository was handed, so a test can assert on what actually goes out.
  NewCustomer sentCustomer() =>
      verify(() => repository.create(captureAny())).captured.last as NewCustomer;

  // ─────────────────────────── creating ───────────────────────────

  blocTest<AddCustomerCubit, AddCustomerState>(
    'emits submitting then success when the server accepts the customer',
    setUp: () => arrangeCreate(const Right(created)),
    build: () => cubit,
    act: (cubit) => cubit.submit(name: 'مطبعة النور', phone: '0913334444'),
    expect: () => const [AddCustomerState.submitting(), AddCustomerState.success(created)],
  );

  blocTest<AddCustomerCubit, AddCustomerState>(
    'surfaces the server\'s own message, not a generic one',
    setUp: () => arrangeCreate(
      const Left(
        ServerFailure(
          message: 'رقم الهاتف مستخدم مسبقاً لعميل آخر',
          statusCode: 422,
          fieldErrors: {
            'phone': ['رقم الهاتف مستخدم مسبقاً لعميل آخر'],
          },
        ),
      ),
    ),
    build: () => cubit,
    act: (cubit) => cubit.submit(name: 'مطبعة النور', phone: '0913334444'),
    expect: () => const [
      AddCustomerState.submitting(),
      AddCustomerState.failure(
        ServerFailure(
          message: 'رقم الهاتف مستخدم مسبقاً لعميل آخر',
          statusCode: 422,
          fieldErrors: {
            'phone': ['رقم الهاتف مستخدم مسبقاً لعميل آخر'],
          },
        ),
      ),
    ],
  );

  test('a second submit while one is in flight is ignored', () async {
    // Arrange — an impatient double tap on a *create* button is the one that matters: two
    // requests would be two customers if the phone were not unique server-side.
    var calls = 0;
    when(() => repository.create(any())).thenAnswer((_) async {
      calls++;
      await Future<void>.delayed(const Duration(milliseconds: 30));

      return const Right(created);
    });

    // Act — deliberately not awaited, so the second call lands mid-flight.
    final first = cubit.submit(name: 'مطبعة النور', phone: '0913334444');
    final second = cubit.submit(name: 'مطبعة النور', phone: '0913334444');
    await Future.wait([first, second]);

    // Assert
    expect(calls, 1);
  });

  // ─────────────────────────── what reaches the API ───────────────────────────

  test('the name is trimmed before it reaches the repository', () async {
    // Arrange — a name pasted from a message carries whitespace, and the customer it creates
    // is one nobody can find by searching for it.
    arrangeCreate(const Right(created));

    // Act
    await cubit.submit(name: '  مطبعة النور  ', phone: '0913334444');

    // Assert
    expect(sentCustomer().name, 'مطبعة النور');
  });

  test('an Arabic-Indic phone number is sent as western digits', () async {
    // Arrange — that is what a Libyan keyboard produces, and the API's `^\d{9,15}$` is
    // ASCII-only, so sending it through untouched is a 422 the user cannot diagnose.
    arrangeCreate(const Right(created));

    // Act
    await cubit.submit(name: 'مطبعة النور', phone: '٠٩١٣٣٣٤٤٤٤');

    // Assert
    expect(sentCustomer().phone, '0913334444');
  });

  // ─────────────────────────── what the screen reads ───────────────────────────

  test('field errors are offered under the field the server blamed', () async {
    // Arrange
    arrangeCreate(
      const Left(
        ServerFailure(
          message: 'البيانات المدخلة غير صحيحة',
          statusCode: 422,
          fieldErrors: {
            'name': ['اسم العميل يجب أن يكون حرفين على الأقل'],
            'phone': ['رقم الهاتف مستخدم مسبقاً لعميل آخر'],
          },
        ),
      ),
    );

    // Act
    await cubit.submit(name: 'م', phone: '0913334444');

    // Assert
    expect(cubit.state.nameError, 'اسم العميل يجب أن يكون حرفين على الأقل');
    expect(cubit.state.phoneError, 'رقم الهاتف مستخدم مسبقاً لعميل آخر');
  });

  test('a network failure carries no field error, so the screen shows a snackbar', () async {
    // Arrange
    arrangeCreate(const Left(NetworkFailure(message: FailureMessages.noConnection)));

    // Act
    await cubit.submit(name: 'مطبعة النور', phone: '0913334444');

    // Assert
    expect(cubit.state.nameError, isNull);
    expect(cubit.state.phoneError, isNull);
    expect(cubit.state, isA<AddCustomerFailure>());
  });

  blocTest<AddCustomerCubit, AddCustomerState>(
    'clearFailure returns to initial so the error under a field disappears while typing',
    setUp: () => arrangeCreate(const Left(ServerFailure(message: 'خطأ', statusCode: 422))),
    build: () => cubit,
    act: (cubit) async {
      await cubit.submit(name: 'مطبعة النور', phone: '0913334444');
      cubit.clearFailure();
    },
    expect: () => const [
      AddCustomerState.submitting(),
      AddCustomerState.failure(ServerFailure(message: 'خطأ', statusCode: 422)),
      AddCustomerState.initial(),
    ],
  );

  blocTest<AddCustomerCubit, AddCustomerState>(
    'clearFailure does nothing when there is no failure to clear',
    build: () => cubit,
    act: (cubit) => cubit.clearFailure(),
    expect: () => const <AddCustomerState>[],
  );

  // ─────────────────────────── the shops ───────────────────────────

  test('a customer added without shops mentions none at all', () async {
    // Arrange — to this API an empty array is a statement about the customer's shops; silence
    // is the honest thing for a form where the user simply added none.
    arrangeCreate(const Right(created));

    // Act
    await cubit.submit(name: 'مطبعة النور', phone: '0913334444');

    // Assert — `verify` consumes the recorded call, so it is read once and asserted on twice.
    final sent = sentCustomer();
    expect(sent.shops, isNull);
    expect(sent.toJson().containsKey('shops'), isFalse);
  });

  test('a shop is sent with its name and its coordinates as numbers', () async {
    // Arrange
    arrangeCreate(const Right(created));

    // Act
    await cubit.submit(
      name: 'مطبعة النور',
      phone: '0913334444',
      shops: const [
        (
          id: null,
          name: '  فرع سوق الجمعة  ',
          latitude: '32.8872',
          longitude: '13.1913',
          pageUrl: 'https://facebook.com/alnoor',
        ),
      ],
    );

    // Assert
    final shop = sentCustomer().shops!.single;
    expect(shop.name, 'فرع سوق الجمعة');
    expect(shop.latitude, 32.8872);
    expect(shop.longitude, 13.1913);
    expect(shop.pageUrl, 'https://facebook.com/alnoor');
  });

  test('Arabic-Indic coordinates and a decimal comma both reach the API as numbers', () async {
    // Arrange — ٣٢٫٨٨ is what a Libyan keyboard produces, and 32,88 is what the same keyboard
    // offers as a decimal mark. Sent through untouched, either is a 422 about a field the user
    // filled in correctly as far as they can tell.
    arrangeCreate(const Right(created));

    // Act
    await cubit.submit(
      name: 'مطبعة النور',
      phone: '0913334444',
      shops: const [
        (id: null, name: 'الفرع', latitude: '٣٢٫٨٨', longitude: '13,19', pageUrl: null),
      ],
    );

    // Assert
    final shop = sentCustomer().shops!.single;
    expect(shop.latitude, 32.88);
    expect(shop.longitude, 13.19);
  });

  test('an empty page link is left out rather than sent as an empty string', () async {
    // Arrange — the API's rule is `nullable|url`, and '' is neither.
    arrangeCreate(const Right(created));

    // Act
    await cubit.submit(
      name: 'مطبعة النور',
      phone: '0913334444',
      shops: const [
        (id: null, name: 'الفرع', latitude: '32.8', longitude: '13.1', pageUrl: '   '),
      ],
    );

    // Assert
    final json = sentCustomer().toJson()['shops'] as List<dynamic>;
    expect((json.single as Map<String, dynamic>).containsKey('page_url'), isFalse);
  });

  test('several shops keep the order they were entered in', () async {
    // Arrange — the server keys its complaints by index (`shops.1.latitude`), so the order the
    // screen shows and the order it sends have to be the same one.
    arrangeCreate(const Right(created));

    // Act
    await cubit.submit(
      name: 'مطبعة النور',
      phone: '0913334444',
      shops: const [
        (id: null, name: 'الأول', latitude: '32.1', longitude: '13.1', pageUrl: null),
        (id: null, name: 'الثاني', latitude: '32.2', longitude: '13.2', pageUrl: null),
        (id: null, name: 'الثالث', latitude: '32.3', longitude: '13.3', pageUrl: null),
      ],
    );

    // Assert
    expect(sentCustomer().shops!.map((shop) => shop.name), ['الأول', 'الثاني', 'الثالث']);
  });

  test('a rejected shop is blamed on the row the server named', () async {
    // Arrange
    arrangeCreate(
      const Left(
        ServerFailure(
          message: 'البيانات غير صحيحة',
          statusCode: 422,
          fieldErrors: {
            'shops.1.latitude': ['خط العرض يجب أن يكون بين -90 و 90'],
          },
        ),
      ),
    );

    // Act
    await cubit.submit(name: 'مطبعة النور', phone: '0913334444');

    // Assert — under the second shop's latitude box, and nowhere else.
    expect(cubit.state.shopError(1, 'latitude'), 'خط العرض يجب أن يكون بين -90 و 90');
    expect(cubit.state.shopError(0, 'latitude'), isNull);
    expect(cubit.state.nameError, isNull);
  });
}
