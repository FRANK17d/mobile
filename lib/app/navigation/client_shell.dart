import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/responsive/adaptive_scaffold.dart';
import '../../core/widgets/navigation/custom_bottom_nav_bar.dart';
import '../../core/widgets/navigation/app_menu_sheet.dart';
import '../../features/chat/screens/conversations_screen.dart';
import '../../features/client/home/screens/client_home_screen.dart';
import '../../features/client/orders/screens/orders_list_screen.dart';

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

  static const _items = [
    NavBarItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: AppStrings.home,
    ),
    NavBarItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: AppStrings.myOrders,
    ),
    NavBarItem(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: AppStrings.messages,
    ),
    NavBarItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Cuenta',
    ),
  ];

  // Paginas correspondientes a los 3 primeros tabs
  static const _pages = [
    ClientHomeScreen(),
    OrdersListScreen(),
    ConversationsScreen(),
  ];

  void _onTabSelected(int index) {
    // El ultimo tab (Cuenta) abre el menu full-screen
    if (index == 3) {
      showAppMenuSheet(context);
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
      body: _pages[_selectedIndex],
    );
  }
}
