import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/paged_list_view.dart';
import 'package:printing/core/widgets/search_field.dart';
import 'package:printing/features/cities/models/city.dart';
import 'package:printing/features/cities/presentation/viewmodel/city_regions_cubit.dart';
import 'package:printing/features/cities/presentation/widgets/region_card.dart';

/// The neighbourhoods inside one city.
///
/// The same screen as the map above it — a search box and one list of the same card — because
/// it is the same question one level down: *where, exactly?* Anything else here would make the
/// second tap feel like a different app.
///
/// The city arrives as `extra` from the row that was tapped, purely to name the app bar. A cold
/// deep link to `/cities/7/regions` has no `extra`, and the screen still works: the regions are
/// fetched by id regardless, and only the title falls back to a generic one. Fetching the city
/// as well, for a heading, would put a second request in front of every open of this screen to
/// save one word on the rare path.
class CityRegionsPage extends StatelessWidget {
  const CityRegionsPage({required this.cityId, this.city, super.key});

  final int cityId;

  /// The row that was tapped, when this screen was opened from the map.
  final City? city;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CityRegionsCubit>(
      create: (_) => sl<CityRegionsCubit>(param1: cityId)..load(),
      child: _CityRegionsView(city: city),
    );
  }
}

class _CityRegionsView extends StatelessWidget {
  const _CityRegionsView({required this.city});

  final City? city;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CityRegionsCubit>();

    return Scaffold(
      appBar: AppBar(
        title: Text(city?.name ?? 'المناطق'),
        // The city's price, once, at the top — a region has none of its own, and it is the
        // number the person on this screen is about to quote.
        actions: [
          if (city != null)
            Padding(
              padding: EdgeInsetsDirectional.only(end: 12.w),
              child: Center(child: _PriceLine(city: city!)),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: SearchField(hint: 'ابحث عن منطقة', onChanged: cubit.search),
          ),
          Expanded(
            child: BlocBuilder<CityRegionsCubit, CityRegionsState>(
              builder: (context, state) => PagedListView<Region>(
                state: state,
                emptyMessage: 'لا توجد مناطق في هذه المدينة',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 68.h,
                itemBuilder: (context, region, index) =>
                    RegionCard(key: ValueKey(region.id), region: region),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What delivering anywhere in this city costs. Plain text, not a pill: the pills on this
/// screen belong to the rows, and a second pill in the bar would read as one of them.
class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.city});

  final City city;

  @override
  Widget build(BuildContext context) {
    return Text(
      city.priceLabel,
      textDirection: TextDirection.rtl,
      style: context.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: context.colorScheme.primary,
      ),
    );
  }
}
