import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../app_router.dart';
import '../models/player.dart';
import '../providers/elo_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/sport_style.dart';

class PlayerFormScreen extends ConsumerStatefulWidget {
  const PlayerFormScreen({super.key, this.player, this.playerId});

  final Player? player;
  final String? playerId;

  @override
  ConsumerState<PlayerFormScreen> createState() => _PlayerFormScreenState();
}

class _PlayerFormScreenState extends ConsumerState<PlayerFormScreen> {
  late final TextEditingController _nameController;
  late PlayerLinePreference _linePreference;
  late PlayerRole _role;
  late bool _isExternal;
  Player? _player;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _player = widget.player ?? _findPlayer(widget.playerId);
    _nameController = TextEditingController(text: _player?.name ?? '');
    _linePreference = _player?.linePreference ?? PlayerLinePreference.offense;
    _role = _player?.role ?? PlayerRole.cutter;
    _isExternal = _player?.isExternal ?? false;
    _profileImagePath = _player?.profileImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SportScreenShell(
        title: _player == null ? 'New player' : 'Edit player',
        subtitle: 'Roster profile',
        child: Column(
          children: [
            const SportBackButton(),
            const SizedBox(height: 14),
            Container(
              decoration: sportGlassDecoration(),
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _showImageSourcePicker,
                    child: SportPlayerAvatar(
                      initials: _nameController.text.trim().isEmpty
                          ? '?'
                          : _initials(_nameController.text),
                      imagePath: _profileImagePath,
                      size: 92,
                      featured: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SportActionButton(
                    label: _profileImagePath == null
                        ? 'Carica foto'
                        : 'Cambia foto',
                    icon: FIcons.image,
                    onPressed: _showImageSourcePicker,
                  ),
                  if (_profileImagePath != null) ...[
                    const SizedBox(height: 8),
                    SportActionButton(
                      label: 'Rimuovi foto',
                      icon: FIcons.x,
                      onPressed: () => setState(() => _profileImagePath = null),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FTextFormField(
                    control: FTextFieldControl.managed(
                      controller: _nameController,
                      onChange: (_) => setState(() {}),
                    ),
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    hint: 'Nome',
                  ),
                  const SizedBox(height: 12),
                  FSelect<PlayerLinePreference>(
                    items: {
                      for (final line in PlayerLinePreference.values)
                        line.label: line,
                    },
                    hint: 'Linea preferita',
                    control: FSelectControl.managed(
                      initial: _linePreference,
                      onChange: (value) {
                        if (value != null) {
                          setState(() => _linePreference = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  FSelect<PlayerRole>(
                    items: {
                      for (final role in PlayerRole.values) role.label: role,
                    },
                    hint: 'Ruolo',
                    control: FSelectControl.managed(
                      initial: _role,
                      onChange: (value) {
                        if (value != null) setState(() => _role = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _isExternal = !_isExternal),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: sportGlassDecoration(radius: 18),
                      child: Row(
                        children: [
                          Icon(
                            _isExternal ? FIcons.check : FIcons.circle,
                            color: AppColors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
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
                  const SizedBox(height: 18),
                  SportActionButton(
                    label: 'Salva',
                    icon: FIcons.check,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImageSourcePicker() async {
    final source = await showModalBottomSheet<_ImageSourceChoice>(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: sportGlassDecoration(radius: 26),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ImageSourceTile(
                  icon: FIcons.image,
                  title: 'Galleria',
                  subtitle: 'Scegli una foto dal rullino.',
                  onTap: () =>
                      Navigator.pop(context, _ImageSourceChoice.gallery),
                ),
                const SizedBox(height: 8),
                _ImageSourceTile(
                  icon: FIcons.folderOpen,
                  title: 'Files',
                  subtitle: 'Fallback utile anche sul simulatore.',
                  onTap: () => Navigator.pop(context, _ImageSourceChoice.files),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (source == null) return;

    final path = switch (source) {
      _ImageSourceChoice.gallery => await _pickFromGallery(),
      _ImageSourceChoice.files => await _pickFromFiles(),
    };
    if (path == null) return;
    setState(() => _profileImagePath = path);
  }

  Future<String?> _pickFromGallery() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        imageQuality: 86,
      );
      if (image == null) return null;
      return _persistImage(File(image.path));
    } catch (_) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Galleria non disponibile. Prova con Files.'),
        ),
      );
      return null;
    }
  }

  Future<String?> _pickFromFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );
    final path = result?.files.single.path;
    if (path == null || path.trim().isEmpty) return null;
    return _persistImage(File(path));
  }

  Future<String> _persistImage(File source) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDirectory = Directory('${directory.path}/player_images');
    if (!imagesDirectory.existsSync()) {
      imagesDirectory.createSync(recursive: true);
    }
    final extension = _imageExtension(source.path);
    final fileName = '${DateTime.now().microsecondsSinceEpoch}$extension';
    final destination = File('${imagesDirectory.path}/$fileName');
    return source.copy(destination.path).then((file) => file.path);
  }

  String _imageExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return '.jpg';
    return path.substring(dot).toLowerCase();
  }

  Future<void> _save() async {
    final repository = ref.read(eloRepositoryProvider);
    if (_player == null) {
      await repository.addPlayerWithLine(
        _nameController.text,
        _linePreference,
        _role,
        _profileImagePath,
        _isExternal,
      );
    } else {
      await repository.savePlayer(
        _player!,
        name: _nameController.text,
        linePreference: _linePreference,
        role: _role,
        profileImagePath: _profileImagePath,
        isExternal: _isExternal,
      );
    }
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.players);
    }
  }

  Player? _findPlayer(String? playerId) {
    if (playerId == null) return null;
    for (final player in ref.read(rankedPlayersProvider)) {
      if (player.id == playerId) return player;
    }
    return null;
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

enum _ImageSourceChoice { gallery, files }

class _ImageSourceTile extends StatelessWidget {
  const _ImageSourceTile({
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.violet, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: sportMutedText,
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
    );
  }
}
