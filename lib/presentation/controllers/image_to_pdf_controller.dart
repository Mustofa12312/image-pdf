import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import '../../services/converter_service.dart';
import '../../core/constants.dart';

enum ImageToPdfState { idle, converting, done, error }

class ImageToPdfController extends ChangeNotifier {
  ImageToPdfState _state = ImageToPdfState.idle;
  final List<ImageItem> _images = [];
  ConversionSettings _settings = const ConversionSettings();
  int _progressCurrent = 0;
  int _progressTotal = 0;
  ConversionResult? _result;
  String? _errorKey;
  String? _lastOutputPath;

  ImageToPdfState get state => _state;
  List<ImageItem> get images => List.unmodifiable(_images);
  ConversionSettings get settings => _settings;
  int get progressCurrent => _progressCurrent;
  int get progressTotal => _progressTotal;
  ConversionResult? get result => _result;
  String? get errorKey => _errorKey;
  String? get lastOutputPath => _lastOutputPath;

  void addImages(List<String> paths) {
    final validPaths = paths.where((p) {
      final ext = p.split('.').last.toLowerCase();
      return AppConstants.imageExtensions.contains(ext);
    });
    _images.addAll(validPaths.map((p) => ImageItem(path: p)));
    notifyListeners();
  }

  void removeImage(int index) {
    if (index >= 0 && index < _images.length) {
      _images.removeAt(index);
      notifyListeners();
    }
  }

  void reorderImages(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex--;
    final item = _images.removeAt(oldIndex);
    _images.insert(newIndex, item);
    notifyListeners();
  }

  void moveUp(int index) {
    if (index > 0) {
      final item = _images.removeAt(index);
      _images.insert(index - 1, item);
      notifyListeners();
    }
  }

  void moveDown(int index) {
    if (index < _images.length - 1) {
      final item = _images.removeAt(index);
      _images.insert(index + 1, item);
      notifyListeners();
    }
  }

  void rotateImage(int index) {
    if (index >= 0 && index < _images.length) {
      _images[index] = _images[index].copyWith(
        rotationDegrees: (_images[index].rotationDegrees + 90) % 360,
      );
      notifyListeners();
    }
  }

  void updateSettings(ConversionSettings s) {
    _settings = s;
    notifyListeners();
  }

  Future<void> savePdf() async {
    if (_images.isEmpty) {
      _errorKey = 'err_no_images';
      _state = ImageToPdfState.error;
      notifyListeners();
      return;
    }

    // Open save dialog
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save PDF',
      fileName: 'output.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (outputPath == null) return;

    _state = ImageToPdfState.converting;
    _progressCurrent = 0;
    _progressTotal = _images.length;
    _result = null;
    _errorKey = null;
    notifyListeners();

    try {
      _result = await ConverterService.instance.convertImagesToPdf(
        images: _images,
        outputPath: outputPath,
        paperSize: _settings.paperSize,
        orientation: _settings.orientation,
        margin: _settings.margin,
        onProgress: (c, t) {
          _progressCurrent = c;
          _progressTotal = t;
          notifyListeners();
        },
      );
      _lastOutputPath = outputPath;
      _state = ImageToPdfState.done;
    } on ConversionException catch (e) {
      _errorKey = e.errorKey;
      _state = ImageToPdfState.error;
    } catch (_) {
      _errorKey = 'err_conversion_failed';
      _state = ImageToPdfState.error;
    }
    notifyListeners();
  }

  void reset() {
    _state = ImageToPdfState.idle;
    _images.clear();
    _result = null;
    _errorKey = null;
    _progressCurrent = 0;
    _progressTotal = 0;
    _lastOutputPath = null;
    notifyListeners();
  }
}
