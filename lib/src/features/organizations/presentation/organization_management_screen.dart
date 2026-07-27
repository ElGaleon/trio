import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:skrim/src/features/auth/application/auth_service.dart';
import 'package:skrim/src/features/organizations/application/organization_providers.dart';
import 'package:skrim/src/features/organizations/domain/organization.dart';
import 'package:skrim/src/routing/app_router.dart';
import 'package:skrim/src/shared/app_empty_state.dart';
import 'package:skrim/src/shared/sport_button.dart';
import 'package:skrim/src/shared/sport_glass_decoration_helper.dart';
import 'package:skrim/src/shared/sport_screen_shell.dart';
import 'package:skrim/theme/app_colors.dart';

class OrganizationManagementScreen extends ConsumerStatefulWidget {
  const OrganizationManagementScreen({super.key});

  @override
  ConsumerState<OrganizationManagementScreen> createState() =>
      _OrganizationManagementScreenState();
}

class _OrganizationManagementScreenState
    extends ConsumerState<OrganizationManagementScreen> {
  final _nameController = TextEditingController();
  final _logoController = TextEditingController();
  String? _loadedOrganizationId;
  bool _saving = false;
  bool _deleting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final organization = ref.watch(activeOrganizationProvider);
    final organizations = ref.watch(organizationsProvider).value ?? const [];
    final userId = ref.watch(authStateProvider).value?.uid;
    final isOwner = organization != null && organization.ownerId == userId;

    if (organization == null) {
      return const SportScreenShell(
        title: 'Organizzazione',
        subtitle: 'Gestione',
        showBackButton: true,
        child: SportEmptyState(
          icon: Icons.business_outlined,
          title: 'Nessuna organizzazione selezionata',
          message: 'Seleziona o crea una organizzazione per gestirla.',
        ),
      );
    }

    if (_loadedOrganizationId != organization.id) {
      _loadedOrganizationId = organization.id;
      _nameController.text = organization.name;
      _logoController.text = organization.logoUrl ?? '';
    }

    return SportScreenShell(
      title: 'Organizzazione',
      subtitle: organization.name,
      showBackButton: true,
      child: Column(
        spacing: 14,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassDecoration(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                spacing: 14,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Dati squadra',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.sportForeground(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextField(
                    controller: _nameController,
                    enabled: isOwner && !_saving && !_deleting,
                    decoration: const InputDecoration(
                      labelText: 'Nome organizzazione',
                    ),
                  ),
                  TextField(
                    controller: _logoController,
                    enabled: isOwner && !_saving && !_deleting,
                    decoration: const InputDecoration(
                      labelText: 'URL logo (opzionale)',
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  SportActionButton(
                    label: _saving ? 'Salvataggio...' : 'Salva',
                    icon: Icons.save_outlined,
                    onPressed: isOwner && !_saving && !_deleting
                        ? () => _save(context, organization.id)
                        : null,
                  ),
                  if (!isOwner)
                    Text(
                      'Solo il creatore della squadra può modificarla.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.sportMutedForeground(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isOwner)
            GlassDecoration(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  spacing: 12,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Zona pericolosa',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Elimina organizzazione, giocatori, partite, eventi, impostazioni e inviti collegati.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.sportMutedForeground(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _deleting || _saving
                          ? null
                          : () => _delete(
                              context,
                              organization.id,
                              organizations,
                            ),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(
                        _deleting
                            ? 'Eliminazione...'
                            : 'Elimina organizzazione',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, String organizationId) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(organizationServiceProvider)
          .updateOrganization(
            organizationId,
            name: name,
            logoUrl: _logoController.text,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Organizzazione salvata.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Salvataggio fallito: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(
    BuildContext context,
    String organizationId,
    List<Organization> organizations,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare organizzazione?'),
        content: const Text(
          'Questa azione elimina tutti i dati collegati e non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await ref
          .read(organizationServiceProvider)
          .deleteOrganization(organizationId);
      final remaining = organizations.where((org) => org.id != organizationId);
      ref
          .read(selectedOrganizationIdProvider.notifier)
          .set(remaining.isEmpty ? null : remaining.first.id);
      ref.invalidate(organizationsProvider);
      if (context.mounted) context.go(AppRoutes.ranking);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Eliminazione fallita: $error')));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }
}
