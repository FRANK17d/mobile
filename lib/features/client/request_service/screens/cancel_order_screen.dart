import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/gradient_pill_button.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../services/request_service.dart';
import '../widgets/request_widgets.dart';

/// Confirmación para cancelar un pedido. Cancela vía
/// [RequestService.cancelRequest] y devuelve `true` al cerrarse con éxito.
class CancelOrderScreen extends StatefulWidget {
  const CancelOrderScreen({super.key, required this.requestId});

  final String requestId;

  @override
  State<CancelOrderScreen> createState() => _CancelOrderScreenState();
}

class _CancelOrderScreenState extends State<CancelOrderScreen> {
  final RequestService _service = RequestService();

  bool _agreed = false;
  bool _cancelling = false;

  Future<void> _cancel() async {
    if (_cancelling || !_agreed) return;
    setState(() => _cancelling = true);
    final result = await _service.cancelRequest(widget.requestId);
    if (!mounted) return;
    setState(() => _cancelling = false);

    if (result.success) {
      Navigator.of(context).pop(true);
    } else {
      showAppToast(
        context,
        message: result.message ?? 'No se pudo cancelar el pedido.',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            'Cancelar mi pedido',
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Column(
          children: [
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderLight,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingH,
                  AppSpacing.xl,
                  AppSpacing.screenPaddingH,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cancelar mi pedido',
                      style: AppTypography.displaySmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Esto hará que tu pedido deje de estar disponible en la '
                      'plataforma, pasará a un estado "Cancelado".',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    CheckTile(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v),
                      label: 'Si, estoy de acuerdo',
                    ),
                  ],
                ),
              ),
            ),
            RequestBottomBar(
              child: Opacity(
                opacity: _agreed ? 1 : 0.5,
                child: GradientPillButton(
                  label: 'Cancelar mi pedido',
                  isLoading: _cancelling,
                  onTap: _cancel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
