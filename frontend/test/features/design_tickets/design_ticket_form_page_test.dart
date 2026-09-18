import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/presentation/views/design_ticket_form_page.dart';
import 'package:dayaa/features/design_tickets/repositories/design_ticket_repository.dart';
import 'package:dayaa/features/design_tickets/usecases/design_ticket_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keeps the designer the form named, and refuses so the page stays put.
class _RecordingRepository implements DesignTicketRepository {
  bool wasCalled = false;
  int? sentDesignerId;

  @override
  Future<Either<Failure, DesignTicket>> create({
    required int customerId,
    required String title,
    required String description,
    String? instructions,
    int? orderId,
    int? assignedDesignerId,
  }) async {
    wasCalled = true;
    sentDesignerId = assignedDesignerId;

    return const Left(Failure.server(message: 'البيانات غير صحيحة'));
  }

  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// «طلب تصميم» — and the one question it did not used to ask.
///
/// **The designer is named here or nowhere.** The form refused to carry the field on the
/// argument that routing is a separate grant; the effect was that every ticket went to the pool
/// and somebody had to open it again to hand it to anybody. The endpoint always accepted
/// `assigned_designer_id` on create — only the screen withheld it.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _RecordingRepository repository;
  late Session session;

  void signInWith(List<AppPermission> grants) => session.adopt(
    AuthUser(
      id: 1,
      name: 'عبدالوهاب',
      phone: '0911234567',
      permissions: [for (final grant in grants) grant.wire],
    ),
  );

  setUp(() {
    repository = _RecordingRepository();
    session = Session();
    sl.registerSingleton<Session>(session);
    sl.registerLazySingleton<CreateDesignTicket>(() => CreateDesignTicket(repository));
  });

  tearDown(() => sl.reset());

  const customer = Customer(
    id: 4,
    code: 'A713',
    name: 'اسامة حماد',
    phone: '0920712003',
    isActive: true,
  );

  Widget host() => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => const MaterialApp(
      locale: Locale('ar'),
      supportedLocales: [Locale('ar')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: DesignTicketFormPage(customer: customer),
      ),
    ),
  );

  testWidgets('somebody who may route work is asked who should draw it', (tester) async {
    // Arrange
    signInWith([AppPermission.manageDesignTickets, AppPermission.assignDesignTickets]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — and it opens on the pool, because «لا أعرف من الفارغ الآن» is the ordinary answer.
    expect(find.text('المصمم'), findsOneWidget);
    expect(find.text('بلا مصمم — تظهر لكل المصممين'), findsOneWidget);
  });

  testWidgets('somebody who may not route work is not shown the field', (tester) async {
    // Arrange — a clerk raises the request; handing it out is somebody else's grant, and a
    // picker they cannot use is a field that teaches them they are not allowed to touch it.
    signInWith([AppPermission.manageDesignTickets]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('المصمم'), findsNothing);
  });

  testWidgets('leaving it on the pool sends no designer at all', (tester) async {
    // Arrange
    signInWith([AppPermission.manageDesignTickets, AppPermission.assignDesignTickets]);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'تصميم شعار');
    await tester.enterText(find.byType(TextFormField).at(1), 'شعار في المنتصف');

    // Act
    await tester.tap(find.text('إرسال الطلب'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Assert — null is the instruction «اعرضها على الجميع», and the server reads it that way.
    expect(repository.wasCalled, isTrue);
    expect(repository.sentDesignerId, isNull);
  });

  testWidgets('the prose about attachments is gone', (tester) async {
    // Arrange
    signInWith([AppPermission.manageDesignTickets]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — a grey paragraph explaining the form to the person filling it in. The labels
    // carry the meaning; the server states the rules it enforces.
    expect(
      find.textContaining('المرفقات تُضاف بعد إنشاء التذكرة'),
      findsNothing,
    );
  });
}
