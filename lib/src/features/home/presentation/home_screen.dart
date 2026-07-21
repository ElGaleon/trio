import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import 'package:trio/src/features/auth/application/auth_service.dart';
import 'package:trio/src/features/auth/application/rbac_provider.dart';
import 'package:trio/src/features/organizations/application/organization_providers.dart';
import 'package:trio/src/features/organizations/presentation/organization_switcher.dart';
import 'package:trio/src/shared/app_empty_state.dart';
import 'package:trio/src/shared/responsive_layout.dart';
import 'package:trio/src/shared/sport_button.dart';
import 'package:trio/src/shared/sport_screen_shell.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = ResponsiveLayout.isWide(context);
    final role = ref.watch(currentRoleProvider);
    final organizations = ref.watch(organizationsProvider);
    final activeOrganization = ref.watch(activeOrganizationProvider);
    final canShowApp = organizations.maybeWhen(
      data: (_) => activeOrganization != null,
      orElse: () => false,
    );
    final footerItems = _visibleNavItems(role, wide: false);
    final footerIndex = footerItems.indexWhere(
      (item) => item.branch == navigationShell.currentIndex,
    );

    return FScaffold(
      header: null,
      childPad: false,
      sidebar: wide && canShowApp
          ? _Sidebar(navigationShell: navigationShell)
          : null,
      footer: wide || !canShowApp
          ? null
          : FBottomNavigationBar(
              index: footerIndex < 0 ? 0 : footerIndex,
              onChange: (index) => _goBranch(footerItems[index].branch),
              children: [
                for (final item in footerItems)
                  FBottomNavigationBarItem(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ),
              ],
            ),
      child: canShowApp ? navigationShell : const _OrganizationSetupScreen(),
    );
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final role = ref.watch(currentRoleProvider);
    final name = user?.displayName?.trim();
    final email = user?.email?.trim();
    final label = switch ((name, email)) {
      (final name?, _) when name.isNotEmpty => name,
      (_, final email?) when email.isNotEmpty => email,
      _ => 'Utente collegato',
    };

    return FSidebar(
      header: const Padding(
        padding: EdgeInsets.fromLTRB(18, 18, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                'TRIO',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            OrganizationSwitcher(),
          ],
        ),
      ),
      footer: _SidebarUserFooter(
        label: label,
        email: name != null && name.isNotEmpty ? email : null,
        onLogout: () {
          ref.read(selectedOrganizationIdProvider.notifier).set(null);
          ref.read(authServiceProvider).signOut();
        },
      ),
      children: [
        FSidebarGroup(
          label: const Text('Navigazione'),
          children: [
            for (final item in _visibleNavItems(role, wide: true))
              _item(item.branch, item.icon, item.label),
          ],
        ),
      ],
    );
  }

  FSidebarItem _item(int index, IconData icon, String label) {
    return FSidebarItem(
      icon: Icon(icon),
      label: Text(label),
      selected: navigationShell.currentIndex == index,
      onPress: () {
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
    );
  }
}

class _OrganizationSetupScreen extends ConsumerWidget {
  const _OrganizationSetupScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizations = ref.watch(organizationsProvider);

    return SportScreenShell(
      title: 'Workspace',
      subtitle: 'Organizzazione',
      child: organizations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: SportEmptyState(
            icon: Icons.error_outline,
            title: 'Workspace non disponibili',
            message: 'Riprova tra poco.',
            action: SportActionButton(
              label: 'Ricarica',
              icon: Icons.refresh,
              onPressed: () => ref.invalidate(organizationsProvider),
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: SportEmptyState(
                icon: Icons.business_outlined,
                title: 'Crea il primo workspace',
                message:
                    'I dati di giocatori, partite, statistiche ed eventi saranno isolati qui.',
                action: SportActionButton(
                  label: 'Crea workspace',
                  icon: Icons.add_business_outlined,
                  onPressed: () => showCreateOrganizationDialog(context, ref),
                ),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Seleziona un workspace',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scegli una delle organizzazioni a cui sei stato invitato oppure creane una nuova.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  for (final organization in items) ...[
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.business_outlined),
                        title: Text(organization.name),
                        subtitle: const Text('Organizzazione disponibile'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          ref
                              .read(selectedOrganizationIdProvider.notifier)
                              .set(organization.id);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 12),
                  SportActionButton(
                    label: 'Crea workspace',
                    icon: Icons.add_business_outlined,
                    onPressed: () => showCreateOrganizationDialog(context, ref),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.branch, this.icon, this.label, this.permission);

  final int branch;
  final IconData icon;
  final String label;
  final AppPermission permission;
}

List<_NavItem> _visibleNavItems(AppRole role, {required bool wide}) {
  final items = [
    const _NavItem(0, FIcons.chartBar, 'Ranking', AppPermission.viewRanking),
    const _NavItem(
      1,
      Icons.scoreboard_outlined,
      'Matches',
      AppPermission.viewMatches,
    ),
    const _NavItem(2, FIcons.users, 'Players', AppPermission.viewPlayers),
    const _NavItem(3, FIcons.activity, 'Stats', AppPermission.viewPlayerStats),
    const _NavItem(4, FIcons.settings, 'Settings', AppPermission.viewSettings),
    const _NavItem(
      5,
      Icons.calendar_month_outlined,
      'Calendario',
      AppPermission.viewEvents,
    ),
  ];
  return items.where((item) => can(role, item.permission)).toList();
}

class _SidebarUserFooter extends StatelessWidget {
  const _SidebarUserFooter({
    required this.label,
    required this.email,
    required this.onLogout,
  });

  final String label;
  final String? email;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return FSidebarGroup(
      label: const Text('Account'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.account_circle_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (email case final email?)
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        FSidebarItem(
          icon: const Icon(Icons.logout),
          label: const Text('Esci'),
          onPress: onLogout,
        ),
      ],
    );
  }
}
