import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:skrim/src/features/auth/application/account_profile_service.dart';
import 'package:skrim/src/features/auth/application/auth_service.dart';
import 'package:skrim/src/features/organizations/application/organization_providers.dart';
import 'package:skrim/src/features/players/application/player_stats_provider.dart';
import 'package:skrim/src/shared/sport_avatar_pill.dart';
import 'package:skrim/src/shared/sport_button.dart';
import 'package:skrim/src/shared/sport_glass_decoration_helper.dart';
import 'package:skrim/src/shared/sport_screen_shell.dart';
import 'package:skrim/theme/app_colors.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _photoController = TextEditingController();
  String? _loadedUserId;
  bool _saving = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final player = ref.watch(currentUserPlayerProvider);
    final nameParts = (user?.displayName ?? player?.name ?? '').trim().split(
      ' ',
    );

    if (user != null && _loadedUserId != user.uid) {
      _loadedUserId = user.uid;
      _firstNameController.text = player?.firstName.isNotEmpty == true
          ? player!.firstName
          : nameParts.firstOrNull ?? '';
      _lastNameController.text = player?.lastName.isNotEmpty == true
          ? player!.lastName
          : nameParts.skip(1).join(' ');
      _photoController.text = user.photoURL ?? player?.profileImagePath ?? '';
    }

    return SportScreenShell(
      title: 'Profilo',
      subtitle: user?.email ?? 'Account utente',
      showBackButton: true,
      child: GlassDecoration(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            spacing: 14,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                spacing: 14,
                children: [
                  SportPlayerAvatar(
                    initials: _initials,
                    imagePath: _photoController.text,
                    size: 64,
                    featured: true,
                  ),
                  Expanded(
                    child: Text(
                      user?.email ?? 'Utente collegato',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.sportForeground(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                textCapitalization: TextCapitalization.words,
              ),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Cognome'),
                textCapitalization: TextCapitalization.words,
              ),
              TextField(
                controller: _photoController,
                decoration: const InputDecoration(
                  labelText: 'URL immagine profilo',
                ),
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(() {}),
              ),
              SportActionButton(
                label: _saving ? 'Salvataggio...' : 'Salva profilo',
                icon: Icons.save_outlined,
                onPressed: user == null || _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _initials {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    if (first.isEmpty && last.isEmpty) return '?';
    return [
      if (first.isNotEmpty) first[0],
      if (last.isNotEmpty) last[0],
    ].join().toUpperCase();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final organizationId = ref.read(activeOrganizationIdProvider);
      final playerId = ref.read(currentUserPlayerProvider)?.id;
      await ref
          .read(accountProfileServiceProvider)
          .saveProfile(
            AccountProfileDraft(
              firstName: _firstNameController.text,
              lastName: _lastNameController.text,
              photoPath: _photoController.text,
            ),
            organizationId: organizationId,
            playerId: playerId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profilo salvato.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Salvataggio fallito: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
