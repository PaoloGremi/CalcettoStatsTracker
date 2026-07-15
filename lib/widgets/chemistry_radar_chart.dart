// ─────────────────────────────────────────────────────────────
// Chemistry Radar Chart
// Avatar del giocatore al centro; intorno, radialmente, gli
// avatar dei compagni (o avversari) con distanza dal centro
// inversamente proporzionale al voto medio ottenuto con/contro.
// ─────────────────────────────────────────────────────────────

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player_model.dart';
import '../models/match_model.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import 'player_avatar.dart';

// ── Dati aggregati per un singolo peer ───────────────────────

class _PeerStat {
  final PlayerModel peer;
  int gamesCount = 0;
  double totalVote = 0;
  int votesCount = 0;

  _PeerStat(this.peer);

  double get avgVote => votesCount > 0 ? totalVote / votesCount : 0.0;

  /// Distanza normalizzata [0,1]:
  /// voto alto  → distanza bassa (vicino al centro)
  /// voto basso → distanza alta (lontano dal centro)
  double normalizedDistance(
      {required double minVote, required double maxVote}) {
    if (votesCount == 0) return 0.88; // senza voti → quasi al bordo
    if (maxVote == minVote) return 0.5;
    final normalized = (avgVote - minVote) / (maxVote - minVote); // 0..1
    return 1.0 - normalized; // inverso
  }
}

// ── Widget principale ─────────────────────────────────────────

class ChemistryRadarChart extends StatefulWidget {
  final List<MatchModel> matches;
  final PlayerModel player;

  const ChemistryRadarChart({
    required this.matches,
    required this.player,
    super.key,
  });

  @override
  State<ChemistryRadarChart> createState() => _ChemistryRadarChartState();
}

class _ChemistryRadarChartState extends State<ChemistryRadarChart> {
  bool _showTeammates = true;
  String? _tappedId;

  List<_PeerStat> _buildStats() {
    final data = Provider.of<DataService>(context, listen: false);
    final allPlayers = {
      for (final p in data.getAllPlayers()) p.id: p,
    };

    final stats = <String, _PeerStat>{};

    for (final m in widget.matches) {
      final inTeamA = m.teamA.contains(widget.player.id);
      final sameTeam = inTeamA ? m.teamA : m.teamB;
      final otherTeam = inTeamA ? m.teamB : m.teamA;

      final peerIds = _showTeammates
          ? sameTeam.where((id) => id != widget.player.id)
          : otherTeam.where((_) => true);

      final myVote = m.votes[widget.player.id];

      for (final peerId in peerIds) {
        final peer = allPlayers[peerId];
        if (peer == null) continue;

        stats.putIfAbsent(peerId, () => _PeerStat(peer));
        stats[peerId]!.gamesCount++;

        if (myVote != null) {
          stats[peerId]!.totalVote += myVote;
          stats[peerId]!.votesCount++;
        }
      }
    }

    return stats.values.toList()
      ..sort((a, b) => b.gamesCount.compareTo(a.gamesCount));
  }

  @override
  Widget build(BuildContext context) {
    final peers = _buildStats();
    final accentColor =
        _showTeammates ? AppTheme.accentGreen : AppTheme.accentRed;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _showTeammates
                      ? 'Voto medio con i compagni'
                      : 'Voto medio contro gli avversari',
                  key: ValueKey(_showTeammates),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              _ModeSwitch(
                isTeammate: _showTeammates,
                onChanged: (v) => setState(() {
                  _showTeammates = v;
                  _tappedId = null;
                }),
              ),
            ],
          ),

          const SizedBox(height: 4),
          Center(
            child: Text(
              'Più vicino al centro = voto medio più alto',
              style: TextStyle(
                color: AppTheme.textMuted.withValues(alpha: 0.55),
                fontSize: 9,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Grafico ─────────────────────────────────────────
          if (peers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  _showTeammates
                      ? 'Nessun compagno trovato.'
                      : 'Nessun avversario trovato.',
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ),
            )
          else
            _RadialLayout(
              centerPlayer: widget.player,
              peers: peers.take(12).toList(),
              accentColor: accentColor,
              tappedId: _tappedId,
              onTap: (id) =>
                  setState(() => _tappedId = _tappedId == id ? null : id),
            ),

          // ── Tooltip peer selezionato ─────────────────────────
          if (_tappedId != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppTheme.border),
            _buildTooltip(
              peers.firstWhere((p) => p.peer.id == _tappedId,
                  orElse: () => peers.first),
              accentColor,
            ),
          ],

          if (_tappedId == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Tocca un avatar per i dettagli',
                  style: TextStyle(
                    color: AppTheme.textMuted.withValues(alpha: 0.55),
                    fontSize: 9,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTooltip(_PeerStat stat, Color accentColor) {
    final hasVote = stat.votesCount > 0;
    final voteColor = hasVote
        ? (stat.avgVote >= 7.0
            ? AppTheme.accentGreen
            : stat.avgVote >= 5.5
                ? AppTheme.accentGold
                : AppTheme.accentRed)
        : AppTheme.textMuted;

    final roleColor = switch (stat.peer.role) {
      'P' => AppTheme.accentGold,
      'D' => AppTheme.accentBlue,
      'C' => AppTheme.accentGreen,
      'A' => AppTheme.accentRed,
      _ => AppTheme.textMuted,
    };

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentColor, width: 1.5),
            ),
            child: ClipOval(
              child: PlayerAvatar(
                  name: stat.peer.name,
                  icon: stat.peer.icon,
                  imagePath: stat.peer.imagePath,
                  radius: 22),
            ),
          ),
          const SizedBox(width: 12),
          // Nome + ruolo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  FifaBadge(stat.peer.role, color: roleColor),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      stat.peer.name.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  '${stat.gamesCount} partite insieme',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Voto medio
          Column(
            children: [
              Text(
                hasVote ? stat.avgVote.toStringAsFixed(1) : '—',
                style: TextStyle(
                    color: voteColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900),
              ),
              Text(
                'VOTO MEDIO',
                style: TextStyle(
                    color: voteColor.withValues(alpha: 0.6),
                    fontSize: 8,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Switch Compagni / Avversari ───────────────────────────────

class _ModeSwitch extends StatelessWidget {
  final bool isTeammate;
  final ValueChanged<bool> onChanged;

  const _ModeSwitch({required this.isTeammate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tab(
            label: '🤝 Con',
            active: isTeammate,
            color: AppTheme.accentGreen,
            onTap: () => onChanged(true),
          ),
          _Tab(
            label: '⚔️ Vs',
            active: !isTeammate,
            color: AppTheme.accentRed,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? color : AppTheme.textMuted,
              fontSize: 10,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      );
}

// ── Layout radiale ────────────────────────────────────────────

class _RadialLayout extends StatelessWidget {
  final PlayerModel centerPlayer;
  final List<_PeerStat> peers;
  final Color accentColor;
  final String? tappedId;
  final ValueChanged<String> onTap;

  const _RadialLayout({
    required this.centerPlayer,
    required this.peers,
    required this.accentColor,
    required this.tappedId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final withVotes = peers.where((p) => p.votesCount > 0).toList();
    final minVote = withVotes.isEmpty
        ? 0.0
        : withVotes.map((p) => p.avgVote).reduce(math.min);
    final maxVote = withVotes.isEmpty
        ? 10.0
        : withVotes.map((p) => p.avgVote).reduce(math.max);

    return LayoutBuilder(builder: (context, constraints) {
      final size = math.min(constraints.maxWidth, 320.0);
      const centerR = 34.0;
      const peerR = 22.0;
      final chartR = size / 2 - peerR - 4;

      return Center(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Cerchi concentrici
              Positioned.fill(
                child: CustomPaint(
                  painter: _RingsPainter(accentColor: accentColor),
                ),
              ),

              // Peer
              ...peers.asMap().entries.map((entry) {
                final i = entry.key;
                final stat = entry.value;
                final angle = (2 * math.pi / peers.length) * i - math.pi / 2;
                final dist = stat.normalizedDistance(
                  minVote: minVote,
                  maxVote: maxVote,
                );
                // Distanza radiale: da centerR+peerR (min) a chartR (max)
                final r = (centerR + peerR) +
                    (chartR - centerR - peerR) * dist.clamp(0.02, 1.0);

                final cx = size / 2 + r * math.cos(angle);
                final cy = size / 2 + r * math.sin(angle);
                final isTapped = stat.peer.id == tappedId;

                return Positioned(
                  left: cx - peerR,
                  top: cy - peerR,
                  child: GestureDetector(
                    onTap: () => onTap(stat.peer.id),
                    child: _PeerAvatar(
                      stat: stat,
                      radius: peerR,
                      accentColor: accentColor,
                      isTapped: isTapped,
                    ),
                  ),
                );
              }),

              // Centro
              Positioned(
                left: size / 2 - centerR,
                top: size / 2 - centerR,
                child: _CenterAvatar(
                  player: centerPlayer,
                  radius: centerR,
                  accentColor: accentColor,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ── Painter cerchi concentrici ────────────────────────────────

class _RingsPainter extends CustomPainter {
  final Color accentColor;
  const _RingsPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2 - 8;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final radialPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.05)
      ..strokeWidth = 0.8;

    // 4 cerchi
    for (int i = 1; i <= 4; i++) {
      final r = maxR * (i / 4);
      ringPaint.color = accentColor.withValues(alpha: i == 4 ? 0.12 : 0.07);
      canvas.drawCircle(center, r, ringPaint);
    }

    // 12 raggi
    for (int i = 0; i < 12; i++) {
      final angle = (2 * math.pi / 12) * i;
      canvas.drawLine(
        center,
        Offset(center.dx + maxR * math.cos(angle),
            center.dy + maxR * math.sin(angle)),
        radialPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.accentColor != accentColor;
}

// ── Avatar centrale ───────────────────────────────────────────

class _CenterAvatar extends StatelessWidget {
  final PlayerModel player;
  final double radius;
  final Color accentColor;

  const _CenterAvatar({
    required this.player,
    required this.radius,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: accentColor, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.4),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: PlayerAvatar(
              name: player.name,
              icon: player.icon,
              imagePath: player.imagePath,
              radius: radius),
        ),
      );
}

// ── Avatar peer ───────────────────────────────────────────────

class _PeerAvatar extends StatelessWidget {
  final _PeerStat stat;
  final double radius;
  final Color accentColor;
  final bool isTapped;

  const _PeerAvatar({
    required this.stat,
    required this.radius,
    required this.accentColor,
    required this.isTapped,
  });

  Color _voteColor(double v) {
    if (v >= 7.0) return AppTheme.accentGreen;
    if (v >= 5.5) return AppTheme.accentGold;
    return AppTheme.accentRed;
  }

  @override
  Widget build(BuildContext context) {
    final hasVote = stat.votesCount > 0;
    final voteColor = hasVote ? _voteColor(stat.avgVote) : AppTheme.textMuted;
    final borderColor = isTapped
        ? voteColor
        : (hasVote ? voteColor : accentColor.withValues(alpha: 0.35));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: isTapped ? 2.5 : 1.8,
            ),
            boxShadow: isTapped
                ? [
                    BoxShadow(
                      color: voteColor.withValues(alpha: 0.45),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.2),
                      blurRadius: 4,
                    )
                  ],
          ),
          child: ClipOval(
            child: PlayerAvatar(
                name: stat.peer.name,
                icon: stat.peer.icon,
                imagePath: stat.peer.imagePath,
                radius: radius),
          ),
        ),
        const SizedBox(height: 2),
        // Badge voto
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: AppTheme.bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color:
                  hasVote ? voteColor.withValues(alpha: 0.5) : AppTheme.border,
              width: 0.8,
            ),
          ),
          child: Text(
            hasVote ? stat.avgVote.toStringAsFixed(1) : '—',
            style: TextStyle(
              color: voteColor,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
