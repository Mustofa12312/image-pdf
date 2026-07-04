import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../core/theme.dart';
import '../../services/converter_service.dart';
import '../widgets/drop_zone_widget.dart';
import '../widgets/progress_widgets.dart';

class ExtractPdfPage extends StatefulWidget {
  const ExtractPdfPage({super.key});
  @override
  State<ExtractPdfPage> createState() => _ExtractPdfPageState();
}

class _ExtractPdfPageState extends State<ExtractPdfPage> {
  String? _pdfPath;
  final TextEditingController _pagesCtrl = TextEditingController();
  bool _isConverting = false;
  int _progressCurrent = 0;
  int _progressTotal = 0;

  @override
  void dispose() {
    _pagesCtrl.dispose();
    super.dispose();
  }

  void _setPdf(List<String> paths) {
    if (paths.isNotEmpty) {
      setState(() {
        _pdfPath = paths.first;
      });
    }
  }

  Future<void> _extractPages() async {
    if (_pdfPath == null) return;
    
    final pagesStr = _pagesCtrl.text.trim();
    if (pagesStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter page numbers to extract.')));
      return;
    }
    
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Extracted PDF',
      fileName: 'extracted_pages.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    
    if (result == null) return;
    final outPath = result.endsWith('.pdf') ? result : '$result.pdf';

    setState(() {
      _isConverting = true;
      _progressCurrent = 0;
      _progressTotal = pagesStr.split(',').length; // rough estimate
    });

    try {
      await ConverterService.instance.extractPdfPages(
        inputPath: _pdfPath!,
        outputPath: outPath,
        pages: pagesStr,
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
        title: Text('Extract Pages', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      body: _isConverting
          ? Center(child: Padding(padding: const EdgeInsets.all(32), child: ProgressOverlay(current: _progressCurrent, total: _progressTotal)))
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Expanded(
                        child: _pdfPath == null
                            ? Padding(padding: const EdgeInsets.all(24), child: DropZoneWidget(isPdf: true, onFilesDropped: _setPdf))
                            : Center(
                                child: Container(
                                  padding: const EdgeInsets.all(32),
                                  margin: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 80, height: 80,
                                        decoration: BoxDecoration(color: AppColors.error.withAlpha(20), borderRadius: BorderRadius.circular(20)),
                                        child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 40),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(p.basename(_pdfPath!), style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      const Text('Source PDF Document', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                                      const SizedBox(height: 32),
                                      OutlinedButton.icon(
                                        onPressed: () => setState(() => _pdfPath = null),
                                        icon: const Icon(Icons.close_rounded, size: 16),
                                        label: const Text('Remove / Change File'),
                                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                VerticalDivider(width: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                SizedBox(
                  width: 280,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Extraction Settings', style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        const Text('Enter the page numbers you want to extract into a new PDF.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                        const SizedBox(height: 24),
                        Text('Pages (1-indexed)', style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _pagesCtrl,
                          style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'e.g. 1, 3, 5, 10',
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                            filled: true,
                            fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.error)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _pdfPath == null ? null : _extractPages,
                            icon: const Icon(Icons.find_in_page_rounded, size: 18),
                            label: const Text('Extract Pages'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
