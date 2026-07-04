import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/localization.dart';
import '../../services/converter_service.dart';
import '../widgets/drop_zone_widget.dart';
import '../widgets/progress_widgets.dart';
import '../controllers/settings_controller.dart';

class WordToImagePage extends StatefulWidget {
  const WordToImagePage({super.key});
  @override
  State<WordToImagePage> createState() => _WordToImagePageState();
}

class _WordToImagePageState extends State<WordToImagePage> {
  String? _wordPath;
  bool _isConverting = false;
  int _progressCurrent = 0;
  int _progressTotal = 0;

  String _outputFormat = 'png';
  int _dpi = 300;
  int _jpgQuality = 90;
  String _outputFolderMode = 'same';
  String? _customOutputFolder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsController>();
      setState(() {
        _dpi = settings.defaultDpi;
        _jpgQuality = settings.defaultQuality;
      });
    });
  }

  void _setWord(List<String> paths) {
    if (paths.isNotEmpty) {
      final ext = p.extension(paths.first).toLowerCase();
      if (ext == '.doc' || ext == '.docx') {
        setState(() {
          _wordPath = paths.first;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Word document (.doc or .docx)')));
      }
    }
  }

  Future<void> _convert() async {
    if (_wordPath == null) return;
    
    String outDir;
    if (_outputFolderMode == 'custom' && _customOutputFolder != null) {
      outDir = _customOutputFolder!;
    } else {
      outDir = p.dirname(_wordPath!);
    }

    setState(() {
      _isConverting = true;
      _progressCurrent = 0;
      _progressTotal = 0;
    });

    try {
      final result = await ConverterService.instance.convertWordToImages(
        wordPath: _wordPath!,
        outputDir: outDir,
        format: _outputFormat,
        dpi: _dpi,
        jpgQuality: _jpgQuality,
        onProgress: (c, t) {
          if (mounted) setState(() { _progressCurrent = c; _progressTotal = t; });
        },
      );
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => CompletionDialog(
            totalItems: result.totalItems,
            isPdf: false,
            outputPath: outDir,
            onDone: () => Navigator.pop(context),
            onOpenFolder: () {
              Navigator.pop(context);
              if (Platform.isLinux) Process.run('xdg-open', [outDir]);
              if (Platform.isWindows) Process.run('explorer', [outDir]);
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
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18), onPressed: () => Navigator.pop(context)),
        title: Text('Word to Image', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
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
                        child: _wordPath == null
                            ? Padding(padding: const EdgeInsets.all(24), child: DropZoneWidget(isPdf: false, isWord: true, onFilesDropped: _setWord))
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
                                        decoration: BoxDecoration(color: Colors.blue.withAlpha(20), borderRadius: BorderRadius.circular(20)),
                                        child: const Icon(Icons.description_rounded, color: Colors.blue, size: 40),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(p.basename(_wordPath!), style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      const Text('Source Word Document', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                                      const SizedBox(height: 32),
                                      OutlinedButton.icon(
                                        onPressed: () => setState(() => _wordPath = null),
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
                  width: 260,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Output Settings', style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        Text(loc.labelOutputFormat, style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: _FormatChip(label: 'PNG', selected: _outputFormat == 'png', isDark: isDark, onTap: () => setState(() => _outputFormat = 'png'))),
                          const SizedBox(width: 10),
                          Expanded(child: _FormatChip(label: 'JPG', selected: _outputFormat == 'jpg', isDark: isDark, onTap: () => setState(() => _outputFormat = 'jpg'))),
                        ]),
                        const SizedBox(height: 20),
                        
                        Text(loc.labelDpi, style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _dpi, isExpanded: true,
                              dropdownColor: isDark ? AppColors.darkCard : AppColors.lightSurface,
                              style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                              items: AppConstants.dpiOptions.map((v) => DropdownMenuItem(value: v, child: Text('$v DPI'))).toList(),
                              onChanged: (v) { if (v != null) setState(() => _dpi = v); },
                            ),
                          ),
                        ),
                        if (_outputFormat == 'jpg') ...[
                          const SizedBox(height: 20),
                          Text(loc.labelQuality, style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _jpgQuality, isExpanded: true,
                                dropdownColor: isDark ? AppColors.darkCard : AppColors.lightSurface,
                                style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                                items: AppConstants.qualityOptions.map((v) => DropdownMenuItem(value: v, child: Text('$v%'))).toList(),
                                onChanged: (v) { if (v != null) setState(() => _jpgQuality = v); },
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        
                        Text(loc.labelOutputFolder, style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        _FolderChip(label: loc.labelSameFolder, selected: _outputFolderMode == 'same', isDark: isDark, onTap: () => setState(() => _outputFolderMode = 'same')),
                        const SizedBox(height: 8),
                        _FolderChip(
                          label: _customOutputFolder != null ? _customOutputFolder!.split(RegExp(r'[/\\]')).last : loc.labelCustomFolder,
                          selected: _outputFolderMode == 'custom',
                          isDark: isDark,
                          onTap: () async {
                            final dir = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select output folder');
                            if (dir != null) setState(() { _outputFolderMode = 'custom'; _customOutputFolder = dir; });
                          },
                        ),

                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _wordPath == null ? null : _convert,
                            icon: const Icon(Icons.bolt_rounded, size: 18),
                            label: Text(loc.btnConvert),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
        child: Center(child: Text(label, style: TextStyle(color: selected ? Colors.white : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary), fontWeight: FontWeight.w600, fontSize: 13))),
      ),
    );
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
