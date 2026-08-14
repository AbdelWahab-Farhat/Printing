import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/customers/models/design_rules.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customer_designs_cubit.dart';
import 'package:dayaa/features/customers/repositories/customer_design_repository.dart';
import 'package:dayaa/features/customers/usecases/delete_customer_design.dart';
import 'package:dayaa/features/customers/usecases/get_customer_designs.dart';
import 'package:dayaa/features/customers/usecases/rename_customer_design.dart';
import 'package:dayaa/features/customers/usecases/upload_customer_design.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// A customer's library of artwork: reading it, adding to it, and tidying it.
///
/// The repository is the fake and the use cases are real, which is deliberate — the pre-flight
/// size check lives in [UploadCustomerDesign], and mocking that away would test a screen
/// against a rule that never runs.
///
/// Arrange - Act - Assert throughout.
class _MockDesignRepository extends Mock implements CustomerDesignRepository {}

void main() {
  late _MockDesignRepository repository;
  late CustomerDesignsCubit cubit;

  const logo = CustomerDesign(
    id: 1,
    customerId: 7,
    label: 'شعار المخبز',
    kind: DesignKind.image,
    kindLabel: 'صورة',
    fileUrl: 'https://cdn.example.com/logo.png',
  );
  const flyer = CustomerDesign(
    id: 2,
    customerId: 7,
    label: 'المنشور.pdf',
    kind: DesignKind.pdf,
    kindLabel: 'PDF',
    fileUrl: 'https://cdn.example.com/flyer.pdf',
  );

  const pickedLogo = PickedFile(path: '/tmp/logo.png', name: 'logo.png', sizeBytes: 2048);
  const pickedFlyer = PickedFile(path: '/tmp/flyer.pdf', name: 'flyer.pdf', sizeBytes: 4096);

  /// Stubs the upload endpoint. Named parameters are matched loosely because what goes down the
  /// wire is `CustomerDesignRepositoryImpl`'s business, not this Cubit's.
  void whenUploading(Answer<Future<Either<Failure, CustomerDesign>>> answer) {
    when(
      () => repository.upload(
        any(),
        path: any(named: 'path'),
        filename: any(named: 'filename'),
        label: any(named: 'label'),
        notes: any(named: 'notes'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer(answer);
  }

  setUp(() {
    repository = _MockDesignRepository();
    cubit = CustomerDesignsCubit(
      customerId: 7,
      getDesigns: GetCustomerDesigns(repository),
      uploadDesign: UploadCustomerDesign(repository),
      renameDesign: RenameCustomerDesign(repository),
      deleteDesign: DeleteCustomerDesign(repository),
    );

    when(() => repository.designs(7)).thenAnswer((_) async => const Right([logo]));
  });

  tearDown(() => cubit.close());

  blocTest<CustomerDesignsCubit, CustomerDesignsState>(
    'loads the library',
    build: () => cubit,
    // Act
    act: (cubit) => cubit.load(),
    // Assert
    expect: () => const [
      CustomerDesignsState.loading(),
      CustomerDesignsState.loaded(designs: [logo]),
    ],
  );

  blocTest<CustomerDesignsCubit, CustomerDesignsState>(
    "shows the server's own message when it cannot",
    setUp: () {
      // Arrange
      when(
        () => repository.designs(7),
      ).thenAnswer((_) async => const Left(Failure.server(message: 'العميل غير موجود')));
    },
    build: () => cubit,
    // Act
    act: (cubit) => cubit.load(),
    // Assert
    expect: () => const [
      CustomerDesignsState.loading(),
      CustomerDesignsState.failure(Failure.server(message: 'العميل غير موجود')),
    ],
  );

  blocTest<CustomerDesignsCubit, CustomerDesignsState>(
    'a refresh never blanks a grid somebody is looking at',
    setUp: () {
      // Arrange — coming back from an upload elsewhere reloads, and a flash of a spinner over
      // a full grid loses the user's place.
      var call = 0;
      when(
        () => repository.designs(7),
      ).thenAnswer((_) async => Right(call++ == 0 ? const [logo] : const [flyer, logo]));
    },
    build: () => cubit,
    // Act
    act: (cubit) async {
      await cubit.load();
      await cubit.load();
    },
    // Assert — `loading` appears once, at the very start.
    expect: () => const [
      CustomerDesignsState.loading(),
      CustomerDesignsState.loaded(designs: [logo]),
      CustomerDesignsState.loaded(designs: [flyer, logo]),
    ],
  );

  blocTest<CustomerDesignsCubit, CustomerDesignsState>(
    'a chosen file shows as a row of its own, then becomes a design',
    setUp: () {
      // Arrange
      whenUploading((_) async => const Right(flyer));
    },
    build: () => cubit,
    // Act
    act: (cubit) async {
      await cubit.load();
      await cubit.add([pickedFlyer]);
    },
    // Assert — the row exists before the request is answered, which is the whole point of it.
    expect: () => const [
      CustomerDesignsState.loading(),
      CustomerDesignsState.loaded(designs: [logo]),
      CustomerDesignsState.loaded(
        designs: [logo],
        uploads: [DesignUpload(file: pickedFlyer)],
      ),
      CustomerDesignsState.loaded(
        designs: [logo],
        uploads: [DesignUpload(file: pickedFlyer, isUploading: true)],
      ),
      // Newest first, and the row is gone the moment it is a real design.
      CustomerDesignsState.loaded(designs: [flyer, logo]),
    ],
  );

  test('a file the API would refuse never leaves the phone', () async {
    // Arrange — 26 MB against the server's 25. Pushing it over a mobile connection to be told
    // its size is a minute of somebody's time and their data allowance.
    await cubit.load();
    const tooBig = PickedFile(
      path: '/tmp/huge.pdf',
      name: 'huge.pdf',
      sizeBytes: (DesignRules.maxKilobytes + 1) * 1024,
    );

    // Act
    await cubit.add([tooBig]);

    // Assert — refused, with the reason attached to its own row, and nothing sent.
    final state = cubit.state as CustomerDesignsLoaded;
    expect(state.uploads.single.hasFailed, isTrue);
    expect(state.uploads.single.failure?.message, contains('25 ميجابايت'));
    verifyNever(
      () => repository.upload(
        any(),
        path: any(named: 'path'),
        filename: any(named: 'filename'),
        label: any(named: 'label'),
        notes: any(named: 'notes'),
        onProgress: any(named: 'onProgress'),
      ),
    );
  });

  test('files go up one at a time, not all at once', () async {
    // Arrange — three bars crawling over one slow uplink means none of them finishes, and the
    // first file is the one the user is waiting on.
    final gate = Completer<Either<Failure, CustomerDesign>>();
    var started = 0;

    whenUploading((_) {
      started++;

      return started == 1 ? gate.future : Future.value(const Right(logo));
    });
    await cubit.load();

    // Act
    final adding = cubit.add([pickedFlyer, pickedLogo]);
    await Future<void>.delayed(Duration.zero);

    // Assert — the second is queued, not sent.
    expect(started, 1);
    final waiting = cubit.state as CustomerDesignsLoaded;
    expect(waiting.uploads.map((upload) => upload.isUploading), [true, false]);

    gate.complete(const Right(flyer));
    await adding;
    expect(started, 2);
  });

  test('a stopped upload keeps its row, and retrying is free', () async {
    // Arrange — the endpoint is idempotent on the file's checksum, which is what lets a retry
    // be offered without asking anybody whether the first attempt landed.
    var attempts = 0;
    whenUploading((_) async {
      attempts++;

      return attempts == 1
          ? const Left(Failure.network(message: FailureMessages.noConnection))
          : const Right(flyer);
    });
    await cubit.load();

    // Act
    await cubit.add([pickedFlyer]);
    final stopped = cubit.state as CustomerDesignsLoaded;

    // Assert — the file is still here, with the reason on it.
    expect(stopped.designs, const [logo]);
    expect(stopped.uploads.single.hasFailed, isTrue);

    // Act
    await cubit.retry(pickedFlyer.path);

    // Assert
    expect(attempts, 2);
    expect((cubit.state as CustomerDesignsLoaded).designs, const [flyer, logo]);
    expect((cubit.state as CustomerDesignsLoaded).uploads, isEmpty);
  });

  test('giving up on an upload takes its row away', () async {
    // Arrange
    whenUploading(
      (_) async => const Left(Failure.network(message: FailureMessages.noConnection)),
    );
    await cubit.load();
    await cubit.add([pickedFlyer]);

    // Act
    cubit.dismiss(pickedFlyer.path);

    // Assert
    expect((cubit.state as CustomerDesignsLoaded).uploads, isEmpty);
  });

  test('picking the same file twice queues it once', () async {
    // Arrange — the sheet can be opened again before the first batch finishes, and two bars
    // for one upload the server counts once is a lie about what is happening.
    final gate = Completer<Either<Failure, CustomerDesign>>();
    whenUploading((_) => gate.future);
    await cubit.load();

    // Act
    final first = cubit.add([pickedFlyer]);
    await cubit.add([pickedFlyer]);

    // Assert
    expect((cubit.state as CustomerDesignsLoaded).uploads, hasLength(1));

    gate.complete(const Right(flyer));
    await first;
  });

  test('re-uploading a file the customer already has moves it up, not in twice', () async {
    // Arrange — the server answers a known checksum with the design it already made, so this
    // returns an id that is already in the list.
    when(() => repository.designs(7)).thenAnswer((_) async => const Right([flyer, logo]));
    whenUploading((_) async => const Right(logo));
    await cubit.load();

    // Act
    await cubit.add([pickedLogo]);

    // Assert
    expect((cubit.state as CustomerDesignsLoaded).designs, const [logo, flyer]);
  });

  test('renaming replaces the design where it stands', () async {
    // Arrange
    const renamed = CustomerDesign(
      id: 1,
      customerId: 7,
      label: 'الشعار الجديد',
      kind: DesignKind.image,
      kindLabel: 'صورة',
      fileUrl: 'https://cdn.example.com/logo.png',
    );
    when(
      () => repository.rename(7, 1, label: 'الشعار الجديد', notes: null),
    ).thenAnswer((_) async => const Right(renamed));
    await cubit.load();

    // Act
    final failure = await cubit.rename(1, label: 'الشعار الجديد');

    // Assert — the caller is told nothing went wrong, and nothing is left marked busy.
    expect(failure, isNull);
    final state = cubit.state as CustomerDesignsLoaded;
    expect(state.designs, const [renamed]);
    expect(state.busy, isEmpty);
  });

  test('a rename that fails is handed back to the caller, and lets go of the row', () async {
    // Arrange — there is nothing left on screen for this failure to attach to, so it is
    // returned rather than parked in the state where a later emit would clear it unseen.
    when(() => repository.rename(7, 1, label: 'اسم', notes: null)).thenAnswer(
      (_) async => const Left(Failure.forbidden(message: FailureMessages.forbidden)),
    );
    await cubit.load();

    // Act
    final failure = await cubit.rename(1, label: 'اسم');

    // Assert
    expect(failure, isA<ForbiddenFailure>());
    final state = cubit.state as CustomerDesignsLoaded;
    expect(state.designs, const [logo], reason: 'the library must not change on a refusal');
    expect(state.busy, isEmpty, reason: 'a row left busy can never be tried again');
  });

  test('removing takes the design out of the library', () async {
    // Arrange
    when(() => repository.remove(7, 1)).thenAnswer((_) async => const Right('تم حذف التصميم'));
    await cubit.load();

    // Act
    final failure = await cubit.remove(1);

    // Assert
    expect(failure, isNull);
    expect((cubit.state as CustomerDesignsLoaded).designs, isEmpty);
  });

  test('a second tap while the first delete is in flight is ignored', () async {
    // Arrange — the sheet can be tapped twice, and two DELETEs racing means the second is a
    // 404 shown to somebody whose action actually worked.
    when(() => repository.remove(7, 1)).thenAnswer(
      (_) => Future.delayed(const Duration(milliseconds: 30), () => const Right('تم')),
    );
    await cubit.load();

    // Act
    final first = cubit.remove(1);
    await cubit.remove(1);
    await first;

    // Assert
    verify(() => repository.remove(7, 1)).called(1);
  });

  test('nothing is uploaded before the library has loaded', () async {
    // Arrange — there is no list to add to, and a request fired at nothing would land back on
    // top of the load.
    // Act
    await cubit.add([pickedFlyer]);

    // Assert
    expect(cubit.state, const CustomerDesignsState.loading());
    verifyNever(
      () => repository.upload(
        any(),
        path: any(named: 'path'),
        filename: any(named: 'filename'),
        label: any(named: 'label'),
        notes: any(named: 'notes'),
        onProgress: any(named: 'onProgress'),
      ),
    );
  });
}
