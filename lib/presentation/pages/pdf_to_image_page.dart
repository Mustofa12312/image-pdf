import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/localization.dart';
import '../controllers/pdf_to_image_controller.dart';
import '../controllers/settings_controller.dart';
import '../widgets/drop_zone_widget.dart';
import '../widgets/progress_widgets.dart';

class PdfToImagePage extends StatefulWidget {
  const PdfToImagePage({super.key});
  @override
  State<PdfToImagePage> createState() => _PdfToImagePageState();
}

class _PdfToImagePageState extends State<PdfToImagePage> {
  late final PdfToImageController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = PdfToImageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsController>();
      _ctrl.applyDefaultSettings(settings.defaultDpi, settings.defaultQuality);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Consumer<PdfToImageController>(
        builder: (context, ctrl, _) {
          // Show error dialog
          if (ctrl.state == PdfToImageState.error && ctrl.errorKey != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(context: context, builder: (_) => ErrorDialog(
                message: loc.translate(ctrl.errorKey!),
                onDismiss: () { Navigator.pop(context); ctrl.reset(); },
              ));
            });
          }
          // Show completion dialog
          if (ctrl.state == PdfToImageState.done && ctrl.result != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final outDir = ctrl.outputDir ?? '';
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => CompletionDialog(
                  totalItems: ctrl.result!.totalItems,
                  isPdf: false,
                  outputPath: outDir,
                  onDone: () { Navigator.pop(context); ctrl.reset(); },
                  onOpenFolder: () { Navigator.pop(context); _openFolder(outDir); ctrl.reset(); },
                ),
              );
            });
          }

          return Scaffold(
            backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
            appBar: AppBar(
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(loc.btnPdfToImage, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
              bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            ),
            body: ctrl.state == PdfToImageState.converting
                ? Center(child: Padding(padding: const EdgeInsets.all(32), child: ProgressOverlay(current: ctrl.progressCurrent, total: ctrl.progressTotal)))
                : _buildContent(context, ctrl, loc, isDark),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, PdfToImageController ctrl, AppLocalizations loc, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ctrl.pdfPath == null)
                  DropZoneWidget(isPdf: true, onFilesDropped: (paths) => ctrl.loadPdf(paths.first))
                else
                  _PdfInfo(path: ctrl.pdfPath!, onClear: ctrl.reset, isDark: isDark),
                if (ctrl.pages.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _PageSelector(ctrl: ctrl, loc: loc, isDark: isDark),
                ],
              ],
            ),
          ),
        ),
        // Divider
        VerticalDivider(width: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        // Right panel — settings
        SizedBox(
          width: 260,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel('Output Settings', isDark),
                const SizedBox(height: 16),
                _FormatSelector(ctrl: ctrl, loc: loc, isDark: isDark),
                const SizedBox(height: 20),
                _DropdownSetting<int>(
                  label: loc.labelDpi,
                  value: ctrl.settings.dpi,
                  items: AppConstants.dpiOptions,
                  itemLabel: (v) => '$v DPI',
                  isDark: isDark,
                  onChanged: (v) => ctrl.updateSettings(ctrl.settings.copyWith(dpi: v)),
                ),
                if (ctrl.settings.outputFormat == 'jpg') ...[
                  const SizedBox(height: 20),
                  _DropdownSetting<int>(
                    label: loc.labelQuality,
                    value: ctrl.settings.jpgQuality,
                    items: AppConstants.qualityOptions,
                    itemLabel: (v) => '$v%',
                    isDark: isDark,
                    onChanged: (v) => ctrl.updateSettings(ctrl.settings.copyWith(jpgQuality: v)),
                  ),
                ],
                const SizedBox(height: 20),
                _FolderSetting(ctrl: ctrl, loc: loc, isDark: isDark),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: ctrl.pages.isEmpty || ctrl.state == PdfToImageState.loading ? null : ctrl.convert,
                    icon: ctrl.state == PdfToImageState.loading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.bolt_rounded, size: 18),
                    label: Text(loc.btnConvert),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openFolder(String path) {
    if (Platform.isLinux) Process.run('xdg-open', [path]);
    if (Platform.isWindows) Process.run('explorer', [path]);
  }
}

class _PdfInfo extends StatelessWidget {
  final String path; final VoidCallback onClear; final bool isDark;
  const _PdfInfo({required this.path, required this.onClear, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final name = path.split(RegExp(r'[/\\]')).last;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentPrimary.withAlpha(100)),
      ),
      child: Row(children: [
        const Icon(Icons.picture_as_pdf_rounded, color: AppColors.accentOrange, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Text(name, style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
        IconButton(icon: const Icon(Icons.close_rounded, size: 16), onPressed: onClear, color: AppColors.textMuted),
      ]),
    );
  }
}

class _PageSelector extends StatelessWidget {
  final PdfToImageController ctrl; final AppLocalizations loc; final bool isDark;
  const _PageSelector({required this.ctrl, required this.loc, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('${ctrl.pages.length} ${loc.labelPages}', style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontWeight: FontWeight.w600)),
        const Spacer(),
        TextButton(onPressed: ctrl.toggleSelectAll, child: Text(ctrl.allSelected ? loc.btnDeselectAll : loc.btnSelectAll, style: const TextStyle(color: AppColors.accentPrimary, fontSize: 12))),
      ]),
      const SizedBox(height: 10),
      ListView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        itemCount: ctrl.pages.length,
        itemBuilder: (_, i) {
          final page = ctrl.pages[i];
          final selected = ctrl.selectedPages.contains(page.pageNumber);
          return InkWell(
            onTap: () => ctrl.togglePage(page.pageNumber),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.accentPrimary.withAlpha(26) : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? AppColors.accentPrimary.withAlpha(120) : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              ),
              child: Row(children: [
                Icon(selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, size: 18, color: selected ? AppColors.accentPrimary : AppColors.textMuted),
                const SizedBox(width: 10),
                Text('${loc.labelPage} ${page.pageNumber}', style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13)),
                const Spacer(),
                Text('${page.width}×${page.height}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ]),
            ),
          );
        },
      ),
    ]);
  }
}

class _FormatSelector extends StatelessWidget {
  final PdfToImageController ctrl; final AppLocalizations loc; final bool isDark;
  const _FormatSelector({required this.ctrl, required this.loc, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Label(loc.labelOutputFormat, isDark),
      const SizedBox(height: 8),
      Row(children: [
        _FormatChip(label: 'PNG', selected: ctrl.settings.outputFormat == 'png', isDark: isDark, onTap: () => ctrl.updateSettings(ctrl.settings.copyWith(outputFormat: 'png'))),
        const SizedBox(width: 10),
        _FormatChip(label: 'JPG', selected: ctrl.settings.outputFormat == 'jpg', isDark: isDark, onTap: () => ctrl.updateSettings(ctrl.settings.copyWith(outputFormat: 'jpg'))),
      ]),
    ]);
  }
}

class _FormatChip extends StatelessWidget {
  final String label; final bool selected, isDark; final VoidCallback onTap;
  const _FormatChip({required this.label, required this.selected, required this.isDark, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.accentPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary), fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}

class _DropdownSetting<T> extends StatelessWidget {
  final String label; final T value; final List<T> items;
  final String Function(T) itemLabel; final bool isDark;
  final void Function(T) onChanged;
  const _DropdownSetting({required this.label, required this.value, required this.items, required this.itemLabel, required this.isDark, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Label(label, isDark),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
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

class _FolderSetting extends StatelessWidget {
  final PdfToImageController ctrl; final AppLocalizations loc; final bool isDark;
  const _FolderSetting({required this.ctrl, required this.loc, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Label(loc.labelOutputFolder, isDark),
      const SizedBox(height: 8),
      _FolderChip(label: loc.labelSameFolder, selected: ctrl.settings.outputFolderMode == 'same', isDark: isDark, onTap: () => ctrl.updateSettings(ctrl.settings.copyWith(outputFolderMode: 'same'))),
      const SizedBox(height: 8),
      _FolderChip(
        label: ctrl.settings.customOutputFolder != null ? ctrl.settings.customOutputFolder!.split(RegExp(r'[/\\]')).last : loc.labelCustomFolder,
        selected: ctrl.settings.outputFolderMode == 'custom',
        isDark: isDark,
        onTap: () async {
          final dir = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select output folder');
          if (dir != null) ctrl.updateSettings(ctrl.settings.copyWith(outputFolderMode: 'custom', customOutputFolder: dir));
        },
      ),
    ]);
  }
}

class _FolderChip extends StatelessWidget {
  final String label; final bool selected, isDark; final VoidCallback onTap;
  const _FolderChip({required this.label, required this.selected, required this.isDark, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentPrimary.withAlpha(26) : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.accentPrimary.withAlpha(150) : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        ),
        child: Row(children: [
          Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded, size: 16, color: selected ? AppColors.accentPrimary : AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 12), overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text; final bool isDark;
  const _SectionLabel(this.text, this.isDark);
  @override
  Widget build(BuildContext context) => Text(text, style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 14, fontWeight: FontWeight.w700));
}

class _Label extends StatelessWidget {
  final String text; final bool isDark;
  const _Label(this.text, this.isDark);
  @override
  Widget build(BuildContext context) => Text(text, style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 12, fontWeight: FontWeight.w500));
}
