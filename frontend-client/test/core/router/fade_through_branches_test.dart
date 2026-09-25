import 'package:dayaa_client/core/router/fade_through_branches.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// الانتقال بين أقسام الشريط السفلي: القديم يتلاشى أولاً، ثم يظهر الجديد.
///
/// **الحاوية تحلّ محلّ `IndexedStack` الذي يبنيه `StatefulShellRoute.indexedStack`**، فكل ما كان
/// يضمنه يجب أن يبقى مضموناً هنا: القسم يحتفظ بحالته، والقسم المخفي لا يستقبل لمساً ولا تركيزاً
/// ولا يقرؤه قارئ الشاشة ولا تعمل حركاته. الجديد هو الحركة وحدها.
///
/// Arrange - Act - Assert throughout.
void main() {
  const sections = ['الرئيسية', 'المنتجات', 'طلباتي'];

  /// الأقسام الثلاثة داخل الحاوية، والقسم [index] هو المعروض.
  ///
  /// [focus] يُعطى لحقل داخل «المنتجات»، لاختبار التركيز.
  Widget host(int index, {bool reducedMotion = false, FocusNode? focus}) {
    return MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
          child: FadeThroughBranches(
            currentIndex: index,
            children: [
              for (final section in sections)
                _Section(label: section, focus: section == 'المنتجات' ? focus : null),
            ],
          ),
        ),
      ),
    );
  }

  /// شفافية القسم [index] الآن: القيمة في هذه اللحظة من الحركة، لا القيمة التي تتجه إليها.
  double opacityOf(WidgetTester tester, int index) {
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(of: find.byType(_Section).at(index), matching: find.byType(FadeTransition))
          .first,
    );

    return fade.opacity.value;
  }

  group('switching', () {
    testWidgets('only the current section shows', (tester) async {
      // Arrange
      const current = 1;

      // Act
      await tester.pumpWidget(host(current));

      // Assert
      expect(opacityOf(tester, 0), 0);
      expect(opacityOf(tester, 1), 1);
      expect(opacityOf(tester, 2), 0);
    });

    testWidgets('the old section leaves before the new one arrives', (tester) async {
      // Arrange
      await tester.pumpWidget(host(0));

      // Act — ٤٥ms من ٣٠٠: القديم في منتصف خروجه.
      await tester.pumpWidget(host(1));
      await tester.pump(const Duration(milliseconds: 45));

      // Assert — والجديد لم يبدأ بعد، فلا تتراكب صفحتان في لحظة واحدة.
      expect(opacityOf(tester, 0), inExclusiveRange(0, 1));
      expect(opacityOf(tester, 1), 0);

      // Act — منتصف المدة.
      await tester.pump(const Duration(milliseconds: 105));

      // Assert — خرج القديم كله، والجديد في منتصف دخوله.
      expect(opacityOf(tester, 0), 0);
      expect(opacityOf(tester, 1), inExclusiveRange(0, 1));

      // Act — نهاية المدة.
      await tester.pump(const Duration(milliseconds: 150));

      // Assert
      expect(opacityOf(tester, 0), 0);
      expect(opacityOf(tester, 1), 1);
    });

    testWidgets('a section keeps its state across a switch', (tester) async {
      // Arrange — ثلاث نقرات على «المنتجات» قبل مغادرته.
      await tester.pumpWidget(host(1));
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byType(_Section).at(1));
        await tester.pump();
      }

      // Act — إلى «طلباتي» ثم العودة.
      await tester.pumpWidget(host(2));
      await tester.pumpAndSettle();
      await tester.pumpWidget(host(1));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('المنتجات 3'), findsOneWidget);
    });

    testWidgets('a tap reaches the current section, not a hidden one above it', (tester) async {
      // Arrange — «الرئيسية» أول الأقسام، فهي أسفل الكومة وكل الأقسام المخفية فوقها بحجمها.
      await tester.pumpWidget(host(0));

      // Act
      await tester.tap(find.byType(_Section).at(0));
      await tester.pump();

      // Assert
      expect(find.text('الرئيسية 1'), findsOneWidget);
      expect(find.text('المنتجات 0'), findsOneWidget);
      expect(find.text('طلباتي 0'), findsOneWidget);
    });
  });

  group('a hidden section', () {
    testWidgets('has its animations paused', (tester) async {
      // Arrange
      await tester.pumpWidget(host(0));

      // Act
      await tester.pumpWidget(host(1));
      await tester.pumpAndSettle();

      // Assert
      bool tickersOf(int index) =>
          TickerMode.valuesOf(tester.element(find.byType(_Section).at(index))).enabled;

      expect(tickersOf(0), isFalse);
      expect(tickersOf(1), isTrue);
    });

    testWidgets('cannot keep the focus', (tester) async {
      // Arrange — كمن يكتب في بحث «المنتجات» ثم ينتقل إلى قسم آخر.
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(host(1, focus: focus));
      focus.requestFocus();
      await tester.pump();
      expect(focus.hasFocus, isTrue);

      // Act
      await tester.pumpWidget(host(0, focus: focus));
      await tester.pumpAndSettle();

      // Assert — كما مع IndexedStack: مغادرة القسم تُسقط التركيز، فتُغلق لوحة المفاتيح.
      expect(focus.hasFocus, isFalse);
    });

    testWidgets('is not read out by a screen reader', (tester) async {
      // Arrange
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(0));

      // Act
      await tester.pumpWidget(host(1));
      await tester.pumpAndSettle();

      // Assert — من شجرة الـ semantics نفسها، لا `find.bySemanticsLabel`: هذا يقرأ آخر ما سجّله
      // كل عنصر، فيجد القسم المخفي بما سجّله قبل أن يُخفى.
      expect(find.semantics.byLabel('المنتجات 0'), findsOne);
      expect(find.semantics.byLabel('الرئيسية 0'), findsNothing);

      // داخل الاختبار لا في `addTearDown`: الإطار يتحقّق من إغلاقه قبل أن تعمل الـ tearDowns.
      semantics.dispose();
    });
  });

  group('reduced motion', () {
    testWidgets('the switch lands in one frame, and nothing keeps running', (tester) async {
      // Arrange
      await tester.pumpWidget(host(0, reducedMotion: true));

      // Act
      await tester.pumpWidget(host(1, reducedMotion: true));

      // Assert — الحركة غائبة، لا سريعة: القيم النهائية في الإطار نفسه، ولا Ticker يعمل. لا
      // `hasScheduledFrame`: نقل التركيز من القسم المخفي يطلب إطاراً واحداً، كما مع IndexedStack.
      expect(opacityOf(tester, 0), 0);
      expect(opacityOf(tester, 1), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}

/// قسم يعدّ النقرات عليه: حالة يجب أن تبقى بعد الانتقال إلى قسم آخر والعودة.
///
/// يملأ المساحة كلها ويلتقط اللمس في أي نقطة منها، كما تفعل `Scaffold` في الأقسام الحقيقية.
class _Section extends StatefulWidget {
  const _Section({required this.label, this.focus});

  final String label;

  final FocusNode? focus;

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  var _taps = 0;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focus,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _taps++),
        child: Center(child: Text('${widget.label} $_taps')),
      ),
    );
  }
}
