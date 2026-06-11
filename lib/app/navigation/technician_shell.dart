import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/responsive/adaptive_scaffold.dart';
import '../../core/services/app_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/navigation/custom_bottom_nav_bar.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/client/home/screens/client_home_screen.dart';
import '../../features/technician/orders/screens/provider_orders_screen.dart';
import '../../features/technician/account/screens/provider_account_screen.dart';

/// Shell de navegacion del Prestador de servicio.
/// 3 tabs: Inicio, Pedidos, Cuenta.
/// Si es la primera vez (guía no vista), arranca en Cuenta.
class TechnicianShell extends StatefulWidget {
  const TechnicianShell({super.key});

  /// Índices de tabs del shell del técnico.
  static const int tabHome = 0;
  static const int tabOrders = 1;
  static const int tabPanel = 2;

  /// Permite a otras pantallas (p. ej. el menú hamburguesa) pedir un cambio de
  /// tab sin acoplarse al estado interno del shell.
  static final ValueNotifier<int> tabRequest = ValueNotifier<int>(tabHome);

  /// Solicita mostrar el tab [index] (usar las constantes `tab*`).
  static void goToTab(int index) {
    // Reasigna a -1 primero para notificar incluso si el valor no cambia.
    tabRequest.value = -1;
    tabRequest.value = index;
  }

  @override
  State<TechnicianShell> createState() => _TechnicianShellState();
}

class _TechnicianShellState extends State<TechnicianShell> {
  int _selectedIndex = 0;
  String? _avatarUrl;

  static const _pages = [
    ClientHomeScreen(),
    ProviderOrdersScreen(),
    ProviderAccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    _loadAvatar();
    TechnicianShell.tabRequest.addListener(_onTabRequested);
  }

  @override
  void dispose() {
    TechnicianShell.tabRequest.removeListener(_onTabRequested);
    super.dispose();
  }

  void _onTabRequested() {
    final requested = TechnicianShell.tabRequest.value;
    if (requested < 0 || !mounted) return;
    setState(() => _selectedIndex = requested);
  }

  Future<void> _loadAvatar() async {
    final profile = await AuthService().getMyTechnicianProfile();
    final url = profile?['avatar_url'] as String?;
    if (url != null && url.isNotEmpty && mounted) {
      setState(() => _avatarUrl = url);
    }
  }

  /// Si el prestador debe ver la guía, arranca en tab Cuenta (index 2).
  Future<void> _checkFirstTime() async {
    final shouldShow = await AppPreferences.shouldShowProviderGuide();
    if (shouldShow && mounted) {
      setState(() => _selectedIndex = 2);
    }
  }

  List<NavBarItem> get _items => [
    const NavBarItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: AppStrings.home,
    ),
    const NavBarItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Pedidos',
    ),
    NavBarItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Cuenta',
      customWidget: _avatarUrl != null
          ? _NavAvatar(url: _avatarUrl!, isActive: false)
          : null,
      activeCustomWidget: _avatarUrl != null
          ? _NavAvatar(url: _avatarUrl!, isActive: true)
          : null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      items: _items,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      body: IndexedStack(index: _selectedIndex, children: _pages),
    );
  }
}

class _NavAvatar extends StatelessWidget {
  const _NavAvatar({required this.url, required this.isActive});

  final String url;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? AppColors.primaryDark : Colors.transparent,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: 22,
          height: 22,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => Icon(
            isActive ? Icons.person_rounded : Icons.person_outline_rounded,
            size: 22,
            color: isActive ? AppColors.primaryDark : const Color(0xFF2E3A4F),
          ),
        ),
      ),
    );
  }
}
