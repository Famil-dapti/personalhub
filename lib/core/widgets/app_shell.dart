import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../supabase/supabase_service.dart';
import '../sync/sync_providers.dart';
import 'responsive.dart';

/// One navigation destination, shared by the phone bottom bar and the desktop
/// left rail so labels/icons never drift between form factors.
class _Dest {
  const _Dest(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const List<_Dest> _destinations = [
  _Dest(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet,
      'Cuzdan'),
  _Dest(Icons.notifications_outlined, Icons.notifications, 'Bildirimler'),
  _Dest(Icons.photo_library_outlined, Icons.photo_library, 'Medya'),
  _Dest(Icons.settings_outlined, Icons.settings, 'Ayarlar'),
];

/// Adaptive app shell: bottom navigation on phone, an 88px left navigation rail
/// on desktop/web (>= [kWideBreakpoint]). Each destination keeps its own
/// navigation stack via the [StatefulNavigationShell].
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _go(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start background sync for the authenticated session and keep it alive.
    ref.watch(syncBootstrapProvider);

    if (context.isWide) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopRail(
              selectedIndex: navigationShell.currentIndex,
              onSelected: _go,
              onSignOut: () => ref.read(supabaseClientProvider).auth.signOut(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _go,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

class _DesktopRail extends StatelessWidget {
  const _DesktopRail({
    required this.selectedIndex,
    required this.onSelected,
    required this.onSignOut,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      minWidth: 88,
      groupAlignment: -0.9,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.account_balance_wallet,
              color: scheme.onPrimaryContainer, size: 24),
        ),
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: IconButton(
              tooltip: 'Cikis',
              onPressed: onSignOut,
              icon: const Icon(Icons.logout),
            ),
          ),
        ),
      ),
      destinations: [
        for (final d in _destinations)
          NavigationRailDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: Text(d.label),
          ),
      ],
    );
  }
}
