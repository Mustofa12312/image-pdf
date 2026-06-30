import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/localization.dart';
import '../../models/models.dart';
import '../controllers/image_to_pdf_controller.dart';
import '../widgets/drop_zone_widget.dart';
import '../widgets/progress_widgets.dart';

class ImageToPdfPage extends StatefulWidget {
  const ImageToPdfPage({super.key});
  @override
  State<ImageToPdfPage> createState() => _ImageToPdfPageState();
}

class _ImageToPdfPageState extends State<ImageToPdfPage> {
  late final ImageToPdfController _ctrl;

  @override
  void initState() { super.initState(); _ctrl = ImageToPdfController(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Consumer<ImageToPdfController>(
        builder: (context, ctrl, _) {
          if (ctrl.state == ImageToPdfState.error && ctrl.errorKey != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(context: context, builder: (_) => ErrorDialog(
                message: loc.translate(ctrl.errorKey!),
                onDismiss: () { Navigator.pop(context); ctrl.reset(); },
              ));
            });
          }
          if (ctrl.state == ImageToPdfState.done && ctrl.lastOutputPath != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: context, barrierDismissible: false,
                builder: (_) => CompletionDialog(
                  totalItems: 1, isPdf: true,
                  outputPath: ctrl.lastOutputPath!,
                  onDone: () { Navigator.pop(context); ctrl.reset(); },
                  onOpenFolder: () {
                    Navigator.pop(context);
                    final dir = File(ctrl.lastOutputPath!).parent.path;
                    if (Platform.isLinux) Process.run('xdg-open', [dir]);
                    if (Platform.isWindows) Process.run('explorer', [dir]);
                    ctrl.reset();
                  },
                ),
              );
            });
          }

          return Scaffold(
            backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
            appBar: AppBar(
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              elevation: 0,
              leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18), onPressed: () => Navigator.pop(context)),
              title: Text(loc.btnImageToPdf, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
              bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            ),
            body: ctrl.state == ImageToPdfState.converting
                ? Center(child: Padding(padding: const EdgeInsets.all(32), child: ProgressOverlay(current: ctrl.progressCurrent, total: ctrl.progressTotal)))
                : _buildBody(context, ctrl, loc, isDark),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext ctx, ImageToPdfController ctrl, AppLocalizations loc, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: image list
        Expanded(
          flex: 3,
          child: Column(children: [
            Expanded(
              child: ctrl.images.isEmpty
                  ? Padding(padding: const EdgeInsets.all(24), child: DropZoneWidget(isPdf: false, onFilesDropped: ctrl.addImages))
                  : _ImageGrid(ctrl: ctrl, loc: loc, isDark: isDark),
            ),
            if (ctrl.images.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      // Pick more images
                      final result = await showFilePicker();
                      if (result != null) ctrl.addImages(result);
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Images'),
                  ),
                ]),
              ),
          ]),
        ),
        VerticalDivider(width: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        // Right: settings
        SizedBox(
          width: 260,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionLabel('PDF Settings', isDark),
              const SizedBox(height: 16),
              _DropdownSetting<String>(
                label: loc.labelPaperSize, value: ctrl.settings.paperSize,
                items: AppConstants.paperSizes, itemLabel: (v) => v, isDark: isDark,
                onChanged: (v) => ctrl.updateSettings(ctrl.settings.copyWith(paperSize: v)),
              ),
              const SizedBox(height: 16),
              _DropdownSetting<String>(
                label: loc.labelOrientation, value: ctrl.settings.orientation,
                items: AppConstants.orientations, itemLabel: (v) => v, isDark: isDark,
                onChanged: (v) => ctrl.updateSettings(ctrl.settings.copyWith(orientation: v)),
              ),
              const SizedBox(height: 16),
              _DropdownSetting<String>(
                label: loc.labelMargin, value: ctrl.settings.margin,
                items: AppConstants.marginOptions, itemLabel: (v) => v, isDark: isDark,
                onChanged: (v) => ctrl.updateSettings(ctrl.settings.copyWith(margin: v)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: ctrl.images.isEmpty ? null : ctrl.savePdf,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: Text(loc.btnSavePdf),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.accentTeal,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${ctrl.images.length} ${loc.labelImages} selected',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Future<List<String>?> showFilePicker() async {
    // Using file_picker directly here
    return null; // handled by DropZoneWidget
  }
}

class _ImageGrid extends StatelessWidget {
  final ImageToPdfController ctrl; final AppLocalizations loc; final bool isDark;
  const _ImageGrid({required this.ctrl, required this.loc, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ctrl.images.length,
      onReorder: ctrl.reorderImages,
      itemBuilder: (context, index) {
        final img = ctrl.images[index];
        return _ImageTile(
          key: ValueKey(img.path + index.toString()),
          img: img, index: index, ctrl: ctrl, isDark: isDark, loc: loc,
        );
      },
    );
  }
}

class _ImageTile extends StatelessWidget {
  final ImageItem img; final int index;
  final ImageToPdfController ctrl; final bool isDark; final AppLocalizations loc;
  const _ImageTile({super.key, required this.img, required this.index, required this.ctrl, required this.isDark, required this.loc});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(children: [
        const SizedBox(width: 4),
        const Icon(Icons.drag_handle_rounded, color: AppColors.textMuted, size: 20),
        const SizedBox(width: 8),
        // Thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Transform.rotate(
            angle: img.rotationDegrees * 3.14159 / 180,
            child: SizedBox(
              width: 52, height: 52,
              child: Image.file(File(img.path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.darkBorder, child: const Icon(Icons.broken_image_rounded, size: 24, color: AppColors.textMuted))),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(img.fileName, style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 12), overflow: TextOverflow.ellipsis),
        ),
        // Actions
        Row(children: [
          _TileBtn(icon: Icons.keyboard_arrow_up_rounded, onTap: () => ctrl.moveUp(index), tooltip: loc.btnMoveUp),
          _TileBtn(icon: Icons.keyboard_arrow_down_rounded, onTap: () => ctrl.moveDown(index), tooltip: loc.btnMoveDown),
          _TileBtn(icon: Icons.rotate_right_rounded, onTap: () => ctrl.rotateImage(index), tooltip: loc.btnRotate),
          _TileBtn(icon: Icons.delete_rounded, onTap: () => ctrl.removeImage(index), tooltip: loc.btnDelete, color: AppColors.error),
        ]),
        const SizedBox(width: 4),
      ]),
    );
  }
}

class _TileBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap; final String tooltip; final Color? color;
  const _TileBtn({required this.icon, required this.onTap, required this.tooltip, this.color});
  @override
  Widget build(BuildContext context) => IconButton(icon: Icon(icon, size: 18, color: color ?? AppColors.textSecondary), onPressed: onTap, tooltip: tooltip, padding: const EdgeInsets.all(6));
}

class _SectionLabel extends StatelessWidget {
  final String text; final bool isDark;
  const _SectionLabel(this.text, this.isDark);
  @override
  Widget build(BuildContext context) => Text(text, style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 14, fontWeight: FontWeight.w700));
}

class _DropdownSetting<T> extends StatelessWidget {
  final String label; final T value; final List<T> items;
  final String Function(T) itemLabel; final bool isDark;
  final void Function(T) onChanged;
  const _DropdownSetting({required this.label, required this.value, required this.items, required this.itemLabel, required this.isDark, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: isDark ? AppColors.darkCard : AppColors.lightCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value, isExpanded: true,
            dropdownColor: isDark ? AppColors.darkCard : AppColors.lightSurface,
            style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
            items: items.map((v) => DropdownMenuItem(value: v, child: Text(itemLabel(v)))).toList(),
            onChanged: (v) { if (v != null) onChanged(v); },
          ),
        ),
      ),
    ]);
  }
}
