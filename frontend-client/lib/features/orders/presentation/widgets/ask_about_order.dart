import 'dart:async';

import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/presentation/widgets/ticket_compose_sheet.dart';
import 'package:dayaa_client/features/support/usecases/open_ticket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «اسأل عن الطلبية»: **ورقة التذكرة مباشرةً**، والطلبية مربوطةٌ بها — لا قائمة «الدعم» ثم
/// «تذكرة جديدة». بعد الإرسال تُفتح المحادثة فوق ما كان العميل فيه، فالرجوع منها يعود إليه،
/// وإغلاق الورقة بلا إرسال يُبقيه حيث كان.
///
/// **`OpenTicket` وحده، لا Cubit القائمة**: لا قائمة هنا تستقبل الصفّ الجديد، و«الدعم» حين
/// يُفتح يقرأ صفحته الأولى وهي فيها.
Future<void> askAboutOrder(BuildContext context, {required int id, required String code}) async {
  final ticket = await TicketComposeSheet.show(
    context,
    order: TicketOrderRef(id: id, code: code),
    submit: ({required subject, required body}) =>
        sl<OpenTicket>()(subject: subject, body: body, orderId: id),
  );

  if (ticket == null || !context.mounted) return;

  await context.push(Routes.ticket(ticket.id));
}

/// تحت «نواقص» و«مرفوضة»: جملة المرحلة، ثم «تواصل معنا» (طلب المستخدم، 2026-10-23).
///
/// **الجملة من الخادم** (`stage_hint`) كالشارة، والزرّ يفتح [askAboutOrder] على الطلبية نفسها —
/// على الرئيسية وفي الطلبية المفتوحة، فلا يُطلب من العميل أن يجد «الدعم» ليسأل عمّا رآه هنا.
class AttentionNote extends StatelessWidget {
  const AttentionNote({required this.id, required this.code, this.hint, this.color, super.key});

  final int id;
  final String code;
  final String? hint;

  /// لون الجملة: حبر المرحلة على بطاقتها الملوّنة، والرماديّ على بطاقة الرئيسية.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hint case final hint?) ...[
          Text(
            hint,
            style: context.textTheme.bodySmall?.copyWith(
              height: 1.5,
              color: color ?? context.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 10.h),
        ],
        AppButton.outlined(
          label: 'تواصل معنا',
          icon: AppIcons.comments,
          height: 44.h,
          onPressed: () => unawaited(askAboutOrder(context, id: id, code: code)),
        ),
      ],
    );
  }
}
