import 'package:flutter/material.dart';
import 'breakpoints.dart';

/// Scaffold adaptivo que cambia entre BottomNavigationBar (movil)
/// y NavigationRail (tablet) automaticamente.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.floatingActionButton,
    this.appBar,
  });

  /// Lista de destinos de navegacion
  final List<NavigationDestination> destinations;

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
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
            destinations: destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: d.icon,
                    selectedIcon: d.selectedIcon,
                    label: Text(d.label),
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
