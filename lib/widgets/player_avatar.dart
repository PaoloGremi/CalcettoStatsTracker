import 'dart:io';
import 'package:flutter/material.dart';
import '../data/player_icons.dart';
import '../models/player.dart';

/// Widget avatar riutilizzabile per un giocatore.
/// Mostra: foto da galleria > icona asset > icona Material (in questo ordine).
class PlayerAvatar extends StatelessWidget {
  final Player player;
  final double radius;

  const PlayerAvatar({
    required this.player,
    this.radius = 22,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // 1️⃣ Foto da galleria (path locale)
    if (player.imagePath != null && player.imagePath!.isNotEmpty) {
      final file = File(player.imagePath!);
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(file),
        backgroundColor: Colors.grey[800],
      );
    }

    // 2️⃣ Icona asset o Material predefinita
    final iconData = getPlayerIcon(player.icon);
    if (iconData.isAsset) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: AssetImage(iconData.assetPath!),
        backgroundColor: Colors.grey[800],
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[800],
      child: Icon(iconData.iconData, size: radius),
    );
  }
}
