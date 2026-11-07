import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:dayaa/features/employee_wallet/presentation/widgets/employee_wallet_entry_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// سطر المحفظة: «أجر التصميم» عنوانُه، ولا يتكرر تحته.
///
/// Arrange - Act - Assert في كل اختبار.
void main() {
  Widget host(EmployeeWalletEntry entry) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: EmployeeWalletEntryRow(entry: entry)),
      ),
    ),
  );

  EmployeeWalletEntry entry({required String label, String? category}) => EmployeeWalletEntry.fromJson({
    'id': 1,
    'type': 'credit',
    'type_label': label,
    'direction': 'in',
    'amount': '50.00',
    'category_name': category,
    'notes': 'أجر تصميم D12',
  });

  testWidgets('design pay reads once, as the title', (tester) async {
    // Arrange
    final row = entry(label: 'أجر التصميم', category: 'أجر التصميم');

    // Act
    await tester.pumpWidget(host(row));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('أجر التصميم'), findsOneWidget);
    expect(find.text('أجر تصميم D12'), findsOneWidget);
  });

  testWidgets('any other credit keeps its category under the title', (tester) async {
    // Arrange
    final row = entry(label: 'مستحق', category: 'رواتب');

    // Act
    await tester.pumpWidget(host(row));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('مستحق'), findsOneWidget);
    expect(find.textContaining('رواتب'), findsOneWidget);
  });
}
