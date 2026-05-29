import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class CardActionsMenu extends StatelessWidget {
  const CardActionsMenu({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FPopoverMenu.tiles(
      menuBuilder: (context, controller, menu) => [
        FTileGroup(
          children: [
            FTile(
              prefix: const Icon(FIcons.pencil, size: 18),
              title: const Text('Modifica'),
              onPress: () {
                controller.hide();
                onEdit();
              },
            ),
            FTile(
              prefix: Icon(FIcons.trash, size: 18, color: colorScheme.error),
              title: Text(
                'Elimina',
                style: TextStyle(color: colorScheme.error),
              ),
              onPress: () {
                controller.hide();
                onDelete();
              },
            ),
          ],
        ),
      ],
      builder: (context, controller, child) => FButton.icon(
        variant: .ghost,
        size: .sm,
        onPress: controller.toggle,
        child: const Icon(FIcons.ellipsis, size: 18),
      ),
    );
  }
}
