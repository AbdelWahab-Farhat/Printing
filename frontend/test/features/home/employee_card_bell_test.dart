import 'package:dartz/dartz.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/home/presentation/widgets/employee_card.dart';
import 'package:dayaa/features/notifications/models/unread_count.dart';
import 'package:dayaa/features/notifications/presentation/viewmodel/unread_badge_cubit.dart';
import 'package:dayaa/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:dayaa/features/notifications/usecases/get_unread_count.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetUnreadCount extends Mock implements GetUnreadCount {}

/// **الجرسُ على بطاقة الموظف بجانب الدور** لا في الشريط — طلبُ المالك ٢٠٢٦-١٠-٢٣، وكبطاقة بريمولا:
/// دائرةٌ زجاجية بحبر البطاقة، ومعها عددُ غير المقروء.
///
/// Arrange - Act - Assert throughout.
void main() {
  const user = AuthUser(
    id: 7,
    name: 'فرحات',
    phone: '0911234567',
    employeeCode: '1013',
    roles: [UserRole(name: 'admin', label: 'مدير')],
  );

  Widget host(UnreadBadgeCubit cubit) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: BlocProvider<UnreadBadgeCubit>.value(
          value: cubit,
          child: const EmployeeCard(user: user, action: NotificationBell(onCard: true)),
        ),
      ),
    ),
  );

  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(view.reset);
  });

  testWidgets('the bell sits on the card beside the role, with what is unread', (tester) async {
    // Arrange
    final getUnreadCount = _MockGetUnreadCount();
    when(getUnreadCount.call).thenAnswer((_) async => const Right(UnreadCount(count: 3)));
    final cubit = UnreadBadgeCubit(getUnreadCount);
    addTearDown(cubit.close);

    // Act
    await tester.pumpWidget(host(cubit));
    await tester.pumpAndSettle();

    // Assert
    final bell = find.descendant(
      of: find.byType(EmployeeCard),
      matching: find.byTooltip('الإشعارات'),
    );
    expect(bell, findsOneWidget);
    expect(find.descendant(of: bell, matching: find.text('3')), findsOneWidget);
    // يسارَ «مدير» في البطاقة العربية — في آخر السطر.
    expect(tester.getCenter(bell).dx, lessThan(tester.getCenter(find.text('مدير')).dx));
  });
}
