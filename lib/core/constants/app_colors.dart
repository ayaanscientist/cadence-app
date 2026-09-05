import 'dart:ui';

/// Cadence design system color palette.
///
/// Industrial minimalism: slate grey, matte black, amber warnings,
/// emerald progress, with high-contrast text on dark surfaces.
abstract final class AppColors {
  // ── Surface & Background ──────────────────────────────────────────────
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceElevated = Color(0xFF242424);
  static const Color surfaceBorder = Color(0xFF2E2E2E);

  // ── Text ──────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textMuted = Color(0xFF616161);

  // ── Accent: Emerald (Progress / Success) ──────────────────────────────
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldDim = Color(0xFF065F46);

  // ── Accent: Amber (Warnings / At-Risk) ────────────────────────────────
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberDim = Color(0xFF78350F);

  // ── Accent: Red (Broken / Critical) ───────────────────────────────────
  static const Color red = Color(0xFFEF4444);
  static const Color redDim = Color(0xFF7F1D1D);

  // ── Accent: Cyan (AI / Gemini) ────────────────────────────────────────
  static const Color cyan = Color(0xFF06B6D4);
  static const Color cyanDim = Color(0xFF164E63);

  // ── Accent: Indigo (Mental / Meditation) ──────────────────────────────
  static const Color indigo = Color(0xFF818CF8);
  static const Color indigoDim = Color(0xFF312E81);

  // ── Accent: Slate (Neutral interactive) ───────────────────────────────
  static const Color slate = Color(0xFF64748B);
  static const Color slateDark = Color(0xFF334155);
}
