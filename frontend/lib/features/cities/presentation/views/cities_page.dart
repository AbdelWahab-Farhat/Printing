import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/cities/models/city.dart';
import 'package:dayaa/features/cities/presentation/viewmodel/cities_cubit.dart';
import 'package:dayaa/features/cities/presentation/widgets/city_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// The delivery map — every place we deliver to, and every branch a customer can collect from.
///
/// Laid out as design **2b**: a search box, then one flat list of cards. The design's two
/// counting tabs above it are gone; they filtered nine rows into two and seven, which is a
/// control that costs a tap and saves a scroll. The tinted glyph on each card already separates
/// a branch from a destination, and it does it without anybody tapping anything.
///
/// Tapping a city opens its regions. Not every row does: a branch has no regions, and neither
/// has a city nobody has mapped yet — [CityCard] refuses the tap for those rather than opening
/// an empty screen.
class CitiesPage extends StatelessWidget {
  const CitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CitiesCubit>(
      create: (_) => sl<CitiesCubit>()..load(),
      child: const _CitiesView(),
    );
  }
}

class _CitiesView extends StatelessWidget {
  const _CitiesView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CitiesCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('مدن التوصيل')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: SearchField(hint: 'ابحث عن مدينة أو فرع', onChanged: cubit.search),
          ),
          Expanded(
            child: BlocBuilder<CitiesCubit, CitiesState>(
              builder: (context, state) => PagedListView<City>(
                state: state,
                emptyMessage: 'لا توجد مدن على الخريطة بعد',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                // One row of the 2b card, measured: a 36 tile with two lines beside it.
                skeletonHeight: 68.h,
                itemBuilder: (context, city, index) => CityCard(
                  key: ValueKey(city.id),
                  city: city,
                  // The city rides along as `extra`, so the regions screen has its name to put
                  // in the app bar without a second request for a record we already hold.
                  onTap: () => context.push(Routes.cityRegions(city.id), extra: city),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
