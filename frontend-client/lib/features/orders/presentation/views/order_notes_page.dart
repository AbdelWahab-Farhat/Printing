import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/dates.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/features/orders/models/order_note.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/order_notes_cubit.dart';
import 'package:dayaa_client/features/orders/presentation/views/stage_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «الملاحظات» على طلبيةٍ واحدة، على شكل شاشة ملاحظات الطلبية في تطبيق الموظفين (طلب
/// المستخدم، 2026-09-25): بطاقةٌ لكل ملاحظة، أعلاها المرحلة التي كُتبت عندها، ثم ما كُتب، ثم
/// متى. من الأقدم، كقصةٍ تُروى بترتيبها.
///
/// **بلا اسمٍ لمن كتب**، كرسائل الدعم: من يكتب للعميل هو المتجر. **ولا جملة تشرح** من أين تأتي
/// الملاحظات أو لماذا لا يرى غيرها — «مفيش داعي توضحله».
///
/// [onRead] تُخبر الطلبية خلفها أن الملاحظات قُرئت، فتنطفئ شارتها بلا طلب: الخادم علّمها مقروءةً
/// حين أرسلها. لا تُنادى إن فشل التحميل، فما لم يُعرض لم يُقرأ.
class OrderNotesPage extends StatelessWidget {
  const OrderNotesPage({required this.orderId, this.onRead, super.key});

  final int orderId;

  /// فارغةٌ حين تُفتح الشاشة من رابطٍ لا من الطلبية: لا شارة خلفها تُطفأ.
  final VoidCallback? onRead;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderNotesCubit>(
      create: (_) => sl<OrderNotesCubit>(param1: orderId)..load(),
      child: BlocListener<OrderNotesCubit, OrderNotesState>(
        listenWhen: (previous, current) => current is OrderNotesLoaded,
        listener: (context, state) => onRead?.call(),
        child: const _NotesView(),
      ),
    );
  }
}

class _NotesView extends StatelessWidget {
  const _NotesView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrderNotesCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('الملاحظات')),
      body: BlocBuilder<OrderNotesCubit, OrderNotesState>(
        builder: (context, state) => switch (state) {
          OrderNotesLoading() => const Center(child: CircularProgressIndicator()),
          OrderNotesFailure(:final failure) => _Failure(failure: failure, onRetry: cubit.load),
          OrderNotesLoaded(:final notes) when notes.isEmpty => const _Nothing(),
          OrderNotesLoaded(:final notes) => ListView.separated(
            padding: EdgeInsets.fromLTRB(
              16.w,
              12.h,
              16.w,
              24.h + MediaQuery.paddingOf(context).bottom,
            ),
            itemCount: notes.length,
            separatorBuilder: (_, _) => SizedBox(height: 12.h),
            itemBuilder: (context, index) => _NoteCard(note: notes[index]),
          ),
        },
      ),
    );
  }
}

/// ملاحظةٌ واحدة: المرحلة التي كُتبت عندها بلونها وأيقونتها، ثم ما كُتب، ثم متى.
class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final OrderNote note;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard.raised(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // المرحلة بلونها في «طلباتي» نفسه، وبحجمها الكامل: هي نصف ما تقوله البطاقة.
          StagePill.large(label: note.stageLabel, stage: note.stage),
          SizedBox(height: 12.h),
          // نثرٌ يلتفّ ولا يُقصّ: ملاحظةٌ لا يُقرأ آخرها شرٌّ من لا ملاحظة.
          Text(
            note.text,
            style: context.textTheme.bodyLarge?.copyWith(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              height: 1.55,
            ),
          ),
          if (note.writtenAt case final at?) ...[
            SizedBox(height: 8.h),
            Text(
              at.stampLabel,
              style: context.textTheme.bodyMedium?.copyWith(
                fontSize: 13.5.sp,
                height: 1.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Nothing extends StatelessWidget {
  const _Nothing();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.notes, size: 44.sp, color: scheme.onSurfaceVariant),
          SizedBox(height: 14.h),
          Text(
            'لا توجد ملاحظات',
            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.failure, required this.onRetry});

  final Failure failure;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // كلمة الخادم كما هي: غالباً تقول ما العمل.
            Text(failure.message, textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            AppButton.outlined(label: 'أعد المحاولة', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
