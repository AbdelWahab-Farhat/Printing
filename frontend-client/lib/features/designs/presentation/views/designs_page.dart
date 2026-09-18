import 'package:cached_network_image/cached_network_image.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/files/attachment_picker.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/core/widgets/app_dialog.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:dayaa_client/core/widgets/attachment_sheet.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/models/design_rules.dart';
import 'package:dayaa_client/features/designs/presentation/viewmodel/designs_cubit.dart';
import 'package:dayaa_client/features/tools/presentation/views/qr_tool_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «تصاميمي» — the feature this app exists to make possible.
///
/// **Uploaded once and pointed at by every order.** Before this, a customer sent the same file
/// again with each order and somebody in the shop had to work out whether it was the same one.
/// `order_designs` holds a reference, not a copy — so renaming a design here renames it
/// everywhere it was used, and that is the intent.
class DesignsPage extends StatelessWidget {
  const DesignsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DesignsCubit>(
      create: (_) => sl<DesignsCubit>()..load(),
      child: const _DesignsView(),
    );
  }
}

class _DesignsView extends StatelessWidget {
  const _DesignsView();

  Future<void> _add(BuildContext context) async {
    final cubit = context.read<DesignsCubit>();

    // The sheet offers the document browser *and* the photo library, because «أرسله لي على
    // واتساب» lands in the second and iOS's Files app cannot see it at all. It picks nothing
    // itself — it answers *where from*, and the picker behind the interface does the rest.
    final source = await showAttachmentSheet(context: context);

    if (source == null) return;

    final files = await sl<AttachmentPicker>().pick(source);

    // Backing out of the system picker is an ordinary ending, and nothing is reported about it.
    if (files.isEmpty) return;

    // **One at a time.** The server answers each upload with the row it wrote, and the library
    // is mutated locally from that — a batch would have to guess at the order they came back in.
    for (final file in files) {
      // **Refused here rather than by the server**, and that is the whole point of
      // [DesignRules]: pushing 26 MB over a Libyan mobile connection to be told the limit is 25
      // costs a minute of somebody's time and their data allowance, to learn something knowable
      // before the first byte leaves the phone.
      final reason = DesignRules.reject(file);

      if (reason != null) {
        if (!context.mounted) return;

        context.showError(reason);
        continue;
      }

      await cubit.add(file: file);
    }
  }

  /// Makes a QR code and puts it straight in the library.
  ///
  /// **The tool does not upload**, and that is the point: uploading is this Cubit's job, with
  /// everything it already knows about doing it. The tool draws a file and hands it back —
  /// exactly as the camera does.
  Future<void> _addQrCode(BuildContext context) async {
    final cubit = context.read<DesignsCubit>();

    final qr = await pickQrCodeFile(context);

    if (qr == null) return;

    // **The name comes back with the file.** It used to be written here, the same literal the
    // tool wrote on its own other path — so a code saved from the drawer and one saved from
    // this screen were both «رمز QR», and naming either one meant renaming it afterwards. The
    // tool now asks, and what it asked for travels; this screen only has to not drop it.
    await cubit.add(file: qr.file, label: qr.label);
  }

  Future<void> _rename(BuildContext context, CustomerDesign design) async {
    final cubit = context.read<DesignsCubit>();

    // **The controller belongs to the dialog, not to this method.** It used to be made here and
    // disposed on the line after `showDialog` returned — which is the moment the *pop* is
    // decided, not the moment the dialog is gone: the exit animation is still running and its
    // `TextField` is still listening. Disposing a `TextEditingController` that a live
    // `EditableText` still depends on throws
    // «'_dependents.isEmpty': is not true» out of `framework.dart`, and it did, on every cancel.
    //
    // A `StatefulWidget` that owns it disposes in its own `dispose()`, which runs when the
    // dialog's element is actually unmounted. The staff app's version of this screen has always
    // done it that way.
    final label = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: design.label),
    );

    if (label == null || label.isEmpty || label == design.label) return;

    await cubit.renameTo(id: design.id, label: label);
  }

  Future<void> _remove(BuildContext context, CustomerDesign design) async {
    final cubit = context.read<DesignsCubit>();

    final confirmed = await showDestructiveDialog(
      context: context,
      title: 'حذف «${design.label}»؟',
      // **Honest about what it does not do.** Deleting here does not unpick the design from
      // orders already placed — those keep the file they were printed from.
      description: 'لن يظهر في مكتبتك بعد الآن. الطلبيات السابقة تحتفظ بالملف الذي طُبعت منه.',
    );

    if (confirmed != true) return;

    await cubit.removeAt(design.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تصاميمي'),
        // **No floating button, because the design draws none.** Adding lives in two places
        // instead, both of them in the design: the filled square in the bar, and the dashed
        // tile at the end of the grid where the eye lands after the last design.
        actions: [
          IconButton(
            icon: Icon(AppIcons.qrCode),
            tooltip: 'أنشئ رمز QR',
            onPressed: () => _addQrCode(context),
          ),
          BlocBuilder<DesignsCubit, DesignsState>(
            builder: (context, state) => Padding(
              padding: EdgeInsetsDirectional.only(end: 8.w),
              child: IconButton.filled(
                icon: Icon(AppIcons.add),
                tooltip: 'أضف تصميماً',
                onPressed: state.isBusy ? null : () => _add(context),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: BlocConsumer<DesignsCubit, DesignsState>(
          listener: (context, state) {
            // A write that failed, reported beside a library that is still on screen.
            if (state case DesignsLoaded(:final lastFailure?)) {
              context.showFailure(lastFailure);
            }
          },
          builder: (context, state) => switch (state) {
            DesignsLoading() => const Center(child: CircularProgressIndicator()),

            DesignsFailure(:final failure) => Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(failure.message, textAlign: TextAlign.center),
                    SizedBox(height: 16.h),
                    OutlinedButton(
                      onPressed: context.read<DesignsCubit>().load,
                      child: const Text('أعد المحاولة'),
                    ),
                  ],
                ),
              ),
            ),

            DesignsLoaded(:final designs, :final isBusy) => designs.isEmpty
                ? _Empty(onAdd: () => _add(context))
                : Opacity(
                    // Dimmed while a write is in flight — the grid stays, which is what keeps
                    // a rename from feeling like the library disappeared.
                    opacity: isBusy ? 0.6 : 1,
                    child: RefreshIndicator(
                      onRefresh: context.read<DesignsCubit>().load,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
                            sliver: const SliverToBoxAdapter(child: _WhyCard()),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                            sliver: SliverGrid.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12.h,
                                crossAxisSpacing: 12.w,
                                childAspectRatio: 0.78,
                              ),
                              // **One past the end**, and the extra cell is the add tile —
                              // where the design puts it, after the last design rather than
                              // floating over one.
                              itemCount: designs.length + 1,
                              itemBuilder: (context, index) => index == designs.length
                                  ? _AddTile(
                                      onTap: isBusy ? null : () => _add(context),
                                    )
                                  : _DesignCard(
                                      design: designs[index],
                                      onRename: () => _rename(context, designs[index]),
                                      onRemove: () => _remove(context, designs[index]),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          },
        ),
      ),
    );
  }
}

/// «تسمية التصميم» — a name, and the two ways out.
///
/// Stateful for one reason: it owns a [TextEditingController], which is a widget-lifecycle
/// resource and must be disposed when the widget is, not when the caller stops awaiting.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تسمية التصميم'),
      content: AppTextField(
        controller: _controller,
        label: 'الاسم',
        autofocus: true,
        // Enter is «حفظ» — the keyboard is already up and open on this field.
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(onPressed: _save, child: const Text('حفظ')),
      ],
    );
  }
}

class _DesignCard extends StatelessWidget {
  const _DesignCard({
    required this.design,
    required this.onRename,
    required this.onRemove,
  });

  final CustomerDesign design;
  final VoidCallback onRename;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard(
      onTap: onRename,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _Thumbnail(design: design),
                // «صورة» / «PDF» — the server's own word for the kind, sitting on the picture
                // where it costs the card no line.
                if (design.kindLabel case final kind?)
                  PositionedDirectional(
                    top: 8.h,
                    end: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Text(
                        kind,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(11.w, 9.h, 4.w, 4.h),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        design.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      // «PNG · 1.2 م.ب». The design draws it; both numbers were already in the
                      // list response.
                      if (design.metaLine case final meta?) ...[
                        SizedBox(height: 2.h),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // **Kept, though the mockup draws no delete.** A library you can fill and not
                // empty is a library that fills up; the button is made quiet rather than
                // removed, and the confirm dialog behind it says what deleting does not undo.
                IconButton(
                  icon: Icon(AppIcons.delete, size: 17.sp, color: scheme.onSurfaceVariant),
                  tooltip: 'احذف',
                  visualDensity: VisualDensity.compact,
                  onPressed: onRemove,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// «أضف تصميماً» — the cell the design puts after the last design.
class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        // Dashed in the mockup; Flutter has no dashed border without a painter, and a painter
        // for one cell of one grid is more machinery than the difference is worth. Solid and
        // dim reads as the same invitation.
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.5), width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(AppIcons.add, color: scheme.primary, size: 24.sp),
            ),
            SizedBox(height: 11.h),
            Text(
              'أضف تصميماً',
              style: context.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The one sentence that explains why this screen exists.
class _WhyCard extends StatelessWidget {
  const _WhyCard();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard.sunken(
      child: Row(
        children: [
          Icon(AppIcons.about, size: 20.sp, color: scheme.primary),
          SizedBox(width: 11.w),
          Expanded(
            child: Text(
              'ارفع شعارك مرة واحدة — يظهر في كل طلبية دون إعادة إرساله.',
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.design});

  final CustomerDesign design;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final url = design.fileUrl;

    final placeholder = Center(
      child: Icon(
        design.kind.isImage ? AppIcons.photos : AppIcons.pdf,
        size: 30.sp,
        color: scheme.onSurfaceVariant,
      ),
    );

    // A PDF has no thumbnail to draw, and the image link is **signed and expiring** — it is
    // minted per request, so it is deliberately not cached across sessions.
    if (!design.kind.isImage || url == null) return placeholder;

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, _) => const SizedBox.shrink(),
      errorWidget: (context, _, _) => placeholder,
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      children: [
        SizedBox(height: 140.h),
        Icon(
          AppIcons.designs,
          size: 48.sp,
          color: context.colorScheme.onSurfaceVariant,
        ),
        SizedBox(height: 14.h),
        Text(
          'لا توجد تصاميم بعد',
          textAlign: TextAlign.center,
          style: context.textTheme.titleSmall,
        ),
        SizedBox(height: 6.h),
        Text(
          'ارفع شعارك أو تصميمك مرة واحدة، ثم اخترْه في أي طلبية بدل إرساله في كل مرة.',
          textAlign: TextAlign.center,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 24.h),
        // **The empty screen carries its own button now the floating one is gone.** An empty
        // library with nothing to press on it is a dead end.
        FilledButton.icon(
          onPressed: onAdd,
          icon: Icon(AppIcons.add),
          label: const Text('أضف تصميماً'),
        ),
      ],
    );
  }
}
