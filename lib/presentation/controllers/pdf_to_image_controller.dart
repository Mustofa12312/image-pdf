import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import '../../services/converter_service.dart';

enum PdfToImageState { idle, loading, converting, done, error }

class PdfToImageController extends ChangeNotifier {
  PdfToImageState _state = PdfToImageState.idle;
  String? _pdfPath;
  List<PdfPageInfo> _pages = [];
  final Set<int> _selectedPages = {};
  ConversionSettings _settings = const ConversionSettings();
  int _progressCurrent = 0;
  int _progressTotal = 0;
  ConversionResult? _result;
  String? _errorKey;

  PdfToImageState get state => _state;
  String? get pdfPath => _pdfPath;
  List<PdfPageInfo> get pages => _pages;
  Set<int> get selectedPages => _selectedPages;
  ConversionSettings get settings => _settings;
  int get progressCurrent => _progressCurrent;
  int get progressTotal => _progressTotal;
  ConversionResult? get result => _result;
  String? get errorKey => _errorKey;
  bool get allSelected => _selectedPages.length == _pages.length;
  String? get outputDir {
    if (_settings.outputFolderMode == 'same' && _pdfPath != null) {
      return File(_pdfPath!).parent.path;
    }
    return _settings.customOutputFolder;
  }

  void applyDefaultSettings(int dpi, int quality) {
    _settings = _settings.copyWith(dpi: dpi, jpgQuality: quality);
    notifyListeners();
  }

  Future<void> loadPdf(String path) async {
    _state = PdfToImageState.loading;
    _pdfPath = path;
    _pages = [];
    _selectedPages.clear();
    _result = null;
    _errorKey = null;
    notifyListeners();

    try {
      _pages = await ConverterService.instance.getPdfInfo(path);
      _selectedPages.addAll(_pages.map((p) => p.pageNumber));
      _state = PdfToImageState.idle;
    } on ConversionException catch (e) {
      _errorKey = e.errorKey;
      _state = PdfToImageState.error;
    } catch (_) {
      _errorKey = 'err_pdf_corrupt';
      _state = PdfToImageState.error;
    }
    notifyListeners();
  }

  void togglePage(int pageNumber) {
    if (_selectedPages.contains(pageNumber)) {
      _selectedPages.remove(pageNumber);
    } else {
      _selectedPages.add(pageNumber);
    }
    notifyListeners();
  }

  void toggleSelectAll() {
    if (allSelected) {
      _selectedPages.clear();
    } else {
      _selectedPages.addAll(_pages.map((p) => p.pageNumber));
    }
    notifyListeners();
  }

  void updateSettings(ConversionSettings s) {
    _settings = s;
    notifyListeners();
  }

  Future<void> convert() async {
    if (_pdfPath == null || _selectedPages.isEmpty) {
      _errorKey = 'err_no_pages_selected';
      _state = PdfToImageState.error;
      notifyListeners();
      return;
    }
    final dir = outputDir;
    if (dir == null) {
      _errorKey = 'err_folder_not_writable';
      _state = PdfToImageState.error;
      notifyListeners();
      return;
    }

    _state = PdfToImageState.converting;
    _progressCurrent = 0;
    _progressTotal = _selectedPages.length;
    _result = null;
    _errorKey = null;
    notifyListeners();

    try {
      _result = await ConverterService.instance.convertPdfToImages(
        pdfPath: _pdfPath!,
        outputDir: dir,
        format: _settings.outputFormat,
        dpi: _settings.dpi,
        jpgQuality: _settings.jpgQuality,
        selectedPages: _selectedPages.toList()..sort(),
        onProgress: (c, t) {
          _progressCurrent = c;
          _progressTotal = t;
          notifyListeners();
        },
      );
      _state = PdfToImageState.done;
    } on ConversionException catch (e) {
      _errorKey = e.errorKey;
      _state = PdfToImageState.error;
    } catch (_) {
      _errorKey = 'err_conversion_failed';
      _state = PdfToImageState.error;
    }
    notifyListeners();
  }

  void reset() {
    _state = PdfToImageState.idle;
    _pdfPath = null;
    _pages = [];
    _selectedPages.clear();
    _result = null;
    _errorKey = null;
    _progressCurrent = 0;
    _progressTotal = 0;
    notifyListeners();
  }
}
