import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_strings.dart';
import 'router/app_router.dart';

/// Widget raiz de Toke+.
/// Configura el tema, router y providers globales.
class TokeApp extends ConsumerWidget {
  const TokeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,

      // Tema
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light, // TODO: Hacer configurable por el usuario
      // Router
      routerConfig: appRouter,
    );
  }
}
