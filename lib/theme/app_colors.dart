import 'package:flutter/material.dart';

@immutable
class AppColorPalette extends ThemeExtension<AppColorPalette> {
  const AppColorPalette({
    required this.violet,
    required this.violetHover,
    required this.violetMid,
    required this.violetLight,
    required this.violetSoft,
    required this.violetDeep,
    required this.violetDarkSoft,
    required this.background,
    required this.surface,
    required this.elevated,
    required this.foreground,
    required this.mutedForeground,
    required this.border,
    required this.sportBackgroundStart,
    required this.sportBackgroundMid,
    required this.sportBackgroundEnd,
    required this.sportHeader,
    required this.sportDotSurface,
    required this.sportBadgeBorder,
    required this.sportMutedText,
    required this.danger,
    required this.onColor,
    required this.transparent,
    required this.shadow,
    required this.loginPanel,
    required this.loginField,
    required this.loginDivider,
    required this.loginOutline,
    required this.bootstrapBackground,
    required this.bootstrapMutedText,
    required this.bootstrapWarning,
  });

  factory AppColorPalette.forBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }

  static const light = AppColorPalette(
    violet: Color(0xFF7C3AED),
    violetHover: Color(0xFF6D28D9),
    violetMid: Color(0xFF8B5CF6),
    violetLight: Color(0xFFA78BFA),
    violetSoft: Color(0xFFF5F3FF),
    violetDeep: Color(0xFF3B1B73),
    violetDarkSoft: Color(0xFF2E1065),
    background: Color(0xFFFAFAFA),
    surface: Colors.white,
    elevated: Color(0xFFF5F3FF),
    foreground: Color(0xFF18181B),
    mutedForeground: Color(0xFF71717A),
    border: Color(0xFFE4E4E7),
    sportBackgroundStart: Color(0xFFFFFFFF),
    sportBackgroundMid: Color(0xFFF8F7FF),
    sportBackgroundEnd: Color(0xFFFAFAFA),
    sportHeader: Colors.white,
    sportDotSurface: Color(0xFF111318),
    sportBadgeBorder: Color(0xFF101216),
    sportMutedText: Color(0xA3FFFFFF),
    danger: Color(0xFFFF4D6D),
    onColor: Colors.white,
    transparent: Colors.transparent,
    shadow: Colors.black,
    loginPanel: Color(0xFF2A2436),
    loginField: Color(0xFF3B344B),
    loginDivider: Color(0xFF4A4358),
    loginOutline: Color(0xFF7E758F),
    bootstrapBackground: Color(0xFF121018),
    bootstrapMutedText: Color(0xFFD8D3E4),
    bootstrapWarning: Color(0xFFFFD166),
  );

  static const dark = AppColorPalette(
    violet: Color(0xFF7C3AED),
    violetHover: Color(0xFF6D28D9),
    violetMid: Color(0xFF8B5CF6),
    violetLight: Color(0xFFA78BFA),
    violetSoft: Color(0xFFF5F3FF),
    violetDeep: Color(0xFF3B1B73),
    violetDarkSoft: Color(0xFF2E1065),
    background: Color(0xFF09090B),
    surface: Color(0xFF18181B),
    elevated: Color(0xFF27272A),
    foreground: Color(0xFFFAFAFA),
    mutedForeground: Color(0xA3FFFFFF),
    border: Color(0xFF27272A),
    sportBackgroundStart: Color(0xFF3B1B73),
    sportBackgroundMid: Color(0xFF14171B),
    sportBackgroundEnd: Color(0xFF07080A),
    sportHeader: Color(0xFF17131F),
    sportDotSurface: Color(0xFF111318),
    sportBadgeBorder: Color(0xFF101216),
    sportMutedText: Color(0xA3FFFFFF),
    danger: Color(0xFFFF4D6D),
    onColor: Colors.white,
    transparent: Colors.transparent,
    shadow: Colors.black,
    loginPanel: Color(0xFF2A2436),
    loginField: Color(0xFF3B344B),
    loginDivider: Color(0xFF4A4358),
    loginOutline: Color(0xFF7E758F),
    bootstrapBackground: Color(0xFF121018),
    bootstrapMutedText: Color(0xFFD8D3E4),
    bootstrapWarning: Color(0xFFFFD166),
  );

  final Color violet;
  final Color violetHover;
  final Color violetMid;
  final Color violetLight;
  final Color violetSoft;
  final Color violetDeep;
  final Color violetDarkSoft;
  final Color background;
  final Color surface;
  final Color elevated;
  final Color foreground;
  final Color mutedForeground;
  final Color border;
  final Color sportBackgroundStart;
  final Color sportBackgroundMid;
  final Color sportBackgroundEnd;
  final Color sportHeader;
  final Color sportDotSurface;
  final Color sportBadgeBorder;
  final Color sportMutedText;
  final Color danger;
  final Color onColor;
  final Color transparent;
  final Color shadow;
  final Color loginPanel;
  final Color loginField;
  final Color loginDivider;
  final Color loginOutline;
  final Color bootstrapBackground;
  final Color bootstrapMutedText;
  final Color bootstrapWarning;

  @override
  AppColorPalette copyWith({
    Color? violet,
    Color? violetHover,
    Color? violetMid,
    Color? violetLight,
    Color? violetSoft,
    Color? violetDeep,
    Color? violetDarkSoft,
    Color? background,
    Color? surface,
    Color? elevated,
    Color? foreground,
    Color? mutedForeground,
    Color? border,
    Color? sportBackgroundStart,
    Color? sportBackgroundMid,
    Color? sportBackgroundEnd,
    Color? sportHeader,
    Color? sportDotSurface,
    Color? sportBadgeBorder,
    Color? sportMutedText,
    Color? danger,
    Color? onColor,
    Color? transparent,
    Color? shadow,
    Color? loginPanel,
    Color? loginField,
    Color? loginDivider,
    Color? loginOutline,
    Color? bootstrapBackground,
    Color? bootstrapMutedText,
    Color? bootstrapWarning,
  }) {
    return AppColorPalette(
      violet: violet ?? this.violet,
      violetHover: violetHover ?? this.violetHover,
      violetMid: violetMid ?? this.violetMid,
      violetLight: violetLight ?? this.violetLight,
      violetSoft: violetSoft ?? this.violetSoft,
      violetDeep: violetDeep ?? this.violetDeep,
      violetDarkSoft: violetDarkSoft ?? this.violetDarkSoft,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      elevated: elevated ?? this.elevated,
      foreground: foreground ?? this.foreground,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      border: border ?? this.border,
      sportBackgroundStart: sportBackgroundStart ?? this.sportBackgroundStart,
      sportBackgroundMid: sportBackgroundMid ?? this.sportBackgroundMid,
      sportBackgroundEnd: sportBackgroundEnd ?? this.sportBackgroundEnd,
      sportHeader: sportHeader ?? this.sportHeader,
      sportDotSurface: sportDotSurface ?? this.sportDotSurface,
      sportBadgeBorder: sportBadgeBorder ?? this.sportBadgeBorder,
      sportMutedText: sportMutedText ?? this.sportMutedText,
      danger: danger ?? this.danger,
      onColor: onColor ?? this.onColor,
      transparent: transparent ?? this.transparent,
      shadow: shadow ?? this.shadow,
      loginPanel: loginPanel ?? this.loginPanel,
      loginField: loginField ?? this.loginField,
      loginDivider: loginDivider ?? this.loginDivider,
      loginOutline: loginOutline ?? this.loginOutline,
      bootstrapBackground: bootstrapBackground ?? this.bootstrapBackground,
      bootstrapMutedText: bootstrapMutedText ?? this.bootstrapMutedText,
      bootstrapWarning: bootstrapWarning ?? this.bootstrapWarning,
    );
  }

  @override
  AppColorPalette lerp(ThemeExtension<AppColorPalette>? other, double t) {
    if (other is! AppColorPalette) return this;

    return AppColorPalette(
      violet: Color.lerp(violet, other.violet, t)!,
      violetHover: Color.lerp(violetHover, other.violetHover, t)!,
      violetMid: Color.lerp(violetMid, other.violetMid, t)!,
      violetLight: Color.lerp(violetLight, other.violetLight, t)!,
      violetSoft: Color.lerp(violetSoft, other.violetSoft, t)!,
      violetDeep: Color.lerp(violetDeep, other.violetDeep, t)!,
      violetDarkSoft: Color.lerp(violetDarkSoft, other.violetDarkSoft, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      border: Color.lerp(border, other.border, t)!,
      sportBackgroundStart: Color.lerp(
        sportBackgroundStart,
        other.sportBackgroundStart,
        t,
      )!,
      sportBackgroundMid: Color.lerp(
        sportBackgroundMid,
        other.sportBackgroundMid,
        t,
      )!,
      sportBackgroundEnd: Color.lerp(
        sportBackgroundEnd,
        other.sportBackgroundEnd,
        t,
      )!,
      sportHeader: Color.lerp(sportHeader, other.sportHeader, t)!,
      sportDotSurface: Color.lerp(sportDotSurface, other.sportDotSurface, t)!,
      sportBadgeBorder: Color.lerp(
        sportBadgeBorder,
        other.sportBadgeBorder,
        t,
      )!,
      sportMutedText: Color.lerp(sportMutedText, other.sportMutedText, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onColor: Color.lerp(onColor, other.onColor, t)!,
      transparent: Color.lerp(transparent, other.transparent, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      loginPanel: Color.lerp(loginPanel, other.loginPanel, t)!,
      loginField: Color.lerp(loginField, other.loginField, t)!,
      loginDivider: Color.lerp(loginDivider, other.loginDivider, t)!,
      loginOutline: Color.lerp(loginOutline, other.loginOutline, t)!,
      bootstrapBackground: Color.lerp(
        bootstrapBackground,
        other.bootstrapBackground,
        t,
      )!,
      bootstrapMutedText: Color.lerp(
        bootstrapMutedText,
        other.bootstrapMutedText,
        t,
      )!,
      bootstrapWarning: Color.lerp(
        bootstrapWarning,
        other.bootstrapWarning,
        t,
      )!,
    );
  }
}

class AppColors {
  const AppColors._();

  static const violet = Color(0xFF7C3AED);
  static const violetHover = Color(0xFF6D28D9);
  static const violetMid = Color(0xFF8B5CF6);
  static const violetLight = Color(0xFFA78BFA);
  static const violetSoft = Color(0xFFF5F3FF);
  static const violetDeep = Color(0xFF3B1B73);
  static const violetDarkSoft = Color(0xFF2E1065);

  static const appLightBackground = Color(0xFFFAFAFA);
  static const appLightSurface = Colors.white;
  static const appLightBorder = Color(0xFFE4E4E7);
  static const appLightForeground = Color(0xFF18181B);

  static const appDarkBackground = Color(0xFF09090B);
  static const appDarkSurface = Color(0xFF18181B);
  static const appDarkElevated = Color(0xFF27272A);
  static const appDarkForeground = Color(0xFFFAFAFA);
  static const appGray = Color(0xFF71717A);

  static const sportBackgroundStart = violetDeep;
  static const sportBackgroundMid = Color(0xFF14171B);
  static const sportBackgroundEnd = Color(0xFF07080A);
  static const sportHeaderDark = Color(0xFF17131F);
  static const sportDotSurface = Color(0xFF111318);
  static const sportBadgeBorder = Color(0xFF101216);
  static const sportMutedText = Color(0xA3FFFFFF);
  static const danger = Color(0xFFFF4D6D);

  static const white = Colors.white;
  static const transparent = Colors.transparent;
  static const black = Colors.black;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static AppColorPalette palette(BuildContext context) =>
      Theme.of(context).extension<AppColorPalette>() ??
      AppColorPalette.forBrightness(Theme.of(context).brightness);

  static Color pageBackground(BuildContext context) =>
      palette(context).background;

  static Color sportSurface(BuildContext context) =>
      palette(context).sportHeader;

  static Color sportElevated(BuildContext context) => palette(context).elevated;

  static Color sportForeground(BuildContext context) =>
      palette(context).foreground;

  static Color sportMutedForeground(BuildContext context) =>
      palette(context).mutedForeground;

  static Color sportBorder(BuildContext context) => isDark(context)
      ? palette(context).onColor.withValues(alpha: 0.13)
      : palette(context).border.withValues(alpha: 0.95);

  static Color sportGlass(BuildContext context) => isDark(context)
      ? palette(context).onColor.withValues(alpha: 0.07)
      : palette(context).onColor;

  static List<Color> sportBackgroundGradient(BuildContext context) => [
    palette(context).sportBackgroundStart,
    palette(context).sportBackgroundMid,
    palette(context).sportBackgroundEnd,
  ];

  static List<Color> sportBackgroundTransparentGradient(BuildContext context) =>
      isDark(context)
      ? [
          palette(context).sportBackgroundStart.withValues(alpha: 0.82),
          palette(context).sportBackgroundMid.withValues(alpha: 0.52),
          palette(context).transparent,
        ]
      : sportBackgroundGradient(context);
}
