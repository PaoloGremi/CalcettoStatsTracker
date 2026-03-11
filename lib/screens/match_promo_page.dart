import 'dart:io';
import 'package:flutter/material.dart';
import '../data/hive_boxes.dart';
import '../data/player_icons.dart';
import '../models/player.dart';
import '../models/field_model.dart';
import '../widgets/player_avatar.dart';
import '../theme/app_theme.dart';

class MatchPromoPage extends StatelessWidget {
  final String dataOra;
  final String campo;        // legacy: key stringa per campi predefiniti
  final FieldModel? fieldModel; // nuovo: campo da Hive (priorità su campo)
  final String prezzo;
  final String nGiocatori;
  final List<String> teamBlack;
  final List<String> teamWhite;

  const MatchPromoPage({
    super.key,
    required this.dataOra,
    this.campo = '',
    this.fieldModel,
    required this.prezzo,
    required this.nGiocatori,
    required this.teamBlack,
    required this.teamWhite,
  });

  static const _backgrounds = {
    'SanFrancesco': 'assets/images/campoSanFrancescoColorato.jpg',
    'Montanaso':    'assets/images/montanaso.jpg',
    'Faustina':     'assets/images/faustina.png',
    'Pergola':      'assets/images/laPergola.jpg',
    'Other':        'assets/images/sfondoPalloneGenerico.png',
  };

  static const _locationLabels = {
    'SanFrancesco': 'San Francesco',
    'Montanaso':    'Montanaso',
    'Faustina':     'Faustina Arena',
    'Pergola':      'La Pergola',
    'Other':        'Campo Sportivo',
  };

  static const _locationAddresses = {
    'SanFrancesco': 'Via Serravalle, 4 — Lodi',
    'Montanaso':    'Via G. Garibaldi — Montanaso Lombardo',
    'Faustina':     'Piazzale degli Sport — Lodi',
    'Pergola':      'Via per Ca de Bolli, 11 — San Martino in Strada',
    'Other':        '',
  };

  String get _bg => fieldModel != null
      ? '' // segnale: usa File image, non asset
      : (_backgrounds[campo] ?? 'assets/images/sfondoPalloneGenerico.png');

  String get _locationLabel => fieldModel != null
      ? fieldModel!.name
      : (_locationLabels[campo] ?? campo);

  String get _locationAddress => fieldModel != null
      ? fieldModel!.address
      : (_locationAddresses[campo] ?? '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const FifaLabel('Locandina Partita',
            color: AppTheme.textPrimary, fontSize: 13),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            // ── HERO POSTER ───────────────────────────────────────
            _HeroPoster(
              bgAsset: _bg,
              fieldImagePath: fieldModel?.imagePath,
              locationLabel: _locationLabel,
              locationAddress: _locationAddress,
              dataOra: dataOra,
              nGiocatori: nGiocatori,
              prezzo: prezzo,
            ),

            // ── VS DIVIDER ────────────────────────────────────────
            _VsDivider(
              leftLabel: 'Maglia Bianca',
              rightLabel: 'Maglia Colorata',
              leftCount: teamWhite.length,
              rightCount: teamBlack.length,
            ),

            // ── GRIGLIA GIOCATORI ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Team Bianco
                  Expanded(
                    child: _PlayerGrid(
                      playerIds: teamWhite,
                      accent: AppTheme.accentBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Team Colorato
                  Expanded(
                    child: _PlayerGrid(
                      playerIds: teamBlack,
                      accent: AppTheme.accentOrange,
                    ),
                  ),
                ],
              ),
            ),

            // ── FOOTER ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_soccer_rounded,
                      color: AppTheme.textMuted, size: 13),
                  const SizedBox(width: 6),
                  FifaLabel('Champions Calcetto Stats',
                      color: AppTheme.textMuted, fontSize: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Hero Poster — sfondo campo con overlay e info partita
// ─────────────────────────────────────────────────────────────

class _HeroPoster extends StatelessWidget {
  final String bgAsset, locationLabel, locationAddress, dataOra, nGiocatori, prezzo;
  final String? fieldImagePath;
  const _HeroPoster({
    required this.bgAsset, required this.locationLabel, required this.locationAddress,
    required this.dataOra, required this.nGiocatori, required this.prezzo,
    this.fieldImagePath,
  });

  @override
  Widget build(BuildContext context) {
    final hasFileImage = fieldImagePath != null && File(fieldImagePath!).existsSync();

    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Foto campo: File se disponibile, altrimenti asset
          if (hasFileImage)
            Image.file(File(fieldImagePath!), fit: BoxFit.cover)
          else
            Image.asset(bgAsset, fit: BoxFit.cover),

          // Overlay con gradiente diagonale
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xCC000000),
                  Color(0x88000000),
                  Color(0xEE000000),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Linea accent verticale sinistra
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(width: 3, color: AppTheme.accentGreen),
          ),

          // Contenuto
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pill data
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppTheme.accentGreen.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: AppTheme.accentGreen, size: 12),
                      const SizedBox(width: 6),
                      Text(dataOra,
                          style: const TextStyle(
                              color: AppTheme.accentGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),

                const Spacer(),

                // Nome campo gigante
                Text(
                  locationLabel.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    height: 1,
                  ),
                ),
                if (locationAddress.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppTheme.textSecondary, size: 12),
                      const SizedBox(width: 4),
                      Text(locationAddress,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Chip info row
                Row(
                  children: [
                    _PosterChip(
                      icon: Icons.sports_soccer_rounded,
                      text: nGiocatori,
                      color: AppTheme.accentGreen,
                    ),
                    const SizedBox(width: 8),
                    if (prezzo != '—' && prezzo.isNotEmpty)
                      _PosterChip(
                        icon: Icons.euro_rounded,
                        text: '$prezzo / persona',
                        color: AppTheme.accentGold,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _PosterChip({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: color.withOpacity(0.45)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// VS Divider — separatore centrale con punteggio VS
// ─────────────────────────────────────────────────────────────

class _VsDivider extends StatelessWidget {
  final String leftLabel, rightLabel;
  final int leftCount, rightCount;
  const _VsDivider({
    required this.leftLabel, required this.rightLabel,
    required this.leftCount, required this.rightCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppTheme.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          // Team A
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FifaLabel(leftLabel, color: AppTheme.accentBlue, fontSize: 11),
                const SizedBox(height: 2),
                Text('$leftCount giocatori',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 10)),
              ],
            ),
          ),

          // Badge VS centrale
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: AppTheme.bg,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 10, spreadRadius: 2),
              ],
            ),
            alignment: Alignment.center,
            child: const Text('VS',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),

          // Team B
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FifaLabel(rightLabel, color: AppTheme.accentOrange, fontSize: 11),
                const SizedBox(height: 2),
                Text('$rightCount giocatori',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Griglia giocatori — card stile figurina Panini
// ─────────────────────────────────────────────────────────────

class _PlayerGrid extends StatelessWidget {
  final List<String> playerIds;
  final Color accent;
  const _PlayerGrid({required this.playerIds, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: playerIds.map((id) {
        final player = HiveBoxes.playersBox.get(id);
        return _PlayerFigCard(player: player, playerId: id, accent: accent);
      }).toList(),
    );
  }
}

class _PlayerFigCard extends StatelessWidget {
  final Player? player;
  final String playerId;
  final Color accent;
  const _PlayerFigCard({required this.player, required this.playerId, required this.accent});

  @override
  Widget build(BuildContext context) {
    final name = player?.name ?? 'Sconosciuto';
    final role = player?.role ?? '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Accent strip sinistra
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(width: 3, color: accent.withOpacity(0.6)),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accent.withOpacity(0.35), width: 1.5),
                    ),
                    child: player != null
                        ? PlayerAvatar(player: player!, radius: 20)
                        : CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.surfaceAlt,
                            child: Icon(Icons.person, color: AppTheme.textMuted, size: 20),
                          ),
                  ),
                  const SizedBox(width: 10),

                  // Nome
                  Expanded(
                    child: Text(
                      name.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Ruolo badge
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: accent.withOpacity(0.35)),
                    ),
                    alignment: Alignment.center,
                    child: Text(role,
                      style: TextStyle(
                          color: accent, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
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
