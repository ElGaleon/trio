import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import 'package:trio/src/features/auth/application/auth_service.dart';
import 'package:trio/src/features/organizations/application/organization_providers.dart';
import 'package:trio/src/features/organizations/domain/organization.dart';

class OrganizationSwitcher extends ConsumerWidget {
  const OrganizationSwitcher({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizations = ref.watch(organizationsProvider).value ?? const [];
    final activeOrganization = ref.watch(activeOrganizationProvider);
    final userId = ref.watch(authStateProvider).value?.uid;
    final canEditOrganization =
        activeOrganization != null && activeOrganization.ownerId == userId;

    if (organizations.isEmpty) {
      return FButton(
        variant: FButtonVariant.outline,
        size: compact ? FButtonSizeVariant.sm : FButtonSizeVariant.md,
        mainAxisSize: MainAxisSize.min,
        onPress: () => showCreateOrganizationDialog(context, ref),
        prefix: const Icon(Icons.add_business_outlined),
        child: const Text('Crea workspace'),
      );
    }

    return FPopoverMenu(
      menuAnchor: Alignment.topRight,
      childAnchor: Alignment.bottomRight,
      maxHeight: 360,
      menuBuilder: (context, controller, menu) => [
        FItemGroup(
          children: [
            for (final organization in organizations)
              _organizationItem(
                ref: ref,
                controller: controller,
                organization: organization,
                selected: organization.id == activeOrganization?.id,
              ),
          ],
        ),
        FItemGroup(
          children: [
            FItem(
              prefix: const Icon(Icons.add),
              title: const Text('Aggiungi organizzazione'),
              onPress: () {
                controller.hide();
                showCreateOrganizationDialog(context, ref);
              },
            ),
            if (canEditOrganization)
              FItem(
                prefix: const Icon(Icons.settings_outlined),
                title: const Text('Dati squadra'),
                onPress: () {
                  controller.hide();
                  showOrganizationDataDialog(context, ref, activeOrganization);
                },
              ),
          ],
        ),
      ],
      builder: (context, controller, child) {
        return FButton(
          variant: FButtonVariant.outline,
          size: compact ? FButtonSizeVariant.sm : FButtonSizeVariant.md,
          mainAxisSize: MainAxisSize.min,
          onPress: controller.toggle,
          prefix: _OrganizationLogo(organization: activeOrganization),
          suffix: const Icon(FIcons.chevronsUpDown),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 150 : 240),
            child: Text(
              activeOrganization?.name ?? 'Seleziona workspace',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  FItem _organizationItem({
    required WidgetRef ref,
    required FPopoverController controller,
    required Organization organization,
    required bool selected,
  }) {
    return FItem(
      prefix: _OrganizationLogo(organization: organization),
      title: Text(organization.name),
      suffix: selected ? const Icon(FIcons.check, size: 18) : null,
      selected: selected,
      onPress: () {
        ref.read(selectedOrganizationIdProvider.notifier).set(organization.id);
        controller.hide();
      },
    );
  }
}

class _OrganizationLogo extends StatelessWidget {
  const _OrganizationLogo({required this.organization});

  final Organization? organization;

  @override
  Widget build(BuildContext context) {
    final logoUrl = organization?.logoUrl?.trim();
    if (logoUrl == null || logoUrl.isEmpty) {
      return const Icon(Icons.business_outlined);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        logoUrl,
        width: 22,
        height: 22,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.business_outlined),
      ),
    );
  }
}

class _OrganizationDraft {
  const _OrganizationDraft(this.name, this.logoUrl);

  final String name;
  final String logoUrl;
}

Future<void> showCreateOrganizationDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final nameController = TextEditingController();
  final logoController = TextEditingController();
  final draft = await showDialog<_OrganizationDraft>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Nuovo workspace'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome organizzazione'),
            textInputAction: TextInputAction.next,
          ),
          TextField(
            controller: logoController,
            decoration: const InputDecoration(
              labelText: 'URL logo (opzionale)',
            ),
            keyboardType: TextInputType.url,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _OrganizationDraft(nameController.text, logoController.text),
          ),
          child: const Text('Crea'),
        ),
      ],
    ),
  );
  nameController.dispose();
  logoController.dispose();
  if (draft == null || draft.name.trim().isEmpty) return;
  try {
    final id = await ref
        .read(organizationServiceProvider)
        .createOrganization(draft.name, logoUrl: draft.logoUrl);
    if (id.isNotEmpty) {
      ref.read(selectedOrganizationIdProvider.notifier).set(id);
    }
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Impossibile creare il workspace: $error')),
    );
  }
}

Future<void> showOrganizationDataDialog(
  BuildContext context,
  WidgetRef ref,
  Organization organization,
) async {
  final nameController = TextEditingController(text: organization.name);
  final logoController = TextEditingController(
    text: organization.logoUrl ?? '',
  );
  final draft = await showDialog<_OrganizationDraft>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Dati squadra'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome squadra'),
            textInputAction: TextInputAction.next,
          ),
          TextField(
            controller: logoController,
            decoration: const InputDecoration(labelText: 'URL logo'),
            keyboardType: TextInputType.url,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _OrganizationDraft(nameController.text, logoController.text),
          ),
          child: const Text('Salva'),
        ),
      ],
    ),
  );
  nameController.dispose();
  logoController.dispose();
  if (draft == null || draft.name.trim().isEmpty) return;
  await ref
      .read(organizationServiceProvider)
      .updateOrganization(
        organization.id,
        name: draft.name,
        logoUrl: draft.logoUrl,
      );
}
