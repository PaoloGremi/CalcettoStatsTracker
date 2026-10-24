import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Scelta del menu del + centrale.
enum AddAction { match, training }

/// Apre il menu del + : due sfere escono a ventaglio sopra il pulsante
/// indicato da [anchorKey] (Partita a sinistra, Allenamento a destra), il +
/// ruota in una ×. Ritorna la scelta, o null se il menu viene chiuso.
Future<AddAction?> showAddActionMenu(
  BuildContext context, {
  required GlobalKey anchorKey,
}) {
  final box = anchorKey.currentContext!.findRenderObject()! as RenderBox;
  final anchor = box.localToGlobal(Offset.zero) & box.size;
  return showGeneralDialog<AddAction>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Chiudi menu',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (ctx, animation, _) =>
        _AddActionMenu(anchor: anchor, animation: animation),
  );
}

class _AddActionMenu extends StatelessWidget {
  const _AddActionMenu({required this.anchor, required this.animation});

  final Rect anchor;
  final Animation<double> animation;

  /// Distanza delle sfere dal centro del +.
  static const double _radius = 100;
  static const double _bubble = 60;

  /// Larghezza riservata a sfera + etichetta.
  static const double _slot = 112;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final center = anchor.center;
    final dx = _radius * math.cos(math.pi / 4);
    final dy = _radius * math.sin(math.pi / 4);
    return Stack(
      children: [
        // Tocco sullo sfondo → chiude senza scelta.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        _bubbleAt(
          context,
          screen: size,
          origin: center,
          offset: Offset(-dx, -dy),
          interval: const Interval(0.0, 0.85, curve: Curves.easeOutBack),
          action: AddAction.match,
          label: 'Partita',
          icon: Icons.sports_soccer_rounded,
          color: AppTheme.accentGreen,
        ),
        _bubbleAt(
          context,
          screen: size,
          origin: center,
          offset: Offset(dx, -dy),
          interval: const Interval(0.15, 1.0, curve: Curves.easeOutBack),
          action: AddAction.training,
          label: 'Allenamento',
          icon: Icons.directions_run_rounded,
          color: AppTheme.accentBlue,
        ),
        // Il + che diventa × , sopra al + vero.
        Positioned.fromRect(
          rect: anchor,
          child: Tooltip(
            message: 'Chiudi',
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen,
                  shape: BoxShape.circle,
                ),
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (_, child) => Transform.rotate(
                    angle:
                        Curves.easeOut.transform(animation.value) * math.pi / 4,
                    child: child,
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.black, size: 30),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bubbleAt(
    BuildContext context, {
    required Size screen,
    required Offset origin,
    required Offset offset,
    required Interval interval,
    required AddAction action,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final curved = CurvedAnimation(parent: animation, curve: interval);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = curved.value;
        final c = origin + offset * t;
        // La colonna sfera+etichetta resta dentro lo schermo.
        final left = (c.dx - _slot / 2).clamp(8.0, screen.width - _slot - 8.0);
        return Positioned(
          left: left,
          top: c.dy - _bubble / 2,
          width: _slot,
          child: Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: t.clamp(0.0, 1.2),
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        key: ValueKey('add_action_${action.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(action),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _bubble,
              height: _bubble,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.black, size: 28),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                // Lo sfondo è sempre scuro (velo nero), in entrambi i temi.
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
