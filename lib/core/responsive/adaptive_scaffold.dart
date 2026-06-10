import 'package:flutter/material.dart';
import 'breakpoints.dart';
import '../widgets/navigation/custom_bottom_nav_bar.dart';

/// Scaffold adaptivo que cambia entre BottomNavigationBar (movil)
/// y NavigationRail (tablet) automaticamente.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.floatingActionButton,
    this.appBar,
  });

  /// Lista de items de navegacion
  final List<NavBarItem> items;

  /// Indice seleccionado actual
  final int selectedIndex;

  /// Callback al seleccionar un destino
  final ValueChanged<int> onDestinationSelected;

  /// Contenido principal
  final Widget body;

  /// FAB opcional
  final Widget? floatingActionButton;

  /// AppBar opcional
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    final breakpoint = Breakpoint.of(context);

    if (breakpoint.isTablet) {
      return _buildTabletLayout(context);
    }
    return _buildMobileLayout(context);
  }

  Widget _buildMobileLayout(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const navBarHeight = 102.0; // nav bar alto + margen

    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: MediaQuery.of(context).padding.copyWith(
            bottom: bottomPadding + navBarHeight,
          ),
        ),
        child: Stack(
          children: [
            body,
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomBottomNavBar(
                items: items,
                currentIndex: selectedIndex,
                onTap: onDestinationSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    final breakpoint = Breakpoint.of(context);
    final isLarge = breakpoint.isLarge;

    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            extended: isLarge,
            minWidth: 72,
            minExtendedWidth: 200,
            leading: isLarge
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Image.asset(
                      'assets/images/toke_logo.png',
                      height: 40,
                    ),
                  )
                : const SizedBox(height: 8),
            destinations: items
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.activeIcon),
                    label: Text(item.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}
