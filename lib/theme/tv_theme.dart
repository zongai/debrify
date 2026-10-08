import 'package:flutter/material.dart';

/// TV 10-foot spacing (logical px, 1080p baseline).
@immutable
class TvSpace {
  const TvSpace({
    this.screenMarginX = 56,
    this.screenMarginY = 40,
    this.sectionGap = 48,
    this.railGap = 28,
    this.cardPadding = 14,
    this.headerHeight = 88,
    this.controlGap = 24,
  });

  final double screenMarginX;
  final double screenMarginY;
  final double sectionGap;
  final double railGap;
  final double cardPadding;
  final double headerHeight;
  final double controlGap;

  TvSpace copyWith({
    double? screenMarginX,
    double? screenMarginY,
    double? sectionGap,
    double? railGap,
    double? cardPadding,
    double? headerHeight,
    double? controlGap,
  }) {
    return TvSpace(
      screenMarginX: screenMarginX ?? this.screenMarginX,
      screenMarginY: screenMarginY ?? this.screenMarginY,
      sectionGap: sectionGap ?? this.sectionGap,
      railGap: railGap ?? this.railGap,
      cardPadding: cardPadding ?? this.cardPadding,
      headerHeight: headerHeight ?? this.headerHeight,
      controlGap: controlGap ?? this.controlGap,
    );
  }
}

@immutable
class TvFocusTokens {
  const TvFocusTokens({
    this.scale = 1.06,
    this.borderWidth = 3,
    this.duration = const Duration(milliseconds: 140),
    this.durationTvos = const Duration(milliseconds: 180),
    this.movingSimplify = true,
  });

  final double scale;
  final double borderWidth;
  final Duration duration;
  final Duration durationTvos;
  final bool movingSimplify;

  TvFocusTokens copyWith({
    double? scale,
    double? borderWidth,
    Duration? duration,
    Duration? durationTvos,
    bool? movingSimplify,
  }) {
    return TvFocusTokens(
      scale: scale ?? this.scale,
      borderWidth: borderWidth ?? this.borderWidth,
      duration: duration ?? this.duration,
      durationTvos: durationTvos ?? this.durationTvos,
      movingSimplify: movingSimplify ?? this.movingSimplify,
    );
  }
}

@immutable
class TvRadius {
  const TvRadius({
    this.card = 12,
    this.button = 10,
    this.chip = 20,
    this.control = 8,
  });

  final double card;
  final double button;
  final double chip;
  final double control;

  TvRadius copyWith({
    double? card,
    double? button,
    double? chip,
    double? control,
  }) {
    return TvRadius(
      card: card ?? this.card,
      button: button ?? this.button,
      chip: chip ?? this.chip,
      control: control ?? this.control,
    );
  }
}

@immutable
class TvColorTokens {
  const TvColorTokens({
    this.surface = const Color(0xFF0E0E12),
    this.surfaceElevated = const Color(0xFF1A1A22),
    this.focus = const Color(0xFF6EA8FF),
    this.onFocus = const Color(0xFFFFFFFF),
    this.disabled = const Color(0xFF6B6B76),
    this.overlayScrim = const Color(0xCC000000),
  });

  final Color surface;
  final Color surfaceElevated;
  final Color focus;
  final Color onFocus;
  final Color disabled;
  final Color overlayScrim;

  TvColorTokens copyWith({
    Color? surface,
    Color? surfaceElevated,
    Color? focus,
    Color? onFocus,
    Color? disabled,
    Color? overlayScrim,
  }) {
    return TvColorTokens(
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      focus: focus ?? this.focus,
      onFocus: onFocus ?? this.onFocus,
      disabled: disabled ?? this.disabled,
      overlayScrim: overlayScrim ?? this.overlayScrim,
    );
  }
}

/// Theme extension for Android TV / tvOS. TV widgets should read [TvThemeX.tv]
/// instead of scaling mobile text styles.
@immutable
class TvTheme extends ThemeExtension<TvTheme> {
  const TvTheme({
    this.space = const TvSpace(),
    this.focus = const TvFocusTokens(),
    this.color = const TvColorTokens(),
    this.radius = const TvRadius(),
  });

  final TvSpace space;
  final TvFocusTokens focus;
  final TvColorTokens color;
  final TvRadius radius;

  static const TvTheme defaults = TvTheme();

  @override
  TvTheme copyWith({
    TvSpace? space,
    TvFocusTokens? focus,
    TvColorTokens? color,
    TvRadius? radius,
  }) {
    return TvTheme(
      space: space ?? this.space,
      focus: focus ?? this.focus,
      color: color ?? this.color,
      radius: radius ?? this.radius,
    );
  }

  @override
  TvTheme lerp(ThemeExtension<TvTheme>? other, double t) {
    if (other is! TvTheme) return this;
    // Discrete tokens: snap at midpoint.
    return t < 0.5 ? this : other;
  }
}

extension TvThemeX on BuildContext {
  TvTheme get tv =>
      Theme.of(this).extension<TvTheme>() ?? TvTheme.defaults;
}

/// Shared focus chrome: scale + border; optional collection glow.
class TvFocusChrome extends StatelessWidget {
  const TvFocusChrome({
    super.key,
    required this.focused,
    required this.child,
    this.enableGlow = false,
    this.glowColor,
    this.borderRadius,
    this.useTvosDuration = false,
  });

  final bool focused;
  final Widget child;
  final bool enableGlow;
  final Color? glowColor;
  final BorderRadius? borderRadius;
  final bool useTvosDuration;

  @override
  Widget build(BuildContext context) {
    final tv = context.tv;
    final duration =
        useTvosDuration ? tv.focus.durationTvos : tv.focus.duration;
    final radius = borderRadius ?? BorderRadius.circular(tv.radius.card);
    final scale = focused ? tv.focus.scale : 1.0;

    return AnimatedScale(
      scale: scale,
      duration: duration,
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: focused ? tv.color.focus : Colors.transparent,
            width: tv.focus.borderWidth,
          ),
          boxShadow: focused && enableGlow && glowColor != null
              ? [
                  BoxShadow(
                    color: glowColor!.withValues(alpha: 0.45),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}
