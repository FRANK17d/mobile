import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/responsive/adaptive_scaffold.dart';
import '../../features/chat/screens/conversations_screen.dart';
import '../../features/client/home/screens/client_home_screen.dart';
import '../../features/client/orders/screens/orders_list_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

/// Shell de navegacion del Cliente.
/// En movil: BottomNavigationBar con 4 tabs.
/// En tablet: NavigationRail lateral.
class ClientShell extends StatefulWidget {
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: AppStrings.home,
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long_rounded),
      label: AppStrings.myOrders,
    ),
    NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline_rounded),
      selectedIcon: Icon(Icons.chat_bubble_rounded),
      label: AppStrings.messages,
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: AppStrings.profileLabel,
    ),
  ];

  // Paginas correspondientes a cada tab
  static const _pages = [
    ClientHomeScreen(),
    OrdersListScreen(),
    ConversationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      destinations: _destinations,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      body: IndexedStack(index: _selectedIndex, children: _pages),
    );
  }
}
