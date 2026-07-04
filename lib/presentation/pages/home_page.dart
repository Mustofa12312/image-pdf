import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import 'pdf_to_image_page.dart';
import 'image_to_pdf_page.dart';
import 'merge_pdf_page.dart';
import 'extract_pdf_page.dart';
import 'word_to_image_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Menu items definition
    final menuItems = [
      _MenuItem(
          icon: Icons.picture_as_pdf_rounded,
          iconColor: AppColors.accentOrange,
          label: loc.btnPdfToImage,
          subtitle: 'PDF → PNG / JPG',
          onTap: () => _push(context, const PdfToImagePage())),
      _MenuItem(
          icon: Icons.image_rounded,
          iconColor: AppColors.accentTeal,
          label: loc.btnImageToPdf,
          subtitle: 'PNG / JPG → PDF',
          onTap: () => _push(context, const ImageToPdfPage())),
      _MenuItem(
          icon: Icons.description_rounded,
          iconColor: Colors.blue,
          label: 'Word to Image',
          subtitle: 'DOC / DOCX → PNG / JPG',
          onTap: () => _push(context, const WordToImagePage())),
      _MenuItem(
          icon: Icons.merge_type_rounded,
          iconColor: AppColors.accentPrimary,
          label: 'Merge PDFs',
          subtitle: 'PDF + PDF → PDF',
          onTap: () => _push(context, const MergePdfPage())),
      _MenuItem(
          icon: Icons.find_in_page_rounded,
          iconColor: AppColors.error,
          label: 'Extract Pages',
          subtitle: 'Halaman tertentu',
          onTap: () => _push(context, const ExtractPdfPage())),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.bgGradient
              : const LinearGradient(
                  colors: [Color(0xFFF5F6FA), Color(0xFFEEEFF8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter),
        ),
        child: Stack(
          children: [
            if (isDark) ...[
              const Positioned(
                  top: -100,
                  left: -100,
                  child:
                      _GlowCircle(color: AppColors.accentPrimary, size: 400)),
              const Positioned(
                  bottom: -120,
                  right: -80,
                  child: _GlowCircle(color: AppColors.accentTeal, size: 350)),
            ],
            // Settings button top-right
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsPage())),
                icon: Icon(Icons.settings_rounded,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.lightTextSecondary),
                tooltip: loc.btnSettings,
                style: IconButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.darkCard : AppColors.lightSurface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
              ),
            ),
            // Main content — centered
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.accentPrimary.withAlpha(100),
                                blurRadius: 28,
                                spreadRadius: 4)
                          ],
                        ),
                        child: const Icon(Icons.swap_horiz_rounded,
                            color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 20),
                      Text(loc.appTitle,
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      Text('Fast • Offline • No Limits',
                          style: TextStyle(
                              color: isDark
                                  ? AppColors.textMuted
                                  : AppColors.lightTextSecondary,
                              fontSize: 11,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 40),

                      // Grid layout — 2 columns, centered
                      LayoutBuilder(builder: (context, constraints) {
                        final cardW = (constraints.maxWidth - 16) / 2;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: menuItems
                              .map((item) => SizedBox(
                                    width: cardW,
                                    child:
                                        _GridCard(item: item, isDark: isDark),
                                  ))
                              .toList(),
                        );
                      }),

                      const SizedBox(height: 36),
                      Text('Di Buat Oleh Mustofa ',
                          style: TextStyle(
                              color: isDark
                                  ? AppColors.textMuted
                                  : AppColors.lightTextSecondary,
                              fontSize: 18)),
                      Text('v1.0.0  •  100% Offline',
                          style: TextStyle(
                              color: isDark
                                  ? AppColors.textMuted
                                  : AppColors.lightTextSecondary,
                              fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, anim, __) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 280),
    ));
  }
}

class _MenuItem {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuItem(
      {required this.icon,
      required this.iconColor,
      required this.label,
      required this.subtitle,
      required this.onTap});
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowCircle({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration:
            BoxDecoration(shape: BoxShape.circle, color: color.withAlpha(18)),
      );
}

/// Square/card-style grid menu item (icon on top, label below)
class _GridCard extends StatefulWidget {
  final _MenuItem item;
  final bool isDark;
  const _GridCard({required this.item, required this.isDark});
  @override
  State<_GridCard> createState() => _GridCardState();
}

class _GridCardState extends State<_GridCard> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _hov
              ? (widget.isDark ? AppColors.darkCard : AppColors.lightSurface)
              : (widget.isDark ? AppColors.darkSurface : AppColors.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _hov
                  ? AppColors.accentPrimary.withAlpha(200)
                  : (widget.isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder),
              width: _hov ? 1.5 : 1),
          boxShadow: _hov
              ? [
                  BoxShadow(
                      color: AppColors.accentPrimary.withAlpha(35),
                      blurRadius: 24,
                      offset: const Offset(0, 6))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: widget.item.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon container
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: widget.item.iconColor.withAlpha(_hov ? 40 : 24),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(widget.item.icon,
                        color: widget.item.iconColor, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.item.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.isDark
                          ? AppColors.textPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.item.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.isDark
                          ? AppColors.textSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
