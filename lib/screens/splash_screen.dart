import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controller per le varie animazioni
  late final AnimationController _shieldCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _overlayCtrl;

  // Shield: sale dal basso + fade in
  late final Animation<double> _shieldScale;
  late final Animation<double> _shieldOpacity;
  late final Animation<Offset> _shieldSlide;

  // Testo: fade in dopo lo scudo
  late final Animation<double> _titleOpacity;
  late final Animation<double> _subtitleOpacity;

  // Overlay bianco per la transizione finale
  late final Animation<double> _overlayOpacity;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // ── Shield animation (0.8s) ──
    _shieldCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _shieldScale = CurvedAnimation(
        parent: _shieldCtrl, curve: Curves.elasticOut)
      ..drive(Tween(begin: 0.4, end: 1.0));

    _shieldOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _shieldCtrl,
            curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));

    _shieldSlide = Tween<Offset>(
            begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _shieldCtrl, curve: Curves.easeOutCubic));

    // ── Text animation (0.6s) — parte dopo lo scudo ──
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textCtrl,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOut)));

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textCtrl,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));

    // ── Overlay transition (0.4s) ──
    _overlayCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    _overlayOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _overlayCtrl, curve: Curves.easeIn));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    await _shieldCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    await _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1200));
    await _overlayCtrl.forward();
    if (!mounted) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _shieldCtrl.dispose();
    _textCtrl.dispose();
    _overlayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [

          // ── Sfondo: campo da calcetto ────────────────────────
          Image.asset(
            'assets/images/backgroundStadium.png',
            fit: BoxFit.cover,
          ),

          // ── Overlay scuro con gradiente verde calcistico ─────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.55),
                  const Color(0xFF001a00).withOpacity(0.85), // verde scurissimo
                  Colors.black.withOpacity(0.92),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Linee campo stilizzate (decorative) ─────────────
          CustomPaint(
            painter: _FieldLinesPainter(),
            size: size,
          ),

          // ── Contenuto centrale ───────────────────────────────
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Scudo animato
              SlideTransition(
                position: _shieldSlide,
                child: FadeTransition(
                  opacity: _shieldOpacity,
                  child: ScaleTransition(
                    scale: _shieldScale,
                    child: SizedBox(
                      width: size.width * 0.52,
                      height: size.width * 0.52,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow dorato sotto lo scudo
                          Container(
                            width: size.width * 0.45,
                            height: size.width * 0.45,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(33, 255, 221, 0).withOpacity(0.35),
                                  blurRadius: 60,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                          ),
                          Image.asset(
                            'assets/icons/logo-removebg.png',
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Titolo
              FadeTransition(
                opacity: _titleOpacity,
                child: const Text(
                  'CHAMPIONS',
                  style: TextStyle(
                    color: AppTheme.accentGold,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FadeTransition(
                opacity: _titleOpacity,
                child: const Text(
                  'CALCETTO STATS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 5,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sottotitolo
              FadeTransition(
                opacity: _subtitleOpacity,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppTheme.accentGreen.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '⚽ EMOZIONI DA SEGNARE',
                    style: TextStyle(
                      color: AppTheme.accentGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Indicatore di caricamento
              FadeTransition(
                opacity: _subtitleOpacity,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.accentGreen.withOpacity(0.7)),
                      minHeight: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Flash bianco per transizione ─────────────────────
          FadeTransition(
            opacity: _overlayOpacity,
            child: Container(color: Colors.black),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Painter per le linee campo decorative
// ─────────────────────────────────────────────────────────────
class _FieldLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Cerchio centrale
    canvas.drawCircle(Offset(cx, cy), size.width * 0.22, paint);

    // Punto centrale
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 4, dotPaint);

    // Linea di metà campo
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paint);

    // Area di rigore sopra
    final areaW = size.width * 0.55;
    final areaH = size.height * 0.12;
    canvas.drawRect(
      Rect.fromLTWH((size.width - areaW) / 2, 0, areaW, areaH),
      paint,
    );

    // Area di rigore sotto
    canvas.drawRect(
      Rect.fromLTWH(
          (size.width - areaW) / 2, size.height - areaH, areaW, areaH),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
