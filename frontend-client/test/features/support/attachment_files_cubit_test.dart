import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/attachment_store.dart';
import 'package:dayaa_client/core/files/transfer_cancel.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/attachment_files_cubit.dart';
import 'package:dayaa_client/features/support/usecases/download_attachment.dart';
import 'package:dayaa_client/features/support/usecases/find_attachment_on_phone.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStore extends Mock implements AttachmentStore {}

/// تنزيلُ ملفات المحادثة: سهمٌ، فحلقةٌ تمتلئ ويمكن إلغاؤها، فملفٌّ يُفتح.
///
/// Arrange - Act - Assert في كل حالة (`build` ثم `act` ثم `expect`/`verify` في `blocTest`).
void main() {
  late _MockStore store;

  const pdf = TicketMessage(
    id: 7,
    from: MessageAuthor.support,
    attachment: TicketAttachment(
      kind: AttachmentKind.pdf,
      name: 'quote.pdf',
      url: 'https://api.example/storage/quote?signature=x',
    ),
  );

  const words = TicketMessage(id: 8, from: MessageAuthor.me, body: 'شكراً');

  setUp(() => store = _MockStore());

  AttachmentFilesCubit build() => AttachmentFilesCubit(
    find: FindAttachmentOnPhone(store),
    download: DownloadAttachment(store),
  );

  group('discover', () {
    blocTest<AttachmentFilesCubit, AttachmentFilesState>(
      'ملفٌّ على الهاتف من قبل يُرسم جاهزاً للفتح، لا بسهم تنزيل',
      build: () {
        when(
          () => store.localPath(key: 'message-7', fileName: 'quote.pdf'),
        ).thenAnswer((_) async => '/cache/support/message-7/quote.pdf');

        return build();
      },
      act: (cubit) => cubit.discover(const [pdf, words]),
      expect: () => const [
        AttachmentFilesState(files: {7: AttachmentFile.local('/cache/support/message-7/quote.pdf')}),
      ],
    );

    blocTest<AttachmentFilesCubit, AttachmentFilesState>(
      'ولا يُسأل الهاتف عن رسالةٍ بلا ملف',
      build: build,
      act: (cubit) => cubit.discover(const [words]),
      expect: () => const <AttachmentFilesState>[],
      verify: (_) {
        verifyNever(
          () => store.localPath(key: any(named: 'key'), fileName: any(named: 'fileName')),
        );
      },
    );
  });

  group('fetch', () {
    blocTest<AttachmentFilesCubit, AttachmentFilesState>(
      'ينزّل الملف بتقدّمٍ ظاهر، ثم يصير جاهزاً للفتح',
      build: () {
        when(
          () => store.download(
            url: any(named: 'url'),
            key: 'message-7',
            fileName: 'quote.pdf',
            onProgress: any(named: 'onProgress'),
            cancel: any(named: 'cancel'),
          ),
        ).thenAnswer((invocation) async {
          final onProgress =
              invocation.namedArguments[#onProgress] as void Function(double)?;
          onProgress?.call(0.5);

          return const Right('/cache/support/message-7/quote.pdf');
        });

        return build();
      },
      act: (cubit) => cubit.fetch(pdf),
      expect: () => const [
        AttachmentFilesState(files: {7: AttachmentFile.downloading()}),
        AttachmentFilesState(files: {7: AttachmentFile.downloading(progress: 0.5)}),
        AttachmentFilesState(files: {7: AttachmentFile.local('/cache/support/message-7/quote.pdf')}),
      ],
    );

    blocTest<AttachmentFilesCubit, AttachmentFilesState>(
      'تنزيلٌ فشل يقول لماذا، ولمسةٌ تعيده',
      build: () {
        when(
          () => store.download(
            url: any(named: 'url'),
            key: any(named: 'key'),
            fileName: any(named: 'fileName'),
            onProgress: any(named: 'onProgress'),
            cancel: any(named: 'cancel'),
          ),
        ).thenAnswer((_) async => const Left(NetworkFailure(message: 'لا يوجد اتصال')));

        return build();
      },
      act: (cubit) => cubit.fetch(pdf),
      expect: () => const [
        AttachmentFilesState(files: {7: AttachmentFile.downloading()}),
        AttachmentFilesState(
          files: {7: AttachmentFile.failed(NetworkFailure(message: 'لا يوجد اتصال'))},
        ),
      ],
    );

    /// **الإلغاء ليس فشلاً**: من ألغى يعرف أنه ألغى، فيعود السهم بلا رسالة خطأ.
    blocTest<AttachmentFilesCubit, AttachmentFilesState>(
      'تنزيلٌ أُلغي يعود سهماً، لا خطأً',
      build: () {
        when(
          () => store.download(
            url: any(named: 'url'),
            key: any(named: 'key'),
            fileName: any(named: 'fileName'),
            onProgress: any(named: 'onProgress'),
            cancel: any(named: 'cancel'),
          ),
        ).thenAnswer((invocation) async {
          final cancel = invocation.namedArguments[#cancel] as TransferCancel;
          await cancel.whenCancelled;

          return const Left(UnexpectedFailure(message: 'أُلغي'));
        });

        return build();
      },
      act: (cubit) async {
        final fetching = cubit.fetch(pdf);
        await Future<void>.delayed(Duration.zero);
        cubit.cancel(7);
        await fetching;
      },
      expect: () => const [
        AttachmentFilesState(files: {7: AttachmentFile.downloading()}),
        AttachmentFilesState(files: {7: AttachmentFile.remote()}),
      ],
    );

    test('ملفٌّ على الهاتف يُرجع مساره بلا تنزيلٍ ثانٍ', () async {
      // Arrange
      when(
        () => store.localPath(key: any(named: 'key'), fileName: any(named: 'fileName')),
      ).thenAnswer((_) async => '/cache/support/message-7/quote.pdf');
      final cubit = build();
      await cubit.discover(const [pdf]);

      // Act
      final path = await cubit.fetch(pdf);

      // Assert
      expect(path, '/cache/support/message-7/quote.pdf');
      verifyNever(
        () => store.download(
          url: any(named: 'url'),
          key: any(named: 'key'),
          fileName: any(named: 'fileName'),
          onProgress: any(named: 'onProgress'),
          cancel: any(named: 'cancel'),
        ),
      );
      await cubit.close();
    });
  });
}
