import 'package:flutter/material.dart';

/// Sistema di design centralizzato — stile FIFA/gaming dark
class AppTheme {
  // ── Colori base ───────────────────────────────────────────────
  static const Color bg          = Color(0xFF080808);
  static const Color surface     = Color(0xFF111111);
  static const Color surfaceAlt  = Color(0xFF181818);
  static const Color border      = Color(0xFF2A2A2A);
  static const Color borderLight = Color(0xFF333333);

  // ── Accenti ───────────────────────────────────────────────────
  static const Color accentGreen  = Color(0xFF00E676);
  static const Color accentRed    = Color(0xFFFF1744);
  static const Color accentGold   = Color(0xFFFFD600);
  static const Color accentOrange = Color(0xFFFF6D00);
  static const Color accentBlue   = Color(0xFF00B0FF);

  // ── Testo ─────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF888888);
  static const Color textMuted     = Color(0xFF444444);

  // ── ThemeData globale ─────────────────────────────────────────
  static ThemeData get theme => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: accentGreen,
      secondary: accentGold,
      surface: surface,
    ),
    appBarTheme: const AppBarTheme(
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
      labelStyle: const TextStyle(color: textSecondary, fontSize: 11, letterSpacing: 1.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: accentGreen, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentGreen,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? accentGreen : Colors.transparent),
      checkColor: WidgetStateProperty.all(Colors.black),
      side: const BorderSide(color: borderLight, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: accentGreen,
      inactiveTrackColor: border,
      thumbColor: accentGreen,
      overlayColor: Color(0x2200E676),
      valueIndicatorColor: accentGreen,
      valueIndicatorTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
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
  final Color color;
  final double fontSize;

  const FifaLabel(this.text, {
    this.color = AppTheme.textSecondary,
    this.fontSize = 10,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: 2.5,
    ),
  );
}

class FifaDivider extends StatelessWidget {
  final Color color;
  const FifaDivider({this.color = AppTheme.border, super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    color: color,
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
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: color.withOpacity(0.4)),
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
  final Color accent;
  const FifaSectionHeader(this.title, {this.accent = AppTheme.accentGreen, super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      children: [
        Container(width: 3, height: 18, color: accent,
            margin: const EdgeInsets.only(right: 10)),
        FifaLabel(title, color: accent, fontSize: 11),
      ],
    ),
  );
}
