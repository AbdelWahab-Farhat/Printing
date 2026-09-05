import 'package:dayaa/core/widgets/register_card.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_card.dart';
import 'package:dayaa/features/vendors/models/vendor.dart';
import 'package:dayaa/features/vendors/presentation/widgets/vendor_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one card the three registers share, and the two rows built on it.
///
/// The customers' own row is covered in `customer_card_test.dart`; what is proved here is that
/// the other two are the *same card* — because three lists a swipe apart drawn three ways is the
/// thing this widget exists to prevent.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// The same frame the app boots into: ScreenUtil at the reference size, Arabic, RTL.
  Widget host(Widget card) => ScreenUtilInit(
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
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(child: card),
        ),
      ),
    ),
  );

  Vendor vendorWith({String? contactPerson = 'محمد علي', bool isActive = true}) => Vendor(
    id: 12,
    name: 'مصنع الرواد',
    phone: '0913334444',
    contactPerson: contactPerson,
    isActive: isActive,
  );

  Investor investorWith({
    bool hasLogin = false,
    bool isActive = true,
    String? phone,
    InvestorTotals? totals,
  }) => Investor(
    id: 7,
    code: 'I7',
    name: 'عبدالرحمن بادي',
    phone: phone,
    isActive: isActive,
    hasLogin: hasLogin,
    totals: totals,
  );

  testWidgets('a supplier is drawn on the register card, not a row of its own', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(host(VendorCard(vendor: vendorWith())));

    // Assert
    expect(find.byType(RegisterCard), findsOneWidget);
    expect(find.text('مصنع الرواد'), findsOneWidget);
    expect(find.text('V12'), findsOneWidget);
    expect(find.text('#'), findsOneWidget);
  });

  testWidgets('a supplier says who we talk to, under its own heading', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(host(VendorCard(vendor: vendorWith())));

    // Assert — a heading over its value, never a glyph beside it.
    expect(find.text('رقم الهاتف'), findsOneWidget);
    expect(find.text('0913334444'), findsOneWidget);
    expect(find.text('المسؤول'), findsOneWidget);
    expect(find.text('محمد علي'), findsOneWidget);
  });

  testWidgets('a supplier with nobody named keeps the column and says so', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(host(VendorCard(vendor: vendorWith(contactPerson: null))));

    // Assert — the column holds its place: a slot that disappears teaches the eye to skip it.
    expect(find.text('المسؤول'), findsOneWidget);
    expect(find.text('–'), findsOneWidget);
  });

  testWidgets('a retired supplier is marked rather than hidden', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(host(VendorCard(vendor: vendorWith(isActive: false))));

    // Assert
    expect(find.text('متوقف'), findsOneWidget);
  });

  testWidgets('an investor is the same card again', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(
      host(InvestorCard(investor: investorWith(phone: '0944909852'), onTap: () {})),
    );

    // Assert
    expect(find.byType(RegisterCard), findsOneWidget);
    expect(find.text('عبدالرحمن بادي'), findsOneWidget);
    expect(find.text('I7'), findsOneWidget);
    expect(find.text('0944909852'), findsOneWidget);
  });

  testWidgets('an investor says what he has with us and what he has earned', (tester) async {
    // Arrange — the whole page's figures arrive with the list, so the row can carry them.
    await tester.pumpWidget(
      host(
        InvestorCard(
          investor: investorWith(
            totals: const InvestorTotals(
              capital: '50000.00',
              profit: '1250.50',
              walletCapital: '20000.00',
              walletProfit: '0.00',
            ),
          ),
          onTap: () {},
        ),
      ),
    );

    // Assert
    expect(find.text('رأس المال'), findsOneWidget);
    expect(find.text('50,000 د.ل'), findsOneWidget);
    expect(find.text('الأرباح'), findsOneWidget);
    expect(find.text('1,250.5 د.ل'), findsOneWidget);
  });

  testWidgets('a row that came back without figures draws a dash, never a zero', (tester) async {
    // Arrange — «لا شيء عنده» and «لم تُرسل أرقامه» are different sentences, and only one of
    // them is true.
    await tester.pumpWidget(host(InvestorCard(investor: investorWith(), onTap: () {})));

    // Assert
    expect(find.textContaining('د.ل'), findsNothing);
    expect(find.text('–'), findsNWidgets(3));
  });

  testWidgets('a tap reaches the caller', (tester) async {
    // Arrange
    var tapped = false;
    await tester.pumpWidget(
      host(InvestorCard(investor: investorWith(), onTap: () => tapped = true)),
    );

    // Act
    await tester.tap(find.byType(RegisterCard));

    // Assert
    expect(tapped, isTrue);
  });
}
