import 'package:flutter/material.dart';
import '../widgets/feedback/app_toast.dart';

/// Extensions utiles sobre BuildContext
extension ContextExtensions on BuildContext {
  // ─── Theme shortcuts ───
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  bool get isDarkMode => theme.brightness == Brightness.dark;

  // ─── MediaQuery shortcuts ───
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);
  double get bottomPadding => padding.bottom;
  double get topPadding => padding.top;
  Orientation get orientation => MediaQuery.orientationOf(this);

  // ─── Navigator shortcuts ───
  NavigatorState get navigator => Navigator.of(this);
  void pop<T>([T? result]) => navigator.pop(result);

  // ─── Toast (reemplaza SnackBar generico) ───
  void showToast(String message, {bool isError = false}) {
    showAppToast(
      this,
      message: message,
      type: isError ? ToastType.error : ToastType.info,
    );
  }
}
