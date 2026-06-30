import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, String> _strings = {};

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  Future<void> load() async {
    final langCode = locale.languageCode == 'id' ? 'id' : 'en';
    final jsonStr = await rootBundle.loadString('assets/i18n/$langCode.json');
    final Map<String, dynamic> data = json.decode(jsonStr);
    _strings = data.map((key, val) => MapEntry(key, val.toString()));
  }

  String translate(String key) => _strings[key] ?? key;

  String get appTitle => translate('app_title');
  String get btnPdfToImage => translate('btn_pdf_to_image');
  String get btnImageToPdf => translate('btn_image_to_pdf');
  String get btnSettings => translate('btn_settings');
  String get btnConvert => translate('btn_convert');
  String get btnSavePdf => translate('btn_save_pdf');
  String get btnBrowse => translate('btn_browse');
  String get btnDone => translate('btn_done');
  String get btnOpenFolder => translate('btn_open_folder');
  String get btnMoveUp => translate('btn_move_up');
  String get btnMoveDown => translate('btn_move_down');
  String get btnRotate => translate('btn_rotate');
  String get btnDelete => translate('btn_delete');
  String get btnSelectAll => translate('btn_select_all');
  String get btnDeselectAll => translate('btn_deselect_all');
  String get dropPdfHint => translate('drop_pdf_hint');
  String get dropImageHint => translate('drop_image_hint');
  String get labelOutputFormat => translate('label_output_format');
  String get labelDpi => translate('label_dpi');
  String get labelQuality => translate('label_quality');
  String get labelOutputFolder => translate('label_output_folder');
  String get labelSameFolder => translate('label_same_folder');
  String get labelCustomFolder => translate('label_custom_folder');
  String get labelPaperSize => translate('label_paper_size');
  String get labelOrientation => translate('label_orientation');
  String get labelMargin => translate('label_margin');
  String get labelPortrait => translate('label_portrait');
  String get labelLandscape => translate('label_landscape');
  String get labelMarginNone => translate('label_margin_none');
  String get labelMarginSmall => translate('label_margin_small');
  String get labelMarginMedium => translate('label_margin_medium');
  String get labelMarginLarge => translate('label_margin_large');
  String get labelPreview => translate('label_preview');
  String get labelPage => translate('label_page');
  String get labelPages => translate('label_pages');
  String get labelImages => translate('label_images');
  String get settingsTitle => translate('settings_title');
  String get settingsTheme => translate('settings_theme');
  String get settingsThemeDark => translate('settings_theme_dark');
  String get settingsThemeLight => translate('settings_theme_light');
  String get settingsDefaultDpi => translate('settings_default_dpi');
  String get settingsDefaultQuality => translate('settings_default_quality');
  String get settingsRememberFolder => translate('settings_remember_folder');
  String get settingsLanguage => translate('settings_language');
  String get convertingTitle => translate('converting_title');
  String get convertingPage => translate('converting_page');
  String get convertingOf => translate('converting_of');
  String get doneTitle => translate('done_title');
  String get doneImagesCreated => translate('done_images_created');
  String get donePdfCreated => translate('done_pdf_created');
  String get errPdfCorrupt => translate('err_pdf_corrupt');
  String get errPdfPassword => translate('err_pdf_password');
  String get errFolderNotWritable => translate('err_folder_not_writable');
  String get errFileInUse => translate('err_file_in_use');
  String get errNoPagesSelected => translate('err_no_pages_selected');
  String get errNoImages => translate('err_no_images');
  String get errConversionFailed => translate('err_conversion_failed');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'id'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final loc = AppLocalizations(locale);
    await loc.load();
    return loc;
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
