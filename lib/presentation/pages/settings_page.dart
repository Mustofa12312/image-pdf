import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/localization.dart';
import '../controllers/settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<SettingsController>(
      builder: (context, ctrl, _) {
        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            elevation: 0,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18), onPressed: () => Navigator.pop(context)),
            title: Text(loc.settingsTitle, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
            bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Appearance section
                  _SectionHeader('Appearance', isDark),
                  const SizedBox(height: 12),
                  _SettingsCard(isDark: isDark, children: [
                    _SettingRow(
                      label: loc.settingsTheme,
                      isDark: isDark,
                      trailing: _SegmentedControl<ThemeMode>(
                        value: ctrl.themeMode,
                        options: const [ThemeMode.dark, ThemeMode.light],
                        labels: [loc.settingsThemeDark, loc.settingsThemeLight],
                        isDark: isDark,
                        onChanged: ctrl.setThemeMode,
                      ),
                    ),
                    _Divider(isDark),
                    _SettingRow(
                      label: loc.settingsLanguage,
                      isDark: isDark,
                      trailing: _SegmentedControl<String>(
                        value: ctrl.language,
                        options: const ['id', 'en'],
                        labels: const ['Indonesia', 'English'],
                        isDark: isDark,
                        onChanged: ctrl.setLanguage,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Conversion defaults
                  _SectionHeader('Conversion Defaults', isDark),
                  const SizedBox(height: 12),
                  _SettingsCard(isDark: isDark, children: [
                    _SettingRow(
                      label: loc.settingsDefaultDpi,
                      isDark: isDark,
                      trailing: _DropdownPicker<int>(
                        value: ctrl.defaultDpi,
                        items: AppConstants.dpiOptions,
                        itemLabel: (v) => '$v DPI',
                        isDark: isDark,
                        onChanged: ctrl.setDefaultDpi,
                      ),
                    ),
                    _Divider(isDark),
                    _SettingRow(
                      label: loc.settingsDefaultQuality,
                      isDark: isDark,
                      trailing: _DropdownPicker<int>(
                        value: ctrl.defaultQuality,
                        items: AppConstants.qualityOptions,
                        itemLabel: (v) => '$v%',
                        isDark: isDark,
                        onChanged: ctrl.setDefaultQuality,
                      ),
                    ),
                    _Divider(isDark),
                    _SettingRow(
                      label: loc.settingsRememberFolder,
                      isDark: isDark,
                      trailing: Switch(
                        value: ctrl.rememberFolder,
                        onChanged: ctrl.setRememberFolder,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // About
                  _SectionHeader('About', isDark),
                  const SizedBox(height: 12),
                  _SettingsCard(isDark: isDark, children: [
                    _SettingRow(label: 'Version', isDark: isDark, trailing: Text('1.0.0', style: TextStyle(color: AppColors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
                    _Divider(isDark),
                    _SettingRow(label: 'Platform', isDark: isDark, trailing: Text('Windows 10/11 x64', style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 13))),
                    _Divider(isDark),
                    _SettingRow(label: 'Engine', isDark: isDark, trailing: Text('Rust + PDFium', style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 13))),
                    _Divider(isDark),
                    _SettingRow(label: 'Internet Required', isDark: isDark, trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.success.withAlpha(26), borderRadius: BorderRadius.circular(6)),
                      child: const Text('Never', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                    )),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text; final bool isDark;
  const _SectionHeader(this.text, this.isDark);
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: TextStyle(color: AppColors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2));
}

class _SettingsCard extends StatelessWidget {
  final bool isDark; final List<Widget> children;
  const _SettingsCard({required this.isDark, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkCard : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
    ),
    child: Column(children: children),
  );
}

class _SettingRow extends StatelessWidget {
  final String label; final bool isDark; final Widget trailing;
  const _SettingRow({required this.label, required this.isDark, required this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    child: Row(children: [
      Text(label, style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 14)),
      const Spacer(),
      trailing,
    ]),
  );
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider(this.isDark);
  @override
  Widget build(BuildContext context) => Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder, indent: 20, endIndent: 20);
}

class _SegmentedControl<T> extends StatelessWidget {
  final T value; final List<T> options; final List<String> labels;
  final bool isDark; final void Function(T) onChanged;
  const _SegmentedControl({required this.value, required this.options, required this.labels, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(options.length, (i) {
        final selected = value == options[i];
        return GestureDetector(
          onTap: () => onChanged(options[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? AppColors.accentPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(labels[i], style: TextStyle(color: selected ? Colors.white : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary), fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        );
      })),
    );
  }
}

class _DropdownPicker<T> extends StatelessWidget {
  final T value; final List<T> items;
  final String Function(T) itemLabel; final bool isDark;
  final void Function(T) onChanged;
  const _DropdownPicker({required this.value, required this.items, required this.itemLabel, required this.isDark, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value, isDense: true,
          dropdownColor: isDark ? AppColors.darkCard : AppColors.lightSurface,
          style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
          items: items.map((v) => DropdownMenuItem(value: v, child: Text(itemLabel(v)))).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}
