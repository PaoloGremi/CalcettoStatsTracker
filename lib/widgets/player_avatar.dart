import 'dart:io';
import 'package:flutter/material.dart';
import '../data/player_icons.dart';

/// Widget avatar riutilizzabile per un giocatore.
/// Mostra: foto da galleria > icona asset > icona Material (in questo ordine).
/// Lo sfondo è un colore vivace deterministico basato sul nome del giocatore.
///
/// Prende campi primitivi invece del modello [Player] per non dipendere dal
/// layer dati: qualunque chiamante (screen, entity di dominio futura, ecc.)
/// può passare i tre valori senza importare `models/player_model.dart`.
class PlayerAvatar extends StatelessWidget {
  final String name;
  final String icon;
  final String? imagePath;
  final double radius;

  const PlayerAvatar({
    required this.name,
    required this.icon,
    this.imagePath,
    this.radius = 22,
    super.key,
  });

  /// Colori vivaci da cui pescare
  static const List<Color> _palette = [
    Color(0xFFE53935), // rosso
    Color(0xFFD81B60), // rosa
    Color(0xFF8E24AA), // viola
    Color(0xFF3949AB), // indaco
    Color(0xFF1E88E5), // blu
    Color(0xFF00897B), // teal
    Color(0xFF43A047), // verde
    Color(0xFFF4511E), // arancione
    Color(0xFFFF8F00), // ambra
    Color(0xFF6D4C41), // marrone
  ];

  /// Restituisce sempre lo stesso colore per lo stesso nome
  Color _colorForPlayer(String name) {
    final hash = name.codeUnits.fold(0, (acc, c) => acc + c);
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final bg = _colorForPlayer(name);

    // 1️⃣ Foto da galleria (path locale)
    if (imagePath != null && imagePath!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(imagePath!)),
        backgroundColor: bg,
      );
    }

    // 2️⃣ Icona asset
    final iconData = getPlayerIcon(icon);
    if (iconData.isAsset) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: AssetImage(iconData.assetPath!),
        backgroundColor: bg,
      );
    }

    // 3️⃣ Icona Material
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Icon(iconData.iconData, size: radius, color: Colors.white),
    );
  }
}
