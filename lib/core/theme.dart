import 'dart:ui';

import 'package:flutter/material.dart';

/// Tokens del sistema "Pronósticos": verde sombrío, vidrio y aire.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg000,
    required this.bg100,
    required this.glow,
    required this.glass100,
    required this.glass200,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.inkMuted,
    required this.brand,
    required this.brandStrong,
    required this.brandSoft,
    required this.onBrand,
    required this.live,
    required this.liveSoft,
    required this.danger,
    required this.shadow,
  });

  final Color bg000, bg100, glow, glass100, glass200, line, lineStrong;
  final Color ink, inkMuted, brand, brandStrong, brandSoft, onBrand;
  final Color live, liveSoft, danger;
  final List<BoxShadow> shadow;

  static const dark = AppColors(
    bg000: Color(0xFF0E1411),
    bg100: Color(0xFF13201A),
    glow: Color(0xFF1F3D2E),
    glass100: Color.fromRGBO(28, 42, 35, 0.55),
    glass200: Color.fromRGBO(36, 54, 45, 0.72),
    line: Color.fromRGBO(168, 200, 180, 0.12),
    lineStrong: Color.fromRGBO(168, 200, 180, 0.28),
    ink: Color(0xFFE4EBE6),
    inkMuted: Color(0xFF93A39A),
    brand: Color(0xFF6FA585),
    brandStrong: Color(0xFF8FBFA3),
    brandSoft: Color.fromRGBO(111, 165, 133, 0.16),
    onBrand: Color(0xFF0C1510),
    live: Color(0xFFD9A441),
    liveSoft: Color.fromRGBO(217, 164, 65, 0.14),
    danger: Color(0xFFE08A7A),
    shadow: [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.35),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
  );

  static const light = AppColors(
    bg000: Color(0xFFEEF1EC),
    bg100: Color(0xFFE3EAE4),
    glow: Color(0xFFCFE0D4),
    glass100: Color.fromRGBO(255, 255, 255, 0.58),
    glass200: Color.fromRGBO(255, 255, 255, 0.8),
    line: Color.fromRGBO(30, 60, 45, 0.12),
    lineStrong: Color.fromRGBO(30, 60, 45, 0.28),
    ink: Color(0xFF16201B),
    inkMuted: Color(0xFF56675D),
    brand: Color(0xFF2F5D46),
    brandStrong: Color(0xFF24493A),
    brandSoft: Color.fromRGBO(47, 93, 70, 0.10),
    onBrand: Color(0xFFF3F7F4),
    live: Color(0xFF8A5A12),
    liveSoft: Color.fromRGBO(138, 90, 18, 0.10),
    danger: Color(0xFFA33B2A),
    shadow: [
      BoxShadow(
        color: Color.fromRGBO(22, 32, 27, 0.08),
        blurRadius: 20,
        offset: Offset(0, 6),
      ),
    ],
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) =>
      t < 0.5 ? this : (other as AppColors? ?? this);
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

const _sans = 'Inter';
const _fallback = ['Roboto', 'Manrope', 'system-ui', 'sans-serif'];

const radiusSm = 8.0;
const radiusMd = 14.0;
const radiusLg = 20.0;

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  final scheme =
      ColorScheme.fromSeed(seedColor: c.brand, brightness: brightness).copyWith(
        primary: c.brand,
        onPrimary: c.onBrand,
        surface: c.bg000,
        onSurface: c.ink,
        onSurfaceVariant: c.inkMuted,
        error: c.danger,
        outline: c.lineStrong,
        outlineVariant: c.line,
        primaryContainer: c.brandSoft,
        onPrimaryContainer: c.brandStrong,
      );
  final base = ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    useMaterial3: true,
  );
  final text = base.textTheme.apply(
    fontFamily: _sans,
    fontFamilyFallback: _fallback,
    bodyColor: c.ink,
    displayColor: c.ink,
  );

  OutlineInputBorder border(Color color, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(radiusSm),
    borderSide: BorderSide(color: color, width: w),
  );

  return base.copyWith(
    extensions: [c],
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 28,
        height: 34 / 28,
        letterSpacing: -0.6,
      ),
      titleMedium: text.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 14, height: 20 / 14),
      bodySmall: text.bodySmall?.copyWith(color: c.inkMuted),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: c.ink,
      titleTextStyle: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 22,
        letterSpacing: -0.4,
      ),
    ),
    dividerTheme: DividerThemeData(color: c.line, space: 1, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.glass200,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: TextStyle(color: c.inkMuted),
      floatingLabelStyle: TextStyle(color: c.brandStrong),
      helperStyle: TextStyle(color: c.inkMuted),
      errorStyle: TextStyle(color: c.danger),
      border: border(c.lineStrong),
      enabledBorder: border(c.lineStrong),
      focusedBorder: border(c.brand, 2),
      errorBorder: border(c.danger),
      focusedErrorBorder: border(c.danger, 2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.brand,
        foregroundColor: c.onBrand,
        disabledBackgroundColor: c.brandSoft,
        shape: const StadiumBorder(),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.ink,
        side: BorderSide(color: c.lineStrong),
        shape: const StadiumBorder(),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.brandStrong,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: c.inkMuted),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.glass200.withValues(alpha: 0.96),
      contentTextStyle: TextStyle(color: c.ink, fontFamily: _sans),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        side: BorderSide(color: c.line),
      ),
      width: 420,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.bg100,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        side: BorderSide(color: c.line),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.brand),
  );
}

/// Fondo de la app: degradado base y halo verde bajo el encabezado.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.bg100, c.bg000],
          stops: const [0, 0.6],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -1.1),
            radius: 0.9,
            colors: [
              c.glow.withValues(alpha: 0.55),
              c.glow.withValues(alpha: 0),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Superficie de vidrio: translúcida, borde de 1px y desenfoque.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.dense = false,
    this.radius = radiusMd,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool dense;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: shape, boxShadow: c.shadow),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: dense ? c.glass200 : c.glass100,
              borderRadius: shape,
              border: Border.all(color: c.line),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Texto en mayúsculas espaciadas: encabezados de día y etiquetas.
class Overline extends StatelessWidget {
  const Overline(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.96,
      color: color ?? context.colors.inkMuted,
    ),
  );
}

/// Chip pequeño con punto de color.
class StatusChip extends StatefulWidget {
  const StatusChip({
    super.key,
    required this.text,
    required this.color,
    required this.soft,
    this.pulse = false,
  });
  final String text;
  final Color color;
  final Color soft;
  final bool pulse;

  @override
  State<StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<StatusChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = widget.pulse && !MediaQuery.disableAnimationsOf(context);
    if (animate && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!animate && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: widget.soft,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: Tween(begin: 1.0, end: 0.35).animate(_ctrl),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          widget.text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: widget.color,
          ),
        ),
      ],
    ),
  );
}

/// Control segmentado compacto en vidrio; se sincroniza con un TabController.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.controller,
    required this.labels,
  });
  final TabController controller;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedBuilder(
      animation: controller.animation!,
      builder: (context, _) => GlassCard(
        dense: true,
        radius: radiusLg,
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: controller.index == i,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => controller.animateTo(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: controller.index == i
                            ? c.brandSoft
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(radiusLg - 4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: controller.index == i
                              ? c.brandStrong
                              : c.inkMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
