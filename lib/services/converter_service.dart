import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/models.dart';
import '../core/constants.dart';

typedef ProgressCallback = void Function(int current, int total);

class ConverterService {
  static ConverterService? _instance;
  static ConverterService get instance => _instance ??= ConverterService._();
  ConverterService._();

  /// Returns path to bundled Rust executable
  Future<String> _getExecutablePath() async {
    final execName = Platform.isWindows
        ? AppConstants.rustExecutableWindows
        : AppConstants.rustExecutableLinux;

    // During development, look next to the app executable
    final appDir = Platform.resolvedExecutable;
    final appDirParent = p.dirname(appDir);

    // Try locations in order
    final candidates = [
      p.join(appDirParent, execName),
      p.join(appDirParent, 'data', 'flutter_assets', execName),
      p.join(Directory.current.path, 'rust', 'target', 'release', execName),
      p.join(Directory.current.path, 'rust', 'target', 'debug', execName),
    ];

    for (final candidate in candidates) {
      if (File(candidate).existsSync()) return candidate;
    }

    throw Exception('Rust engine not found. Please build the Rust backend first.\n'
        'Run: cd rust && cargo build --release');
  }

  Map<String, String> _getEnvironment(String execPath) {
    if (Platform.isLinux) return {'LD_LIBRARY_PATH': p.dirname(execPath)};
    return {};
  }

  /// Get PDF page info (count, dimensions)
  Future<List<PdfPageInfo>> getPdfInfo(String pdfPath) async {
    final exec = await _getExecutablePath();
    final result = await Process.run(exec, ['info', '--input', pdfPath], environment: _getEnvironment(exec));
    if (result.exitCode != 0) {
      _throwRustError(result.stderr.toString());
    }
    final data = jsonDecode(result.stdout.toString()) as List;
    return data.map((e) => PdfPageInfo.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Convert PDF to images
  Future<ConversionResult> convertPdfToImages({
    required String pdfPath,
    required String outputDir,
    required String format,
    required int dpi,
    required int jpgQuality,
    required List<int> selectedPages,
    ProgressCallback? onProgress,
  }) async {
    final exec = await _getExecutablePath();

    final args = [
      'pdf2img',
      '--input', pdfPath,
      '--output-dir', outputDir,
      '--format', format,
      '--dpi', dpi.toString(),
      '--quality', jpgQuality.toString(),
      if (selectedPages.isNotEmpty) ...[
        '--pages',
        selectedPages.join(','),
      ],
      '--progress', // Rust will emit JSON progress to stdout
    ];

    final process = await Process.start(exec, args, environment: _getEnvironment(exec));
    int current = 0;
    int total = 0;
    final outputFiles = <String>[];

    // Listen to stdout for progress JSON lines
    await for (final line in process.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        final json = jsonDecode(trimmed) as Map<String, dynamic>;
        if (json['type'] == 'progress') {
          current = json['current'] as int;
          total = json['total'] as int;
          onProgress?.call(current, total);
        } else if (json['type'] == 'output') {
          outputFiles.add(json['file'] as String);
        } else if (json['type'] == 'result') {
          // Final result — parse it
          return ConversionResult.fromJson(json);
        }
      } catch (_) {
        // Non-JSON line, ignore
      }
    }

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      final errOut = await process.stderr.transform(utf8.decoder).join();
      _throwRustError(errOut);
    }

    return ConversionResult(
      success: true,
      totalItems: outputFiles.length,
      outputFiles: outputFiles,
    );
  }

  /// Convert images to PDF
  Future<ConversionResult> convertImagesToPdf({
    required List<ImageItem> images,
    required String outputPath,
    required String paperSize,
    required String orientation,
    required String margin,
    ProgressCallback? onProgress,
  }) async {
    final exec = await _getExecutablePath();

    final marginValue = AppConstants.marginValues[margin] ?? 0;

    final args = [
      'img2pdf',
      '--output', outputPath,
      '--paper', paperSize,
      '--orientation', orientation.toLowerCase(),
      '--margin', marginValue.toString(),
      '--progress',
      '--inputs',
      ...images.map((img) => '${img.path}:${img.rotationDegrees}'),
    ];

    final process = await Process.start(exec, args, environment: _getEnvironment(exec));
    final outputFiles = <String>[];

    await for (final line in process.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        final json = jsonDecode(trimmed) as Map<String, dynamic>;
        if (json['type'] == 'progress') {
          onProgress?.call(json['current'] as int, json['total'] as int);
        } else if (json['type'] == 'output') {
          outputFiles.add(json['file'] as String);
        } else if (json['type'] == 'result') {
          return ConversionResult.fromJson(json);
        }
      } catch (_) {}
    }

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      final errOut = await process.stderr.transform(utf8.decoder).join();
      _throwRustError(errOut);
    }

    return ConversionResult(
      success: true,
      totalItems: 1,
      outputFiles: [outputPath],
    );
  }

  /// Merge multiple PDFs into one
  Future<ConversionResult> mergePdfs({
    required List<String> inputPaths,
    required String outputPath,
    ProgressCallback? onProgress,
  }) async {
    final exec = await _getExecutablePath();
    final args = [
      'merge-pdf',
      '--output', outputPath,
      '--progress',
      '--inputs', ...inputPaths,
    ];

    final process = await Process.start(exec, args, environment: _getEnvironment(exec));
    final outputFiles = <String>[];

    await for (final line in process.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        final json = jsonDecode(trimmed) as Map<String, dynamic>;
        if (json['type'] == 'progress') {
          onProgress?.call(json['current'] as int, json['total'] as int);
        } else if (json['type'] == 'output') {
          outputFiles.add(json['file'] as String);
        } else if (json['type'] == 'result') {
          return ConversionResult.fromJson(json);
        }
      } catch (_) {}
    }

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      final errOut = await process.stderr.transform(utf8.decoder).join();
      _throwRustError(errOut);
    }

    return ConversionResult(
      success: true,
      totalItems: 1,
      outputFiles: [outputPath],
    );
  }

  /// Extract specific pages from a PDF
  Future<ConversionResult> extractPdfPages({
    required String inputPath,
    required String outputPath,
    required String pages,
    ProgressCallback? onProgress,
  }) async {
    final exec = await _getExecutablePath();
    final args = [
      'extract-pdf',
      '--input', inputPath,
      '--output', outputPath,
      '--pages', pages,
      '--progress',
    ];

    final process = await Process.start(exec, args, environment: _getEnvironment(exec));
    final outputFiles = <String>[];

    await for (final line in process.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        final json = jsonDecode(trimmed) as Map<String, dynamic>;
        if (json['type'] == 'progress') {
          onProgress?.call(json['current'] as int, json['total'] as int);
        } else if (json['type'] == 'output') {
          outputFiles.add(json['file'] as String);
        } else if (json['type'] == 'result') {
          return ConversionResult.fromJson(json);
        }
      } catch (_) {}
    }

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      final errOut = await process.stderr.transform(utf8.decoder).join();
      _throwRustError(errOut);
    }

    return ConversionResult(
      success: true,
      totalItems: 1,
      outputFiles: [outputPath],
    );
  }

  /// Convert Word to images
  Future<ConversionResult> convertWordToImages({
    required String wordPath,
    required String outputDir,
    required String format,
    required int dpi,
    required int jpgQuality,
    ProgressCallback? onProgress,
  }) async {
    final exec = await _getExecutablePath();

    final args = [
      'word2img',
      '--input', wordPath,
      '--output-dir', outputDir,
      '--format', format,
      '--dpi', dpi.toString(),
      '--quality', jpgQuality.toString(),
      '--progress',
    ];

    final process = await Process.start(exec, args, environment: _getEnvironment(exec));
    int current = 0;
    int total = 0;
    final outputFiles = <String>[];

    await for (final line in process.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        final json = jsonDecode(trimmed) as Map<String, dynamic>;
        if (json['type'] == 'progress') {
          current = json['current'] as int;
          total = json['total'] as int;
          onProgress?.call(current, total);
        } else if (json['type'] == 'output') {
          outputFiles.add(json['file'] as String);
        } else if (json['type'] == 'result') {
          return ConversionResult.fromJson(json);
        }
      } catch (_) {}
    }

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      final errOut = await process.stderr.transform(utf8.decoder).join();
      _throwRustError(errOut);
    }

    return ConversionResult(
      success: true,
      totalItems: outputFiles.length,
      outputFiles: outputFiles,
    );
  }

  void _throwRustError(String stderr) {
    if (stderr.contains('password')) throw const ConversionException('err_pdf_password');
    if (stderr.contains('corrupt') || stderr.contains('invalid')) throw const ConversionException('err_pdf_corrupt');
    if (stderr.contains('permission') || stderr.contains('writable')) throw const ConversionException('err_folder_not_writable');
    if (stderr.contains('in use') || stderr.contains('locked')) throw const ConversionException('err_file_in_use');
    if (stderr.trim().isNotEmpty) throw ConversionException(stderr.trim());
    throw const ConversionException('err_conversion_failed');
  }
}

class ConversionException implements Exception {
  final String errorKey;
  const ConversionException(this.errorKey);
}
