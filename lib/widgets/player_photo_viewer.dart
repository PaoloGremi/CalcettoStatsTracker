import 'dart:io';

import 'package:flutter/material.dart';

import '../data/player_icons.dart';

/// Immagine a schermo intero della foto (o dell'icona asset) di un giocatore.
/// Pizzica per zoomare; un tocco o la X chiudono.
class PlayerPhotoViewer extends StatelessWidget {
  final ImageProvider image;
  final String heroTag;

  const PlayerPhotoViewer({
    required this.image,
    required this.heroTag,
    super.key,
  });

  /// Immagine mostrabile per un giocatore: foto da galleria > icona asset.
  /// `null` se il giocatore ha solo un'icona Material (niente da ingrandire).
  static ImageProvider? imageFor({required String icon, String? imagePath}) {
    if (imagePath != null && imagePath.isNotEmpty) {
      return FileImage(File(imagePath));
    }
    final iconData = getPlayerIcon(icon);
    return iconData.isAsset ? AssetImage(iconData.assetPath!) : null;
  }

  /// Apre il visualizzatore con una dissolvenza su sfondo nero.
  static Future<void> open(
    BuildContext context, {
    required ImageProvider image,
    required String heroTag,
  }) =>
      Navigator.of(context).push(PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) =>
            PlayerPhotoViewer(image: image, heroTag: heroTag),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ));

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: InteractiveViewer(
                  maxScale: 4,
                  child: Center(
                    child: Hero(
                      tag: heroTag,
                      child: Image(image: image, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  tooltip: 'Chiudi',
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      );
}
