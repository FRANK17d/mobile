import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/insforge_client.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/services/auth_store.dart';
import '../../discover/screens/discover_screen.dart';
import '../../explore/screens/explore_screen.dart';
import '../../how_it_works/screens/how_it_works_screen.dart';
import '../../notifications/screens/client_notifications_screen.dart';
import '../../orders/screens/my_requests_screen.dart';
import '../../request_service/screens/order_review_screen.dart';
import '../../request_service/screens/request_service_wizard_screen.dart';
import '../../request_service/services/request_service.dart';
import '../../../auth/screens/account_prompt_screen.dart';
import '../widgets/client_menu_sheet.dart';
import '../widgets/hero_bubble.dart';
import '../widgets/home_mascot.dart';
import '../widgets/search_header.dart';
import '../widgets/social_media_section.dart';
import '../widgets/success_stories_section.dart';
import '../../../../core/widgets/navigation/app_menu_sheet.dart';
import '../../../technician/home/widgets/technician_menu_sheet.dart';
import '../../../technician/notifications/screens/notifications_screen.dart';

/// Pantalla principal del cliente.
///
/// Layout inspirado en Pimer: header, hero gradient con burbuja
/// de busqueda typewriter + categorias, mascota animada flotando,
/// y secciones de contenido debajo.
class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  // Estado leído de AuthStore de forma síncrona: el header arranca con el valor
  // correcto desde el primer frame (sin el parpadeo "no autenticado →
  // autenticado"). Reacciona en vivo a login/logout.
  AuthSnapshot _auth = AuthStore.instance.value;
  final RequestService _requestService = RequestService();
  List<MyRequest> _myRequests = const [];
  bool _loadingRequests = false;

  final List<VoidCallback> _rtUnsub = [];
  String? _clientChannel;

  @override
  void initState() {
    super.initState();
    AuthStore.instance.notifier.addListener(_onAuthChanged);
    RequestService.ordersChanged.addListener(_onOrdersChanged);
    if (_auth.isAuthenticated) {
      _loadMyRequests();
      _setupRealtime();
    }
  }

  @override
  void dispose() {
    AuthStore.instance.notifier.removeListener(_onAuthChanged);
    RequestService.ordersChanged.removeListener(_onOrdersChanged);
    _teardownRealtime();
    super.dispose();
  }

  /// Un pedido fue creado en otra pantalla: recarga la lista al volver.
  void _onOrdersChanged() {
    if (mounted && _auth.isAuthenticated) _loadMyRequests();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final auth = AuthStore.instance.value;
    setState(() {
      _auth = auth;
      if (!auth.isAuthenticated) _myRequests = const [];
    });
    if (auth.isAuthenticated) {
      _loadMyRequests();
      _setupRealtime();
    } else {
      _teardownRealtime();
    }
  }

  /// Suscribe el home al canal del cliente para reflejar en vivo cambios de
  /// estado (p. ej. cuando el admin aprueba/rechaza) y nuevas postulaciones.
  Future<void> _setupRealtime() async {
    if (_clientChannel != null) return; // ya configurado
    final rt = RealtimeService.instance;
    await rt.connect();
    final uid = await InsForgeClient().getCurrentUserId();
    if (uid == null || !mounted) return;
    _clientChannel = 'client:$uid';
    rt.subscribe(_clientChannel!);
    void refresh(Map<String, dynamic> _) {
      if (mounted) _loadMyRequests();
    }

    _rtUnsub.add(rt.on('status_changed', refresh));
    _rtUnsub.add(rt.on('new_application', refresh));
  }

  void _teardownRealtime() {
    for (final off in _rtUnsub) {
      off();
    }
    _rtUnsub.clear();
    if (_clientChannel != null) {
      RealtimeService.instance.unsubscribe(_clientChannel!);
      _clientChannel = null;
    }
  }

  Future<void> _loadMyRequests() async {
    if (mounted) setState(() => _loadingRequests = true);
    final list = await _requestService.getMyRequests();
    if (!mounted) return;
    setState(() {
      _myRequests = list;
      _loadingRequests = false;
    });
  }

  Future<void> _handleRefresh() async {
    if (_auth.isAuthenticated) await _loadMyRequests();
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
                // ZONA HERO: fondo gradient + burbuja + mascota
                // ════════════════════════════════════════════
                _HeroSection(
                  topPadding: padding.top,
                  isAuthenticated: _auth.isAuthenticated,
                  profileData: _auth.profile,
                  myRequests: _auth.isAuthenticated ? _myRequests : const [],
                  loadingOrders:
                      _auth.isAuthenticated &&
                      _loadingRequests &&
                      _myRequests.isEmpty,
                  onReloadOrders: _loadMyRequests,
                ),

                // ════════════════════════════════════════════
                // ZONA CONTENIDO: promos, tecnicos, etc.
                // ════════════════════════════════════════════
                const _ContentSection(),

                // Espacio para el nav bar flotante
                SizedBox(height: padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Hero Section: gradient + header + burbuja con carrusel + mascota
// ─────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.topPadding,
    this.isAuthenticated = false,
    this.profileData,
    this.myRequests = const [],
    this.loadingOrders = false,
    this.onReloadOrders,
  });

  final double topPadding;
  final bool isAuthenticated;
  final Map<String, dynamic>? profileData;
  final List<MyRequest> myRequests;
  final bool loadingOrders;
  final VoidCallback? onReloadOrders;

  /// Título del hero: con sesión usa el nombre del usuario; sin sesión, la
  /// pregunta genérica.
  String _heroTitle() {
    if (!isAuthenticated) return AppStrings.homeQuestion;
    final first = (profileData?['first_name'] as String?)?.trim() ?? '';
    if (first.isEmpty) return AppStrings.homeQuestion;
    return '$first, ¿Algo que solucionar?';
  }

  /// Abre el flujo "Pedir un servicio" (barra de búsqueda / ícono de cámara).
  /// Sin sesión muestra el prompt "¿Tenés una cuenta?".
  void _openRequestService(BuildContext context) {
    if (!isAuthenticated) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(builder: (_) => const AccountPromptScreen()),
      );
      return;
    }
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => const RequestServiceWizardScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Fondo gradient: rojo suave → blanco ──
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF4A0A0), // rojo suave arriba
                Color(0xFFFDE0E0), // rosa claro medio
                Colors.white, // blanco abajo
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: topPadding + 8),

              // ── Header: texto toke+ blanco + campana + menu ──
              Builder(
                builder: (ctx) => SearchHeader(
                  isAuthenticated: isAuthenticated,
                  onLoginTap: () => ctx.push(AppRoutes.login),
                  onMenuTap: () => isAuthenticated
                      ? (AuthStore.instance.value.isTechnician
                            ? showTechnicianMenuSheet(
                                ctx,
                                profileData: profileData,
                              )
                            : showClientMenuSheet(
                                ctx,
                                profileData: profileData,
                              ))
                      : showAppMenuSheet(ctx),
                  onNotificationTap: () =>
                      Navigator.of(ctx, rootNavigator: true).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AuthStore.instance.value.isTechnician
                              ? NotificationsScreen(
                                  profileData: AuthStore.instance.value.profile,
                                )
                              : const ClientNotificationsScreen(),
                        ),
                      ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Burbuja hero (pregunta + buscador + categorias) ──
              Builder(
                builder: (ctx) => HeroBubble(
                  title: _heroTitle(),
                  myRequests: myRequests,
                  loadingOrders: loadingOrders,
                  onSearchTap: () => _openRequestService(ctx),
                  onCameraTap: () => _openRequestService(ctx),
                  onOpenOrder: (req) => Navigator.of(ctx, rootNavigator: true)
                      .push(
                        MaterialPageRoute<void>(
                          builder: (_) => OrderReviewScreen(
                            requestId: req.id,
                            initial: req,
                          ),
                        ),
                      )
                      .then((_) => onReloadOrders?.call()),
                  onSeeAllOrders: () => Navigator.of(ctx, rootNavigator: true)
                      .push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MyRequestsScreen(),
                        ),
                      )
                      .then((_) => onReloadOrders?.call()),
                ),
              ),

              const SizedBox(height: 16),

              // ── Mascota animada ──
              const RepaintBoundary(child: HomeMascot(size: 110)),

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
// Content Section: explorar
// ─────────────────────────────────────────────────────────
class _ContentSection extends StatelessWidget {
  const _ContentSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          const _ExploreSection(),

          const SizedBox(height: 44),

          const SuccessStoriesSection(),

          const SizedBox(height: 44),

          const _HowItWorksSection(),

          const SizedBox(height: 44),

          const SocialMediaSection(),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Seccion Explorar
// ─────────────────────────────────────────────────────────
class _ExploreSection extends StatelessWidget {
  const _ExploreSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.neutral200)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                AppStrings.homeExplore,
                style: AppTypography.headingLarge.copyWith(
                  color: AppColors.neutral900,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.neutral200)),
          ],
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 220,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(child: _ExploreProvidersCard()),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _ExploreActionCard(
                        icon: Icons.question_mark_rounded,
                        label: '¿Cómo funciona?',
                        onTap: (ctx) => Navigator.of(ctx).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const HowItWorksScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _ExploreActionCard(
                        icon: Icons.tips_and_updates_outlined,
                        label: 'Descubrir',
                        onTap: (ctx) => Navigator.of(ctx).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const DiscoverScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExploreProvidersCard extends StatelessWidget {
  const _ExploreProvidersCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const ExploreScreen())),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.neutral50,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.neutral200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              flex: 7,
              child: Container(
                width: double.infinity,
                color: const Color(0xFFEFF1F7),
                padding: const EdgeInsets.only(top: 6),
                child: Image.asset(
                  'assets/images/explorar-section.webp',
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  cacheWidth: 400,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F8FC),
                  border: Border(top: BorderSide(color: AppColors.neutral200)),
                ),
                child: Text(
                  'Prestadores\nde servicios',
                  textAlign: TextAlign.center,
                  style: AppTypography.headingSmall.copyWith(
                    color: const Color(0xFF444A5F),
                    fontSize: 18,
                    height: 1.15,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreActionCard extends StatelessWidget {
  const _ExploreActionCard({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final void Function(BuildContext context)? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(context),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEDEFF6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.neutral800, size: 23),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.headingSmall.copyWith(
                      color: const Color(0xFF444A5F),
                      fontSize: 15,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              right: 8,
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.neutral500,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Seccion: Por que elegirnos (trust signals)
// ─────────────────────────────────────────────────────────
class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Por qué elegirnos?',
          style: AppTypography.headingLarge.copyWith(
            color: const Color(0xFF162033),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Confianza respaldada por resultados reales.',
          style: AppTypography.bodyLarge.copyWith(
            color: const Color(0xFF5F6678),
            fontSize: 12,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _TrustStat(
                icon: Icons.verified_rounded,
                value: '100%',
                label: 'Verificados',
                color: const Color(0xFF4A8FE7),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TrustStat(
                icon: Icons.schedule_rounded,
                value: '24/7',
                label: 'Disponibles',
                color: const Color(0xFFE8943A),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TrustStat(
                icon: Icons.shield_rounded,
                value: 'Seguro',
                label: 'Garantizado',
                color: const Color(0xFF4CAF7D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TrustStat(
                icon: Icons.star_rounded,
                value: '4.9',
                label: 'Calificación',
                color: const Color(0xFFF5A623),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TrustStat(
                icon: Icons.people_alt_rounded,
                value: '+500',
                label: 'Prestadores',
                color: const Color(0xFF7C5CFC),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TrustStat(
                icon: Icons.thumb_up_alt_rounded,
                value: '+2k',
                label: 'Servicios',
                color: const Color(0xFFE05A8D),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrustStat extends StatelessWidget {
  const _TrustStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.headingSmall.copyWith(
              color: const Color(0xFF162033),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.bodyLarge.copyWith(
              color: const Color(0xFF5F6678),
              fontSize: 10.5,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Pintor de curva inferior del hero
// ─────────────────────────────────────────────────────────
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
