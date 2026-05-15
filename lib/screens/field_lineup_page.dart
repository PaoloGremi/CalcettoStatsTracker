import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/hive_boxes.dart';
import '../models/player.dart';
import '../widgets/player_avatar.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// Costanti avatar
// ─────────────────────────────────────────────────────────────
const double _kAvatarRadius = 22.0;
// [MIGLIORIA 2] Altezza token aumentata per ospitare il ruolo sotto il nome
const double _kLabelHeight  = 28.0;
const double _kTokenW       = _kAvatarRadius * 2 + 16;
const double _kTokenH       = _kAvatarRadius * 2 + _kLabelHeight + 6;

// ─────────────────────────────────────────────────────────────
// Modello token — posizione mutabile, stato drag
// ─────────────────────────────────────────────────────────────
class _PlayerToken {
  final Player?  player;
  final String   playerId;
  final Color    accent;
  Offset         position;   // centro del token sul campo
  bool           isDragging;

  _PlayerToken({
    required this.player,
    required this.playerId,
    required this.accent,
    required this.position,
    this.isDragging = false,
  });
}

// ─────────────────────────────────────────────────────────────
// FieldLineupPage
// ─────────────────────────────────────────────────────────────
class FieldLineupPage extends StatefulWidget {
  final List<String> teamWhite;
  final List<String> teamBlack;

  const FieldLineupPage({
    super.key,
    required this.teamWhite,
    required this.teamBlack,
  });

  @override
  State<FieldLineupPage> createState() => _FieldLineupPageState();
}

// [MIGLIORIA 3 + 6] TickerProviderStateMixin per supportare più AnimationController
class _FieldLineupPageState extends State<FieldLineupPage>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  // [MIGLIORIA 6] Controller per hint pulsante
  late AnimationController _hintController;
  bool _hintVisible = true; // nasconde l'hint dopo il primo drag

  double _fieldWidth  = 0;
  double _fieldHeight = 0;

  List<_PlayerToken> _tokens = [];
  int? _draggingIndex;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    // [MIGLIORIA 6] Hint che pulsa tra 0.35 e 1.0 di opacità
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  // ── Inizializzazione token (una volta sola) ──────────────
  void _initTokens(double fw, double fh) {
    if (_initialized) return;
    _initialized  = true;
    _fieldWidth   = fw;
    _fieldHeight  = fh;

    final whitePos = _computePositions(
      widget.teamWhite.map((id) => HiveBoxes.playersBox.get(id)).toList(),
      fw, fh, isTop: false,
    );
    final blackPos = _computePositions(
      widget.teamBlack.map((id) => HiveBoxes.playersBox.get(id)).toList(),
      fw, fh, isTop: true,
    );

    _tokens = [
      for (int i = 0; i < widget.teamWhite.length; i++)
        _PlayerToken(
          player:   HiveBoxes.playersBox.get(widget.teamWhite[i]),
          playerId: widget.teamWhite[i],
          accent:   AppTheme.accentBlue,
          position: i < whitePos.length
              ? whitePos[i]
              : Offset(fw / 2, fh * 0.8),
        ),
      for (int i = 0; i < widget.teamBlack.length; i++)
        _PlayerToken(
          player:   HiveBoxes.playersBox.get(widget.teamBlack[i]),
          playerId: widget.teamBlack[i],
          accent:   AppTheme.accentOrange,
          position: i < blackPos.length
              ? blackPos[i]
              : Offset(fw / 2, fh * 0.2),
        ),
    ];

    _entryController.forward();
  }

  // ── Drag handlers — unico GestureDetector sullo Stack ───
  int? _hitTest(Offset localPos) {
    final order = <int>[
      for (int i = _tokens.length - 1; i >= 0; i--)
        if (i != _draggingIndex) i,
    ];
    if (_draggingIndex != null) order.insert(0, _draggingIndex!);

    for (final i in order) {
      final center = _tokens[i].position;
      if ((localPos - center).distance <= _kAvatarRadius + 10) return i;
    }
    return null;
  }

  void _handlePanStart(DragStartDetails d) {
    final hit = _hitTest(d.localPosition);
    if (hit == null) return;
    setState(() {
      _draggingIndex = hit;
      _tokens[hit].isDragging = true;
      // [MIGLIORIA 6] Nascondi hint al primo drag
      if (_hintVisible) {
        _hintVisible = false;
        _hintController.stop();
      }
    });
  }

  void _handlePanUpdate(DragUpdateDetails d) {
    if (_draggingIndex == null) return;
    setState(() {
      final t  = _tokens[_draggingIndex!];
      final np = t.position + d.delta;
      t.position = Offset(
        np.dx.clamp(_kTokenW / 2, _fieldWidth  - _kTokenW / 2),
        np.dy.clamp(_kTokenH / 2, _fieldHeight - _kTokenH / 2),
      );
    });
  }

  void _handlePanEnd(DragEndDetails d) {
    if (_draggingIndex == null) return;
    setState(() {
      _tokens[_draggingIndex!].isDragging = false;
      _draggingIndex = null;
    });
  }

  // ── Reset formazione automatica ──────────────────────────
  void _resetPositions() {
    final whitePos = _computePositions(
      widget.teamWhite.map((id) => HiveBoxes.playersBox.get(id)).toList(),
      _fieldWidth, _fieldHeight, isTop: false,
    );
    final blackPos = _computePositions(
      widget.teamBlack.map((id) => HiveBoxes.playersBox.get(id)).toList(),
      _fieldWidth, _fieldHeight, isTop: true,
    );

    setState(() {
      int wi = 0, bi = 0;
      for (final t in _tokens) {
        if (t.accent == AppTheme.accentBlue) {
          if (wi < whitePos.length) t.position = whitePos[wi++];
        } else {
          if (bi < blackPos.length) t.position = blackPos[bi++];
        }
      }
    });
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        // [MIGLIORIA 5] AppBar con icona + titolo centrato
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_soccer_rounded, size: 16, color: AppTheme.accentBlue),
            const SizedBox(width: 7),
            const FifaLabel('FORMAZIONE', color: AppTheme.textPrimary, fontSize: 13),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Ripristina formazione',
            onPressed: _initialized ? _resetPositions : null,
            color: AppTheme.textSecondary,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // [MIGLIORIA 4] Legenda pill
            _TeamLegend(),
            // [MIGLIORIA 6] Hint pulsante
            if (_hintVisible)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: AnimatedBuilder(
                  animation: _hintController,
                  builder: (context, child) {
                    final opacity = 0.35 + 0.65 * _hintController.value;
                    return Opacity(opacity: opacity, child: child);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.open_with_rounded,
                          size: 12, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Trascina i giocatori per riposizionarli',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const SizedBox(height: 6),
            // Campo — occupa tutto lo spazio disponibile
            Expanded(
              child: LayoutBuilder(builder: (context, constraints) {
                final fw = constraints.maxWidth - 24;
                final fh = constraints.maxHeight - 12;

                if (!_initialized) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => setState(() {
                            _initTokens(fw, fh);
                          }));
                  return const SizedBox.shrink();
                }

                return Center(
                  child: Container(
                    width: fw,
                    height: fh,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: const Color(0xFF1a7a2e).withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart:  _handlePanStart,
                        onPanUpdate: _handlePanUpdate,
                        onPanEnd:    _handlePanEnd,
                        child: Stack(
                          children: [
                            // [MIGLIORIA 1] Campo con gradiente overlay
                            Positioned.fill(
                              child: CustomPaint(painter: _FieldPainter()),
                            ),
                            ..._buildTokenWidgets(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // Token non in drag prima, token in drag per ultimo (sopra tutti)
  List<Widget> _buildTokenWidgets() {
    final result = <Widget>[];
    for (int i = 0; i < _tokens.length; i++) {
      if (i != _draggingIndex) result.add(_buildToken(i));
    }
    if (_draggingIndex != null) result.add(_buildToken(_draggingIndex!));
    return result;
  }

  Widget _buildToken(int index) {
    final t          = _tokens[index];
    final player     = t.player;
    final shortName  = _shortenName(player?.name ?? '?');
    final role       = player?.role ?? '';
    final accent     = t.accent;
    final isDragging = t.isDragging;

    // Animazione entrata staggered
    final delayStart = (index * 0.05).clamp(0.0, 0.75);
    final delayEnd   = (delayStart + 0.4).clamp(0.0, 1.0);
    final curvedAnim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(delayStart, delayEnd, curve: Curves.easeOut),
    );

    // [MIGLIORIA 3] SlideTransition: i giocatori "entrano in campo" dal basso/alto
    final slideOffset = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(curvedAnim);

    return Positioned(
      key: ValueKey(t.playerId),
      left: t.position.dx - _kTokenW / 2,
      top:  t.position.dy - _kTokenH / 2,
      child: IgnorePointer(
        child: SlideTransition(
          position: slideOffset,
          child: FadeTransition(
            opacity: curvedAnim,
            child: AnimatedScale(
              scale: isDragging ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              child: SizedBox(
                width: _kTokenW,
                height: _kTokenH,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Avatar ──────────────────────────────
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          width:  _kAvatarRadius * 2 + 10,
                          height: _kAvatarRadius * 2 + 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(
                                    isDragging ? 0.80 : 0.40),
                                blurRadius: isDragging ? 24 : 12,
                                spreadRadius: isDragging ? 4 : 1,
                              ),
                            ],
                          ),
                        ),
                        // Anello accent
                        Container(
                          width:  _kAvatarRadius * 2 + 4,
                          height: _kAvatarRadius * 2 + 4,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: accent),
                        ),
                        // Foto / icona
                        Container(
                          width: _kAvatarRadius * 2,
                          height: _kAvatarRadius * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0x33FFFFFF),
                                Color(0x33000000),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(3, 3),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.25),
                                blurRadius: 6,
                                offset: const Offset(-2, -2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: player != null
                                ? PlayerAvatar(player: player!, radius: _kAvatarRadius)
                                : CircleAvatar(
                                    radius: _kAvatarRadius,
                                    backgroundColor: AppTheme.surfaceAlt,
                                    child: Icon(
                                      Icons.person,
                                      color: AppTheme.textMuted,
                                      size: _kAvatarRadius,
                                    ),
                                  ),
                          ),
                        ),
                        // [MIGLIORIA 2] Badge ruolo rimosso dall'angolo avatar
                        // (spostato sotto il nome — vedi sezione nome)
                      ],
                    ),
                    const SizedBox(height: 3),
                    // ── [MIGLIORIA 2] Nome + strip ruolo come mini-card ──
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      decoration: BoxDecoration(
                        color: isDragging
                            ? accent.withOpacity(0.92)
                            : Colors.black.withOpacity(0.70),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: accent.withOpacity(isDragging ? 0.0 : 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Riga nome
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            child: Text(
                              shortName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Strip ruolo (visibile solo se ruolo disponibile)
                          if (role.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.85),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                ),
                              ),
                              child: Text(
                                role.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 6.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _shortenName(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return name.toUpperCase();
    return '${parts.first[0].toUpperCase()}. ${parts.last.toUpperCase()}';
  }

  // ══════════════════════════════════════════════════════════
  // Algoritmo di posizionamento
  // ══════════════════════════════════════════════════════════

  int _roleGroup(Player? player) {
    final r = (player?.role ?? '').toUpperCase().trim();
    const gk  = {'P', 'GK', 'POR', 'PORTIERE'};
    const def = {'D', 'DC', 'DS', 'DD', 'TS', 'TD', 'DEF', 'DIF', 'LB', 'RB', 'CB'};
    const mid = {'C', 'CC', 'CM', 'M', 'MID', 'CAM', 'CDM', 'CEN', 'MC', 'MDC', 'MOC'};
    const fwd = {'A', 'ATT', 'W', 'FW', 'ST', 'ALA', 'TR', 'PC', 'CF', 'SS', 'FOR'};
    if (gk.contains(r))  return 0;
    if (def.contains(r)) return 1;
    if (mid.contains(r)) return 2;
    if (fwd.contains(r)) return 3;
    return -1;
  }

  List<({int idx, double x, double y, int group})> _buildSlots(
    int total,
    double fieldWidth,
    double fieldHeight, {
    required bool isTop,
  }) {
    const double margin    = 0.03;
    const double midMargin = 0.04;
    final double yNear = isTop ? margin          : 1.0 - margin;
    final double yFar  = isTop ? 0.5 - midMargin : 0.5 + midMargin;

    double rowY(double t) =>
        (yNear + (yFar - yNear) * t) * fieldHeight;

    const double avatarDiameter = 52.0;
    final maxPerRow = math.max(1, (fieldWidth / avatarDiameter).floor());

    final outfield  = (total - 1).clamp(0, 999);
    final rowCounts = _splitRows(outfield, maxPerRow);

    final slots = <({int idx, double x, double y, int group})>[];
    int slotIdx = 0;

    // GK
    slots.add((idx: slotIdx++, x: fieldWidth / 2, y: rowY(0.0), group: 0));

    // DEF, MID, FWD
    const tValues = [0.30, 0.60, 0.90];
    for (int r = 0; r < rowCounts.length; r++) {
      final count = rowCounts[r];
      if (count == 0) continue;
      final double t = rowCounts.length == 1 ? 0.60 : tValues[r];
      for (int c = 0; c < count; c++) {
        final double xNorm = (c + 1) / (count + 1);
        slots.add((
          idx:   slotIdx++,
          x:     xNorm * fieldWidth,
          y:     rowY(t),
          group: r + 1,
        ));
      }
    }

    return slots;
  }

  List<int> _splitRows(int n, int maxPerRow) {
    if (n <= 0) return [0, 0, 0];
    int nDef = (n / 3).ceil();
    int nFwd = (n / 3).ceil();
    int nMid = n - nDef - nFwd;
    if (nMid < 0) { nFwd += nMid; nMid = 0; }
    nDef = nDef.clamp(0, maxPerRow);
    nFwd = nFwd.clamp(0, maxPerRow);
    nMid = (n - nDef - nFwd).clamp(0, maxPerRow);
    int extra = n - nDef - nMid - nFwd;
    while (extra > 0) {
      if (nDef < maxPerRow)      { nDef++; extra--; }
      else if (nMid < maxPerRow) { nMid++; extra--; }
      else if (nFwd < maxPerRow) { nFwd++; extra--; }
      else break;
    }
    return [nDef, nMid, nFwd];
  }

  List<Offset> _computePositions(
    List<Player?> players,
    double fieldWidth,
    double fieldHeight, {
    required bool isTop,
  }) {
    if (players.isEmpty) return [];

    final total     = players.length;
    final slots     = _buildSlots(total, fieldWidth, fieldHeight, isTop: isTop);
    final positions = List<Offset>.filled(total, Offset.zero);
    final slotFree  = List<bool>.filled(slots.length, true);

    final byGroup = <int, List<int>>{
      0: [], 1: [], 2: [], 3: [], -1: [],
    };
    for (int i = 0; i < total; i++) {
      byGroup[_roleGroup(players[i])]!.add(i);
    }

    bool assignToPreferred(int pi, List<int> groups) {
      for (int s = 0; s < slots.length; s++) {
        if (slotFree[s] && groups.contains(slots[s].group)) {
          positions[pi] = Offset(slots[s].x, slots[s].y);
          slotFree[s]   = false;
          return true;
        }
      }
      return false;
    }

    bool assignToAny(int pi) {
      final ig = _roleGroup(players[pi]);
      final sameGroup = slots.where((s) => s.group == (ig < 0 ? 2 : ig));
      double idealY = sameGroup.isEmpty
          ? fieldHeight / 2
          : sameGroup.map((s) => s.y).reduce((a, b) => a + b) /
              sameGroup.length;

      int? best;
      double bestDist = double.infinity;
      for (int s = 0; s < slots.length; s++) {
        if (!slotFree[s]) continue;
        final d = (slots[s].y - idealY).abs();
        if (d < bestDist) { bestDist = d; best = s; }
      }
      if (best == null) return false;
      positions[pi] = Offset(slots[best].x, slots[best].y);
      slotFree[best] = false;
      return true;
    }

    for (final i in byGroup[0]!)  { if (!assignToPreferred(i, [0])) assignToAny(i); }
    for (final i in byGroup[1]!)  { if (!assignToPreferred(i, [1])) assignToAny(i); }
    for (final i in byGroup[2]!)  { if (!assignToPreferred(i, [2])) assignToAny(i); }
    for (final i in byGroup[3]!)  { if (!assignToPreferred(i, [3])) assignToAny(i); }
    for (final i in byGroup[-1]!) { assignToAny(i); }

    return positions;
  }
}

// ─────────────────────────────────────────────────────────────
// [MIGLIORIA 4] Legenda team — pill colorata
// ─────────────────────────────────────────────────────────────

class _TeamLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _LegendChip(color: AppTheme.accentBlue,   label: 'Maglia Bianca'),
          _LegendChip(color: AppTheme.accentOrange, label: 'Maglia Colorata'),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color  color;
  final String label;
  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 5)],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// [MIGLIORIA 1] _FieldPainter — campo verde con gradiente overlay
// ─────────────────────────────────────────────────────────────

class _FieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Strisce verde alternato
    const stripes = 10;
    for (int i = 0; i < stripes; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, h / stripes * i, w, h / stripes),
        Paint()
          ..color = i.isEven
              ? const Color(0xFF1e8b3a)
              : const Color(0xFF1a7a2e),
      );
    }

    // [MIGLIORIA 1] Gradiente overlay per profondità realistica
    final gradOverlay = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x44000000), // ombra bordo superiore
          Color(0x00000000), // centro trasparente
          Color(0x00000000),
          Color(0x44000000), // ombra bordo inferiore
        ],
        stops: [0.0, 0.22, 0.78, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), gradOverlay);

    // [MIGLIORIA 1] Linee più visibili: opacità 0.75, strokeWidth 2.2
    final line = Paint()
      ..color = Colors.white.withOpacity(0.75)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(6, 6, w - 12, h - 12), const Radius.circular(4)),
      line,
    );
    canvas.drawLine(Offset(6, h / 2), Offset(w - 6, h / 2), line);
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.18, line);
    canvas.drawCircle(Offset(w / 2, h / 2), 2.5,
        Paint()..color = Colors.white.withOpacity(0.6));

    final pW = w * 0.6, pH = h * 0.13, pxL = (w - w * 0.6) / 2;
    final sW = w * 0.3, sH = h * 0.06;

    // Aree superiori
    canvas.drawRect(Rect.fromLTWH(pxL, 6, pW, pH), line);
    canvas.drawRect(Rect.fromLTWH((w - sW) / 2, 6, sW, sH), line);
    canvas.drawCircle(Offset(w / 2, 6 + pH * 0.75), 2.5,
        Paint()..color = Colors.white.withOpacity(0.6));

    // Aree inferiori
    canvas.drawRect(Rect.fromLTWH(pxL, h - 6 - pH, pW, pH), line);
    canvas.drawRect(Rect.fromLTWH((w - sW) / 2, h - 6 - sH, sW, sH), line);
    canvas.drawCircle(Offset(w / 2, h - 6 - pH * 0.75), 2.5,
        Paint()..color = Colors.white.withOpacity(0.6));

    // Porte
    final gW = w * 0.22, gH = h * 0.022;
    final gPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH((w - gW) / 2, 3.5, gW, gH), gPaint);
    canvas.drawRect(
        Rect.fromLTWH((w - gW) / 2, h - 3.5 - gH, gW, gH), gPaint);

    // Archi area
    final arc = Paint()
      ..color = Colors.white.withOpacity(0.50)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w / 2, 6 + pH * 0.75),
          width: w * 0.28, height: w * 0.28),
      math.pi * 0.15, math.pi * 0.7, false, arc,
    );
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w / 2, h - 6 - pH * 0.75),
          width: w * 0.28, height: w * 0.28),
      -math.pi * 0.85, math.pi * 0.7, false, arc,
    );

    // Angoli
    final cR = w * 0.035;
    final corners = [Offset(6,6), Offset(w-6,6), Offset(6,h-6), Offset(w-6,h-6)];
    final cAngles = [0.0, math.pi/2, -math.pi/2, math.pi];
    for (int k = 0; k < 4; k++) {
      canvas.drawArc(
        Rect.fromCenter(center: corners[k], width: cR*2, height: cR*2),
        cAngles[k], math.pi/2, false, line,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
