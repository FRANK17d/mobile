import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/responsive/adaptive_scaffold.dart';
import '../../features/technician/home/screens/tech_dashboard_screen.dart';
import '../../features/technician/requests/screens/tech_requests_screen.dart';
import '../../features/technician/jobs/screens/tech_jobs_screen.dart';

/// Shell de navegacion del Tecnico.
/// En movil: BottomNavigationBar con 5 tabs.
/// En tablet: NavigationRail lateral.
class TechnicianShell extends StatefulWidget {
  const TechnicianShell({super.key});

  @override
  State<TechnicianShell> createState() => _TechnicianShellState();
}

class _TechnicianShellState extends State<TechnicianShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard_rounded),
      label: AppStrings.dashboard,
    ),
    NavigationDestination(
      icon: Icon(Icons.notifications_outlined),
      selectedIcon: Icon(Icons.notifications_rounded),
      label: AppStrings.requests,
    ),
    NavigationDestination(
      icon: Icon(Icons.work_outline_rounded),
      selectedIcon: Icon(Icons.work_rounded),
      label: AppStrings.myJobs,
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

  static const _pages = [
    TechDashboardScreen(),
    TechRequestsScreen(),
    TechJobsScreen(),
    _TechChatPlaceholder(),
    _TechProfilePlaceholder(),
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

// ─── Placeholders internos del Tecnico ───
// Dashboard, Requests y Jobs tienen pantallas reales.
// Chat y Profile aun en construccion.

class _TechChatPlaceholder extends StatelessWidget {
  const _TechChatPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const _TechTabPlaceholder(
      icon: Icons.chat_bubble_rounded,
      title: 'Mensajes',
      subtitle: 'Chatea con tus clientes',
    );
  }
}

class _TechProfilePlaceholder extends StatelessWidget {
  const _TechProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const _TechTabPlaceholder(
      icon: Icons.person_rounded,
      title: 'Perfil',
      subtitle: 'Tu informacion, portafolio y configuracion',
    );
  }
}

class _TechTabPlaceholder extends StatelessWidget {
  const _TechTabPlaceholder({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'En construccion',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
