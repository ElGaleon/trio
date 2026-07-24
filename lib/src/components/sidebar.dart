
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/assets.dart';
import 'package:forui/forui.dart';
import 'package:forui/widgets/sidebar.dart';
import 'package:go_router/go_router.dart';
import 'package:trio/src/extensions/theme_extension.dart';
import 'package:trio/src/features/auth/application/auth_service.dart';
import 'package:trio/src/features/auth/application/rbac_provider.dart';
import 'package:trio/src/features/organizations/application/organization_providers.dart';
import 'package:trio/src/features/organizations/presentation/organization_switcher.dart';
import 'package:trio/src/features/settings/application/theme_mode_provider.dart';
import 'package:trio/src/routing/app_router.dart';

import '../shared/sport_player_avatar.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final role = ref.watch(currentRoleProvider);
    final name = user?.displayName?.trim();
    final email = user?.email?.trim();
    final photoUrl = user?.photoURL?.trim();
    final themeModeIndex = ref.watch(themeModeIndexProvider);
    final label = switch ((name, email)) {
      (final name?, _) when name.isNotEmpty => name,
      (_, final email?) when email.isNotEmpty => email,
      _ => 'Utente collegato',
    };

    return FSidebar(
      header: const Padding(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OrganizationSwitcher(),
          ],
        ),
      ),
      footer: _SidebarUserFooter(
        label: label,
        email: name != null && name.isNotEmpty ? email : null,
        photoUrl: photoUrl == null || photoUrl.isEmpty ? null : photoUrl,
        themeModeIndex: themeModeIndex,
        onProfile: () => context.go(AppRoutes.profile),
        onThemeChanged: (value) =>
            ref.read(themeModeIndexProvider.notifier).set(value),
        onLogout: () {
          ref.read(selectedOrganizationIdProvider.notifier).set(null);
          ref.read(authServiceProvider).signOut();
        },
      ),
      children: [
        FSidebarGroup(
          children: [
            for (final item in visibleNavItems(role, wide: true))
              FSidebarItem(
                style: FSidebarItemStyleDelta.delta(iconSpacing: 8, borderRadius: BorderRadius.circular(4),padding: EdgeInsetsGeometryDelta.value(EdgeInsetsGeometry.symmetric(horizontal: 8, vertical: 12))),
                icon: Icon(item.icon),
                label: Text(item.label, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),),
                selected: navigationShell.currentIndex == item.branch,
                onPress: () {
                  navigationShell.goBranch(
                    item.branch,
                    initialLocation: item.branch == navigationShell.currentIndex,
                  );
                },
              )
          ],
        ),
      ],
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

List<_NavItem> visibleNavItems(AppRole role, {required bool wide}) {
  final items = [
    if (wide)
      const _NavItem(
        0,
        Icons.dashboard_outlined,
        'Dashboard',
        AppPermission.viewRanking,
      ),
    const _NavItem(1, FIcons.chartBar, 'Ranking', AppPermission.viewRanking),
    const _NavItem(
      2,
      Icons.scoreboard_outlined,
      'Matches',
      AppPermission.viewMatches,
    ),
    const _NavItem(3, FIcons.users, 'Players', AppPermission.viewPlayers),
    const _NavItem(4, FIcons.activity, 'Stats', AppPermission.viewPlayerStats),
    const _NavItem(
      5,
      Icons.account_circle_outlined,
      'Le mie stats',
      AppPermission.viewPlayerStats,
    ),
    const _NavItem(6, FIcons.settings, 'Settings', AppPermission.viewSettings),
    const _NavItem(
      7,
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
    required this.photoUrl,
    required this.themeModeIndex,
    required this.onProfile,
    required this.onThemeChanged,
    required this.onLogout,
  });

  final String label;
  final String? email;
  final String? photoUrl;
  final int themeModeIndex;
  final VoidCallback onProfile;
  final ValueChanged<int> onThemeChanged;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return FSidebarGroup(
      label: const Text('Account'),
      children: [
        PopupMenuButton<_UserMenuAction>(
          tooltip: 'Account',
          onSelected: (action) {
            switch (action) {
              case _OpenProfile():
                onProfile();
              case _SetTheme(:final index):
                onThemeChanged(index);
              case _Logout():
                onLogout();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: _OpenProfile(),
              child: ListTile(
                leading: Icon(Icons.person_outline),
                title: Text('Profilo'),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: const _SetTheme(0),
              child: _ThemeMenuTile(
                label: 'Tema sistema',
                selected: themeModeIndex == 0,
              ),
            ),
            PopupMenuItem(
              value: const _SetTheme(1),
              child: _ThemeMenuTile(
                label: 'Tema chiaro',
                selected: themeModeIndex == 1,
              ),
            ),
            PopupMenuItem(
              value: const _SetTheme(2),
              child: _ThemeMenuTile(
                label: 'Tema scuro',
                selected: themeModeIndex == 2,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: _Logout(),
              child: ListTile(
                leading: Icon(Icons.logout),
                title: Text('Esci'),
                dense: true,
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                SportPlayerAvatar(
                  initials: _initials(label),
                  imagePath: photoUrl,
                  size: 34,
                ),
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
                const Icon(Icons.expand_more, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _initials(String label) {
    final parts = label.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}

sealed class _UserMenuAction {
  const _UserMenuAction();
}

class _OpenProfile extends _UserMenuAction {
  const _OpenProfile();
}

class _SetTheme extends _UserMenuAction {
  const _SetTheme(this.index);

  final int index;
}

class _Logout extends _UserMenuAction {
  const _Logout();
}

class _ThemeMenuTile extends StatelessWidget {
  const _ThemeMenuTile({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(selected ? Icons.check_circle : Icons.circle_outlined),
      title: Text(label),
      dense: true,
    );
  }
}