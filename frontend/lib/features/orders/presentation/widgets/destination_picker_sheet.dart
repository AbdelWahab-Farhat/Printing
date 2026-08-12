import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/paged_list_view.dart';
import 'package:printing/core/widgets/search_field.dart';
import 'package:printing/features/cities/models/city.dart';
import 'package:printing/features/cities/presentation/viewmodel/cities_cubit.dart';
import 'package:printing/features/cities/presentation/viewmodel/city_regions_cubit.dart';

/// Choosing where an order goes.
///
/// **The delivery map has been readable in this app since the start and never selectable** — the
/// cities screen opens a city's regions rather than answering with one. These two sheets are the
/// missing half: the same lists, asked as a question.
///
/// The office branches are in the same list as the delivery cities, and deliberately so: the
/// server reads `fulfilment_type` off whichever city is chosen, so picking «إستلام مكتب(قرجي)»
/// *is* how an order becomes a collection — there is no second switch to keep in step with it.
///
/// [deliveryOnly] is the one caller that disagrees, and only about the branches: a customer's
/// shop is somewhere *they* sell, and «هذا المحل يقع في: إستلام مكتب طرابلس» is a sentence with
/// no meaning. See [showCityPicker]'s parameter for why the filter is here and not on the API.
Future<City?> showCityPicker({
  required BuildContext context,
  int? selectedId,

  /// Hide our own branches, leaving only real places.
  ///
  /// Filtered here rather than through a `fulfilment_type` parameter on `GET /cities`, which
  /// the endpoint does not have: there are exactly two such rows on the whole map and they sort
  /// first, so a client-side `where` costs one line and no round trip. If the map ever grows
  /// enough branches to push a real city off the first page, this becomes a server filter.
  bool deliveryOnly = false,
}) {
  return showModalBottomSheet<City>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider<CitiesCubit>(
      create: (_) => sl<CitiesCubit>()..load(),
      child: _CityPicker(selectedId: selectedId, deliveryOnly: deliveryOnly),
    ),
  );
}

/// The neighbourhoods inside one city.
///
/// Only asked for when the city has any — a city with none has nothing to show, and an empty
/// sheet is a tap that leads nowhere.
Future<Region?> showRegionPicker({
  required BuildContext context,
  required int cityId,
  int? selectedId,
}) {
  return showModalBottomSheet<Region>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider<CityRegionsCubit>(
      create: (_) => sl<CityRegionsCubit>(param1: cityId)..load(),
      child: _RegionPicker(selectedId: selectedId),
    ),
  );
}

class _CityPicker extends StatelessWidget {
  const _CityPicker({this.selectedId, this.deliveryOnly = false});

  final int? selectedId;
  final bool deliveryOnly;

  /// The same state with our branches taken out of the loaded page.
  ///
  /// The page's `meta` is left alone: it describes what the server sent, and rewriting `total`
  /// to match what is on screen would make "load more" ask the wrong question.
  CitiesState _visible(CitiesState state) {
    if (!deliveryOnly) return state;

    return switch (state) {
      CitiesLoaded(:final page, :final isLoadingMore, :final search) => CitiesLoaded(
        page: Paginated<City>(
          items: page.items.where((city) => !city.isOfficePickup).toList(),
          meta: page.meta,
          extraMeta: page.extraMeta,
        ),
        isLoadingMore: isLoadingMore,
        search: search,
      ),
      _ => state,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CitiesCubit>();

    return _Sheet(
      title: deliveryOnly ? 'اختيار المدينة' : 'اختيار المدينة أو المكتب',
      searchHint: deliveryOnly ? 'ابحث عن مدينة' : 'ابحث عن مدينة أو فرع',
      onSearch: cubit.search,
      child: BlocBuilder<CitiesCubit, CitiesState>(
        builder: (context, state) => PagedListView<City>(
          state: _visible(state),
          emptyMessage: 'لا توجد مدن على الخريطة',
          onLoadMore: cubit.loadMore,
          onRefresh: cubit.refresh,
          skeletonHeight: 60.h,
          itemBuilder: (context, city, index) => _Row(
            title: city.name,
            // The rate is what the choice costs, and it lands on the order the moment it is
            // made — so it is on screen before the tap, not after it. Recording where a shop
            // *is* costs nothing, so that caller gets the map's own description instead.
            subtitle: deliveryOnly ? (city.subtitle ?? '') : city.priceLabel,
            isSelected: city.id == selectedId,
            onTap: () => Navigator.of(context).pop(city),
          ),
        ),
      ),
    );
  }
}

class _RegionPicker extends StatelessWidget {
  const _RegionPicker({this.selectedId});

  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CityRegionsCubit>();

    return _Sheet(
      title: 'اختيار المنطقة',
      searchHint: 'ابحث عن منطقة',
      onSearch: cubit.search,
      child: BlocBuilder<CityRegionsCubit, CityRegionsState>(
        builder: (context, state) => PagedListView<Region>(
          state: state,
          emptyMessage: 'لا توجد مناطق مسجّلة لهذه المدينة',
          onLoadMore: cubit.loadMore,
          onRefresh: cubit.refresh,
          skeletonHeight: 60.h,
          itemBuilder: (context, region, index) => _Row(
            title: region.name,
            subtitle: region.subtitle ?? '',
            isSelected: region.id == selectedId,
            onTap: () => Navigator.of(context).pop(region),
          ),
        ),
      ),
    );
  }
}

/// The frame both pickers share: a grab handle, a title, a search box and a list.
class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.title,
    required this.searchHint,
    required this.onSearch,
    required this.child,
  });

  final String title;
  final String searchHint;
  final ValueChanged<String> onSearch;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Column(
        children: [
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            child: Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
            child: SearchField(hint: searchHint, onChanged: onSearch),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected ? Icon(Icons.check_rounded, color: scheme.primary) : null,
      onTap: onTap,
    );
  }
}
