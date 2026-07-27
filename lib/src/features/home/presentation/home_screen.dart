import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:skrim/src/components/sidebar.dart';
import 'package:skrim/src/features/auth/application/rbac_provider.dart';
import 'package:skrim/src/features/home/presentation/organization_setup_screen.dart';
import 'package:skrim/src/features/organizations/application/organization_providers.dart';
import 'package:skrim/src/shared/responsive_layout.dart';

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
    final footerItems = visibleNavItems(role, wide: false);
    final footerIndex = footerItems.indexWhere(
      (item) => item.branch == navigationShell.currentIndex,
    );

    return Material(
      type: MaterialType.transparency,
      child: FScaffold(
        header: null,
        childPad: false,
        sidebar: wide && canShowApp
            ? Sidebar(navigationShell: navigationShell)
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
        child: canShowApp ? navigationShell : const OrganizationSetupScreen(),
      ),
    );
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
