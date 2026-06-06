import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../app_router.dart';
import '../components/shared/sport_avatar_pill.dart';
import '../components/shared/sport_button.dart';
import '../components/shared/sport_screen_shell.dart';
import '../model/player.dart';
import '../providers/player_form_provider.dart';
import '../theme/app_colors.dart';

class PlayerFormScreen extends ConsumerStatefulWidget {
  const PlayerFormScreen({super.key, this.player, this.playerId});

  final Player? player;
  final String? playerId;

  @override
  ConsumerState<PlayerFormScreen> createState() => _PlayerFormScreenState();
}

class _PlayerFormScreenState extends ConsumerState<PlayerFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _jerseyNumberController;

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(playerFormProvider(widget.playerId));
    _nameController = TextEditingController(text: initialState.name);
    _jerseyNumberController = TextEditingController(
      text: initialState.jerseyNumber,
    );
    _nameController.addListener(() {
      ref
          .read(playerFormProvider(widget.playerId).notifier)
          .updateName(_nameController.text);
    });
    _jerseyNumberController.addListener(() {
      ref
          .read(playerFormProvider(widget.playerId).notifier)
          .updateJerseyNumber(_jerseyNumberController.text);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jerseyNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerFormProvider(widget.playerId));
    final notifier = ref.read(playerFormProvider(widget.playerId).notifier);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SportScreenShell(
        title: widget.playerId == null && widget.player == null
            ? 'New player'
            : 'Edit player',
        subtitle: 'Roster profile',
        showBackButton: true,
        child: Column(
          spacing: 14,
          children: [
            DecoratedBox(
              decoration: sportGlassDecoration(),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  spacing: 12,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showImageSourcePicker(context, notifier),
                      child: SportPlayerAvatar(
                        initials: state.name.trim().isEmpty
                            ? '?'
                            : _initials(state.name),
                        imagePath: state.profileImagePath,
                        size: 92,
                        featured: true,
                      ),
                    ),
                    SportActionButton(
                      label: state.profileImagePath == null
                          ? 'Carica foto'
                          : 'Cambia foto',
                      icon: FIcons.image,
                      onPressed: () =>
                          _showImageSourcePicker(context, notifier),
                    ),
                    if (state.profileImagePath != null)
                      SportActionButton(
                        label: 'Rimuovi foto',
                        icon: FIcons.x,
                        onPressed: notifier.removeImage,
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: FTextFormField(
                        control: FTextFieldControl.managed(
                          controller: _nameController,
                        ),
                        textCapitalization: TextCapitalization.words,
                        hint: 'Nome',
                      ),
                    ),
                    FTextFormField(
                      control: FTextFieldControl.managed(
                        controller: _jerseyNumberController,
                      ),
                      keyboardType: TextInputType.number,
                      hint: 'Numero di maglia (opzionale)',
                    ),
                    FSelect<PlayerLinePreference>(
                      items: {
                        for (final line in PlayerLinePreference.values)
                          line.label: line,
                      },
                      hint: 'Linea preferita',
                      control: FSelectControl.managed(
                        initial: state.linePreference,
                        onChange: (value) {
                          if (value != null) {
                            notifier.updateLinePreference(value);
                          }
                        },
                      ),
                    ),
                    FSelect<PlayerRole>(
                      items: {
                        for (final role in PlayerRole.values) role.label: role,
                      },
                      hint: 'Ruolo',
                      control: FSelectControl.managed(
                        initial: state.role,
                        onChange: (value) {
                          if (value != null) {
                            notifier.updateRole(value);
                          }
                        },
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: notifier.toggleIsExternal,
                      child: DecoratedBox(
                        decoration: sportGlassDecoration(radius: 18),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            spacing: 10,
                            children: [
                              Icon(
                                state.isExternal ? FIcons.check : FIcons.circle,
                                color: AppColors.white,
                                size: 18,
                              ),
                              Expanded(
                                child: Text(
                                  'Giocatore esterno',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: SportActionButton(
                        label: 'Salva',
                        icon: FIcons.check,
                        onPressed: () => _save(context, notifier),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImageSourcePicker(
    BuildContext context,
    PlayerFormNotifier notifier,
  ) async {
    final source = await showModalBottomSheet<ImageSourceChoice>(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.sportHeaderDark,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.42),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  ImageSourceTile(
                    icon: FIcons.camera,
                    title: 'Fotocamera',
                    subtitle: 'Scatta una nuova foto profilo.',
                    onTap: () =>
                        Navigator.pop(context, ImageSourceChoice.camera),
                  ),
                  ImageSourceTile(
                    icon: FIcons.image,
                    title: 'Galleria',
                    subtitle: 'Scegli una foto dal rullino.',
                    onTap: () =>
                        Navigator.pop(context, ImageSourceChoice.gallery),
                  ),
                  ImageSourceTile(
                    icon: FIcons.folderOpen,
                    title: 'Files',
                    subtitle: 'Fallback utile anche sul simulatore.',
                    onTap: () =>
                        Navigator.pop(context, ImageSourceChoice.files),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (source == null) return;

    final success = switch (source) {
      ImageSourceChoice.camera => await notifier.pickImageFromCamera(),
      ImageSourceChoice.gallery => await notifier.pickImageFromGallery(),
      ImageSourceChoice.files => await notifier.pickImageFromFiles(),
    };

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile caricare la foto. Prova un altro metodo.'),
        ),
      );
    }
  }

  Future<void> _save(BuildContext context, PlayerFormNotifier notifier) async {
    if (_nameController.text.trim().isEmpty) return;
    final jersey = _jerseyNumberController.text.trim();
    if (jersey.isNotEmpty && int.tryParse(jersey) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un numero di maglia valido.')),
      );
      return;
    }
    await notifier.save(widget.playerId);
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.players);
    }
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts[1].characters.first}'
        .toUpperCase();
  }
}

enum ImageSourceChoice { camera, gallery, files }

class ImageSourceTile extends StatelessWidget {
  const ImageSourceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            spacing: 12,
            children: [
              Icon(icon, color: AppColors.violet, size: 20),
              Expanded(
                child: Column(
                  spacing: 2,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.sportMutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(FIcons.chevronRight, color: AppColors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
