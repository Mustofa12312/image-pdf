import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';

class DropZoneWidget extends StatefulWidget {
  final bool isPdf; // true = PDF, false = images
  final void Function(List<String> paths) onFilesDropped;

  const DropZoneWidget({
    super.key,
    required this.isPdf,
    required this.onFilesDropped,
  });

  @override
  State<DropZoneWidget> createState() => _DropZoneWidgetState();
}

class _DropZoneWidgetState extends State<DropZoneWidget> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = _isDragging ? AppColors.accentPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final bgColor = _isDragging
        ? AppColors.accentPrimary.withAlpha(20)
        : (isDark ? AppColors.darkCard.withAlpha(128) : AppColors.lightCard);

    return DropTarget(
      onDragDone: (detail) {
        final paths = detail.files.map((f) => f.path).toList();
        if (widget.isPdf) {
          final pdf = paths.where((p) => p.toLowerCase().endsWith('.pdf')).toList();
          if (pdf.isNotEmpty) widget.onFilesDropped([pdf.first]);
        } else {
          final imgs = paths
              .where((p) => RegExp(r'\.(png|jpg|jpeg)$', caseSensitive: false).hasMatch(p))
              .toList();
          if (imgs.isNotEmpty) widget.onFilesDropped(imgs);
        }
        setState(() => _isDragging = false);
      },
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: _isDragging ? 2 : 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: InkWell(
          onTap: _browse,
          borderRadius: BorderRadius.circular(16),
          hoverColor: AppColors.accentPrimary.withAlpha(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: _isDragging ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: _isDragging ? AppColors.primaryGradient : null,
                    color: _isDragging ? null : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                    size: 26,
                    color: _isDragging ? Colors.white : AppColors.accentPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.isPdf ? loc.dropPdfHint : loc.dropImageHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 10),
              _BrowseButton(onTap: _browse, label: loc.btnBrowse),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _browse() async {
    if (widget.isPdf) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        dialogTitle: 'Select PDF file',
      );
      if (result != null && result.files.single.path != null) {
        widget.onFilesDropped([result.files.single.path!]);
      }
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
        allowMultiple: true,
        dialogTitle: 'Select Images',
      );
      if (result != null) {
        final paths = result.files.where((f) => f.path != null).map((f) => f.path!).toList();
        if (paths.isNotEmpty) widget.onFilesDropped(paths);
      }
    }
  }
}

class _BrowseButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _BrowseButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.accentPrimary, width: 1),
        ),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}
