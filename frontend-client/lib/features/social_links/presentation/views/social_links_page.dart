import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/validators.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:dayaa_client/features/social_links/models/social_link.dart';
import 'package:dayaa_client/features/social_links/models/social_platform.dart';
import 'package:dayaa_client/features/social_links/presentation/viewmodel/social_links_cubit.dart';
import 'package:dayaa_client/features/social_links/presentation/widgets/social_platform_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «روابط التواصل» — صفحات العميل على فيسبوك وإنستغرام وغيرها، تُفتح من «حسابي».
///
/// **سطرٌ لكل رابط، باسم منصّته وشعارها وهو يكتب**، وسلّةٌ في طرفه، و«إضافة رابط» تحتها. و«حفظ» يرسلها
/// كلها مرةً واحدة ويعود إلى «حسابي» بـ`true` لتعيد قراءة عددها.
///
/// **بلا روابط ولا سطر:** الشاشة تقول «لا توجد روابط بعد» ولا تعرض إلا «إضافة رابط» — لا شيء يُحفظ.
/// أما حين يحذف العميل آخر رابطٍ محفوظ فيبقى «حفظ»: بدونه لا طريق لإبلاغ الخادم بالحذف.
class SocialLinksPage extends StatelessWidget {
  const SocialLinksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SocialLinksCubit>(
      create: (_) => sl<SocialLinksCubit>()..load(),
      child: const _SocialLinksView(),
    );
  }
}

class _SocialLinksView extends StatefulWidget {
  const _SocialLinksView();

  @override
  State<_SocialLinksView> createState() => _SocialLinksViewState();
}

/// ذات حالةٍ من أجل السطور ومتحكّماتها وحدها: موارد شجرة الويدجت تُتخلّص منها، والـ Cubit ليس
/// آلية تخلّص. وإضافة سطرٍ أو حذفه `setState` لأنه شكل النموذج، لا قرارٌ عن العميل.
class _SocialLinksViewState extends State<_SocialLinksView> {
  /// حدُّ الخادم نفسه (`social_links` → `max:10`): الزرّ يتوقّف عنده بدل أن يردّه الحفظ.
  static const _maxLinks = 10;

  final _formKey = GlobalKey<FormState>();
  final _rows = <_LinkRow>[];

  /// السطور تُزرع مما على الخادم مرةً واحدة، عند أول تحميل. ما بعده يكتبه العميل.
  bool _seeded = false;

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _add() => setState(() => _rows.add(_LinkRow()));

  void _remove(int index) {
    // يُتخلّص منه في طريقه خارجاً: السطر غاب عن الشجرة، ومتحكّمٌ لن يُقرأ ثانيةً تسرّبٌ ما بقيت الشاشة.
    final removed = _rows.removeAt(index);
    removed.dispose();
    setState(() {});
    context.read<SocialLinksCubit>().clearFailure();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? true)) return;

    final saved = await context.read<SocialLinksCubit>().save([
      for (final row in _rows) (id: row.id, url: row.url.text),
    ]);

    if (!mounted || saved == null) return;

    context.showSuccess('تم حفظ الروابط');
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    const title = Text('روابط التواصل');

    return BlocConsumer<SocialLinksCubit, SocialLinksState>(
      // ما له سطرٌ يُعلَّق تحته، وما تبقّى رسالة — ولا شيء منه يُبتلع.
      listenWhen: (previous, current) => current.hasUnplacedFailure,
      listener: (context, state) {
        if (state case SocialLinksLoaded(:final lastFailure?)) context.showFailure(lastFailure);
      },
      builder: (context, state) {
        switch (state) {
          case SocialLinksLoading():
            return Scaffold(
              appBar: AppBar(title: title),
              body: const Center(child: CircularProgressIndicator()),
            );

          case SocialLinksFailure(:final failure):
            return Scaffold(
              appBar: AppBar(title: title),
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(failure.message, textAlign: TextAlign.center),
                      SizedBox(height: 16.h),
                      AppButton.outlined(
                        label: 'أعد المحاولة',
                        onPressed: context.read<SocialLinksCubit>().load,
                      ),
                    ],
                  ),
                ),
              ),
            );

          case SocialLinksLoaded(:final links, :final isSaving):
            // هنا لا في مستمعٍ: المستمع يجري بعد أول رسمٍ للقائمة، فتومض «لا توجد روابط بعد» لحظةً
            // قبل أن تصل السطور.
            if (!_seeded) {
              _seeded = true;
              _rows.addAll(links.map(_LinkRow.from));
            }

            if (links.isEmpty && _rows.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: title),
                body: const _Empty(),
                bottomNavigationBar: _BottomAction(
                  child: AppButton(label: 'إضافة رابط', icon: AppIcons.add, onPressed: _add),
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(title: title),
              body: AbsorbPointer(
                // الشاشة مقفلة أثناء الحفظ، فما عليها هو ما أُرسل.
                absorbing: isSaving,
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                    children: [
                      for (final (index, row) in _rows.indexed) ...[
                        _LinkField(
                          key: ObjectKey(row),
                          row: row,
                          errorText: state.rowError(index),
                          onRemove: () => _remove(index),
                          onChanged: context.read<SocialLinksCubit>().clearFailure,
                        ),
                        SizedBox(height: 16.h),
                      ],
                      AppButton.outlined(
                        label: 'إضافة رابط',
                        icon: AppIcons.add,
                        onPressed: _rows.length >= _maxLinks ? null : _add,
                      ),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: _BottomAction(
                child: AppButton(label: 'حفظ', isLoading: isSaving, onPressed: _save),
              ),
            );
        }
      },
    );
  }
}

/// سطرُ رابط: الخانة باسم المنصّة وشعارها، يتبدّلان والعميل يكتب، وسلّةٌ في طرفها.
class _LinkField extends StatelessWidget {
  const _LinkField({
    required this.row,
    required this.errorText,
    required this.onRemove,
    required this.onChanged,
    super.key,
  });

  final _LinkRow row;
  final String? errorText;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    // يُعاد رسم السطر وحده مع كل حرف، لا الشاشة كلها.
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: row.url,
      builder: (context, value, _) {
        final platform = SocialPlatform.of(value.text);

        return AppTextField(
          controller: row.url,
          label: platform.label,
          hint: 'https://facebook.com/...',
          // المنصّة التي لا نعرفها أيقونةُ رابطٍ تتبع حالات الحقل — حمراء حين يخطئ — والمعروفة
          // شعارها بلونها.
          prefixIcon: platform == SocialPlatform.other ? AppIcons.link : null,
          prefix: platform == SocialPlatform.other ? null : SocialPlatformMark(platform),
          suffix: IconButton(
            onPressed: onRemove,
            icon: Icon(AppIcons.delete, size: 20.sp, color: context.colorScheme.onSurfaceVariant),
            tooltip: 'حذف الرابط',
          ),
          textDirection: TextDirection.ltr,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          // السطر الذي بُدئ يُكمَل أو يُحذف، ويُفحص بعد أن يُكمَل بـ`https://` كما سيُرسل.
          validator: (input) => Validators.url(normalizeSocialLink(input ?? '')),
          errorText: errorText,
          onChanged: (_) => onChanged(),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88.w,
            height: 88.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.12),
            ),
            child: Icon(AppIcons.link, size: 40.sp, color: scheme.primary),
          ),
          SizedBox(height: 14.h),
          Text(
            'لا توجد روابط بعد',
            style: context.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// الزرّ في أسفل الشاشة، بهوامش «متاجري» نفسها.
class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h), child: child),
    );
  }
}

/// المتحكّم وراء سطرٍ واحد، ومعه مُعرِّفه إن كان رابطاً محفوظاً.
class _LinkRow {
  _LinkRow();

  /// سطرٌ من رابطٍ على الخادم، بمُعرِّفه — فيُعدَّل في مكانه ولا يُحذف ويُنشأ غيره.
  factory _LinkRow.from(SocialLink link) => _LinkRow()
    ..id = link.id
    ..url.text = link.url;

  final url = TextEditingController();

  /// `null` لسطرٍ أُضيف للتوّ.
  int? id;

  void dispose() => url.dispose();
}
