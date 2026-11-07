// أداةٌ لا اختبار: ترسم «أجر التصميم» وشاشاته إلى PNG لتُرى بلا هاتف. خارج `test/` فلا يجمعها
// `flutter test`. الأسماء والأرقام توضيحية.
//
//   FLUTTER_ROOT=… PREVIEW_OUT=/tmp/out flutter test --no-pub tool/preview/design_pay_preview.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart' show Either, Right;
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/theme/theme.dart';
import 'package:dayaa/features/access/presentation/viewmodel/employee_detail_cubit.dart';
import 'package:dayaa/features/access/presentation/views/employee_detail_page.dart';
import 'package:dayaa/features/access/repositories/access_repository.dart';
import 'package:dayaa/features/access/usecases/get_user.dart';
import 'package:dayaa/features/access/usecases/set_employee_service_price.dart';
import 'package:dayaa/features/access/usecases/set_user_activation.dart';
import 'package:dayaa/features/access/usecases/set_user_password.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_file.dart';
import 'package:dayaa/features/design_tickets/presentation/viewmodel/design_ticket_detail_cubit.dart';
import 'package:dayaa/features/design_tickets/presentation/views/design_ticket_detail_page.dart';
import 'package:dayaa/features/design_tickets/presentation/views/design_ticket_form_page.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/design_ticket_card.dart';
import 'package:dayaa/features/design_tickets/repositories/design_ticket_repository.dart';
import 'package:dayaa/features/design_tickets/usecases/design_ticket_usecases.dart';
import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:dayaa/features/employee_wallet/presentation/widgets/employee_wallet_entry_row.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _version = DesignTicketFile(
  id: 3,
  designTicketId: 1,
  kind: DesignTicketFileKind.submission,
  kindLabel: 'نسخة',
  label: 'النسخة 1',
  fileKind: DesignKind.image,
  fileKindLabel: 'صورة',
  status: DesignSubmissionStatus.proposed,
  isAwaitingReview: true,
  uploader: DesignTicketActor(id: 5, name: 'أحمد علي'),
);

DesignTicket _ticket({
  String? pay,
  String? suggested,
  bool canSetPay = false,
  bool canAccept = false,
  bool canReview = false,
  bool canManage = false,
  List<DesignTicketFile> versions = const [],
}) => DesignTicket(
  id: 1,
  code: 'D128',
  title: 'شعار مقهى الواحة',
  description: 'الشعار في المنتصف، وأسفله رقم الهاتف',
  status: DesignTicketStatus.inProgress,
  statusLabel: 'قيد التصميم',
  customerId: 4,
  customerName: 'مقهى الواحة',
  customerCode: 'A713',
  designer: const DesignTicketActor(id: 5, name: 'أحمد علي'),
  designerPay: pay,
  suggestedPay: suggested,
  canSetPay: canSetPay,
  canManage: canManage,
  canAccept: canAccept,
  canReview: canReview,
  versions: versions,
);

class _Tickets implements DesignTicketRepository {
  DesignTicket current = _ticket();

  @override
  Future<Either<Failure, DesignTicket>> ticket(int ticketId) async => Right(current);

  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Access implements AccessRepository {
  @override
  Future<Either<Failure, AuthUser>> user(int userId) async => const Right(
    AuthUser(
      id: 5,
      name: 'أحمد علي',
      phone: '0944909851',
      employeeCode: 'E5',
      salary: '1500.00',
      roles: [UserRole(name: 'designer', label: 'مصمم')],
      services: [
        EmployeeServicePrice(service: 'design', label: 'التصميم', suggestedPrice: '75.00'),
      ],
    ),
  );

  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<ByteData> _bytes(String path) =>
    File(path).readAsBytes().then((bytes) => ByteData.view(bytes.buffer));

Future<void> _loadFonts() async {
  final cairo = FontLoader('Cairo');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold', 'Black']) {
    cairo.addFont(_bytes('../frontend-client/assets/fonts/Cairo-$weight.ttf'));
  }
  await cairo.load();

  final config =
      jsonDecode(File('.dart_tool/package_config.json').readAsStringSync())
          as Map<String, dynamic>;
  final cupertinoRoot = (config['packages'] as List)
      .cast<Map<String, dynamic>>()
      .firstWhere((package) => package['name'] == 'cupertino_icons')['rootUri'] as String;
  await (FontLoader('packages/cupertino_icons/CupertinoIcons')
        ..addFont(_bytes('${Uri.parse(cupertinoRoot).toFilePath()}/assets/CupertinoIcons.ttf')))
      .load();

  if (Platform.environment['FLUTTER_ROOT'] case final flutterRoot?) {
    await (FontLoader('MaterialIcons')
          ..addFont(_bytes('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')))
        .load();
  }
}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final out = Platform.environment['PREVIEW_OUT'] ?? '.';

  setUpAll(_loadFonts);

  testWidgets('draw the pay', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    debugDisableShadows = false;

    try {
      final tickets = _Tickets();
      final access = _Access();
      final session = Session();

      void signIn(List<String> permissions) => session.adopt(
        AuthUser(id: 9, name: 'هدى', phone: '0911234567', permissions: permissions),
      );

      sl
        ..registerSingleton<Session>(session)
        ..registerLazySingleton<CreateDesignTicket>(() => CreateDesignTicket(tickets))
        ..registerFactoryParam<DesignTicketDetailCubit, int, void>(
          (ticketId, _) => DesignTicketDetailCubit(
            ticketId: ticketId,
            getTicket: GetDesignTicket(tickets),
            acceptTicket: AcceptDesignTicket(tickets),
            assignTicket: AssignDesignTicket(tickets),
            updateTicket: UpdateDesignTicket(tickets),
            cancelTicket: CancelDesignTicket(tickets),
            attachFile: AttachDesignTicketFile(tickets),
            removeAttachment: RemoveDesignTicketAttachment(tickets),
            submitVersion: SubmitDesignVersion(tickets),
            reviewVersion: ReviewDesignVersion(tickets),
            withdrawVersion: WithdrawDesignVersion(tickets),
            setPay: SetDesignTicketPay(tickets),
          ),
        )
        ..registerFactoryParam<EmployeeDetailCubit, int, void>(
          (userId, _) => EmployeeDetailCubit(
            userId: userId,
            getUser: GetUser(access),
            setPassword: SetUserPassword(access),
            setServicePrice: SetEmployeeServicePrice(access),
            setActivation: SetUserActivation(access),
          ),
        );

      final theme = MaterialTheme(Typography.material2021().black.apply(fontFamily: 'Cairo'));

      tester.view
        ..physicalSize = const Size(440 * 3, 956 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      Future<GlobalKey> draw(Widget page, {bool dark = false}) async {
        await tester.pumpWidget(const SizedBox());

        final key = GlobalKey();
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
                home: Directionality(textDirection: TextDirection.rtl, child: page),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        return key;
      }

      Future<void> shoot(GlobalKey key, String name) async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 3);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('$out/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
        });
      }

      Future<void> tapText(String label) async {
        await tester.ensureVisible(find.text(label).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text(label).first);
        await tester.pumpAndSettle();
      }

      const ticketPage = DesignTicketDetailPage(ticketId: 1);

      signIn(['design_tickets.view']);
      tickets.current = _ticket(pay: '75.00', canSetPay: true);
      var key = await draw(ticketPage);
      await shoot(key, 'dp-1-ticket');

      await tester.tap(find.byTooltip('تعديل أجر التصميم'));
      await tester.pumpAndSettle();
      await shoot(key, 'dp-2-pay-sheet');

      tickets.current = _ticket(pay: '100.00', canManage: true, canSetPay: true);
      key = await draw(ticketPage, dark: true);
      await tester.tap(find.byTooltip('تعديل الطلب'));
      await tester.pumpAndSettle();
      await shoot(key, 'dp-2b-edit-sheet');

      DesignTicket row(
        String title,
        String code, {
        String? pay,
        DesignTicketStatus status = DesignTicketStatus.fresh,
        String label = 'جديد',
        bool canAccept = false,
        int versions = 0,
      }) => _ticket(pay: pay, canAccept: canAccept).copyWith(
        title: title,
        code: code,
        status: status,
        statusLabel: label,
        versionsCount: versions,
      );

      key = await draw(
        Scaffold(
          appBar: AppBar(title: const Text('التذاكر')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final ticket in [
                row('if fhhh', 'D5', pay: '100.00'),
                row('Edward awe', 'D4'),
                row(
                  'شعار مقهى الواحة',
                  'D3',
                  pay: '1500.00',
                  status: DesignTicketStatus.inProgress,
                  label: 'قيد التصميم',
                  versions: 2,
                ),
                row('fairly', 'D2', pay: '75.00', canAccept: true),
                row(
                  'كيس شحن',
                  'D1',
                  pay: '60.00',
                  status: DesignTicketStatus.completed,
                  label: 'مكتمل',
                ),
                row(
                  'كيس هدايا',
                  'D0',
                  pay: '40.00',
                  status: DesignTicketStatus.cancelled,
                  label: 'ملغاة',
                ),
              ]) ...[
                DesignTicketCard(ticket: ticket, onTap: () {}, onAccept: () {}),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        dark: true,
      );
      await shoot(key, 'dp-0-list');

      tickets.current = _ticket(pay: '75.00', canReview: true, versions: const [_version]);
      key = await draw(ticketPage);
      await tapText('مراجعة التصميم');
      await tapText('اعتماد التصميم');
      await shoot(key, 'dp-3-approve');

      tickets.current = _ticket(suggested: '75.00', canAccept: true);
      key = await draw(ticketPage);
      await tapText('قبول الطلب');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await shoot(key, 'dp-4-accept');

      signIn(['design_tickets.manage', 'design_tickets.assign']);
      key = await draw(
        const DesignTicketFormPage(
          customer: Customer(
            id: 4,
            code: 'A713',
            name: 'مقهى الواحة',
            phone: '0920712003',
            isActive: true,
          ),
        ),
      );
      await shoot(key, 'dp-5-form');

      signIn(['users.view', 'users.salary']);
      key = await draw(const EmployeeDetailPage(userId: 5));
      await shoot(key, 'dp-6-employee');

      key = await draw(
        Scaffold(
          appBar: AppBar(title: const Text('محفظتي')),
          body: ListView(
            children: [
              EmployeeWalletEntryRow(
                entry: EmployeeWalletEntry.fromJson(const {
                  'id': 1,
                  'type': 'credit',
                  'type_label': 'أجر التصميم',
                  'direction': 'in',
                  'amount': '75.00',
                  'category_name': 'أجر التصميم',
                  'notes': 'أجر تصميم D128',
                  'occurred_at': '2026-11-07T10:30:00+02:00',
                }),
              ),
              EmployeeWalletEntryRow(
                entry: EmployeeWalletEntry.fromJson(const {
                  'id': 2,
                  'type': 'credit',
                  'type_label': 'مستحق',
                  'direction': 'in',
                  'amount': '1500.00',
                  'category_name': 'رواتب',
                  'occurred_at': '2026-11-01T10:30:00+02:00',
                }),
              ),
            ],
          ),
        ),
      );
      await shoot(key, 'dp-7-wallet');
    } finally {
      debugDefaultTargetPlatformOverride = null;
      debugDisableShadows = true;
    }
  });
}
