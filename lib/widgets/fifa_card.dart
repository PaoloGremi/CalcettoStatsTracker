import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Card con lo stile "FIFA" condiviso da diversi form (nuova partita,
/// modifica partita, locandina, impostazioni). Prima di questo widget
/// la stessa classe privata `_FifaCard` era duplicata identica in 4 file.
class FifaCard extends StatelessWidget {
  final Widget child;
  const FifaCard({required this.child, super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: child,
      );
}
