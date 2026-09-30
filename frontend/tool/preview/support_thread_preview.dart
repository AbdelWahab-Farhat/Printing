// A harness, not a test: it draws one support thread to PNGs so it can be set beside Primula's
// chat without the phone. Named outside `test/` so `flutter test` never collects it.
//
//   FLUTTER_ROOT=… PREVIEW_OUT=/tmp flutter test tool/preview/support_thread_preview.dart
//
// The bundled Almarai is registered under the family the theme asks for, and Material's icon
// font is loaded from the Flutter SDK (FLUTTER_ROOT) so glyphs draw instead of empty squares.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/theme/theme.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/models/ticket_change.dart';
import 'package:dayaa/features/support/presentation/viewmodel/ticket_thread_cubit.dart';
import 'package:dayaa/features/support/presentation/views/ticket_thread_page.dart';
import 'package:dayaa/features/support/repositories/support_repository.dart';
import 'package:dayaa/features/support/usecases/support_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.now();
DateTime _ago(int minutes) => _now.subtract(Duration(minutes: minutes));

final _ticket = SupportTicket(
  id: 12,
  subject: 'مرحبا كيف الحال',
  status: TicketStatus.inProgress,
  statusLabel: 'قيد المعالجة',
  customer: const TicketCustomer(id: 4, code: 'A727', name: 'Flyrex', phone: '0910000000'),
  order: const TicketOrderRef(id: 77, code: '1077'),
  customerReadUpTo: 5,
  messages: [
    TicketMessage(id: 1, from: MessageAuthor.customer, body: 'السلام عليكم', sentAt: _ago(60 * 26)),
    TicketMessage(
      id: 2,
      from: MessageAuthor.customer,
      body: 'متى تصل طلبيتي؟ مرّ أسبوع على الدفع',
      sentAt: _ago(60 * 26 - 1),
    ),
    TicketMessage(
      id: 3,
      from: MessageAuthor.customer,
      sentAt: _ago(60 * 26 - 2),
      attachment: const TicketAttachment(
        kind: AttachmentKind.pdf,
        kindLabel: 'PDF',
        name: 'receipt-0934.pdf',
        sizeBytes: 3355443,
        url: 'https://example.test/signed',
      ),
    ),
    TicketMessage(
      id: 4,
      from: MessageAuthor.staff,
      authorName: 'فرحات',
      body: 'وعليكم السلام، نعتذر عن التأخير',
      sentAt: _ago(40),
    ),
    TicketMessage(
      id: 5,
      from: MessageAuthor.staff,
      authorName: 'فرحات',
      body: 'خرجت طلبيتك اليوم مع المندوب',
      sentAt: _ago(39),
    ),
    TicketMessage(id: 6, from: MessageAuthor.customer, body: 'OK, thanks!', sentAt: _ago(20)),
    TicketMessage(
      id: 7,
      from: MessageAuthor.staff,
      authorName: 'محمد',
      body: 'تحت أمرك 🌷',
      sentAt: _ago(2),
    ),
  ],
);

class _StubRepository implements SupportRepository {
  @override
  Stream<TicketChange> watchChanges() => const Stream.empty();

  @override
  Stream<void> get liveResumed => const Stream.empty();

  @override
  Future<Either<Failure, SupportTicket>> ticket(int id) async => Right(_ticket);

  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final cairo = FontLoader('Cairo');
    for (final file in ['Almarai-Regular.ttf', 'Almarai-Bold.ttf']) {
      cairo.addFont(
        File('assets/fonts/$file').readAsBytes().then((bytes) => ByteData.view(bytes.buffer)),
      );
    }
    await cairo.load();

    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot != null) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
              .readAsBytes()
              .then((bytes) => ByteData.view(bytes.buffer)),
        );
      await icons.load();
    }
  });

  for (final dark in [true, false]) {
    testWidgets('draw the thread (${dark ? 'dark' : 'light'})', (tester) async {
      await Injector.reset();
      final repository = _StubRepository();
      sl
        ..registerSingleton<Session>(
          Session()
            ..adopt(
              const AuthUser(
                id: 1,
                name: 'عبدالوهاب',
                phone: '0911234567',
                permissions: ['support.view', 'support.manage', 'customers.view'],
              ),
            ),
        )
        ..registerFactoryParam<TicketThreadCubit, int, void>(
          (ticketId, _) => TicketThreadCubit(
            ticketId: ticketId,
            get: GetTicket(repository),
            reply: ReplyToTicket(repository),
            assign: AssignTicket(repository),
            close: CloseTicket(repository),
            reopen: ReopenTicket(repository),
            watch: WatchTicketChanges(repository),
          ),
        );

      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final key = GlobalKey();
      final text = dark ? Typography.material2021().white : Typography.material2021().black;
      final theme = MaterialTheme(text.apply(fontFamily: 'Cairo'));

      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: ScreenUtilInit(
            designSize: const Size(430, 932),
            builder: (context, _) => MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: dark ? theme.dark() : theme.light(),
              locale: const Locale('ar'),
              supportedLocales: const [Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const TicketThreadPage(ticketId: 12),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> shoot(String name) async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('${Platform.environment['PREVIEW_OUT'] ?? '.'}/$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
        });
      }

      final mode = dark ? 'dark' : 'light';
      await shoot('thread-$mode');

      // الضغطةُ المطوّلة: الرسالةُ فوق محادثةٍ مضبّبة، وبجانبها ما يُفعل بها.
      await tester.longPress(find.textContaining('خرجت طلبيتك'));
      await tester.pumpAndSettle();
      await shoot('thread-$mode-long-press');
      await tester.tapAt(const Offset(20, 200));
      await tester.pumpAndSettle();

      // «⋮».
      await tester.tap(find.byTooltip('إجراءات التذكرة'));
      await tester.pumpAndSettle();
      await shoot('thread-$mode-menu');
    });
  }
}
