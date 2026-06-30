class ConversionSettings {
  // PDF → Image settings
  final String outputFormat; // 'png' | 'jpg'
  final int dpi;
  final int jpgQuality;
  final String outputFolderMode; // 'same' | 'custom'
  final String? customOutputFolder;
  final List<int> selectedPages; // 1-indexed, empty = all

  // Image → PDF settings
  final String paperSize; // 'Original' | 'A4' | 'Letter'
  final String orientation; // 'Portrait' | 'Landscape'
  final String margin; // 'None' | 'Small' | 'Medium' | 'Large'

  const ConversionSettings({
    this.outputFormat = 'png',
    this.dpi = 300,
    this.jpgQuality = 90,
    this.outputFolderMode = 'same',
    this.customOutputFolder,
    this.selectedPages = const [],
    this.paperSize = 'A4',
    this.orientation = 'Portrait',
    this.margin = 'None',
  });

  ConversionSettings copyWith({
    String? outputFormat,
    int? dpi,
    int? jpgQuality,
    String? outputFolderMode,
    String? customOutputFolder,
    List<int>? selectedPages,
    String? paperSize,
    String? orientation,
    String? margin,
  }) {
    return ConversionSettings(
      outputFormat: outputFormat ?? this.outputFormat,
      dpi: dpi ?? this.dpi,
      jpgQuality: jpgQuality ?? this.jpgQuality,
      outputFolderMode: outputFolderMode ?? this.outputFolderMode,
      customOutputFolder: customOutputFolder ?? this.customOutputFolder,
      selectedPages: selectedPages ?? this.selectedPages,
      paperSize: paperSize ?? this.paperSize,
      orientation: orientation ?? this.orientation,
      margin: margin ?? this.margin,
    );
  }
}

class PdfPageInfo {
  final int pageNumber;
  final int width;
  final int height;

  const PdfPageInfo({
    required this.pageNumber,
    required this.width,
    required this.height,
  });

  factory PdfPageInfo.fromJson(Map<String, dynamic> json) {
    return PdfPageInfo(
      pageNumber: json['page_number'] as int,
      width: json['width'] as int,
      height: json['height'] as int,
    );
  }
}

class ConversionResult {
  final bool success;
  final int totalItems;
  final List<String> outputFiles;
  final String? errorCode;
  final String? errorMessage;

  const ConversionResult({
    required this.success,
    required this.totalItems,
    this.outputFiles = const [],
    this.errorCode,
    this.errorMessage,
  });

  factory ConversionResult.fromJson(Map<String, dynamic> json) {
    return ConversionResult(
      success: json['success'] as bool,
      totalItems: json['total_items'] as int? ?? 0,
      outputFiles: (json['output_files'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      errorCode: json['error_code'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }

  factory ConversionResult.error(String code, String message) {
    return ConversionResult(
      success: false,
      totalItems: 0,
      errorCode: code,
      errorMessage: message,
    );
  }
}

class ImageItem {
  final String path;
  int rotationDegrees; // 0, 90, 180, 270

  ImageItem({required this.path, this.rotationDegrees = 0});

  ImageItem copyWith({String? path, int? rotationDegrees}) {
    return ImageItem(
      path: path ?? this.path,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
    );
  }

  String get fileName {
    final parts = path.split(RegExp(r'[/\\]'));
    return parts.isNotEmpty ? parts.last : path;
  }
}
