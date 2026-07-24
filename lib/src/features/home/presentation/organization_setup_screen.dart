import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:trio/src/features/auth/application/auth_service.dart';
import 'package:trio/src/features/organizations/application/organization_invite_service.dart';
import 'package:trio/src/features/organizations/application/organization_providers.dart';
import 'package:trio/src/features/organizations/domain/organization.dart';
import 'package:trio/src/features/organizations/presentation/organization_switcher.dart';
import 'package:trio/src/shared/app_empty_state.dart';
import 'package:trio/src/shared/sport_screen_shell.dart';

import '../../../shared/sport_style.dart' show SportActionButton;

class OrganizationSetupScreen extends ConsumerWidget {
  const OrganizationSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizations = ref.watch(organizationsProvider);
    final pendingInvites = ref.watch(pendingOrganizationInvitesProvider);

    return SportScreenShell(
      title: 'Organizations',
      subtitle: 'Organizzazione',
      headerActions: [
        HeaderIconButton(
          size: 44,
          icon: Icons.logout,
          tooltip: 'Esci',
          onTap: () {
            ref.read(selectedOrganizationIdProvider.notifier).set(null);
            ref.read(authServiceProvider).signOut();
          },
        ),
      ],
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
        data: (items) => pendingInvites.when(
          loading: () => items.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _OrganizationPicker(items: items, invites: const []),
          error: (error, stackTrace) {
            return Center(
              child: SportEmptyState(
                icon: Icons.mark_email_unread_outlined,
                title: 'Inviti non disponibili',
                message:
                    'Non riesco a caricare gli inviti collegati a questa mail.',
                action: SportActionButton(
                  label: 'Ricarica',
                  icon: Icons.refresh,
                  onPressed: () =>
                      ref.invalidate(pendingOrganizationInvitesProvider),
                ),
              ),
            );
          },
          data: (invites) =>
              _OrganizationPicker(items: items, invites: invites),
        ),
      ),
    );
  }
}

class _OrganizationPicker extends ConsumerWidget {
  const _OrganizationPicker({required this.items, required this.invites});

  final List<Organization> items;
  final List<OrganizationInvite> invites;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty && invites.isEmpty) {
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
              'Seleziona una squadra',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Scegli una squadra collegata al tuo account oppure accetta un invito.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (invites.isNotEmpty) ...[
              _SectionTitle('Inviti'),
              const SizedBox(height: 8),
              FItemGroup(
                divider: .full,
                children: [
                  for (final invite in invites)
                    _inviteItem(context, ref, invite),
                ],
              ),
              const SizedBox(height: 18),
            ],
            _SectionTitle('Le tue organizzazioni'),
            const SizedBox(height: 8),
            FItemGroup(
              divider: .full,
              children: [
                for (final org in items) _organizationItem(ref, org),
                FItem(
                  variant: .web,
                  prefix: SizedBox.square(
                    dimension: 64,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Icon(Icons.add_business, size: 36),
                    ),
                  ),
                  title: Text('Nuova organizzazione'),
                  subtitle: Text('Crea una nuova squadra'),
                  suffix: Icon(Icons.chevron_right),
                  onPress: () => showCreateOrganizationDialog(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  FItem _inviteItem(
    BuildContext context,
    WidgetRef ref,
    OrganizationInvite invite,
  ) {
    return FItem(
      variant: .web,
      prefix: SizedBox.square(
        dimension: 64,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Icon(
            invite.isExpired ? Icons.event_busy_outlined : Icons.mail_outline,
            size: 36,
          ),
        ),
      ),
      title: Text(invite.organizationName),
      subtitle: Text(
        invite.isExpired ? 'Invito scaduto' : 'Invito per ${invite.email}',
      ),
      suffix: Icon(
        invite.isExpired ? Icons.delete_outline : Icons.chevron_right,
      ),
      onPress: () => invite.isExpired
          ? _discardInvite(context, ref, invite)
          : _acceptInvite(context, ref, invite),
    );
  }

  FItem _organizationItem(WidgetRef ref, Organization org) {
    return FItem(
      variant: .web,
      prefix: SizedBox.square(
        dimension: 64,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: (org.logoUrl != null)
              ? Image.network(org.logoUrl!, fit: BoxFit.cover)
              : Icon(Icons.business_outlined, size: 36),
        ),
      ),
      title: Text(org.name),
      suffix: Icon(Icons.chevron_right),
      onPress: () =>
          ref.read(selectedOrganizationIdProvider.notifier).set(org.id),
    );
  }

  Future<void> _acceptInvite(
    BuildContext context,
    WidgetRef ref,
    OrganizationInvite invite,
  ) async {
    try {
      await ref
          .read(organizationInviteServiceProvider)
          .acceptInvite(invite: invite);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _discardInvite(
    BuildContext context,
    WidgetRef ref,
    OrganizationInvite invite,
  ) async {
    try {
      await ref.read(organizationInviteServiceProvider).discardInvite(invite);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}
