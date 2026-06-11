import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/services/auth_service.dart';
import '../../../auth/services/auth_store.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../widgets/technician_menu_sheet.dart';

// ─────────────────────────────────────────────────────────
// Technician Home Screen
// ─────────────────────────────────────────────────────────

/// Pantalla principal del tecnico/prestador autenticado.
///
/// Similar al home del cliente pero con header adaptado:
/// logo + campana de notificaciones + menu hamburguesa (sin boton "Entrar").
class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  Map<String, dynamic>? _profileData;
  String _firstName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Semilla síncrona desde AuthStore (perfil ya cargado en el splash/login):
    // evita el parpadeo del nombre al entrar. Igual revalidamos en segundo plano.
    final cached = AuthStore.instance.value.profile;
    if (cached != null) {
      _profileData = cached;
      _firstName = _extractFirstName(cached);
      _isLoading = false;
    }
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AuthService().getMyTechnicianProfile();
      if (!mounted) return;
      AuthStore.instance.setAuthenticated(profile);
      setState(() {
        _profileData = profile;
        _firstName = _extractFirstName(profile);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _firstName = 'Profesional';
        _isLoading = false;
      });
    }
  }

  String _extractFirstName(Map<String, dynamic>? profile) {
    if (profile == null) return 'Profesional';
    final fullName =
        profile['full_name'] as String? ?? profile['name'] as String? ?? '';
    if (fullName.isEmpty) return 'Profesional';
    return fullName.split(' ').first;
  }

  Future<void> _handleRefresh() async {
    await _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _handleRefresh,
          edgeOffset: padding.top,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            child: Column(
              children: [
                // ════════════════════════════════════════════
                // ZONA HERO: gradient + header + burbuja + mascota
                // ════════════════════════════════════════════
                _HeroSection(
                  topPadding: padding.top,
                  firstName: _firstName,
                  isLoading: _isLoading,
                  profileData: _profileData,
                ),

                // ════════════════════════════════════════════
                // ZONA CONTENIDO: promo + explorar
                // ════════════════════════════════════════════
                const _ContentSection(),

                // Espacio para nav bar flotante
                SizedBox(height: padding.bottom + 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Hero Section: gradient + header + burbuja + mascota
// ─────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.topPadding,
    required this.firstName,
    required this.isLoading,
    this.profileData,
  });

  final double topPadding;
  final String firstName;
  final bool isLoading;
  final Map<String, dynamic>? profileData;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Fondo gradient: naranja cálido → rosa claro → blanco ──
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.gradientStart,
                AppColors.gradientEnd,
                Color(0xFFFDE8D0), // naranja claro transicion
                Colors.white,
              ],
              stops: [0.0, 0.35, 0.65, 1.0],
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: topPadding + 8),

              // ── Header: logo + campana + menu ──
              _TechnicianHeader(profileData: profileData),

              const SizedBox(height: 24),

              // ── Burbuja hero (saludo + buscador + categorias) ──
              _HeroBubble(firstName: firstName, isLoading: isLoading),

              const SizedBox(height: 16),

              // ── Mascota ──
              RepaintBoundary(
                child: SvgPicture.asset(
                  AppImages.mascot,
                  width: 160,
                  height: 160,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),

        // ── Curva inferior para transicion suave ──
        Positioned(
          left: 0,
          right: 0,
          bottom: -1,
          child: CustomPaint(
            size: const Size(double.infinity, 32),
            painter: _CurvedEdgePainter(color: AppColors.backgroundPrimary),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Header del tecnico: logo + campana + hamburguesa
// ─────────────────────────────────────────────────────────
class _TechnicianHeader extends StatelessWidget {
  const _TechnicianHeader({this.profileData});

  final Map<String, dynamic>? profileData;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingH,
        vertical: 6,
      ),
      child: Row(
        children: [
          // ── Logo SVG toke+ en blanco ──
          SvgPicture.asset(
            AppImages.logoTextSvg,
            height: 36,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),

          const Spacer(),

          // ── Campana de notificaciones ──
          _HeaderIconButton(
            icon: Icons.notifications_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NotificationsScreen(profileData: profileData),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ── Menu hamburguesa ──
          _HeaderIconButton(
            icon: Icons.menu_rounded,
            onTap: () =>
                showTechnicianMenuSheet(context, profileData: profileData),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        child: Center(child: Icon(icon, size: 22, color: Colors.white)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Hero Bubble: saludo + buscador + categorias
// ─────────────────────────────────────────────────────────
class _HeroBubble extends StatelessWidget {
  const _HeroBubble({required this.firstName, required this.isLoading});

  final String firstName;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingH,
      ),
      child: Column(
        children: [
          // ── Burbuja blanca ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Greeting ──
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isLoading
                      ? SizedBox(
                          height: 30,
                          child: Container(
                            width: 200,
                            decoration: BoxDecoration(
                              color: AppColors.neutral200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                      : Text(
                          '$firstName, ¿Algo que solucionar?',
                          key: ValueKey(firstName),
                          style: AppTypography.displaySmall.copyWith(
                            color: AppColors.secondaryDark,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Search bar placeholder ──
                Container(
                  width: double.infinity,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(color: AppColors.neutral200, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: AppColors.neutral500,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Buscar servicios...',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.neutral500,
                          ),
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.neutral200.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          color: AppColors.neutral600,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Category chips ──
                const _CategoryChips(),
              ],
            ),
          ),

          // ── Cola de burbuja (triangulo) ──
          CustomPaint(size: const Size(24, 12), painter: _BubbleTailPainter()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Chips de categorias horizontales
// ─────────────────────────────────────────────────────────
class _CategoryChips extends StatelessWidget {
  const _CategoryChips();

  static const _categories = [
    ('Albañilería', '🧱'),
    ('Electricidad', '⚡'),
    ('Pintura', '🎨'),
    ('Plomería', '🔧'),
    ('Jardinería', '🌿'),
    ('Aire Acond.', '❄️'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (_, index) {
          final (label, emoji) = _categories[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.neutral200.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.secondaryDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Content Section: promo + explorar
// ─────────────────────────────────────────────────────────
class _ContentSection extends StatelessWidget {
  const _ContentSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingH,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Promo banner: completar perfil ──
          const _ProfilePromoBanner(),

          const SizedBox(height: AppSpacing.xxl),

          // ── Seccion explorar ──
          const _ExploreSection(),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Banner promo: "Completá tu perfil"
// ─────────────────────────────────────────────────────────
class _ProfilePromoBanner extends StatelessWidget {
  const _ProfilePromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF87171), // rosa/rojo
            Color(0xFFEE7070), // primary
            Color(0xFFFB923C), // naranja
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completá tu perfil',
                  style: AppTypography.headingMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'y recibí más pedidos de clientes cerca tuyo.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    'Completar',
                    style: AppTypography.buttonMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Icono/ilustracion decorativa
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Center(
              child: Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Seccion Explorar (placeholder)
// ─────────────────────────────────────────────────────────
class _ExploreSection extends StatelessWidget {
  const _ExploreSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explorar',
          style: AppTypography.headingLarge.copyWith(
            color: AppColors.secondaryDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Servicios populares en tu zona.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            itemCount: _exploreItems.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              final item = _exploreItems[index];
              return _ExploreCard(
                title: item.$1,
                emoji: item.$2,
                color: item.$3,
              );
            },
          ),
        ),
      ],
    );
  }
}

const _exploreItems = [
  ('Electricidad', '⚡', Color(0xFFFFF3CD)),
  ('Plomería', '🔧', Color(0xFFD1ECF1)),
  ('Pintura', '🎨', Color(0xFFE2D9F3)),
  ('Limpieza', '🧹', Color(0xFFD4EDDA)),
];

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.title,
    required this.emoji,
    required this.color,
  });

  final String title;
  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.secondaryDark,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Painters
// ─────────────────────────────────────────────────────────

/// Cola/triangulo de la burbuja de dialogo.
class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    // Sombra suave
    canvas.drawShadow(path, Colors.black26, 4, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Curva inferior del hero para transicion suave a blanco.
class _CurvedEdgePainter extends CustomPainter {
  _CurvedEdgePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..quadraticBezierTo(size.width * 0.5, size.height * 1.3, 0, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CurvedEdgePainter old) => color != old.color;
}
