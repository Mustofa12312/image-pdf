class AppConstants {
  // DPI options for PDF → Image
  static const List<int> dpiOptions = [72, 150, 300, 600];
  static const int defaultDpi = 300;

  // JPG quality options
  static const List<int> qualityOptions = [50, 70, 90, 100];
  static const int defaultQuality = 90;

  // Paper sizes for Image → PDF
  static const List<String> paperSizes = ['Original', 'A4', 'Letter'];
  static const String defaultPaperSize = 'A4';

  // Orientations
  static const List<String> orientations = ['Portrait', 'Landscape'];
  static const String defaultOrientation = 'Portrait';

  // Margin options
  static const List<String> marginOptions = ['None', 'Small', 'Medium', 'Large'];
  static const String defaultMargin = 'None';

  // Margin values in points (72 points = 1 inch)
  static const Map<String, double> marginValues = {
    'None': 0,
    'Small': 18,
    'Medium': 36,
    'Large': 72,
  };

  // A4 dimensions in points
  static const double a4Width = 595.28;
  static const double a4Height = 841.89;

  // Letter dimensions in points
  static const double letterWidth = 612.0;
  static const double letterHeight = 792.0;

  // Supported image extensions
  static const List<String> imageExtensions = ['png', 'jpg', 'jpeg'];

  // Rust executable name
  static const String rustExecutableLinux = 'pdf_converter_engine';
  static const String rustExecutableWindows = 'pdf_converter_engine.exe';

  // SharedPreferences keys
  static const String prefTheme = 'theme_mode';
  static const String prefLanguage = 'language';
  static const String prefDefaultDpi = 'default_dpi';
  static const String prefDefaultQuality = 'default_quality';
  static const String prefRememberFolder = 'remember_folder';
  static const String prefLastFolder = 'last_folder';
}
