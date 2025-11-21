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

  // 🟢 Icone personalizzate
  PlayerIcon(key: 'Niko', assetPath: 'assets/icons/niko.png'),
  PlayerIcon(key: 'Paul', assetPath: 'assets/icons/paul.png'),
  PlayerIcon(key: 'Jack', assetPath: 'assets/icons/jack.png'),
  PlayerIcon(key: 'Max', assetPath: 'assets/icons/max.png'),
  PlayerIcon(key: 'Lucio', assetPath: 'assets/icons/lucio.png'),
  PlayerIcon(key: 'Ste', assetPath: 'assets/icons/stefano.png'),
  PlayerIcon(key: 'Fla', assetPath: 'assets/icons/flavio.png'),
  PlayerIcon(key: 'Dan', assetPath: 'assets/icons/DanieleGandolfi.png'),
  PlayerIcon(key: 'Ago', assetPath: 'assets/icons/Ago.png'),
  PlayerIcon(key: 'Cesa', assetPath: 'assets/icons/cesare.png'),
  PlayerIcon(key: 'Dinho', assetPath: 'assets/icons/danielinho.png'),
  PlayerIcon(key: 'Gigi', assetPath: 'assets/icons/luigi.png'),
  PlayerIcon(key: 'Espo', assetPath: 'assets/icons/marcoEspo.png'),
  PlayerIcon(key: 'TeoL', assetPath: 'assets/icons/matteoLupo.png'),
  PlayerIcon(key: 'Mauri', assetPath: 'assets/icons/maurizio.png'),
  PlayerIcon(key: 'Rob', assetPath: 'assets/icons/roberto.png'),
  PlayerIcon(key: 'Sam', assetPath: 'assets/icons/samuele.png'),
  PlayerIcon(key: 'TeoV', assetPath: 'assets/icons/teoVanini.png'),
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