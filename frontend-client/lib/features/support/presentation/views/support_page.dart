import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:dayaa_client/core/widgets/paged_list_view.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/support_cubit.dart';
import 'package:dayaa_client/features/support/presentation/widgets/ticket_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «الدعم» — a thread per question.
///
/// **تبويبان في الأعلى: «المفتوحة» و«المغلقة».** كانت ثلاث شرائح تحت بطاقة الساعات، و«الكل»
/// أولها؛ والعميل يسأل أحد سؤالين — ما الذي ينتظر جواباً، وما الذي انتهى — فصار لكلٍّ تبويبه
/// وقائمته، وتبقى كلٌّ في مكانها حين يُتنقّل بينهما. «المفتوحة» تشمل «قيد المعالجة»: هي التذاكر
/// الحيّة كلها، والصفّ يقول أيّها أجاب عنه أحد.
///
/// **وساعاتُ الدعم سطرٌ تحت العنوان، لا بطاقةٌ فوق القائمة** — المعلومة نفسها، بلا لوحةٍ تأخذ
/// سطرين من كل شاشة.
///
/// **No employee is ever named.** Which member of staff answered is the shop's internal
/// arrangement, and putting a name on a reply would make one person the target of a complaint
/// about a decision the business made. The server sends `me` or `support` and nothing else.
class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> with SingleTickerProviderStateMixin {
  TabController? _tabs;

  /// قائمتان مستقلتان، لكلّ تبويبٍ واحدة — تبقى كلٌّ بتمريرها وصفحاتها حين يُتنقّل بينهما.
  /// «المغلقة» تُنشأ حين تُفتح أول مرة: قلّ من يزورها، فلا طلب لها قبل ذلك.
  late final SupportCubit _open = sl<SupportCubit>()..narrowTo(true);
  SupportCubit? _closedCubit;

  SupportCubit get _closed => _closedCubit ??= sl<SupportCubit>()..narrowTo(false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // الانزلاق بين التبويبين إزاحةٌ، وهي مسموحة — وتغيب كلها مع «تقليل الحركة».
    _tabs ??= TabController(
      length: 2,
      vsync: this,
      animationDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _tabs?.dispose();
    _open.close();
    _closedCubit?.close();
    super.dispose();
  }

  Future<void> _openThread(SupportTicket ticket) async {
    final updated = await context.push<SupportTicket>(Routes.ticket(ticket.id));

    if (updated == null || !mounted) return;

    // يُسلَّم للتبويبين وكلٌّ يأخذ ما يخصّه: تذكرةٌ أعاد ردُّ العميل فتحها تغادر «المغلقة»
    // وتظهر أعلى «المفتوحة» — بلا طلبٍ وبلا رجوعٍ إلى أعلى القائمة. انظر `SupportCubit.absorb`.
    _open.absorb(updated);
    _closedCubit?.absorb(updated);
  }

  Future<void> _compose() async {
    // The order this thread is about, when the customer came here from one — read from the
    // location so it survives the branch switch, so they do not have to describe which order
    // they mean. A malformed value is simply no order, never a crash.
    final orderId = int.tryParse(
      GoRouterState.of(context).uri.queryParameters['order'] ?? '',
    );

    final ticket = await showModalBottomSheet<SupportTicket>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) => BlocProvider<SupportCubit>.value(
        value: _open,
        child: _ComposeSheet(orderId: orderId),
      ),
    );

    if (ticket == null || !mounted) return;

    // التذكرة الجديدة مفتوحةٌ بطبيعتها، فتبويبها «المفتوحة».
    _tabs?.index = 0;

    // Straight into the thread — which is what somebody who has just written a question
    // expects to happen next.
    await _openThread(ticket);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الدعم'),
            Text(
              'السبت–الخميس · 9 ص – 5 م',
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorColor: scheme.primary,
          dividerColor: scheme.outlineVariant,
          labelColor: scheme.primary,
          unselectedLabelColor: scheme.onSurfaceVariant,
          labelStyle: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          unselectedLabelStyle: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(height: 46.h, text: 'المفتوحة'),
            Tab(height: 46.h, text: 'المغلقة'),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _TicketsTab(
                    cubit: _open,
                    emptyMessage: 'لا توجد تذاكر مفتوحة',
                    onOpen: _openThread,
                  ),
                  // Builder كي لا تُنشأ قائمة «المغلقة» قبل أن تُرسم.
                  Builder(
                    builder: (context) => _TicketsTab(
                      cubit: _closed,
                      emptyMessage: 'لا توجد تذاكر مغلقة',
                      onOpen: _openThread,
                    ),
                  ),
                ],
              ),
            ),

            // **A button on the floor, not a floating one.** Full width across the bottom, as
            // every action button in this app is.
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              child: AppButton(label: 'تذكرة جديدة', icon: AppIcons.add, onPressed: _compose),
            ),
          ],
        ),
      ),
    );
  }
}

/// قائمة تبويبٍ واحد، **حيّةٌ ما دامت الشاشة حيّة** — التنقّل إلى التبويب الآخر والعودة لا يعيد
/// تحميلها ولا يرجعها إلى أعلاها.
class _TicketsTab extends StatefulWidget {
  const _TicketsTab({required this.cubit, required this.emptyMessage, required this.onOpen});

  final SupportCubit cubit;
  final String emptyMessage;
  final Future<void> Function(SupportTicket ticket) onOpen;

  @override
  State<_TicketsTab> createState() => _TicketsTabState();
}

class _TicketsTabState extends State<_TicketsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<SupportCubit, SupportState>(
      bloc: widget.cubit,
      builder: (context, state) => PagedListView<SupportTicket>(
        state: state,
        onLoadMore: widget.cubit.loadMore,
        onRefresh: widget.cubit.refresh,
        emptyMessage: widget.emptyMessage,
        skeletonHeight: 84.h,
        padding: EdgeInsets.only(top: 4.h, bottom: 12.h),
        separatorBuilder: (context, _) => Divider(
          height: 1,
          thickness: 1,
          indent: 78.w,
          color: context.colorScheme.outlineVariant,
        ),
        itemBuilder: (context, ticket, _) =>
            TicketRow(ticket: ticket, onOpen: () => widget.onOpen(ticket)),
      ),
    );
  }
}

class _ComposeSheet extends StatefulWidget {
  const _ComposeSheet({this.orderId});

  final int? orderId;

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _body = TextEditingController();

  bool _isSending = false;

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    final result = await context.read<SupportCubit>().submit(
      subject: _subject.text.trim(),
      body: _body.text.trim(),
      orderId: widget.orderId,
    );

    if (!mounted) return;

    setState(() => _isSending = false);

    result.fold(
      context.showFailure,
      (ticket) => Navigator.of(context).pop(ticket),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lifted above the keyboard, so the send button is never behind it.
      padding: EdgeInsets.only(bottom: context.keyboardInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.orderId == null ? 'تذكرة جديدة' : 'تذكرة عن الطلبية',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 16.h),

                AppTextField(
                  controller: _subject,
                  label: 'الموضوع',
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'اكتب موضوعاً' : null,
                ),
                SizedBox(height: 12.h),
                AppTextField(
                  controller: _body,
                  label: 'اشرح لنا',
                  maxLines: 5,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'اكتب رسالتك' : null,
                ),
                SizedBox(height: 20.h),

                AppButton(label: 'أرسل', isLoading: _isSending, onPressed: _send),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
