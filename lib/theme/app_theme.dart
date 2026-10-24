import 'package:flutter/material.dart';

/// Sistema di design centralizzato — stile FIFA/gaming dark
class AppTheme {
  /// Palette attiva. Viene cambiata da [ThemeController]; i colori sotto
  /// sono getter (non const) così ogni rebuild legge quella corrente.
  static bool isLight = false;

  // ── Colori base ───────────────────────────────────────────────
  static Color get bg =>
      isLight ? const Color(0xFFF2F3F5) : const Color(0xFF080808);
  static Color get surface =>
      isLight ? const Color(0xFFFFFFFF) : const Color(0xFF111111);
  static Color get surfaceAlt =>
      isLight ? const Color(0xFFE9EBEE) : const Color(0xFF181818);
  static Color get border =>
      isLight ? const Color(0xFFD5D8DD) : const Color(0xFF2A2A2A);
  static Color get borderLight =>
      isLight ? const Color(0xFFC4C8CE) : const Color(0xFF333333);

  // ── Accenti (più scuri in chiaro per restare leggibili su bianco) ──
  static Color get accentGreen =>
      isLight ? const Color(0xFF00A152) : const Color(0xFF00E676);
  static Color get accentRed =>
      isLight ? const Color(0xFFD50032) : const Color(0xFFFF1744);
  static Color get accentGold =>
      isLight ? const Color(0xFFC79400) : const Color(0xFFFFD600);
  static Color get accentOrange =>
      isLight ? const Color(0xFFE65100) : const Color(0xFFFF6D00);
  static Color get accentBlue =>
      isLight ? const Color(0xFF0081CB) : const Color(0xFF00B0FF);
  static Color get accentCyan =>
      isLight ? const Color(0xFF00897B) : const Color(0xFF1DE9B6);

  // ── Testo ─────────────────────────────────────────────────────
  static Color get textPrimary =>
      isLight ? const Color(0xFF111111) : const Color(0xFFFFFFFF);
  static Color get textSecondary =>
      isLight ? const Color(0xFF5F6368) : const Color(0xFF888888);
  static Color get textMuted =>
      isLight ? const Color(0xFF9AA0A6) : const Color(0xFF444444);

  /// Colore "in primo piano" per superfici neutre: bianco in scuro,
  /// nero in chiaro. Sostituisce i `Colors.white` usati come testo/bordi.
  static Color get onBg => isLight ? Colors.black : Colors.white;

  // ── ThemeData globale ─────────────────────────────────────────
  static ThemeData get theme =>
      (isLight ? ThemeData.light() : ThemeData.dark()).copyWith(
        scaffoldBackgroundColor: bg,
        colorScheme:
            (isLight ? const ColorScheme.light() : const ColorScheme.dark())
                .copyWith(
          primary: accentGreen,
          secondary: accentGold,
          surface: surface,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: bg,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        cardColor: surface,
        dividerColor: border,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceAlt,
          labelStyle:
              TextStyle(color: textSecondary, fontSize: 11, letterSpacing: 1.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: accentGreen, width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentGreen,
            foregroundColor: Colors.black,
            textStyle: const TextStyle(
                fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? accentGreen
                  : Colors.transparent),
          checkColor: WidgetStateProperty.all(Colors.black),
          side: BorderSide(color: borderLight, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: accentGreen,
          inactiveTrackColor: border,
          thumbColor: accentGreen,
          overlayColor: Color(0x2200E676),
          valueIndicatorColor: accentGreen,
          valueIndicatorTextStyle:
              TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: accentGreen,
          foregroundColor: Colors.black,
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          menuStyle: MenuStyle(
            backgroundColor: WidgetStateProperty.all(surfaceAlt),
          ),
        ),
      );
}

/// Widget riutilizzabili del design system
class FifaLabel extends StatelessWidget {
  final String text;
  final Color? color;
  final double fontSize;

  const FifaLabel(
    this.text, {
    this.color,
    this.fontSize = 10,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color ?? AppTheme.textSecondary,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.5,
        ),
      );
}

class FifaDivider extends StatelessWidget {
  final Color? color;
  const FifaDivider({this.color, super.key});

  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        color: color ?? AppTheme.border,
        margin: const EdgeInsets.symmetric(vertical: 12),
      );
}

class FifaBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const FifaBadge(this.text, {required this.color, this.icon, super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 5),
            ],
            Text(
              text.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
}

class FifaSectionHeader extends StatelessWidget {
  final String title;
  final Color? accent;
  const FifaSectionHeader(this.title, {this.accent, super.key});

  @override
  Widget build(BuildContext context) {
    final accent = this.accent ?? AppTheme.accentGreen;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
              width: 3,
              height: 18,
              color: accent,
              margin: const EdgeInsets.only(right: 10)),
          FifaLabel(title, color: accent, fontSize: 11),
        ],
      ),
    );
  }
}
