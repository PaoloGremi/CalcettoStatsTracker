import 'package:flutter/material.dart';

/// Mappa delle icone disponibili per i giocatori.
/// Chiave = stringa salvata nel modello Player.
/// Valore = icona Material.
final List<PlayerIcon> availableIcons = [
  // 🔵 Icone Flutter
  PlayerIcon(key: 'person', iconData: Icons.person),
  PlayerIcon(key: 'soccer', iconData: Icons.sports_soccer),
  PlayerIcon(key: 'star', iconData: Icons.star),
  PlayerIcon(key: 'tech', iconData: Icons.military_tech),
  PlayerIcon(key: 'shield', iconData: Icons.shield),
  PlayerIcon(key: 'flash', iconData: Icons.flash_on),
  PlayerIcon(key: 'run', iconData: Icons.directions_run),

  // 🟢 Icone personalizzate
  PlayerIcon(key: 'custom1', assetPath: 'assets/icons/niko.png'),
  PlayerIcon(key: 'custom2', assetPath: 'assets/icons/paul.png'),
  PlayerIcon(key: 'custom3', assetPath: 'assets/icons/jack.png'),
  PlayerIcon(key: 'custom4', assetPath: 'assets/icons/max.png'),
  PlayerIcon(key: 'custom5', assetPath: 'assets/icons/lucio.png'),
  PlayerIcon(key: 'custom6', assetPath: 'assets/icons/stefano.png'),
  PlayerIcon(key: 'custom7', assetPath: 'assets/icons/flavio.png'),
];

class PlayerIcon {
  final String key;
  final IconData? iconData;   // per icone Flutter
  final String? assetPath;    // per icone personalizzate

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