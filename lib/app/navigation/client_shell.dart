import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/responsive/adaptive_scaffold.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/navigation/custom_bottom_nav_bar.dart';
import '../../core/widgets/navigation/app_menu_sheet.dart';
import '../../features/chat/screens/conversations_screen.dart';
import '../../features/client/home/screens/client_home_screen.dart';
import '../../features/client/orders/screens/orders_list_screen.dart';
import '../../features/auth/services/auth_store.dart';
import '../../features/profile/screens/profile_screen.dart';

/// Shell de navegacion del Cliente.
/// En movil: BottomNavigationBar con 3 tabs + Cuenta abre menu.
/// En tablet: NavigationRail lateral.
class ClientShell extends StatefulWidget {
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    AuthStore.instance.notifier.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    AuthStore.instance.notifier.removeListener(_onAuthChanged);
    super.dispose();
  }

  /// Reacciona a login/logout: si se cierra sesión estando en "Cuenta" vuelve
  /// al Inicio, y refresca el avatar del nav.
  void _onAuthChanged() {
    if (!mounted) return;
    setState(() {
      if (!AuthStore.instance.value.isAuthenticated && _selectedIndex == 3) {
        _selectedIndex = 0;
      }
    });
  }

  List<NavBarItem> get _items {
    final avatarUrl =
        AuthStore.instance.value.profile?['avatar_url'] as String?;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    return [
      const NavBarItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: AppStrings.home,
      ),
      const NavBarItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: AppStrings.myOrders,
      ),
      const NavBarItem(
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: AppStrings.messages,
      ),
      NavBarItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Cuenta',
        customWidget: hasAvatar
            ? _NavAvatar(url: avatarUrl, isActive: false)
            : null,
        activeCustomWidget: hasAvatar
            ? _NavAvatar(url: avatarUrl, isActive: true)
            : null,
      ),
    ];
  }

  // Paginas correspondientes a los 3 primeros tabs
  static const _pages = [
    ClientHomeScreen(),
    OrdersListScreen(),
    ConversationsScreen(),
  ];

  void _onTabSelected(int index) {
    // El ultimo tab (Cuenta): con sesion abre el perfil; sin sesion, el menu
    // full-screen (login / registro).
    if (index == 3) {
      if (AuthStore.instance.value.isAuthenticated) {
        setState(() => _selectedIndex = 3);
      } else {
        showAppMenuSheet(context);
      }
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      items: _items,
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onTabSelected,
      body: _selectedIndex == 3
          ? const ProfileScreen()
          : _pages[_selectedIndex],
    );
  }
}

/// Avatar circular para el tab "Cuenta" del nav bar.
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
