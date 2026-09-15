import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Where a ticket stands, in one or two words.
///
/// **The words are the server's** — `status_label`, never this app's copy — so a status renamed
/// on the backend is renamed on the card without a release. The colour is the app's, chosen from
/// [DesignTicketStatus] so a status this build has never heard of still draws, in the neutral
/// tone, wearing the name it arrived with. The `ShortageStatusPill` shape.
class DesignTicketStatusPill extends StatelessWidget {
  const DesignTicketStatusPill({required this.status, required this.label, super.key});

  final DesignTicketStatus status;

  /// The server's own wording.
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final (background, foreground) = switch (status) {
      // Nobody has picked it up yet.
      DesignTicketStatus.fresh => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      // Work in hand — the same family as «جاري البحث» on a shortage.
      DesignTicketStatus.inProgress => (scheme.primaryContainer, scheme.onPrimaryContainer),
      // Waiting on a person rather than on work: the tertiary family, which this app uses for
      // «somebody has to decide».
      DesignTicketStatus.underReview => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      // The one that genuinely needs somebody — work has come back.
      DesignTicketStatus.changesRequested => (scheme.errorContainer, scheme.onErrorContainer),
      // Green, like every «انتهى هذا» in this app.
      DesignTicketStatus.completed => (scheme.paid, scheme.onPrimary),
      // Deliberately neutral rather than red: a cancellation is not a failure of anybody's work.
      DesignTicketStatus.cancelled => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      DesignTicketStatus.unknown => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        label,
        style: context.textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
