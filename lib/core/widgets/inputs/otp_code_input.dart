import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Campo de código OTP de N dígitos (cajas individuales con auto-avance).
///
/// Robustez clave — corrige el bug de "el cursor se pone delante del número y no
/// deja borrar": el cursor se mantiene SIEMPRE al final del dígito, así el
/// backspace del teclado virtual borra el dígito visible (dispara `onChanged`
/// con texto vacío). El backspace sobre una caja vacía retrocede a la anterior
/// vía `onKeyEvent`. Pegar el código completo lo distribuye entre las cajas.
///
/// Responsive: las cajas se reparten el ancho disponible (se encogen en
/// pantallas pequeñas) con un tope para que no se agranden de más en tablets.
class OtpCodeInput extends StatefulWidget {
  const OtpCodeInput({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.hasError = false,
    this.autoFocus = true,
  });

  /// Cantidad de dígitos.
  final int length;

  /// Se llama cuando se completan todos los dígitos (auto-verificación).
  final ValueChanged<String> onCompleted;

  /// Se llama en cada cambio con el código parcial actual.
  final ValueChanged<String>? onChanged;

  /// Pinta las cajas en estado de error.
  final bool hasError;

  /// Enfoca la primera caja al montar.
  final bool autoFocus;

  @override
  State<OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends State<OtpCodeInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  /// Evita reentrancia mientras escribimos en los controladores por código.
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNodes[0].requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  /// Escribe [value] en la caja [index] dejando el cursor AL FINAL del texto.
  void _setDigit(int index, String value) {
    _controllers[index].value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _cursorToEnd(int index) {
    final length = _controllers[index].text.length;
    _controllers[index].selection = TextSelection.collapsed(offset: length);
  }

  void _emit() {
    widget.onChanged?.call(_code);
    if (_code.length == widget.length) {
      widget.onCompleted(_code);
    }
  }

  /// Reparte varios dígitos (pegado) a partir de [startIndex].
  void _distribute(int startIndex, String digits) {
    _isApplying = true;
    for (var i = 0; i < digits.length; i++) {
      final target = startIndex + i;
      if (target >= _controllers.length) break;
      _setDigit(target, digits[i]);
    }
    _isApplying = false;

    final nextEmpty = _controllers.indexWhere((c) => c.text.isEmpty);
    final focusIndex = nextEmpty == -1 ? _controllers.length - 1 : nextEmpty;
    _focusNodes[focusIndex].requestFocus();
    _cursorToEnd(focusIndex);

    setState(() {});
    _emit();
  }

  void _onChanged(String raw, int index) {
    if (_isApplying) return;

    final digits = raw.replaceAll(RegExp(r'\D'), '');

    // Borrado: la caja quedó vacía → se limpia y el dígito desaparece.
    if (digits.isEmpty) {
      _setDigit(index, '');
      setState(() {});
      _emit();
      return;
    }

    // Pegado de varios dígitos → distribuir entre las cajas.
    if (digits.length > 2) {
      _distribute(index, digits);
      return;
    }

    // Un dígito (o sobre-escritura sobre uno existente): nos quedamos con el
    // último carácter tecleado y avanzamos a la siguiente caja.
    _isApplying = true;
    _setDigit(index, digits[digits.length - 1]);
    _isApplying = false;

    if (index < _controllers.length - 1) {
      _focusNodes[index + 1].requestFocus();
      _cursorToEnd(index + 1);
    }

    setState(() {});
    _emit();
  }

  KeyEventResult _onKeyEvent(int index, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }

    // Caja con dígito → la limpiamos y nos quedamos (también lo cubre onChanged,
    // pero esto cubre teclados físicos / casos donde no llega a onChanged).
    if (_controllers[index].text.isNotEmpty) {
      _setDigit(index, '');
      setState(() {});
      _emit();
      return KeyEventResult.handled;
    }

    // Caja vacía → retrocede a la anterior y la limpia.
    if (index > 0) {
      _setDigit(index - 1, '');
      _focusNodes[index - 1].requestFocus();
      _cursorToEnd(index - 1);
      setState(() {});
      _emit();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Código de verificación de ${widget.length} dígitos',
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = AppSpacing.xs; // 8
          final maxBox = 56.0;
          final available = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 360.0;
          final rawBox =
              (available - gap * (widget.length - 1)) / widget.length;
          final boxW = rawBox.clamp(38.0, maxBox);
          final boxH = (boxW + 6).clamp(46.0, 64.0);
          final totalW = boxW * widget.length + gap * (widget.length - 1);

          return Center(
            child: SizedBox(
              width: totalW,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(widget.length, (index) {
                  return _OtpBox(
                    width: boxW,
                    height: boxH,
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    hasError: widget.hasError,
                    filled: _controllers[index].text.isNotEmpty,
                    semanticsLabel: 'Dígito ${index + 1} de ${widget.length}',
                    onTap: () => _cursorToEnd(index),
                    onChanged: (value) => _onChanged(value, index),
                    onKeyEvent: (event) => _onKeyEvent(index, event),
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.width,
    required this.height,
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.filled,
    required this.semanticsLabel,
    required this.onTap,
    required this.onChanged,
    required this.onKeyEvent,
  });

  final double width;
  final double height;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final bool filled;
  final String semanticsLabel;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;
  final KeyEventResult Function(KeyEvent) onKeyEvent;

  @override
  Widget build(BuildContext context) {
    final Color idleBorder = hasError
        ? AppColors.error
        : (filled ? AppColors.primary.withValues(alpha: 0.45) : Colors.transparent);

    OutlineInputBorder border(Color color, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      borderSide: BorderSide(color: color, width: w),
    );

    return SizedBox(
      width: width,
      height: height,
      child: Semantics(
        textField: true,
        label: semanticsLabel,
        child: Focus(
          onKeyEvent: (_, event) => onKeyEvent(event),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            cursorColor: AppColors.primary,
            style: AppTypography.headingLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: hasError
                  ? AppColors.error.withValues(alpha: 0.06)
                  : AppColors.neutral100,
              contentPadding: EdgeInsets.zero,
              border: border(idleBorder, 1),
              enabledBorder: border(idleBorder, filled ? 1.5 : 1),
              focusedBorder: border(
                hasError ? AppColors.error : AppColors.primary,
                2,
              ),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onTap: onTap,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
