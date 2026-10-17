import 'package:flutter/material.dart';

/// Mappa delle icone disponibili per i giocatori.
/// Chiave = stringa salvata nel modello Player.
/// Valore = icona Material.
final List<PlayerIcon> availableIcons = [
  // 🔵 Icone Flutter
  PlayerIcon(key: 'person', iconData: Icons.person),
  PlayerIcon(key: 'soccer', iconData: Icons.sports_soccer),
  PlayerIcon(key: 'star', iconData: Icons.star),
  PlayerIcon(key: 'shield', iconData: Icons.shield),
  PlayerIcon(key: 'flash', iconData: Icons.flash_on),
  PlayerIcon(key: 'run', iconData: Icons.directions_run),
];

class PlayerIcon {
  final String key;
  final IconData? iconData; // per icone Flutter
  final String? assetPath; // per icone personalizzate

  const PlayerIcon({
    required this.key,
    this.iconData,
    this.assetPath,
  });
  bool get isAsset => assetPath != null;
}

PlayerIcon getPlayerIcon(String key) {
  return availableIcons.firstWhere(
    (icon) => icon.key == key,
    orElse: () => PlayerIcon(key: 'person', iconData: Icons.person),
  );
}
