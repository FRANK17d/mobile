import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../account/services/credit_service.dart';
import '../services/earnings_service.dart';

/// Pantalla de historial financiero / ganancias del técnico.
///
/// Muestra el saldo actual de créditos en un header destacado y
/// debajo una lista cronológica de transacciones con pull-to-refresh.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final CreditService _creditService = CreditService();
  final EarningsService _earningsService = EarningsService();

  int _balance = 0;
  List<CreditTransaction> _transactions = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _creditService.getBalance(),
      _earningsService.getTransactions(),
    ]);
    if (!mounted) return;
    setState(() {
      _balance = results[0] as int;
      _transactions = results[1] as List<CreditTransaction>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundSecondary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            'Mis créditos',
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
                onRefresh: _loadAll,
                color: AppColors.primary,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // ── Balance card ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPaddingH,
                          AppSpacing.md,
                          AppSpacing.screenPaddingH,
                          AppSpacing.sectionGap,
                        ),
                        child: _BalanceCard(balance: _balance),
                      ),
                    ),

                    // ── Encabezado de sección ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPaddingH,
                        ),
                        child: Text(
                          'Historial de movimientos',
                          style: AppTypography.headingSmall.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.md),
                    ),

                    // ── Lista o empty state ──
                    if (_transactions.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyTransactions(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPaddingH,
                        ),
                        sliver: SliverList.separated(
                          itemCount: _transactions.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.xs),
                          itemBuilder: (context, index) {
                            return _TransactionCard(
                              transaction: _transactions[index],
                            );
                          },
                        ),
                      ),

                    // Padding inferior
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xxl),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Tarjeta de saldo
// ─────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Saldo disponible',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textOnPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$balance',
                style: AppTypography.displayLarge.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'créditos',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Tarjeta de transacción
// ─────────────────────────────────────────────────────────
class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});

  final CreditTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.isPositive;
    final amountColor = isPositive ? AppColors.success : AppColors.error;
    final amountPrefix = isPositive ? '+' : '-';
    final icon = _iconForKind(transaction.kind);
    final iconBgColor = _iconBgForKind(transaction.kind);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          // Icono
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              icon,
              size: 20,
              color: _iconColorForKind(transaction.kind),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Descripción + fecha
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description.isNotEmpty
                      ? transaction.description
                      : transaction.kind.label,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxxs),
                Text(
                  _formatDate(transaction.createdAt),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),

          // Monto
          Text(
            '$amountPrefix${transaction.amount.abs()}',
            style: AppTypography.titleLarge.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForKind(CreditTransactionKind kind) {
    return switch (kind) {
      CreditTransactionKind.purchase => Icons.shopping_cart_rounded,
      CreditTransactionKind.subscriptionRenewal => Icons.autorenew_rounded,
      CreditTransactionKind.debit => Icons.remove_circle_outline_rounded,
      CreditTransactionKind.free => Icons.card_giftcard_rounded,
    };
  }

  Color _iconBgForKind(CreditTransactionKind kind) {
    return switch (kind) {
      CreditTransactionKind.purchase => AppColors.successLight,
      CreditTransactionKind.subscriptionRenewal => AppColors.infoLight,
      CreditTransactionKind.debit => AppColors.errorLight,
      CreditTransactionKind.free => AppColors.warningLight,
    };
  }

  Color _iconColorForKind(CreditTransactionKind kind) {
    return switch (kind) {
      CreditTransactionKind.purchase => AppColors.success,
      CreditTransactionKind.subscriptionRenewal => AppColors.info,
      CreditTransactionKind.debit => AppColors.error,
      CreditTransactionKind.free => AppColors.warning,
    };
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year  $hour:$minute';
  }
}

// ─────────────────────────────────────────────────────────
// Estado vacío
// ─────────────────────────────────────────────────────────
class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              size: 64,
              color: AppColors.neutral300,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Sin movimientos aún',
              style: AppTypography.headingSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Aquí verás tu historial de créditos\ncuando realices operaciones.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
