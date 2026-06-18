import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../core/services/app_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../auth/services/auth_service.dart';
import 'credits_screen.dart';
import 'identity_verification_screen.dart';
import 'panel_screens.dart';
import 'technician_profile_preview_screen.dart';
import 'toke_pro_screen.dart';

void _pushAccountDetailScreen(BuildContext context, Widget screen) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

/// Pantalla de Cuenta del prestador de servicio.
///
/// Muestra perfil, panel profesional, card de perfil público,
/// promo TokePro, mis servicios y datos generales.
/// La primera vez muestra un overlay de guía (2 pasos).
class ProviderAccountScreen extends StatefulWidget {
  const ProviderAccountScreen({super.key});

  @override
  State<ProviderAccountScreen> createState() => _ProviderAccountScreenState();
}

class _ProviderAccountScreenState extends State<ProviderAccountScreen> {
  bool _showGuide = false;
  int _guideStep = 0;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authService = AuthService();
    final profile = await authService.getMyTechnicianProfile();
    if (mounted) {
      setState(() {
        _profileData = profile;
      });
    }
  }

  Future<void> _checkFirstTime() async {
    final shouldShow = await AppPreferences.shouldShowProviderGuide();
    if (shouldShow && mounted) {
      setState(() => _showGuide = true);
    }
  }

  void _nextGuideStep() {
    if (_guideStep < 1) {
      setState(() => _guideStep = 1);
    } else {
      _dismissGuide();
    }
  }

  Future<void> _dismissGuide() async {
    await AppPreferences.setShouldShowProviderGuide(false);
    if (mounted) setState(() => _showGuide = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Stack(
        children: [
          // ── Contenido principal ──
          _AccountContent(
            profileData: _profileData,
            onVerificationSubmitted: _loadProfile,
          ),

          // ── Overlay de guía (primera vez) ──
          if (_showGuide)
            _GuideOverlay(
              step: _guideStep,
              onNext: _nextGuideStep,
              onDismiss: _dismissGuide,
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CONTENIDO PRINCIPAL
// ═══════════════════════════════════════════════════════════
class _AccountContent extends StatelessWidget {
  const _AccountContent({
    this.profileData,
    required this.onVerificationSubmitted,
  });

  final Map<String, dynamic>? profileData;
  final Future<void> Function() onVerificationSubmitted;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header con gradient ──
            _ProfileHeader(topPadding: topPadding, profileData: profileData),

            // ── Cards de verificación ──
            _VerificationCards(
              profileData: profileData,
              onVerificationSubmitted: onVerificationSubmitted,
            ),

            const SizedBox(height: 16),

            // ── Botones de acción ──
            _ActionButtons(profileData: profileData),

            const SizedBox(height: 24),

            // ── Panel profesional ──
            _PanelProfesional(profileData: profileData),

            const SizedBox(height: 28),

            // ── Card de perfil público ──
            _PublicProfileCard(profileData: profileData),

            const SizedBox(height: 28),

            // ── Promo TokePro ──
            const _TokeProPromo(),

            const SizedBox(height: 28),

            // ── Mis servicios ──
            const _MisServicios(),

            const SizedBox(height: 28),

            // ── Datos generales ──
            const _DatosGenerales(),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// HEADER CON GRADIENT
// ═══════════════════════════════════════════════════════════
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.topPadding, this.profileData});

  final double topPadding;
  final Map<String, dynamic>? profileData;

  @override
  Widget build(BuildContext context) {
    final credits = _readCredits(profileData);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8B9DC3), Color(0xFFB8C6DB), Colors.white],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: topPadding + 12),

          // ── Top bar: campana + menú ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _HeaderIcon(icon: Icons.notifications_outlined),
                const SizedBox(width: 16),
                _HeaderIcon(icon: Icons.menu_rounded),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Avatar + créditos ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AvatarWithCamera(profileData: profileData),
              const SizedBox(width: 22),
              _CreditsPill(credits: credits),
            ],
          ),

          const SizedBox(height: 16),

          // ── Nombre ──
          Text(
            profileData != null
                ? '${profileData!['first_name'] ?? ''} ${profileData!['last_name'] ?? ''}'
                      .trim()
                : 'Cargando...',
            style: GoogleFonts.nunito(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          ),

          const SizedBox(height: 4),

          // ── Bio / ubicación ──
          Text(
            profileData?['technician']?['bio'] ?? 'Prestador de servicios',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF5F6678),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static int _readCredits(Map<String, dynamic>? profileData) {
    final technician = profileData?['technician'];
    final rawCredits =
        profileData?['credits'] ??
        profileData?['creditos'] ??
        (technician is Map
            ? technician['credits'] ?? technician['creditos']
            : null);

    if (rawCredits is int) return rawCredits;
    if (rawCredits is num) return rawCredits.toInt();
    if (rawCredits is String) return int.tryParse(rawCredits) ?? 0;
    return 0;
  }
}

class _AvatarWithCamera extends StatelessWidget {
  const _AvatarWithCamera({this.profileData});

  final Map<String, dynamic>? profileData;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF5C6B7F),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: profileData?['avatar_url'] != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: profileData!['avatar_url'] as String,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.person_outline_rounded,
                      size: 60,
                      color: Colors.white70,
                    ),
                  ),
                )
              : const Icon(
                  Icons.person_outline_rounded,
                  size: 60,
                  color: Colors.white70,
                ),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 18,
              color: Color(0xFF3A3F4B),
            ),
          ),
        ),
      ],
    );
  }
}

class _CreditsPill extends StatelessWidget {
  const _CreditsPill({required this.credits});

  final int credits;

  @override
  Widget build(BuildContext context) {
    final label = credits == 1 ? 'crédito' : 'créditos';

    return Container(
      padding: const EdgeInsets.fromLTRB(7, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            AppImages.tokeCoin,
            width: 42,
            height: 42,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 7),
          Text(
            '$credits $label',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.25),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CARDS DE VERIFICACIÓN
// ═══════════════════════════════════════════════════════════
class _VerificationCards extends StatelessWidget {
  const _VerificationCards({
    this.profileData,
    required this.onVerificationSubmitted,
  });

  final Map<String, dynamic>? profileData;
  final Future<void> Function() onVerificationSubmitted;

  Future<void> _openVerification(BuildContext context) async {
    final submitted = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) =>
            IdentityVerificationScreen(profileData: profileData),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );

    if (submitted == true) {
      await onVerificationSubmitted();
    }
  }

  String get _status {
    final technician = profileData?['technician'];
    if (technician is Map && technician['verification_status'] != null) {
      return technician['verification_status'].toString();
    }
    return 'pending';
  }

  String? get _rejectionReason {
    final technician = profileData?['technician'];
    if (technician is Map && technician['rejection_reason'] != null) {
      final reason = technician['rejection_reason'].toString().trim();
      return reason.isEmpty ? null : reason;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          switch (_status) {
            'verified' => const _VerificationCard(
              icon: Icons.verified_rounded,
              iconBgColor: AppColors.successLight,
              iconColor: AppColors.success,
              title: 'Identidad verificada',
              description: 'Tu cuenta ya puede postular a pedidos disponibles.',
            ),
            'rejected' => _VerificationCard(
              icon: Icons.error_outline_rounded,
              iconBgColor: AppColors.errorLight,
              iconColor: AppColors.error,
              title: 'Verificación rechazada',
              description:
                  _rejectionReason ??
                  'Reenvía fotos claras de tu DNI y una selfie para volver a revisión.',
              onTap: () => _openVerification(context),
            ),
            _ => _VerificationCard(
              icon: Icons.badge_outlined,
              iconBgColor: const Color(0xFFFFF3E0),
              iconColor: const Color(0xFFE65100),
              title: 'Verificá tu identidad',
              description:
                  'Sube tu DNI y una selfie para mantener segura la comunidad.',
              onTap: () => _openVerification(context),
            ),
          },
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.description,
    this.onTap,
  });

  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              // ── Ícono ──
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),

              const SizedBox(width: 14),

              // ── Texto ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF5F6678),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.neutral500,
                  size: 24,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// BOTONES DE ACCIÓN
// ═══════════════════════════════════════════════════════════
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({this.profileData});

  final Map<String, dynamic>? profileData;

  void _openCreditsScreen(BuildContext context) {
    _pushAccountDetailScreen(context, const CreditsScreen());
  }

  void _openTokeProScreen(BuildContext context) {
    _pushAccountDetailScreen(context, const TokeProScreen());
  }

  void _openPublicPreview(BuildContext context) {
    _pushAccountDetailScreen(
      context,
      TechnicianPublicPreviewScreen(profileData: profileData),
    );
  }

  void _openShareCard(BuildContext context) {
    _pushAccountDetailScreen(
      context,
      TechnicianShareCardScreen(profileData: profileData),
    );
  }

  void _handleMoreAction(BuildContext context, _AccountMenuAction action) {
    switch (action) {
      case _AccountMenuAction.viewAsClient:
        _openPublicPreview(context);
      case _AccountMenuAction.shareProfile:
        _openShareCard(context);
      case _AccountMenuAction.settings:
        showAppToast(
          context,
          message: 'Ajustes del perfil disponibles pronto',
          type: ToastType.info,
          icon: Icons.settings_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // ── Cargar créditos (primario) ──
          Expanded(
            child: Semantics(
              button: true,
              label: 'Cargar créditos',
              child: GestureDetector(
                onTap: () => _openCreditsScreen(context),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEE7070), Color(0xFFE85555)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Cargar créditos',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ── TokePro (outlined) ──
          Semantics(
            button: true,
            label: 'Ver TokePro',
            child: GestureDetector(
              onTap: () => _openTokeProScreen(context),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.neutral400),
                ),
                alignment: Alignment.center,
                child: Text(
                  'TokePro',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ── Más opciones ──
          PopupMenuButton<_AccountMenuAction>(
            offset: const Offset(0, 52),
            color: Colors.white,
            elevation: 12,
            shadowColor: AppColors.secondary.withValues(alpha: 0.14),
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            constraints: const BoxConstraints(minWidth: 246),
            onSelected: (action) => _handleMoreAction(context, action),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _AccountMenuAction.viewAsClient,
                child: _AccountPopupItem(
                  icon: Icons.visibility_outlined,
                  label: 'Ver como cliente',
                ),
              ),
              PopupMenuItem(
                value: _AccountMenuAction.shareProfile,
                child: _AccountPopupItem(
                  icon: Icons.share_outlined,
                  label: 'Compartir tu ficha',
                ),
              ),
              PopupMenuItem(
                value: _AccountMenuAction.settings,
                child: _AccountPopupItem(
                  icon: Icons.settings_outlined,
                  label: 'Ajustes',
                ),
              ),
            ],
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.neutral400),
              ),
              child: const Icon(
                Icons.more_vert_rounded,
                color: Color(0xFF3A3F4B),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _AccountMenuAction { viewAsClient, shareProfile, settings }

class _AccountPopupItem extends StatelessWidget {
  const _AccountPopupItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondaryDark, size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PANEL PROFESIONAL
// ═══════════════════════════════════════════════════════════
class _PanelProfesional extends StatelessWidget {
  const _PanelProfesional({this.profileData});

  final Map<String, dynamic>? profileData;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Título con divider ──
          Row(
            children: [
              Text(
                'Panel profesional',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Divider(color: AppColors.neutral300)),
            ],
          ),

          const SizedBox(height: 16),

          // ── Items ──
          _PanelItem(
            emoji: 'ℹ️',
            label: 'Editar mi información',
            trailing: _AttentionBadge(),
            onTap: () => _pushAccountDetailScreen(
              context,
              EditProfileScreen(profileData: profileData),
            ),
          ),
          _PanelItem(
            emoji: '🧰',
            label: 'Servicios y habilidades',
            onTap: () => _pushAccountDetailScreen(
              context,
              ServicesScreen(profileData: profileData),
            ),
          ),
          _PanelItem(
            emoji: '📍',
            label: 'Zona de cobertura',
            onTap: () => _pushAccountDetailScreen(
              context,
              CoverageZoneScreen(profileData: profileData),
            ),
          ),
          _PanelItem(
            emoji: '📷',
            label: 'Trabajos realizados',
            onTap: () => _pushAccountDetailScreen(
              context,
              WorkPhotosScreen(profileData: profileData),
            ),
          ),
          _PanelItem(
            emoji: '❓',
            label: 'Preguntas y respuestas',
            onTap: () => _pushAccountDetailScreen(
              context,
              QuestionsScreen(profileData: profileData),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelItem extends StatelessWidget {
  const _PanelItem({
    required this.emoji,
    required this.label,
    this.trailing,
    this.onTap,
  });

  final String emoji;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2E2E2E),
                ),
              ),
            ),
            if (trailing != null)
              trailing!
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.neutral500,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class _AttentionBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8E5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'Atención',
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFE85555),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CARD DE PERFIL PÚBLICO
// ═══════════════════════════════════════════════════════════
class _PublicProfileCard extends StatelessWidget {
  const _PublicProfileCard({this.profileData});

  final Map<String, dynamic>? profileData;

  String get _fullName {
    final first = profileData?['first_name'] ?? '';
    final last = profileData?['last_name'] ?? '';
    final name = '$first $last'.trim();
    return name.isEmpty ? 'Técnico' : name;
  }

  String get _district {
    final technician = profileData?['technician'];
    if (technician is Map) {
      final d = technician['district'] ?? technician['district_name'];
      if (d != null && d.toString().trim().isNotEmpty) return d.toString();
    }
    final d = profileData?['district'] ?? profileData?['district_name'];
    if (d != null && d.toString().trim().isNotEmpty) return d.toString();
    return 'Trujillo';
  }

  String? get _avatarUrl {
    final url = profileData?['avatar_url'] ?? profileData?['avatarUrl'];
    if (url is String && url.isNotEmpty) return url;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Chevron de navigación ──
          Align(
            alignment: Alignment.topRight,
            child: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.neutral500,
              size: 26,
            ),
          ),

          // ── Avatar centrado ──
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF5C6B7F),
            ),
            child: _avatarUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _avatarUrl!,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const Icon(
                        Icons.person_outline_rounded,
                        size: 44,
                        color: Colors.white70,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.person_outline_rounded,
                    size: 44,
                    color: Colors.white70,
                  ),
          ),

          const SizedBox(height: 14),

          // ── Nombre ──
          Text(
            _fullName,
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          ),

          const SizedBox(height: 4),

          // ── Ubicación ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 16, color: AppColors.neutral500),
              const SizedBox(width: 4),
              Text(
                _district,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: AppColors.neutral500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Botones ──
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pushAccountDetailScreen(
                    context,
                    TechnicianShareCardScreen(profileData: profileData),
                  ),
                  child: const _OutlinedPillButton(label: 'Compartir'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pushAccountDetailScreen(
                    context,
                    TechnicianPublicPreviewScreen(profileData: profileData),
                  ),
                  child: const _OutlinedPillButton(label: 'Ver mi perfil'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OutlinedPillButton extends StatelessWidget {
  const _OutlinedPillButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.neutral400),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2E2E2E),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PROMO TOKEPRO
// ═══════════════════════════════════════════════════════════
class _TokeProPromo extends StatelessWidget {
  const _TokeProPromo();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF0ED), Color(0xFFFFE2D9), Color(0xFFFFF5F2)],
        ),
      ),
      child: Column(
        children: [
          // ── Logo TokePro ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'toke+',
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  'Pro',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            '¿Aún no sos parte de TokePro?\nMirá todo lo que te estás perdiendo:',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3A3F4B),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          // ── Grid de beneficios (2 columnas) ──
          Row(
            children: const [
              Expanded(
                child: _BenefitItem(emoji: '🔝', label: 'Más visibilidad'),
              ),
              Expanded(
                child: _BenefitItem(emoji: '🪙', label: '200 Créditos'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: _BenefitItem(emoji: '🎯', label: 'Contacto directo'),
              ),
              Expanded(
                child: _BenefitItem(emoji: '🔍', label: 'Resaltado'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: _BenefitItem(emoji: '🔔', label: 'Notificaciones'),
              ),
              Expanded(
                child: _BenefitItem(emoji: '🚀', label: 'Servicios ilimitados'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Botón CTA ──
          Semantics(
            button: true,
            label: 'Adquirir plan TokePro',
            child: GestureDetector(
              onTap: () =>
                  _pushAccountDetailScreen(context, const TokeProScreen()),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2B4A),
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Adquirir plan TokePro',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2E2E2E),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MIS SERVICIOS
// ═══════════════════════════════════════════════════════════
class _MisServicios extends StatelessWidget {
  const _MisServicios();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mis servicios',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.neutral500,
                size: 26,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: const [
              _ServiceChip(
                emoji: '🔧',
                title: 'Plomero',
                subtitle: 'Plomería en general.',
              ),
              SizedBox(width: 12),
              _ServiceChip(
                emoji: '🏗️',
                title: 'Azulejista',
                subtitle: 'Instalación de pisos.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  final String emoji;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DATOS GENERALES
// ═══════════════════════════════════════════════════════════
class _DatosGenerales extends StatelessWidget {
  const _DatosGenerales();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Datos generales',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.neutral500,
                size: 26,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: const Color(0xFF2E2E2E),
                      height: 1.6,
                    ),
                    children: const [
                      TextSpan(
                        text: '0',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(text: ' Postulaciones hechas\n'),
                      TextSpan(
                        text: '0',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(text: ' Pedidos completados'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Te uniste hace un momento a Toke+',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// OVERLAY DE GUÍA (2 PASOS)
// ═══════════════════════════════════════════════════════════
class _GuideOverlay extends StatelessWidget {
  const _GuideOverlay({
    required this.step,
    required this.onNext,
    required this.onDismiss,
  });

  final int step;
  final VoidCallback onNext;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onNext,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withValues(alpha: 0.55),
        child: SafeArea(
          child: Column(
            children: [
              if (step == 0) ...[
                // Step 1: apunta al header del perfil
                const Spacer(flex: 3),
                _TooltipBubble(
                  title: 'Este es tu perfil',
                  description:
                      'Un resumen, tus insignias y más detalles como prestador de servicio.',
                  arrowOnTop: true,
                ),
                const Spacer(flex: 5),
              ] else ...[
                // Step 2: apunta al panel profesional
                const Spacer(flex: 4),
                _TooltipBubble(
                  title: '¡Completá tu perfil y aprovechá al máximo Toke+! 🚀',
                  description: '',
                  arrowOnTop: false,
                ),
                const Spacer(flex: 4),
              ],

              // ── Indicador de pasos ──
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StepDot(isActive: step == 0),
                    const SizedBox(width: 8),
                    _StepDot(isActive: step == 1),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TooltipBubble extends StatelessWidget {
  const _TooltipBubble({
    required this.title,
    required this.description,
    required this.arrowOnTop,
  });

  final String title;
  final String description;
  final bool arrowOnTop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (arrowOnTop) _BubbleArrow(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0ED),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF4A4A4A),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!arrowOnTop) _BubbleArrow(),
        ],
      ),
    );
  }
}

class _BubbleArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0.2, 0),
      child: CustomPaint(
        size: const Size(24, 12),
        painter: _ArrowPainter(color: const Color(0xFFFFF0ED)),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) => color != old.color;
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isActive ? 24 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
