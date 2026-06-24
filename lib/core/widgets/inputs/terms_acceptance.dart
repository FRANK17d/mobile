import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../web/in_app_web_view_screen.dart';

/// Checkbox "Acepto los términos y condiciones…" con los enlaces tocables:
/// al tocar "términos y condiciones" o "política de privacidad" se abre el
/// visor web embebido (WebView) con la página correspondiente. Tocar el resto
/// del texto o la casilla marca/desmarca la aceptación.
class TermsAcceptanceCheckbox extends StatefulWidget {
  const TermsAcceptanceCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  State<TermsAcceptanceCheckbox> createState() =>
      _TermsAcceptanceCheckboxState();
}

class _TermsAcceptanceCheckboxState extends State<TermsAcceptanceCheckbox> {
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()
      ..onTap = () =>
          _openWeb('https://tokeplus.app/terminos', 'Términos y condiciones');
    _privacyTap = TapGestureRecognizer()
      ..onTap = () =>
          _openWeb('https://tokeplus.app/privacidad', 'Política de privacidad');
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  void _openWeb(String url, String title) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => InAppWebViewScreen(url: url, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = AppTypography.bodyMedium.copyWith(
      color: AppColors.secondary,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
    );

    return Semantics(
      toggled: widget.value,
      label: 'Aceptar términos y condiciones',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: widget.value,
              onChanged: (v) => widget.onChanged(v ?? false),
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: const BorderSide(color: AppColors.neutral400, width: 1.5),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: () => widget.onChanged(!widget.value),
              child: RichText(
                text: TextSpan(
                  text: 'Acepto los ',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  children: [
                    TextSpan(
                      text: 'términos y condiciones de uso',
                      style: linkStyle,
                      recognizer: _termsTap,
                    ),
                    const TextSpan(text: ' y la '),
                    TextSpan(
                      text: 'política de privacidad de datos',
                      style: linkStyle,
                      recognizer: _privacyTap,
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
