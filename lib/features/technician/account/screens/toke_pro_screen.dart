import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../services/payment_checkout_service.dart';
import '../services/toke_pro_service.dart';

class TokeProScreen extends StatefulWidget {
  const TokeProScreen({super.key});

  @override
  State<TokeProScreen> createState() => _TokeProScreenState();
}

class _TokeProScreenState extends State<TokeProScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final TokeProService _tokeProService = TokeProService();
  final PaymentCheckoutService _paymentService = PaymentCheckoutService();
  static const double _stickyPlansReservedHeight = 340;

  static const _benefits = [
    _ProBenefit(
      icon: Icons.trending_up_rounded,
      title: 'Visibilidad',
      body: 'Prioridad y mayor presencia frente a las cuentas gratuitas.',
    ),
    _ProBenefit(
      icon: Icons.campaign_rounded,
      title: 'Pedidos exclusivos',
      body: 'Acceso a pedidos exclusivos de clientes activos.',
    ),
    _ProBenefit(
      icon: Icons.ads_click_rounded,
      title: 'Contacto directo',
      body: 'Contacta a tus clientes sin costos extra ni bloqueos.',
    ),
    _ProBenefit(
      icon: Icons.notifications_active_rounded,
      title: 'Notificaciones',
      body:
          'Enterate primero cuando alguien necesita un servicio como el tuyo.',
    ),
    _ProBenefit(
      icon: Icons.saved_search_rounded,
      title: 'Resaltado',
      body: 'Tu perfil destaca en los buscadores para que te vean mejor.',
    ),
    _ProBenefit(
      icon: Icons.rocket_launch_rounded,
      title: 'Servicios ilimitados',
      body: 'Ofrece tus servicios sin límite durante todo el plan.',
    ),
    _ProBenefit(
      icon: Icons.paid_rounded,
      title: 'Créditos',
      body: 'Recibe créditos incluidos según el plan que elijas.',
    ),
  ];

  List<_ProPlan> _plans = const [];
  bool _isLoadingPlans = true;
  int? _startingPlanId;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final plans = await _tokeProService.getActivePlans();
    if (!mounted) return;

    setState(() {
      _plans = plans == null
          ? const []
          : plans
                .map(
                  (plan) => _ProPlan(
                    id: plan.id,
                    title: plan.name,
                    price: 'S/ ${plan.pricePen.toStringAsFixed(2)}',
                    period: _durationLabel(plan.durationDays),
                    credits: plan.includedCredits,
                  ),
                )
                .toList();
      _isLoadingPlans = false;
    });
  }

  String _durationLabel(int days) {
    if (days % 365 == 0) {
      final years = days ~/ 365;
      return '$years ${years == 1 ? 'año' : 'años'}';
    }
    if (days % 30 == 0) {
      final months = days ~/ 30;
      return '$months ${months == 1 ? 'mes' : 'meses'}';
    }
    return '$days días';
  }

  Future<void> _startCheckout(_ProPlan plan) async {
    if (_startingPlanId != null) return;

    if (plan.id <= 0) {
      _showCheckoutMessage(
        'No se pudo identificar este plan. Intentalo de nuevo.',
      );
      return;
    }

    setState(() => _startingPlanId = plan.id);

    try {
      final checkout = await _paymentService.createTokeProCheckout(plan.id);
      if (!mounted) return;

      if (checkout == null) {
        _showCheckoutMessage(
          'No se pudo iniciar Mercado Pago. Intentalo de nuevo.',
        );
        return;
      }

      final launched = await launchUrl(
        Uri.parse(checkout.checkoutUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showCheckoutMessage(
          'No se pudo abrir Mercado Pago en este dispositivo.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showCheckoutMessage(
          'No se pudo abrir Mercado Pago. Intentalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _startingPlanId = null);
    }
  }

  void _showCheckoutMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Stack(
          children: [
            const _ProBackground(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingH,
                  0,
                  AppSpacing.screenPaddingH,
                  _stickyPlansReservedHeight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: topPadding > 0 ? 10 : 18),
                    _AnimatedIn(
                      controller: _controller,
                      begin: 0,
                      end: 0.35,
                      offset: const Offset(0, -0.14),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _CloseButton(
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _AnimatedIn(
                      controller: _controller,
                      begin: 0.05,
                      end: 0.45,
                      child: const _ProLogo(),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _AnimatedIn(
                      controller: _controller,
                      begin: 0.12,
                      end: 0.54,
                      offset: const Offset(0, 0.14),
                      child: const _BenefitsSection(benefits: _benefits),
                    ),
                    const SizedBox(height: AppSpacing.massive),
                    _AnimatedIn(
                      controller: _controller,
                      begin: 0.28,
                      end: 0.7,
                      offset: const Offset(0, 0.16),
                      child: const _WalletSection(),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.screenPaddingH,
              right: AppSpacing.screenPaddingH,
              bottom: bottomPadding + AppSpacing.xs,
              child: _AnimatedIn(
                controller: _controller,
                begin: 0.44,
                end: 0.92,
                offset: const Offset(0, 0.18),
                child: _StickyPlansPanel(
                  plans: _plans,
                  isLoading: _isLoadingPlans,
                  startingPlanId: _startingPlanId,
                  onPlanTap: _startCheckout,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProBackground extends StatelessWidget {
  const _ProBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE7E2), Color(0xFFFFF7F5), Colors.white],
              stops: [0, 0.48, 1],
            ),
          ),
        ),
        Positioned(
          top: -26,
          left: 112,
          child: _GhostCoin(size: 78, opacity: 0.1),
        ),
        Positioned(
          top: 82,
          right: -16,
          child: _GhostCoin(size: 104, opacity: 0.11),
        ),
        Positioned(
          top: 540,
          right: -20,
          child: _GhostCoin(size: 86, opacity: 0.1),
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
      label: 'Cerrar TokePro',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.84),
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

class _ProLogo extends StatelessWidget {
  const _ProLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'toke+',
          style: AppTypography.displayMedium.copyWith(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: AppColors.secondaryDark,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            'Pro',
            style: AppTypography.headingMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.secondaryDark,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _BenefitsSection extends StatelessWidget {
  const _BenefitsSection({required this.benefits});

  final List<_ProBenefit> benefits;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Beneficios de #TokePro',
          style: AppTypography.displayMedium.copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryDark,
            height: 1.12,
            letterSpacing: -0.9,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ...List.generate(benefits.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == benefits.length - 1 ? 0 : AppSpacing.lg,
            ),
            child: _BenefitRow(benefit: benefits[index]),
          );
        }),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.benefit});

  final _ProBenefit benefit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(benefit.icon, color: AppColors.primaryDark, size: 25),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTypography.bodyLarge.copyWith(
                fontSize: 16,
                height: 1.36,
                color: AppColors.textSecondary,
              ),
              children: [
                TextSpan(
                  text: '${benefit.title}: ',
                  style: AppTypography.bodyLarge.copyWith(
                    fontSize: 17,
                    height: 1.32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondaryDark,
                  ),
                ),
                TextSpan(text: benefit.body),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletSection extends StatelessWidget {
  const _WalletSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _WalletHero(),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Tu billetera de Créditos',
          style: AppTypography.displaySmall.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.secondaryDark,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'En Toke+ usamos créditos para que puedas postularte a pedidos reales de clientes.',
          style: AppTypography.headingSmall.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.36,
            color: AppColors.secondaryDark,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const _CreditBonusCallout(),
      ],
    );
  }
}

class _WalletHero extends StatelessWidget {
  const _WalletHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 4,
            right: 4,
            bottom: 0,
            child: Container(
              height: 132,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                AppImages.walletCredits,
                height: 228,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditBonusCallout extends StatelessWidget {
  const _CreditBonusCallout();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.stacked_line_chart_rounded,
            color: AppColors.secondaryLight,
            size: 26,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Text(
            'Con TokePro ganas más visibilidad, más oportunidades y créditos incluidos según el plan activo que elijas.',
            style: AppTypography.headingSmall.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.42,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StickyPlansPanel extends StatelessWidget {
  const _StickyPlansPanel({
    required this.plans,
    required this.isLoading,
    required this.startingPlanId,
    required this.onPlanTap,
  });

  final List<_ProPlan> plans;
  final bool isLoading;
  final int? startingPlanId;
  final ValueChanged<_ProPlan> onPlanTap;

  @override
  Widget build(BuildContext context) {
    return _PlansPanel(
      plans: plans,
      isLoading: isLoading,
      startingPlanId: startingPlanId,
      onPlanTap: onPlanTap,
    );
  }
}

class _PlansPanel extends StatelessWidget {
  const _PlansPanel({
    required this.plans,
    required this.isLoading,
    required this.startingPlanId,
    required this.onPlanTap,
  });

  final List<_ProPlan> plans;
  final bool isLoading;
  final int? startingPlanId;
  final ValueChanged<_ProPlan> onPlanTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E4F1).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else if (plans.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'No hay planes activos por ahora.',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ...List.generate(plans.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == plans.length - 1 ? 0 : AppSpacing.md,
                ),
                child: _PlanCard(
                  plan: plans[index],
                  isBusy: startingPlanId == plans[index].id,
                  isDisabled: startingPlanId != null,
                  onTap: () => onPlanTap(plans[index]),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.onTap,
    required this.isBusy,
    required this.isDisabled,
  });

  final _ProPlan plan;
  final VoidCallback onTap;
  final bool isBusy;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Activar ${plan.title}',
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: AnimatedOpacity(
          opacity: isDisabled && !isBusy ? 0.62 : 1,
          duration: const Duration(milliseconds: 160),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 13, 14, 13),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.07),
                      blurRadius: 12,
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
                            plan.title,
                            style: AppTypography.headingSmall.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xxs,
                            children: [
                              Text(
                                plan.price,
                                style: AppTypography.displaySmall.copyWith(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.secondaryDark,
                                  letterSpacing: -0.7,
                                ),
                              ),
                              if (plan.oldPrice != null)
                                Text(
                                  plan.oldPrice!,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textTertiary,
                                    decoration: TextDecoration.lineThrough,
                                    decorationThickness: 1.5,
                                  ),
                                ),
                              Text(
                                '(${plan.period})',
                                style: AppTypography.titleLarge.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '${plan.credits} créditos incluidos',
                            style: AppTypography.labelLarge.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (isBusy)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    else
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                  ],
                ),
              ),
              if (plan.badge != null)
                Positioned(
                  top: -12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF009688),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF009688,
                          ).withValues(alpha: 0.24),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      plan.badge!,
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
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

class _ProBenefit {
  const _ProBenefit({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _ProPlan {
  const _ProPlan({
    required this.id,
    required this.title,
    required this.price,
    required this.period,
    required this.credits,
    this.oldPrice,
    this.badge,
  });

  final int id;
  final String title;
  final String price;
  final String period;
  final int credits;
  final String? oldPrice;
  final String? badge;
}
