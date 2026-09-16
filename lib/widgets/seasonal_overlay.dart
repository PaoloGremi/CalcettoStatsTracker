import 'dart:math';

import 'package:flutter/material.dart';

import '../core/util/seasonal_theme.dart';

/// Overlay decorativo animato che disegna particelle a tema (neve, uova,
/// pipistrelli, sole...) in base al [SeasonalTheme] corrente. Pensato per
/// essere posato sopra lo sfondo della splash screen, dietro a logo/testo.
///
/// Possiede un proprio [AnimationController] (ciclo di vita autonomo): il
/// widget che lo usa non deve gestirne il dispose.
class SeasonalOverlay extends StatefulWidget {
  final SeasonalTheme theme;

  const SeasonalOverlay({super.key, required this.theme});

  @override
  State<SeasonalOverlay> createState() => _SeasonalOverlayState();
}

class _SeasonalOverlayState extends State<SeasonalOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _particles = _buildParticles(widget.theme);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty) return const SizedBox.shrink();

    final motion = _motionFor(widget.theme);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _SeasonalPainter(
            particles: _particles,
            progress: _ctrl.value,
            motion: motion,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Configurazione per tema
// ─────────────────────────────────────────────────────────────

enum _MotionStyle { falling, floating, crossing, rising }

class _SeasonalConfig {
  final List<String> glyphs;
  final int count;
  final double minSize;
  final double maxSize;
  final double minSpeed;
  final double maxSpeed;
  final double minOpacity;
  final double maxOpacity;
  final double sway;

  const _SeasonalConfig({
    required this.glyphs,
    required this.count,
    required this.minSize,
    required this.maxSize,
    required this.minSpeed,
    required this.maxSpeed,
    required this.minOpacity,
    required this.maxOpacity,
    required this.sway,
  });
}

const Map<SeasonalTheme, _SeasonalConfig> _configs = {
  SeasonalTheme.christmas: _SeasonalConfig(
    glyphs: ['❄️', '✨', '🎄'],
    count: 26,
    minSize: 14,
    maxSize: 26,
    minSpeed: 0.5,
    maxSpeed: 1.1,
    minOpacity: 0.35,
    maxOpacity: 0.85,
    sway: 0.05,
  ),
  SeasonalTheme.easter: _SeasonalConfig(
    glyphs: ['🥚', '🐰', '🌸'],
    count: 14,
    minSize: 18,
    maxSize: 30,
    minSpeed: 0.4,
    maxSpeed: 0.9,
    minOpacity: 0.4,
    maxOpacity: 0.85,
    sway: 0.04,
  ),
  SeasonalTheme.halloween: _SeasonalConfig(
    glyphs: ['🎃', '🦇', '👻'],
    count: 12,
    minSize: 18,
    maxSize: 30,
    minSpeed: 0.4,
    maxSpeed: 1.0,
    minOpacity: 0.35,
    maxOpacity: 0.8,
    sway: 0.06,
  ),
  SeasonalTheme.summer: _SeasonalConfig(
    glyphs: ['☀️', '🌴', '🌊'],
    count: 16,
    minSize: 16,
    maxSize: 28,
    minSpeed: 0.3,
    maxSpeed: 0.8,
    minOpacity: 0.35,
    maxOpacity: 0.8,
    sway: 0.05,
  ),
};

_MotionStyle _motionFor(SeasonalTheme theme) => switch (theme) {
      SeasonalTheme.christmas => _MotionStyle.falling,
      SeasonalTheme.easter => _MotionStyle.floating,
      SeasonalTheme.halloween => _MotionStyle.crossing,
      SeasonalTheme.summer => _MotionStyle.rising,
      SeasonalTheme.none => _MotionStyle.falling,
    };

// ─────────────────────────────────────────────────────────────
// Particella
// ─────────────────────────────────────────────────────────────

class _Particle {
  final TextPainter painter;
  final double glyphSize;
  final double startX; // 0..1, normalizzato rispetto alla larghezza
  final double startY; // 0..1, normalizzato rispetto all'altezza
  final double speed; // cicli per loop
  final double sway; // ampiezza oscillazione (frazione della dimensione)
  final double phase; // sfasamento in radianti
  final double opacity;

  _Particle({
    required this.painter,
    required this.glyphSize,
    required this.startX,
    required this.startY,
    required this.speed,
    required this.sway,
    required this.phase,
    required this.opacity,
  });
}

List<_Particle> _buildParticles(SeasonalTheme theme) {
  final config = _configs[theme];
  if (config == null) return const [];

  // Seed fisso: layout visivo stabile tra un avvio e l'altro dello stesso
  // giorno, senza bisogno di un vero RNG crittografico.
  final rnd = Random(theme.index * 1000 + 7);

  return List.generate(config.count, (_) {
    final size = _lerpRandom(rnd, config.minSize, config.maxSize);
    final glyph = config.glyphs[rnd.nextInt(config.glyphs.length)];

    // Layout fatto una sola volta qui: il paint() per-frame nel painter
    // riusa questo stesso TextPainter senza mai ri-calcolare il testo.
    final painter = TextPainter(
      text: TextSpan(text: glyph, style: TextStyle(fontSize: size)),
      textDirection: TextDirection.ltr,
    )..layout();

    return _Particle(
      painter: painter,
      glyphSize: size,
      startX: rnd.nextDouble(),
      startY: rnd.nextDouble(),
      speed: _lerpRandom(rnd, config.minSpeed, config.maxSpeed),
      sway: config.sway,
      phase: rnd.nextDouble() * 2 * pi,
      opacity: _lerpRandom(rnd, config.minOpacity, config.maxOpacity),
    );
  });
}

double _lerpRandom(Random rnd, double min, double max) =>
    min + rnd.nextDouble() * (max - min);

// ─────────────────────────────────────────────────────────────
// Painter
// ─────────────────────────────────────────────────────────────

class _SeasonalPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress; // 0..1, in loop continuo
  final _MotionStyle motion;

  _SeasonalPainter({
    required this.particles,
    required this.progress,
    required this.motion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speed) % 1.0;
      final swayOffset = sin(2 * pi * t * 2 + p.phase) * p.sway;

      double nx = p.startX;
      double ny = p.startY;

      switch (motion) {
        case _MotionStyle.falling:
          ny = (p.startY + t) % 1.15 - 0.075;
          nx = p.startX + swayOffset;
        case _MotionStyle.rising:
          ny = (p.startY - t) % 1.15;
          if (ny < -0.075) ny += 1.15;
          nx = p.startX + swayOffset;
        case _MotionStyle.crossing:
          nx = (p.startX + t) % 1.2 - 0.1;
          ny = p.startY + swayOffset;
        case _MotionStyle.floating:
          nx = p.startX + swayOffset;
          ny = p.startY + cos(2 * pi * t * 2 + p.phase) * p.sway;
      }

      final dx = nx * size.width;
      final dy = ny * size.height;

      // Gli emoji sono glifi a colori: non rispondono a TextStyle.color né
      // a un'opacità applicata al testo stesso. L'unico modo per dare
      // trasparenza per-particella è disegnarli dentro un saveLayer con un
      // Paint semi-trasparente (stessa tecnica che usa internamente Opacity).
      canvas.saveLayer(
        Rect.fromLTWH(dx, dy, p.glyphSize, p.glyphSize),
        Paint()..color = Colors.black.withValues(alpha: p.opacity),
      );
      p.painter.paint(canvas, Offset(dx, dy));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SeasonalPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
