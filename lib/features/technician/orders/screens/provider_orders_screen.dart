import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/navigation/app_menu_sheet.dart';

/// Pantalla de Pedidos del prestador de servicio.
///
/// Muestra pedidos disponibles, buscador, y historial.
class ProviderOrdersScreen extends StatelessWidget {
  const ProviderOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header oscuro con info de pedidos ──
              _OrdersHeader(topPadding: topPadding),

              const SizedBox(height: 20),

              // ── Buscador ──
              const _SearchBar(),

              const SizedBox(height: 28),

              // ── Historial de pedidos ──
              const _OrdersHistory(),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// HEADER OSCURO
// ═══════════════════════════════════════════════════════════
class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({required this.topPadding});

  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: topPadding + 12, bottom: 24),
      color: const Color(0xFF1D2939),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _HeaderIcon(icon: Icons.notifications_outlined),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => showAppMenuSheet(context),
                  child: _HeaderIcon(icon: Icons.menu_rounded),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Card de pedidos disponibles ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF2D3E50),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Saludo ──
                Text(
                  '¡Hola, José!',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),

                const SizedBox(height: 6),

                // ── Pedidos disponibles ──
                Row(
                  children: [
                    Text(
                      '40 Pedidos disponibles',
                      style: GoogleFonts.nunito(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34D399),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  '¿Listo para conectar? 📣',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),

                const SizedBox(height: 22),

                // ── Botón principal: Ver todos ──
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ver todos y postularme',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Botón secundario: Recomendados ──
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Recomendados para vos',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ],
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
        color: Colors.white.withValues(alpha: 0.1),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// BUSCADOR
// ═══════════════════════════════════════════════════════════
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: AppColors.neutral500, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Buscar por oficio, zona, y más...',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppColors.neutral500,
              ),
            ),
          ),
          Icon(Icons.tune_rounded, color: AppColors.neutral600, size: 22),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// HISTORIAL DE PEDIDOS
// ═══════════════════════════════════════════════════════════
class _OrdersHistory extends StatelessWidget {
  const _OrdersHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Título ──
          Row(
            children: [
              Text(
                'Historial de mis pedidos',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Divider(color: AppColors.neutral300)),
            ],
          ),

          const SizedBox(height: 18),

          // ── Cards de pedidos ──
          const _OrderCard(
            title: 'Albañil',
            description: 'Albañil.',
            location: 'Villeta',
            clientName: 'José L.',
            status: 'En revisión',
            orderNumber: 'N° 3976',
          ),

          const SizedBox(height: 12),

          const _OrderCard(
            title: 'Electricista',
            description: 'Instalación eléctrica.',
            location: 'Asunción',
            clientName: 'María C.',
            status: 'Completado',
            orderNumber: 'N° 3941',
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.title,
    required this.description,
    required this.location,
    required this.clientName,
    required this.status,
    required this.orderNumber,
  });

  final String title;
  final String description;
  final String location;
  final String clientName;
  final String status;
  final String orderNumber;

  @override
  Widget build(BuildContext context) {
    final isReview = status == 'En revisión';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Título + Nro ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              Text(
                orderNumber,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          // ── Descripción ──
          Text(
            description,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.neutral600,
            ),
          ),

          const SizedBox(height: 4),

          // ── Ubicación ──
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.neutral500,
              ),
              const SizedBox(width: 4),
              Text(
                location,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Divider(height: 1, color: AppColors.neutral200),

          const SizedBox(height: 12),

          // ── Footer: cliente + estado ──
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 18,
                color: AppColors.neutral600,
              ),
              const SizedBox(width: 6),
              Text(
                clientName,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2E2E2E),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isReview
                      ? const Color(0xFFFFF0ED)
                      : const Color(0xFFE8F8EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isReview
                        ? AppColors.primary
                        : const Color(0xFF2ECC71),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.neutral500,
                size: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
