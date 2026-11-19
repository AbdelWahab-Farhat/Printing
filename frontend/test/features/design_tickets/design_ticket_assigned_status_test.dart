import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_thread.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/design_ticket_status_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «مُسنَد»: addressed to a designer who has not accepted yet.
///
/// Arrange - Act - Assert throughout.
void main() {
  test('the server word "assigned" is read as the assigned status', () {
    // Arrange
    final json = {
      'ticket': {
        'id': 3,
        'code': 'D3',
        'title': 'كيس شحن أسود',
        'status': 'assigned',
        'status_label': 'مُسنَد',
        'is_open': true,
      },
      'messages': <Map<String, dynamic>>[],
    };

    // Act
    final thread = DesignTicketThread.fromJson(json);

    // Assert
    expect(thread.ticket.status, DesignTicketStatus.assigned);
    expect(thread.ticket.status.label, 'مُسنَد');
  });

  test('the status filter offers it between new and in progress', () {
    // Act
    final offered = DesignTicketStatus.offered;

    // Assert
    expect(offered.indexOf(DesignTicketStatus.assigned), 1);
    expect(offered.first, DesignTicketStatus.fresh);
    expect(offered[2], DesignTicketStatus.inProgress);
  });

  testWidgets('its pill is coloured apart from new and in progress', (tester) async {
    // Arrange
    Color? background(DesignTicketStatus status) {
      final box = tester.widget<Container>(
        find.descendant(
          of: find.byKey(ValueKey(status)),
          matching: find.byType(Container),
        ),
      );
      return (box.decoration! as BoxDecoration).color;
    }

    // Act
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                for (final status in [
                  DesignTicketStatus.fresh,
                  DesignTicketStatus.assigned,
                  DesignTicketStatus.inProgress,
                ])
                  DesignTicketStatusPill(key: ValueKey(status), status: status, label: status.label),
              ],
            ),
          ),
        ),
      ),
    );

    // Assert
    expect(find.text('مُسنَد'), findsOneWidget);
    expect(background(DesignTicketStatus.assigned), isNot(background(DesignTicketStatus.fresh)));
    expect(
      background(DesignTicketStatus.assigned),
      isNot(background(DesignTicketStatus.inProgress)),
    );
  });
}
