import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/app_text_field.dart';
import 'package:printing/features/cities/models/city.dart';
import 'package:printing/features/cities/presentation/viewmodel/cities_cubit.dart';

/// The delivery map, as the reference implementation of a screen.
///
/// What every view in this app does, and nothing more:
///   * builds its Cubit from the injector and closes it (`BlocProvider` does the closing),
///   * `switch`es over a sealed state, so a new state is a compile error here rather than a
///     blank screen in production,
///   * calls methods on the Cubit and never a repository, a use case or Dio.
///
/// There is no business logic below this line — no filtering a list, no deciding what a price
/// means. If a widget starts computing something, it belongs in the Cubit or a use case.
class CitiesPage extends StatelessWidget {
  const CitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
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
            padding: EdgeInsets.all(16.w),
            child: AppTextField(
              hint: 'ابحث عن مدينة أو فرع',
              prefixIcon: AppIcons.search,
              textInputAction: TextInputAction.search,
              onChanged: cubit.search,
            ),
          ),
          Expanded(
            child: BlocBuilder<CitiesCubit, CitiesState>(
              builder: (context, state) => switch (state) {
                CitiesInitial() || CitiesLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                CitiesFailure(:final failure) => _ErrorView(
                  message: failure.message,
                  onRetry: cubit.refresh,
                ),
                CitiesLoaded(:final page, :final isLoadingMore) => page.isEmpty
                    ? const _EmptyView()
                    : _CityList(
                        cities: page.items,
                        isLoadingMore: isLoadingMore,
                        onLoadMore: cubit.loadMore,
                        onRefresh: cubit.refresh,
                      ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CityList extends StatefulWidget {
  const _CityList({
    required this.cities,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.onRefresh,
  });

  final List<City> cities;
  final bool isLoadingMore;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRefresh;

  @override
  State<_CityList> createState() => _CityListState();
}

class _CityListState extends State<_CityList> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    // Removing the listener before disposing: a controller disposed with a live listener
    // still fires it once, into a State that is already gone.
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _controller.position;

    // Fetches a screen early so the next page is usually there before the user reaches the
    // bottom. The Cubit ignores the call when a page is already in flight.
    if (position.pixels >= position.maxScrollExtent - 400) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.separated(
        controller: _controller,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: widget.cities.length + (widget.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => SizedBox(height: 8.h),
        itemBuilder: (context, index) {
          if (index >= widget.cities.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return _CityTile(city: widget.cities[index]);
        },
      ),
    );
  }
}

class _CityTile extends StatelessWidget {
  const _CityTile({required this.city});

  final City city;

  @override
  Widget build(BuildContext context) {
    // "لم يُحدد" rather than a 0: the API says null when no rate is agreed, and showing 0.00
    // would read as free delivery.
    final price = city.hasDeliveryPrice ? '${city.deliveryPrice} د.ل' : 'السعر لم يُحدد';

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          city.isOfficePickup ? Icons.storefront_rounded : Icons.location_on_outlined,
          color: context.colorScheme.primary,
        ),
        title: Text(city.name, style: context.textTheme.titleMedium),
        subtitle: Text([price, if (city.darbBranch != null) city.darbBranch!].join(' · ')),
        trailing: city.isRegionRequired
            ? Chip(
                label: Text('${city.regionsCount ?? 0} منطقة'),
                visualDensity: VisualDensity.compact,
              )
            : null,
        onTap: () => context.read<CitiesCubit>().selectCity(city),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 56.sp, color: context.colorScheme.outline),
          SizedBox(height: 12.h),
          Text('لا توجد مدن مطابقة', style: context.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 56.sp, color: context.colorScheme.error),
            SizedBox(height: 12.h),
            // The server's own Arabic message, not a generic one — it usually says exactly
            // what went wrong, and replacing it with "حدث خطأ" throws that away.
            Text(message, textAlign: TextAlign.center, style: context.textTheme.bodyLarge),
            SizedBox(height: 16.h),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
