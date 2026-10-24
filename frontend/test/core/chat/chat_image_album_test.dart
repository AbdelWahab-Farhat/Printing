import 'package:dayaa/core/chat/chat_attachments.dart';
import 'package:dayaa/core/chat/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// ألبومُ الصور في الفقاعة — **شكلُ بريمولا**: صورتان جنباً إلى جنب، وثلاثٌ كبيرةٌ وصغيرتان،
/// وأربعٌ فأكثر شبكةٌ تحمل رابعتُها «+العدد» الباقي. والرسالةُ تُقرأ بعدد صورها.
///
/// Arrange - Act - Assert throughout.
void main() {
  List<ChatAttachment> photos(int count) => [
    for (var i = 1; i <= count; i++) ChatAttachment(id: i, kind: ChatAttachmentKind.image),
  ];

  Widget host(Widget child) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: Center(child: child)),
    ),
  );

  group('the message', () {
    test('lists its pictures in order and reads by their count', () {
      // Arrange
      final two = ChatMessage(id: 1, attachments: photos(2));
      final five = ChatMessage(id: 2, attachments: photos(5));
      final one = ChatMessage(id: 3, attachments: photos(1));

      // Act
      final ids = five.images.map((photo) => photo.id).toList();

      // Assert
      expect(ids, [1, 2, 3, 4, 5]);
      expect(one.preview, 'صورة');
      expect(two.preview, 'صورتان');
      expect(five.preview, '5 صور');
    });
  });

  group('the album', () {
    testWidgets('two pictures sit side by side', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(ChatImageAlbum(images: photos(2), cacheKeyOf: (photo) => 'k${photo.id}', onOpen: (_) {})),
      );

      // Act
      final tiles = find.bySemanticsLabel(RegExp(r'^صورة \d من 2$'));

      // Assert
      expect(tiles, findsNWidgets(2));
    });

    testWidgets('past four, the fourth carries the rest', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(ChatImageAlbum(images: photos(6), cacheKeyOf: (photo) => 'k${photo.id}', onOpen: (_) {})),
      );

      // Act
      final tiles = find.bySemanticsLabel(RegExp(r'^صورة \d من 6$'));

      // Assert
      expect(tiles, findsNWidgets(4));
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('a tap opens the album at that picture', (tester) async {
      // Arrange
      int? opened;
      await tester.pumpWidget(
        host(
          ChatImageAlbum(
            images: photos(3),
            cacheKeyOf: (photo) => 'k${photo.id}',
            onOpen: (index) => opened = index,
          ),
        ),
      );

      // Act
      await tester.tap(find.bySemanticsLabel('صورة 3 من 3'));

      // Assert
      expect(opened, 2);
    });
  });
}
