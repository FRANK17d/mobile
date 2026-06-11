import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _packages = [
    _CreditPackage(
      credits: 10,
      price: 'S/ 15.00',
      asset: AppImages.coinPackSmall,
    ),
    _CreditPackage(
      credits: 20,
      price: 'S/ 25.00',
      oldPrice: 'S/ 30.00',
      discount: '17% de descuento',
      asset: AppImages.coinPackMedium,
    ),
    _CreditPackage(
      credits: 40,
      price: 'S/ 40.00',
      oldPrice: 'S/ 60.00',
      discount: '33% de descuento',
      asset: AppImages.coinPackLarge,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Stack(
          children: [
            const _CreditsBackground(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingH,
                  0,
                  AppSpacing.screenPaddingH,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: topPadding > 0 ? 10 : 18),
                    _AnimatedIn(
                      controller: _controller,
                      begin: 0,
                      end: 0.42,
                      offset: const Offset(0, -0.18),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _CloseButton(
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _AnimatedIn(
                      controller: _controller,
                      begin: 0.06,
                      end: 0.5,
                      offset: const Offset(0, 0.18),
                      child: Center(
                        child: Text(
                          'Créditos',
                          style: AppTypography.displayLarge.copyWith(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondaryDark,
                            letterSpacing: -1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.massive),
                    _AnimatedIn(
                      controller: _controller,
                      begin: 0.14,
                      end: 0.58,
                      child: Text(
                        'Comprar paquetes:',
                        style: AppTypography.headingSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ...List.generate(_packages.length, (index) {
                      final pack = _packages[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == _packages.length - 1
                              ? 0
                              : AppSpacing.xl,
                        ),
                        child: _AnimatedIn(
                          controller: _controller,
                          begin: 0.2 + (index * 0.08),
                          end: 0.72 + (index * 0.06),
                          offset: const Offset(0, 0.22),
                          child: _CreditPackageCard(package: pack),
                        ),
                      );
                    }),
                    const SizedBox(height: 96),
                    _AnimatedIn(
                      controller: _controller,
                      begin: 0.48,
                      end: 0.96,
                      offset: const Offset(0, 0.16),
                      child: const _WalletHero(),
                    ),
                    const SizedBox(height: AppSpacing.massive),
                    _AnimatedIn(
                      controller: _controller,
                      begin: 0.56,
                      end: 1,
                      offset: const Offset(0, 0.12),
                      child: const _CreditsInfo(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditsBackground extends StatelessWidget {
  const _CreditsBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE2D9), AppColors.backgroundPrimary],
              stops: [0, 0.42],
            ),
          ),
        ),
        Positioned(
          top: -34,
          right: 86,
          child: _GhostCoin(size: 94, opacity: 0.12),
        ),
        Positioned(
          top: 174,
          left: -20,
          child: _GhostCoin(size: 88, opacity: 0.1),
        ),
        Positioned(
          top: 218,
          right: 22,
          child: _GhostCoin(size: 70, opacity: 0.13),
        ),
        Positioned(
          top: 690,
          right: -8,
          child: _GhostCoin(size: 76, opacity: 0.12),
        ),
      ],
    );
  }
}

class _GhostCoin extends StatelessWidget {
  const _GhostCoin({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Image.asset(
        AppImages.tokeCoin,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Cerrar pantalla de créditos',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.close_rounded,
            color: AppColors.secondaryDark,
            size: 34,
          ),
        ),
      ),
    );
  }
}

class _CreditPackageCard extends StatelessWidget {
  const _CreditPackageCard({required this.package});

  final _CreditPackage package;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 104),
          padding: const EdgeInsets.fromLTRB(26, 18, 20, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset(
                package.asset,
                width: 92,
                height: 74,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${package.credits}',
                            style: AppTypography.displaySmall.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.gradientEnd,
                            ),
                          ),
                          TextSpan(
                            text: ' créditos',
                            style: AppTypography.headingLarge.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            package.price,
                            style: AppTypography.headingLarge.copyWith(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: AppColors.secondaryDark,
                            ),
                          ),
                        ),
                        if (package.oldPrice != null) ...[
                          const SizedBox(width: 10),
                          Text(
                            package.oldPrice!,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textTertiary,
                              decoration: TextDecoration.lineThrough,
                              decorationThickness: 1.6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (package.discount != null)
          Positioned(
            top: -16,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF009688),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF009688).withValues(alpha: 0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Text(
                package.discount!,
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WalletHero extends StatelessWidget {
  const _WalletHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 245,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 142,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                AppImages.walletCredits,
                height: 245,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditsInfo extends StatelessWidget {
  const _CreditsInfo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tu billetera de Créditos',
          style: AppTypography.displaySmall.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.secondaryDark,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'En Toke+ usamos un sistema de créditos para que los prestadores de servicios puedan postularse a los pedidos de los clientes.',
          style: AppTypography.headingSmall.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.38,
            color: AppColors.secondaryDark,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        const _InfoRow(
          icon: Icons.paid_outlined,
          title: null,
          body:
              'Registrate gratis y arranca con 7 créditos de regalo. Solo usás créditos cuando te postulás a un pedido. Invertís solo cuando querés conectar con nuevos clientes. Así de simple.',
        ),
        const SizedBox(height: AppSpacing.xxl),
        const _InfoRow(
          icon: Icons.push_pin_outlined,
          title: 'Un crédito = oportunidad',
          body:
              'Cada crédito es una oportunidad laboral. Como prestador de servicio competís de forma transparente para tomar un pedido.',
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Usá tus créditos con inteligencia, postulándote a los trabajos que se ajustan a tu perfil. Cada crédito bien usado es una oportunidad real de generar ingresos.',
          style: AppTypography.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.42,
            color: AppColors.secondaryDark,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String? title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.24),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 30),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: AppTypography.headingLarge.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondaryDark,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                body,
                style: AppTypography.headingSmall.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.42,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedIn extends StatelessWidget {
  const _AnimatedIn({
    required this.controller,
    required this.child,
    this.begin = 0,
    this.end = 1,
    this.offset = const Offset(0, 0.14),
  });

  final AnimationController controller;
  final Widget child;
  final double begin;
  final double end;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        begin.clamp(0, 1),
        end.clamp(0, 1),
        curve: Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: offset,
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class _CreditPackage {
  const _CreditPackage({
    required this.credits,
    required this.price,
    required this.asset,
    this.oldPrice,
    this.discount,
  });

  final int credits;
  final String price;
  final String asset;
  final String? oldPrice;
  final String? discount;
}
