import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/expense_categories_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «تصنيفات المصروفات» — بابٌ وحده تحت «المالية» في الدرج.
///
/// كانت القسمَ الأخير في «إعدادات المالية»، تحت الحسابات، فلا يصلها أحدٌ إلا بعد تمريرٍ طويل
/// — وهي قائمةٌ تُدار لا قاعدةٌ تُضبط. الصفوفُ كما كانت هناك تماماً؛ الذي تغيّر مكانُها فقط.
class ExpenseCategoriesPage extends StatelessWidget {
  const ExpenseCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExpenseCategoriesCubit(getCategories: sl(), saveCategory: sl())..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('تصنيفات المصروفات')),
        body: BlocBuilder<ExpenseCategoriesCubit, ExpenseCategoriesState>(
          builder: (context, state) => switch (state) {
            ExpenseCategoriesLoading() => const Center(child: CircularProgressIndicator()),
            ExpenseCategoriesFailed(:final failure) => Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(failure.message, textAlign: TextAlign.center),
                    SizedBox(height: 16.h),
                    AppButton.tonal(
                      label: 'إعادة المحاولة',
                      onPressed: context.read<ExpenseCategoriesCubit>().load,
                    ),
                  ],
                ),
              ),
            ),
            ExpenseCategoriesLoaded() => _Loaded(state: state),
          },
        ),
      ),
    );
  }
}

/// يُظهر ما عادت به الكتابة — تنبيهٌ عند الفشل، ولا شيء عند النجاح (الصفُّ يتبدّل).
Future<void> _run(BuildContext context, Future<Failure?> Function() write) async {
  final failure = await write();

  if (failure != null && context.mounted) {
    context.showError(failure.message, details: failure.details);
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state});

  final ExpenseCategoriesLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ExpenseCategoriesCubit>();

    return RefreshIndicator(
      onRefresh: cubit.load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 48.h),
        children: [
          for (final category in state.categories)
            SwitchListTile(
              key: ValueKey('category-${category.id}'),
              contentPadding: EdgeInsets.zero,
              value: category.isActive,
              title: Text(category.name),
              subtitle: Text(
                [
                  if (category.isSystem) 'يعتمد عليه النظام',
                  if (category.requiresEmployee) 'يتطلب موظفاً',
                ].join(' · '),
              ),
              secondary: IconButton(
                tooltip: 'إعادة التسمية',
                icon: Icon(AppIcons.edit),
                onPressed: () async {
                  final name = await _askName(
                    context,
                    title: 'تعديل التصنيف',
                    initial: category.name,
                  );

                  if (name != null && context.mounted) {
                    await _run(context, () => cubit.save(id: category.id, name: name));
                  }
                },
              ),
              // التصنيفان اللذان يعتمد عليهما النظام لا يُوقفان.
              onChanged: category.isSystem
                  ? null
                  : (v) => _run(
                      context,
                      () => cubit.save(id: category.id, name: category.name, isActive: v),
                    ),
            ),
          SizedBox(height: 8.h),
          AppButton.tonal(
            label: 'تصنيف جديد',
            icon: AppIcons.add,
            onPressed: () async {
              final name = await _askName(context, title: 'تصنيف جديد');

              if (name != null && context.mounted) {
                await _run(context, () => cubit.save(name: name));
              }
            },
          ),
        ],
      ),
    );
  }
}

Future<String?> _askName(BuildContext context, {required String title, String initial = ''}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NameDialog(title: title, initial: initial),
  );
}

/// المتحكّمُ يعيش ويموت مع النافذة، لا مع من فتحها.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _name,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'الاسم'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        FilledButton(
          onPressed: () {
            final text = _name.text.trim();

            if (text.isNotEmpty) Navigator.of(context).pop(text);
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
