import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/investment_fund/presentation/viewmodel/fund_detail_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// جسمُ شاشة بندٍ من بنود اللوحة: انتظار، أو سببُ الفشل بزرّ إعادة، أو المحتوى بسحبٍ للتحديث.
///
/// الشاشاتُ الثلاث — الرفُّ والبضاعةُ الخارجة والأرباحُ المستحقّة — تفترق فيما ترسمه وحده،
/// فهو ما تمرّره في [builder]، وما سواه مكتوبٌ هنا مرّة.
class FundDetailBody<T> extends StatelessWidget {
  const FundDetailBody({required this.builder, super.key});

  final List<Widget> Function(BuildContext context, T value) builder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FundDetailCubit<T>, FundDetailState<T>>(
      builder: (context, state) => switch (state) {
        FundDetailLoading<T>() => const Center(child: CircularProgressIndicator()),
        FundDetailFailure<T>(:final failure) => _Retry<T>(message: failure.message),
        FundDetailLoaded<T>(:final value) => RefreshIndicator(
          onRefresh: () => context.read<FundDetailCubit<T>>().load(),
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
            children: builder(context, value),
          ),
        ),
      },
    );
  }
}

class _Retry<T> extends StatelessWidget {
  const _Retry({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: context.textTheme.bodyMedium),
            SizedBox(height: 16.h),
            AppButton(
              label: 'إعادة المحاولة',
              onPressed: () => context.read<FundDetailCubit<T>>().load(),
            ),
          ],
        ),
      ),
    );
  }
}

/// سطرٌ يقول إن القائمة فارغة — بدل قائمةٍ بيضاء تُقرأ عطباً.
class FundEmptyLine extends StatelessWidget {
  const FundEmptyLine(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: context.textTheme.bodyMedium?.copyWith(color: context.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// عنوانُ قسمٍ ومجموعُه في سطرٍ واحد — «أُفرج عنها ولم تُسحب ····· 50 د.ل».
class FundSectionTitle extends StatelessWidget {
  const FundSectionTitle({required this.title, this.amount, super.key});

  final String title;

  /// مجموعُ القسم كما قاله الخادم — لا يُجمع هنا من صفوفه.
  final String? amount;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700);

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Expanded(child: Text(title, style: style)),
          if (amount case final figure?) ...[
            SizedBox(width: 8.w),
            Text(figure, textDirection: TextDirection.ltr, style: style),
          ],
        ],
      ),
    );
  }
}

/// خطٌّ رفيعٌ بين سطرين في جدول — لا فجوةُ بطاقتين.
class FundHairline extends StatelessWidget {
  const FundHairline({super.key});

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    thickness: 1,
    color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
  );
}
