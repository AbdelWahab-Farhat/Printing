import 'package:dayaa/core/config/app_config.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/location/presentation/viewmodel/pick_location_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

/// Pick a point on the map.
///
/// It replaces two number fields and a hint that told staff to long-press in Google Maps and
/// copy the coordinates by hand. The realistic outcome of that instruction is a shop recorded
/// with no pin at all, which is data lost at the moment it is collected.
///
/// **The pin does not move — the map does.** A crosshair is painted at the centre of the
/// viewport and the map slides underneath it. Three things follow from that, and they are why
/// it is worth more than a draggable marker: the answer is always `camera.center`, so there is
/// no second copy of the position to keep in step; the chosen point is never hidden under the
/// thumb choosing it; and it is the gesture every delivery app here has already taught the user.
///
/// Returns a [LatLng] through `context.pop`, or nothing if the user backs out.
class PickLocationPage extends StatelessWidget {
  const PickLocationPage({this.initial, this.tileProvider, super.key});

  /// Where to open. The shop's existing pin, if it has one.
  final LatLng? initial;

  /// Tests pass a provider that answers from memory.
  ///
  /// Injected from the first line rather than added after the first red CI run: a [FlutterMap]
  /// in `pumpWidget` otherwise reaches for real HTTP and the failure reads like a bug in the
  /// screen.
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PickLocationCubit>(
      create: (_) => sl<PickLocationCubit>(),
      child: _PickLocationView(initial: initial, tileProvider: tileProvider),
    );
  }
}

class _PickLocationView extends StatefulWidget {
  const _PickLocationView({this.initial, this.tileProvider});

  final LatLng? initial;
  final TileProvider? tileProvider;

  @override
  State<_PickLocationView> createState() => _PickLocationViewState();
}

class _PickLocationViewState extends State<_PickLocationView> {
  final _map = MapController();
  final _query = TextEditingController();

  /// Where the crosshair is now, mirrored out of the camera so the footer can show it.
  ///
  /// Not the source of truth — `_map.camera.center` is. This exists only because a `Text` cannot
  /// read a controller that does not notify.
  late LatLng _centre = widget.initial ?? _tripoli;

  late double _zoom = widget.initial != null ? 16 : 12;

  /// Set when the tile server cannot be reached.
  ///
  /// It matters more than a cosmetic banner: the map keeps panning perfectly over a blank grey
  /// grid and still yields a real [LatLng], so a pin dropped on an empty canvas is a *wrong*
  /// pin, stored with complete confidence.
  bool _tilesFailed = false;

  /// The middle of Tripoli. Where the map opens when there is nothing better.
  static const LatLng _tripoli = LatLng(32.8872, 13.1913);

  /// Below this the map is a country, not a street, and a pin is a guess.
  static const double _preciseEnoughZoom = 14;

  /// Somewhere to go when the geocoder answers nothing — or cannot be reached at all. No
  /// network, and between them they cover most of where this business delivers.
  static const List<(String, LatLng)> _cities = [
    ('طرابلس', LatLng(32.8872, 13.1913)),
    ('بنغازي', LatLng(32.1167, 20.0667)),
    ('مصراتة', LatLng(32.3754, 15.0925)),
    ('الزاوية', LatLng(32.7571, 12.7278)),
    ('سبها', LatLng(27.0377, 14.4283)),
  ];

  @override
  void dispose() {
    _query.dispose();
    _map.dispose();
    super.dispose();
  }

  void _moveTo(LatLng point, {double zoom = 15}) {
    _map.move(point, zoom);
    context.read<PickLocationCubit>().clear();
    FocusScope.of(context).unfocus();
  }

  void _confirm() => context.pop(_map.camera.center);

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('تحديد الموقع')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _centre,
              initialZoom: _zoom,
              minZoom: 4,
              maxZoom: 19,
              // Rotation is off: a rotated map has no up, and nothing here needs one.
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onPositionChanged: (camera, _) {
                if (!mounted) return;

                setState(() {
                  _centre = camera.center;
                  _zoom = camera.zoom;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: AppConfig.mapTileUrl,
                // Required by the OSM tile policy, and enforced: a request carrying a library's
                // default agent is refused.
                userAgentPackageName: AppConfig.mapPackageName,
                tileProvider: widget.tileProvider,
                errorTileCallback: (tile, error, stack) {
                  if (mounted && !_tilesFailed) setState(() => _tilesFailed = true);
                },
              ),
            ],
          ),

          // Painted over the map and deaf to touch, so every gesture reaches the map beneath.
          IgnorePointer(child: Center(child: _Crosshair(colour: scheme.primary))),

          Positioned(
            top: 12.h,
            left: 12.w,
            right: 12.w,
            child: _SearchPanel(
              controller: _query,
              onPick: _moveTo,
              cities: _cities,
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _Footer(
              centre: _centre,
              // Inside the footer rather than floating above it, and that is not only because
              // a floated banner was being clipped behind it: a warning about the pin belongs
              // against the button that commits the pin.
              hasFailedTiles: _tilesFailed,
              // Advice, never a disabled button: somebody in a town with no map detail to zoom
              // into would be stranded by a confirm that refuses to work.
              isCoarse: _zoom < _preciseEnoughZoom,
              onConfirm: _confirm,
            ),
          ),

          // The tile policy requires attribution to be *displayed*. Plain text, not a link —
          // display is the obligation, and a link would cost a url_launcher dependency.
          Positioned(
            bottom: 4.h,
            right: 8.w,
            child: Text(
              '© مساهمو OpenStreetMap',
              style: context.textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The fixed sight at the centre of the map.
class _Crosshair extends StatelessWidget {
  const _Crosshair({required this.colour});

  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lifted by half its own height so the *point* of the pin sits on the centre of the
      // viewport, not the middle of the glyph.
      padding: EdgeInsets.only(bottom: 36.h),
      child: Icon(AppIcons.mapPin, size: 40.sp, color: colour),
    );
  }
}

/// The search field, and whatever the search came back with.
class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.controller,
    required this.onPick,
    required this.cities,
  });

  final TextEditingController controller;
  final void Function(LatLng point, {double zoom}) onPick;
  final List<(String, LatLng)> cities;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PickLocationCubit>();

    return Column(
      children: [
        Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(14.r),
          child: AppTextField(
            controller: controller,
            hint: 'ابحث عن مدينة أو منطقة',
            prefixIcon: AppIcons.search,
            textInputAction: TextInputAction.search,
            // On submit, never on a keystroke. Nominatim's policy forbids per-keystroke
            // autocomplete and rate-limits by source IP — five staff behind one office router
            // are one source. A debounce would not fix that; not sending the request does.
            onSubmitted: cubit.search,
            onChanged: (value) {
              if (value.trim().isEmpty) cubit.clear();
            },
          ),
        ),
        SizedBox(height: 8.h),
        BlocBuilder<PickLocationCubit, PickLocationState>(
          builder: (context, state) => switch (state) {
            PickLocationIdle() => const SizedBox.shrink(),
            PickLocationSearching() => const _Panel(child: LinearProgressIndicator()),
            PickLocationResults(:final places) => _Panel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final place in places)
                    ListTile(
                      dense: true,
                      title: Text(place.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        place.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // A result moves the camera. It does not answer — the crosshair stays the
                      // only truth, so nobody can confirm a point they never looked at.
                      onTap: () => onPick(place.point),
                    ),
                ],
              ),
            ),
            PickLocationNoResults(:final term) => _Panel(
              child: _NoResults(term: term, cities: cities, onPick: onPick),
            ),
            PickLocationSearchFailed(:final failure) => _Panel(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Text(
                  failure.message,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.error,
                  ),
                ),
              ),
            ),
          },
        ),
      ],
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.term, required this.cities, required this.onPick});

  final String term;
  final List<(String, LatLng)> cities;
  final void Function(LatLng point, {double zoom}) onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('لا توجد نتائج لـ «$term»', style: context.textTheme.bodyMedium),
          SizedBox(height: 4.h),
          Text(
            // The actual fix about four times in five: «مطبعة النور» is not in the geocoder and
            // never will be, but the district it sits in is.
            'ابحث باسم المدينة أو المنطقة، لا باسم المحل',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final (name, point) in cities)
                ActionChip(label: Text(name), onPressed: () => onPick(point, zoom: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      color: context.colorScheme.surface,
      borderRadius: BorderRadius.circular(14.r),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _TilesFailedBanner extends StatelessWidget {
  const _TilesFailedBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: scheme.errorContainer,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Text(
          // Said plainly, because the danger is silent: the map still pans over a blank grid
          // and still returns coordinates, so a pin placed now would be confidently wrong.
          'تعذّر تحميل الخريطة — تحقّق من الاتصال. لا تحدّد موقعاً على خريطة فارغة.',
          style: context.textTheme.bodySmall?.copyWith(color: scheme.onErrorContainer),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.centre,
    required this.isCoarse,
    required this.hasFailedTiles,
    required this.onConfirm,
  });

  final LatLng centre;
  final bool isCoarse;
  final bool hasFailedTiles;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 22.h),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
        boxShadow: [
          BoxShadow(color: scheme.shadow.withValues(alpha: 0.12), blurRadius: 16),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasFailedTiles) ...[
            const _TilesFailedBanner(),
            SizedBox(height: 10.h),
          ],
          Text(
            // Six decimals: the column is decimal(10,7), and six is about a tenth of a metre.
            '${centre.latitude.toStringAsFixed(6)}, ${centre.longitude.toStringAsFixed(6)}',
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            style: context.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isCoarse) ...[
            SizedBox(height: 4.h),
            Text(
              'قرّب أكثر لتحديد المكان بدقة',
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(color: scheme.tertiary),
            ),
          ],
          SizedBox(height: 12.h),
          AppButton(label: 'تأكيد الموقع', onPressed: onConfirm),
        ],
      ),
    );
  }
}
