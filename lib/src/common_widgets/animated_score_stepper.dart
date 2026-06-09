import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class AnimatedScoreStepper extends StatelessWidget {
  const AnimatedScoreStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
  });

  final String label;
  final int value;
  final int min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final canDecrease = value > min;

    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          spacing: 10,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScoreButton(
                    icon: Icons.remove,
                    enabled: canDecrease,
                    onTap: () => onChanged(value - 1),
                  ),
                  SizedBox(
                    width: 76,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
                          ),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        '$value',
                        key: ValueKey(value),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  ScoreButton(
                    icon: Icons.add,
                    enabled: true,
                    onTap: () => onChanged(value + 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScoreButton extends StatelessWidget {
  const ScoreButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.35,
      child: FButton.icon(
        variant: .outline,
        size: .sm,
        onPress: enabled ? onTap : null,
        child: Icon(icon, size: 18),
      ),
    );
  }
}
