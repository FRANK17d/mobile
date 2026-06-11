import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_strings.dart';
import '../features/auth/services/auth_service.dart';
import '../features/auth/services/auth_store.dart';
import 'router/app_router.dart';

/// Widget raiz de Toke+.
/// Configura el tema, router y providers globales.
class TokeApp extends ConsumerStatefulWidget {
  const TokeApp({super.key});

  @override
  ConsumerState<TokeApp> createState() => _TokeAppState();
}

class _TokeAppState extends ConsumerState<TokeApp> {
  StreamSubscription<Uri>? _linkSubscription;
  bool _handlingOAuthCallback = false;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    try {
      final appLinks = AppLinks();
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null) {
        unawaited(_handleIncomingLink(initialUri));
      }

      _linkSubscription = appLinks.uriLinkStream.listen(
        (uri) => unawaited(_handleIncomingLink(uri)),
        onError: (Object error) {
          debugPrint('Deep link stream error: $error');
        },
      );
    } catch (e) {
      debugPrint('Deep link init error: $e');
    }
  }

  Future<void> _handleIncomingLink(Uri uri) async {
    final callbackUri = Uri.parse(AuthService.googleOAuthRedirectUri);
    final isGoogleCallback =
        uri.scheme == callbackUri.scheme &&
        uri.host == callbackUri.host &&
        uri.path == callbackUri.path &&
        uri.queryParameters.containsKey('insforge_code');

    if (!isGoogleCallback || _handlingOAuthCallback) return;

    _handlingOAuthCallback = true;
    // Mostramos la animación de carga mientras se completa el intercambio OAuth
    // + la carga de perfil (evita quedarse unos segundos viendo el login).
    appRouter.go(AppRoutes.authProcessing);
    try {
      final authService = AuthService();
      final userId = await authService.completeGoogleLogin(uri);
      if (!mounted) return;

      if (userId == null) {
        appRouter.go(AppRoutes.login);
        return;
      }

      // Detectar rol para navegar correctamente
      final profile = await authService.getMyTechnicianProfile();
      if (!mounted) return;

      AuthStore.instance.setAuthenticated(profile);

      if (profile != null && profile['role'] == 'technician') {
        appRouter.go(AppRoutes.techHome);
      } else {
        appRouter.go(AppRoutes.clientHome);
      }
    } finally {
      _handlingOAuthCallback = false;
    }
  }

  @override
  Widget build(BuildContext context) {
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
