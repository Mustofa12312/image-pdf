import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import 'pdf_to_image_page.dart';
import 'image_to_pdf_page.dart';
import 'merge_pdf_page.dart';
import 'extract_pdf_page.dart';
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
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.bgGradient
              : const LinearGradient(colors: [Color(0xFFF5F6FA), Color(0xFFEEEFF8)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Stack(
          children: [
            if (isDark) ...[
              const Positioned(top: -100, left: -100, child: _GlowCircle(color: AppColors.accentPrimary, size: 400)),
              const Positioned(bottom: -120, right: -80, child: _GlowCircle(color: AppColors.accentTeal, size: 350)),
            ],
            Positioned(top: 20, right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
                icon: Icon(Icons.settings_rounded, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                tooltip: loc.btnSettings,
                style: IconButton.styleFrom(backgroundColor: isDark ? AppColors.darkCard : AppColors.lightSurface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Container(
                          width: 88, height: 88,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: AppColors.accentPrimary.withAlpha(100), blurRadius: 30, spreadRadius: 4)],
                          ),
                          child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 28),
                        Text(loc.appTitle, style: Theme.of(context).textTheme.displayLarge, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text('Fast • Offline • No Limits',
                          style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.lightTextSecondary, fontSize: 12, letterSpacing: 1.5)),
                        const SizedBox(height: 48),
                        _MenuCard(
                          icon: Icons.picture_as_pdf_rounded, iconColor: AppColors.accentOrange,
                          label: loc.btnPdfToImage, subtitle: 'PDF → PNG / JPG', isDark: isDark,
                          onTap: () => _push(context, const PdfToImagePage()),
                        ),
                        const SizedBox(height: 16),
                        _MenuCard(
                          icon: Icons.image_rounded, iconColor: AppColors.accentTeal,
                          label: loc.btnImageToPdf, subtitle: 'PNG / JPG → PDF', isDark: isDark,
                          onTap: () => _push(context, const ImageToPdfPage()),
                        ),
                        const SizedBox(height: 16),
                        _MenuCard(
                          icon: Icons.merge_type_rounded, iconColor: AppColors.accentPrimary,
                          label: 'Merge PDFs', subtitle: 'PDF + PDF → PDF', isDark: isDark,
                          onTap: () => _push(context, const MergePdfPage()),
                        ),
                        const SizedBox(height: 16),
                        _MenuCard(
                          icon: Icons.find_in_page_rounded, iconColor: AppColors.error,
                          label: 'Extract Pages', subtitle: 'Extract specific pages from PDF', isDark: isDark,
                          onTap: () => _push(context, const ExtractPdfPage()),
                        ),
                        const SizedBox(height: 48),
                        Text('v1.0.0  •  100% Offline', style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.lightTextSecondary, fontSize: 11)),
                      ],
                    ),
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
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 280),
    ));
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color; final double size;
  const _GlowCircle({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color.withAlpha(18)),
  );
}

class _MenuCard extends StatefulWidget {
  final IconData icon; final Color iconColor;
  final String label, subtitle; final bool isDark;
  final VoidCallback onTap;
  const _MenuCard({required this.icon, required this.iconColor, required this.label, required this.subtitle, required this.isDark, required this.onTap});
  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _hov ? (widget.isDark ? AppColors.darkCard : AppColors.lightSurface) : (widget.isDark ? AppColors.darkSurface : AppColors.lightCard),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _hov ? AppColors.accentPrimary.withAlpha(200) : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder), width: _hov ? 1.5 : 1),
          boxShadow: _hov ? [BoxShadow(color: AppColors.accentPrimary.withAlpha(30), blurRadius: 20)] : [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: widget.onTap, borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: widget.iconColor.withAlpha(_hov ? 38 : 26), borderRadius: BorderRadius.circular(14)),
                  child: Icon(widget.icon, color: widget.iconColor, size: 26),
                ),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.label, style: TextStyle(color: widget.isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(widget.subtitle, style: TextStyle(color: widget.isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 12)),
                ]),
                const Spacer(),
                AnimatedOpacity(opacity: _hov ? 1.0 : 0.4, duration: const Duration(milliseconds: 180),
                  child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.accentPrimary)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
