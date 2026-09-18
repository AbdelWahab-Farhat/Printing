import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_file.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/design_version_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// One version, and the reviewer's words on it.
///
/// **The note is headed by the verdict it came with.** The box was red and headed «المطلوب
/// تعديله» on any note at all, so a version the reviewer had approved with a word of praise
/// was drawn as a rejection — a green «معتمد» pill a centimetre above a red heading saying the
/// opposite.
///
/// Arrange - Act - Assert throughout.
void main() {
  DesignTicketFile version({
    required DesignSubmissionStatus status,
    required String note,
  }) => DesignTicketFile(
    id: 3,
    designTicketId: 1,
    kind: DesignTicketFileKind.submission,
    kindLabel: 'نسخة',
    label: 'النسخة 1',
    fileKind: DesignKind.image,
    fileKindLabel: 'صورة',
    status: status,
    statusLabel: status == DesignSubmissionStatus.approved ? 'معتمد' : 'تعديل مطلوب',
    reviewNote: note,
  );

  Widget host(DesignTicketFile file) => ScreenUtilInit(
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
        child: Scaffold(body: DesignVersionTile(version: file, onTap: () {})),
      ),
    ),
  );

  testWidgets('an approved version does not read as a rejection', (tester) async {
    // Arrange
    final file = version(
      status: DesignSubmissionStatus.approved,
      note: 'منظمة واطلع طول',
    );

    // Act
    await tester.pumpWidget(host(file));
    await tester.pumpAndSettle();

    // Assert — the words are kept, the heading that contradicts the verdict is not.
    expect(find.text('منظمة واطلع طول'), findsOneWidget);
    expect(find.text('المطلوب تعديله'), findsNothing);
    expect(find.text('ملاحظة المُراجِع'), findsOneWidget);
  });

  testWidgets('a rejected version still says what has to change', (tester) async {
    // Arrange
    final file = version(
      status: DesignSubmissionStatus.changesRequested,
      note: 'كبّر الشعار',
    );

    // Act
    await tester.pumpWidget(host(file));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('المطلوب تعديله'), findsOneWidget);
    expect(find.text('كبّر الشعار'), findsOneWidget);
  });
}
