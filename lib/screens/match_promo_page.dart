import 'dart:io';
import 'package:flutter/material.dart';
import '../data/hive_boxes.dart';
import '../models/player.dart';
import '../models/field_model.dart';
import '../widgets/player_avatar.dart';
import '../theme/app_theme.dart';
import 'field_lineup_page.dart';

class MatchPromoPage extends StatefulWidget {
  final String dataOra;
  final String campo;
  final FieldModel? fieldModel;
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

  @override
  State<MatchPromoPage> createState() => _MatchPromoPageState();
}

class _MatchPromoPageState extends State<MatchPromoPage>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _listController;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;

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

  String get _bg => widget.fieldModel != null
      ? ''
      : (_backgrounds[widget.campo] ?? 'assets/images/sfondoPalloneGenerico.png');

  String get _locationLabel => widget.fieldModel != null
      ? widget.fieldModel!.name
      : (_locationLabels[widget.campo] ?? widget.campo);

  String get _locationAddress => widget.fieldModel != null
      ? widget.fieldModel!.address
      : (_locationAddresses[widget.campo] ?? '');

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _heroFade = CurvedAnimation(parent: _heroController, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroController, curve: Curves.easeOut));

    _heroController.forward().then((_) => _listController.forward());
  }

  @override
  void dispose() {
    _heroController.dispose();
    _listController.dispose();
    super.dispose();
  }

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
            FadeTransition(
              opacity: _heroFade,
              child: SlideTransition(
                position: _heroSlide,
                child: _HeroPoster(
                  bgAsset: _bg,
                  fieldImagePath: widget.fieldModel?.imagePath,
                  locationLabel: _locationLabel,
                  locationAddress: _locationAddress,
                  dataOra: widget.dataOra,
                  nGiocatori: widget.nGiocatori,
                  prezzo: widget.prezzo,
                ),
              ),
            ),

            // ── VS DIVIDER ────────────────────────────────────────
            _VsDivider(
              leftLabel: 'Maglia Bianca',
              rightLabel: 'Maglia Colorata',
              leftCount: widget.teamWhite.length,
              rightCount: widget.teamBlack.length,
              listController: _listController,
            ),

            // ── GRIGLIA GIOCATORI ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _PlayerGrid(
                      playerIds: widget.teamWhite,
                      accent: AppTheme.accentBlue,
                      listController: _listController,
                      startDelay: 0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PlayerGrid(
                      playerIds: widget.teamBlack,
                      accent: AppTheme.accentOrange,
                      listController: _listController,
                      startDelay: 100,
                    ),
                  ),
                ],
              ),
            ),

            // ── PULSANTE FORMAZIONE ───────────────────────────────
            _LineupButton(
              teamWhite: widget.teamWhite,
              teamBlack: widget.teamBlack,
            ),

            // ── FOOTER ────────────────────────────────────────────
            _FooterBranding(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Hero Poster — gradiente bottom-up, overlay saturazione
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
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Foto campo
          if (hasFileImage)
            Image.file(File(fieldImagePath!), fit: BoxFit.cover)
          else
            Image.asset(bgAsset, fit: BoxFit.cover),

          // Overlay multiply per saturazione
          Container(
            decoration: const BoxDecoration(
              color: Color(0x22001a00),
            ),
          ),

          // Gradiente bottom-up: lascia la foto visibile in alto
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x55000000),
                  Color(0xDD000000),
                  Color(0xF5000000),
                ],
                stops: [0.0, 0.35, 0.72, 1.0],
              ),
            ),
          ),

          // Linea accent verticale sinistra con gradient
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(
              width: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.accentGreen,
                    AppTheme.accentGreen,
                  ],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // Contenuto
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pill data con glow
                _GlowPill(
                  icon: Icons.calendar_today_rounded,
                  text: dataOra,
                  color: AppTheme.accentGreen,
                ),

                const Spacer(),

                // Nome campo
                Text(
                  locationLabel.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    height: 1,
                    shadows: [
                      Shadow(color: Color(0x88000000), blurRadius: 12),
                    ],
                  ),
                ),

                // Indirizzo con colore accent leggibile
                if (locationAddress.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          color: AppTheme.accentGreen.withOpacity(0.8), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        locationAddress,
                        style: TextStyle(
                          color: AppTheme.accentGreen.withOpacity(0.75),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
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

// Pill con box shadow glow
class _GlowPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _GlowPill({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: color.withOpacity(0.5)),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.35),
          blurRadius: 14,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 6),
        Text(dataOra_placeholder,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800)),
      ],
    ),
  );

  // placeholder field workaround per campo testo
  String get dataOra_placeholder => text;
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
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.2),
          blurRadius: 10,
          spreadRadius: 0,
        ),
      ],
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
// VS Divider — scenografico con gradient e jersey swatches
// ─────────────────────────────────────────────────────────────

class _VsDivider extends StatelessWidget {
  final String leftLabel, rightLabel;
  final int leftCount, rightCount;
  final AnimationController listController;

  const _VsDivider({
    required this.leftLabel, required this.rightLabel,
    required this.leftCount, required this.rightCount,
    required this.listController,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: listController, curve: Curves.easeOut),
      child: Container(
        margin: EdgeInsets.zero,
        decoration: const BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(color: AppTheme.border),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Gradient di sfondo che evoca i due team
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentBlue.withOpacity(0.07),
                    AppTheme.surface,
                    AppTheme.accentOrange.withOpacity(0.07),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Linee decorative laterali al badge VS
            Positioned(
              left: 0, right: 0,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.accentBlue.withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 56), // spazio badge VS
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppTheme.accentOrange.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),

            // Contenuto
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                children: [
                  // Team Bianco
                  Expanded(
                    child: Row(
                      children: [
                        // Jersey swatch
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentBlue.withOpacity(0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FifaLabel(leftLabel,
                                color: AppTheme.accentBlue, fontSize: 11),
                            const SizedBox(height: 2),
                            Text('$leftCount giocatori',
                                style: const TextStyle(
                                    color: AppTheme.textMuted, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Badge VS centrale con gradient border
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accentBlue.withOpacity(0.25),
                          AppTheme.bg,
                          AppTheme.accentOrange.withOpacity(0.25),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      border: Border.all(color: AppTheme.border, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: AppTheme.accentBlue.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(-3, 0),
                        ),
                        BoxShadow(
                          color: AppTheme.accentOrange.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(3, 0),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text('VS',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  // Team Colorato
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            FifaLabel(rightLabel,
                                color: AppTheme.accentOrange, fontSize: 11),
                            const SizedBox(height: 2),
                            Text('$rightCount giocatori',
                                style: const TextStyle(
                                    color: AppTheme.textMuted, fontSize: 10)),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentOrange.withOpacity(0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
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

// ─────────────────────────────────────────────────────────────
// Player Grid — con animazione staggered
// ─────────────────────────────────────────────────────────────

class _PlayerGrid extends StatelessWidget {
  final List<String> playerIds;
  final Color accent;
  final AnimationController listController;
  final int startDelay;

  const _PlayerGrid({
    required this.playerIds,
    required this.accent,
    required this.listController,
    required this.startDelay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: playerIds.asMap().entries.map((entry) {
        final index = entry.key;
        final id = entry.value;
        final player = HiveBoxes.playersBox.get(id);

        // stagger: ogni card appare con delay progressivo
        final double delayStart = (startDelay / 1000) + (index * 0.08);
        final double delayEnd = (delayStart + 0.4).clamp(0.0, 1.0);
        final Animation<double> fade = CurvedAnimation(
          parent: listController,
          curve: Interval(delayStart.clamp(0.0, 1.0), delayEnd,
              curve: Curves.easeOut),
        );
        final Animation<Offset> slide = Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: listController,
          curve: Interval(delayStart.clamp(0.0, 1.0), delayEnd,
              curve: Curves.easeOut),
        ));

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: _PlayerFigCard(
                player: player, playerId: id, accent: accent),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PlayerFigCard — stile figurina con glow e rating
// ─────────────────────────────────────────────────────────────

class _PlayerFigCard extends StatelessWidget {
  final Player? player;
  final String playerId;
  final Color accent;
  const _PlayerFigCard(
      {required this.player, required this.playerId, required this.accent});

  @override
  Widget build(BuildContext context) {
    final name = player?.name ?? 'Sconosciuto';
    final role = player?.role ?? '?';
    // Rating non disponibile nel modello Player attuale
    const int? rating = null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Sottile shimmer/glow gradient sul bordo superiore
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      accent.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Accent strip sinistra con gradient verticale
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accent.withOpacity(0.3),
                      accent.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              child: Row(
                children: [
                  // Avatar con border glow
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: accent.withOpacity(0.45), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: player != null
                        ? PlayerAvatar(player: player!, radius: 20)
                        : CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.surfaceAlt,
                            child: Icon(Icons.person,
                                color: AppTheme.textMuted, size: 20),
                          ),
                  ),
                  const SizedBox(width: 10),

                  // Nome
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
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
                        if (rating != null) ...[
                          const SizedBox(height: 2),
                          _MiniStars(rating: rating, color: accent),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Rating numerico FUT (se disponibile)
                  if (rating != null) ...[
                    Container(
                      width: 30, height: 28,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: accent.withOpacity(0.4)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$rating',
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],

                  // Ruolo badge
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: accent.withOpacity(0.35)),
                    ),
                    alignment: Alignment.center,
                    child: Text(role,
                      style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w900),
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

// Mini stelle rating
class _MiniStars extends StatelessWidget {
  final int rating;
  final Color color;
  const _MiniStars({required this.rating, required this.color});

  @override
  Widget build(BuildContext context) {
    // Converte rating (es. 0-100) in stelle su 5
    final stars = ((rating / 20).clamp(0, 5)).round();
    return Row(
      children: List.generate(5, (i) => Icon(
        i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
        color: i < stars ? color.withOpacity(0.9) : color.withOpacity(0.25),
        size: 9,
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Lineup Button — apre la pagina campo stile FIFA
// ─────────────────────────────────────────────────────────────

class _LineupButton extends StatelessWidget {
  final List<String> teamWhite;
  final List<String> teamBlack;
  const _LineupButton({required this.teamWhite, required this.teamBlack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => FieldLineupPage(
              teamWhite: teamWhite,
              teamBlack: teamBlack,
            ),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        ),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                AppTheme.accentGreen.withOpacity(0.85),
                const Color(0xFF0d6b25),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppTheme.accentGreen.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentGreen.withOpacity(0.35),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icona campo
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sports_soccer_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'VISUALIZZA FORMAZIONE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Footer branding — gradient separatore e logo stilizzato
// ─────────────────────────────────────────────────────────────

class _FooterBranding extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Separatore gradient bicolore
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.accentBlue.withOpacity(0.6),
                Colors.transparent,
                AppTheme.accentOrange.withOpacity(0.6),
              ],
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icona con glow verde
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentGreen.withOpacity(0.08),
                  border: Border.all(
                      color: AppTheme.accentGreen.withOpacity(0.25), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGreen.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.sports_soccer_rounded,
                    color: AppTheme.accentGreen, size: 13),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FifaLabel('Champions Calcetto Stats',
                      color: AppTheme.textSecondary, fontSize: 11),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
