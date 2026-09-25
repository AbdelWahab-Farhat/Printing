import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/features/badges/presentation/viewmodel/badges_cubit.dart';
import 'package:dayaa_client/features/billboards/presentation/viewmodel/billboard_cubit.dart';
import 'package:dayaa_client/features/billboards/presentation/views/billboard_carousel.dart';
import 'package:dayaa_client/features/home/presentation/viewmodel/active_orders_cubit.dart';
import 'package:dayaa_client/features/home/presentation/widgets/active_orders_section.dart';
import 'package:dayaa_client/features/home/presentation/widgets/home_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// الشاشة التي يُفتح عليها التطبيق: ما يعرضه المتجر، وما في طريقه إلى العميل.
///
/// **لا شيء هنا يكرّر الشريط السفلي.** «الخدمات» و«المتاجر» خرجتا من الرئيسية (طلب المستخدم،
/// 2026-09-25): كانت قائمة اختصاراتٍ إلى ما تحت الإبهام أصلاً. وكذلك «منتجاتنا» بعدها في اليوم
/// نفسه: صفٌّ من الكتالوج وتبويب «المنتجات» تحته يعرضه كله. مكانها ما يهتم به العميل: أين طلبيته.
///
/// **قسمان، كلٌّ منهما يحمّل وحده ويفشل وحده.** إعلانٌ لم يُحمَّل لا يُخفي طلبيةً في الطريق.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BillboardCubit>(create: (_) => sl<BillboardCubit>()..load()),
        BlocProvider<ActiveOrdersCubit>(create: (_) => sl<ActiveOrdersCubit>()..load()),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HomeAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<BillboardCubit>().load(),
            context.read<ActiveOrdersCubit>().load(),
            // **الطريق الوحيد لمعرفة ردٍّ دون مغادرة التطبيق.** الشارة تُجلب عند الفتح وعند
            // العودة إليه فقط، فتطبيقٌ تُرك مفتوحاً على هذه الشاشة لن يسمع أن المتجر ردّ. والسحب
            // إلى الأسفل هو ما يفعله الناس أصلاً حين يريدون أن يعرفوا هل من جديد.
            context.read<BadgesCubit>().refresh(),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(top: 8.h, bottom: 24.h),
          children: [
            const BillboardCarousel(),
            SizedBox(height: 22.h),
            const ActiveOrdersSection(),
          ],
        ),
      ),
    );
  }
}
