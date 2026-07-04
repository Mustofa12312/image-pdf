import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../core/theme.dart';
import '../../services/converter_service.dart';
import '../widgets/drop_zone_widget.dart';
import '../widgets/progress_widgets.dart';

class MergePdfPage extends StatefulWidget {
  const MergePdfPage({super.key});
  @override
  State<MergePdfPage> createState() => _MergePdfPageState();
}

class _MergePdfPageState extends State<MergePdfPage> {
  final List<String> _pdfPaths = [];
  bool _isConverting = false;
  int _progressCurrent = 0;
  int _progressTotal = 0;

  void _addPdfs(List<String> paths) {
    setState(() {
      for (final path in paths) {
        if (!_pdfPaths.contains(path)) {
          _pdfPaths.add(path);
        }
      }
    });
  }

  void _removePdf(int index) {
    setState(() {
      _pdfPaths.removeAt(index);
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _pdfPaths.removeAt(oldIndex);
      _pdfPaths.insert(newIndex, item);
    });
  }

  void _moveUp(int index) {
    if (index > 0) _reorder(index, index - 1);
  }

  void _moveDown(int index) {
    if (index < _pdfPaths.length - 1) _reorder(index, index + 2);
  }

  Future<void> _mergePdfs() async {
    if (_pdfPaths.length < 2) return;
    
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Merged PDF',
      fileName: 'merged_document.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    
    if (result == null) return;
    final outPath = result.endsWith('.pdf') ? result : '$result.pdf';

    setState(() {
      _isConverting = true;
      _progressCurrent = 0;
      _progressTotal = _pdfPaths.length;
    });

    try {
      await ConverterService.instance.mergePdfs(
        inputPaths: _pdfPaths,
        outputPath: outPath,
        onProgress: (c, t) {
          if (mounted) setState(() { _progressCurrent = c; _progressTotal = t; });
        },
      );
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => CompletionDialog(
            totalItems: 1,
            isPdf: true,
            outputPath: outPath,
            onDone: () => Navigator.pop(context),
            onOpenFolder: () {
              Navigator.pop(context);
              final dir = File(outPath).parent.path;
              if (Platform.isLinux) Process.run('xdg-open', [dir]);
              if (Platform.isWindows) Process.run('explorer', [dir]);
            },
          ),
        );
      }
    } on ConversionException catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => ErrorDialog(
            message: e.errorKey,
            onDismiss: () => Navigator.pop(context),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => ErrorDialog(
            message: 'err_conversion_failed',
            onDismiss: () => Navigator.pop(context),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConverting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18), onPressed: () => Navigator.pop(context)),
        title: Text('Merge PDFs', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      body: _isConverting
          ? Center(child: Padding(padding: const EdgeInsets.all(32), child: ProgressOverlay(current: _progressCurrent, total: _progressTotal)))
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(children: [
                    Expanded(
                      child: _pdfPaths.isEmpty
                          ? Padding(padding: const EdgeInsets.all(24), child: DropZoneWidget(isPdf: true, allowMultiplePdf: true, onFilesDropped: _addPdfs))
                          : _PdfList(paths: _pdfPaths, isDark: isDark, onReorder: _reorder, onRemove: _removePdf, onMoveUp: _moveUp, onMoveDown: _moveDown),
                    ),
                    if (_pdfPaths.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], allowMultiple: true);
                              if (result != null) {
                                _addPdfs(result.files.where((f) => f.path != null).map((f) => f.path!).toList());
                              }
                            },
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Add PDFs'),
                          ),
                        ]),
                      ),
                  ]),
                ),
                VerticalDivider(width: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                SizedBox(
                  width: 260,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Merge Settings', style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      const Text('Add two or more PDFs to merge them into a single document. Drag to reorder them.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _pdfPaths.length < 2 ? null : _mergePdfs,
                          icon: const Icon(Icons.merge_type_rounded, size: 18),
                          label: const Text('Merge PDFs'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.accentPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_pdfPaths.length} PDFs selected',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PdfList extends StatelessWidget {
  final List<String> paths;
  final bool isDark;
  final void Function(int, int) onReorder;
  final void Function(int) onRemove;
  final void Function(int) onMoveUp;
  final void Function(int) onMoveDown;
  
  const _PdfList({required this.paths, required this.isDark, required this.onReorder, required this.onRemove, required this.onMoveUp, required this.onMoveDown});

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: paths.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final path = paths[index];
        final fileName = p.basename(path);
        return Container(
          key: ValueKey(path + index.toString()),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Row(children: [
            const SizedBox(width: 8),
            const Icon(Icons.drag_handle_rounded, color: AppColors.textMuted, size: 20),
            const SizedBox(width: 12),
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.accentPrimary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.accentPrimary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(fileName, style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13), overflow: TextOverflow.ellipsis)),
            IconButton(icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 18), onPressed: () => onMoveUp(index), color: AppColors.textSecondary, tooltip: 'Move Up'),
            IconButton(icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18), onPressed: () => onMoveDown(index), color: AppColors.textSecondary, tooltip: 'Move Down'),
            IconButton(icon: const Icon(Icons.delete_rounded, size: 18), onPressed: () => onRemove(index), color: AppColors.error, tooltip: 'Remove'),
            const SizedBox(width: 8),
          ]),
        );
      },
    );
  }
}
