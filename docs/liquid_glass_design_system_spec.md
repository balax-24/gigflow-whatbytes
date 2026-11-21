# 03 — Zero-Lag Liquid Glass & Glassmorphism Design System

> **Critical Performance Objective:** Deliver a tactile, refractive **Liquid Glass** aesthetic inspired by modern translucent OS design while maintaining **locked 60/120 FPS (raster time under 8 ms)** on mid-range Android and iOS hardware.

---

## 1. The 2-Tier Rendering Strategy (Why It Never Lags)

| Tier | Widget | Technique | Allowed Usage | GPU Cost |
|---|---|---|---|---|
| **Background** | `AmbientMeshBackground` | Static dark/light canvas + 3 soft radial gradient orbs inside `RepaintBoundary` | Full screen behind `Scaffold` | Rasterized once (near 0 ms/frame) |
| **Tier 1 (Optical Blur)** | `LiquidGlassChrome` | `ClipRRect` + `BackdropFilter(sigma: 16, TileMode.clamp)` + specular rim `CustomPainter` | **Max 2–3 surfaces on screen:** pinned header/filter dock, floating `+ New Task` pill, modal bottom sheet, Auth card | Low (bounded, non-scrolling count) |
| **Tier 2 (Specular Glass)** | `LiquidGlassCard` | **Zero `BackdropFilter`!** Multi-stop translucent gradient fill + diagonal 1.2px refractive rim `CustomPainter` + subtle shadow inside `RepaintBoundary` | **All scrolling items:** Task tiles in `SliverList` / `ListView.builder` | Ultra-low (60/120 FPS with 100+ items) |

**Hard Rule:** Never put `LiquidGlassChrome` or `BackdropFilter` inside a `ListView` or `SliverList`.

---

## 2. Color Tokens (`lib/app/theme/app_colors.dart`)

Both themes must meet **WCAG AA contrast** so gig workers can read tasks outdoors in daylight or during night shifts.

### Dark Mode — "Obsidian Glass" (Default)
- `bgBase`: `#070B14` (Deep midnight slate)
- `orbPrimary`: `#3B82F6` at 24% alpha (Electric cobalt glow, top-left)
- `orbSecondary`: `#14B8A6` at 18% alpha (Teal glow, bottom-right)
- `orbAccent`: `#6366F1` at 16% alpha (Indigo mist, center-right)
- `textPrimary`: `#F8FAFC`
- `textSecondary`: `#94A3B8`
- `textMuted`: `#64748B`

### Light Mode — "Daylight Frost"
- `bgBase`: `#EEF3FA` (Cool frosted alabaster)
- `orbPrimary`: `#93C5FD` at 42% alpha
- `orbSecondary`: `#99F6E4` at 36% alpha
- `orbAccent`: `#C7D2FE` at 38% alpha
- `textPrimary`: `#0F172A`
- `textSecondary`: `#475569`
- `textMuted`: `#64748B`

### Semantic Gig-Worker Urgency Tokens (Shared Across Themes)
- `priorityHigh`: `#FF5C72` (Coral Red — urgent deliveries/deadlines)
- `priorityMedium`: `#FFB020` (Warm Amber — scheduled shifts)
- `priorityLow`: `#2DD4BF` (Mint Teal — flexible tasks)
- `statusComplete`: `#22C55E` (Emerald Check)
- `overdueAlert`: `#EF4444` (Crimson badge for missed due dates)
- `accentPrimary`: `#38BDF8` (Sky Cyan interactive highlight)

---

## 3. Typography & Responsive Spacing

- **Font Family:** `Plus Jakarta Sans` (via `google_fonts`) for clean geometric legibility on both iOS and Android.
- **Scale:**
  - `displayTitle`: 26px, Weight 700, letterSpacing `-0.5`
  - `sectionHeader`: 13px, Weight 700, uppercase, letterSpacing `1.1`
  - `cardTitle`: 16px, Weight 600, height `1.3`
  - `cardBody`: 13.5px, Weight 400, height `1.4`, max 2 lines with ellipsis on list card
  - `chipLabel`: 12.5px, Weight 600
- **Responsive Layout Rules:**
  - Respect `SafeArea` on top and bottom (notches, Dynamic Island, Android gesture nav).
  - Horizontal screen margin: `16px` on phones; constrain content to `maxWidth: 640px` centered on tablets/landscape.
  - Minimum touch target size: `48x48dp` for completion checkboxes, filter chips, and icon buttons (critical for one-handed gig-worker use).
  - Use `Platform.isIOS` / `Theme.of(context).platform` adaptive physics (`BouncingScrollPhysics` on iOS, `ClampingScrollPhysics` on Android) via Material 3 defaults.

---

## 4. Reference Dart Implementations for Core Glass Widgets

### 4.1 `AmbientMeshBackground` (`lib/core/widgets/ambient_mesh_background.dart`)
```dart
import 'package:flutter/material.dart';

/// Cached static mesh backdrop. Wrapped in RepaintBoundary so it rasterizes ONCE.
class AmbientMeshBackground extends StatelessWidget {
  final Widget child;

  const AmbientMeshBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _AmbientMeshPainter(isDark: isDark),
            isComplex: true,
            willChange: false,
          ),
        ),
        child,
      ],
    );
  }
}

class _AmbientMeshPainter extends CustomPainter {
  final bool isDark;

  _AmbientMeshPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF070B14) : const Color(0xFFEEF3FA);
    canvas.drawRect(Offset.zero & size, bgPaint);

    _drawOrb(
      canvas,
      center: Offset(size.width * 0.15, size.height * 0.12),
      radius: size.width * 0.75,
      color: isDark
          ? const Color(0xFF3B82F6).withValues(alpha: 0.24)
          : const Color(0xFF93C5FD).withValues(alpha: 0.45),
    );
    _drawOrb(
      canvas,
      center: Offset(size.width * 0.90, size.height * 0.45),
      radius: size.width * 0.65,
      color: isDark
          ? const Color(0xFF6366F1).withValues(alpha: 0.18)
          : const Color(0xFFC7D2FE).withValues(alpha: 0.40),
    );
    _drawOrb(
      canvas,
      center: Offset(size.width * 0.25, size.height * 0.88),
      radius: size.width * 0.70,
      color: isDark
          ? const Color(0xFF14B8A6).withValues(alpha: 0.16)
          : const Color(0xFF99F6E4).withValues(alpha: 0.38),
    );
  }

  void _drawOrb(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0.0)],
      ).createShader(rect);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AmbientMeshPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
```

### 4.2 `LiquidGlassChrome` & `LiquidGlassCard`
Use a shared `_SpecularBorderPainter` (1.2px diagonal specular stroke: bright top-left highlight -> soft center -> subtle tinted bottom-right bounce light):

- **`LiquidGlassChrome` (Tier 1):** `ClipRRect` -> `BackdropFilter(filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16, tileMode: TileMode.clamp))` -> `CustomPaint(foregroundPainter: _SpecularBorderPainter)` -> translucent `LinearGradient` container.
- **`LiquidGlassCard` (Tier 2):** `RepaintBoundary` -> `CustomPaint(foregroundPainter: _SpecularBorderPainter)` -> translucent `LinearGradient` container with subtle `BoxShadow(blurRadius: 12, offset: Offset(0, 6))` and optional `accentTint` (e.g., high-priority coral tint at 8–10% opacity).

---

## 5. Screen-by-Screen Layout Blueprints

### Screen A: Login & Register Screens
- Background: `AmbientMeshBackground`.
- Centered scrollable layout (`SingleChildScrollView` with `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag` so the keyboard never causes `RenderFlex overflow`).
- App mark at top ("GigFlow" + subtitle "Stay ahead of every shift").
- Single **Tier-1 `LiquidGlassChrome`** card containing:
  - Email input (`TextInputType.emailAddress`, `TextInputAction.next`)
  - Password input (obscure toggle icon, `TextInputAction.done`)
  - Register screen adds Confirm Password field.
  - Inline error banner (animated `AnimatedSize` glass pill in coral red) when `AuthFailure` occurs.
  - Primary gradient pill CTA (`Sign In` / `Create Account`) with inline `CircularProgressIndicator` during loading.
  - Footer toggle link (`New to GigFlow? Create account` / `Already have an account? Sign in`).

### Screen B: Task Dashboard (`TaskDashboardScreen`)
- `Scaffold(backgroundColor: Colors.transparent)` inside `AmbientMeshBackground`.
- `CustomScrollView` with:
  1. **Pinned/Floating Tier-1 Top Header (`ShiftSummaryHeader`):**
     - Greeting + today's date + quick theme toggle (Sun/Moon) + Logout icon button (with confirmation dialog).
     - Compact shift progress bar (`X of Y tasks done` + count of High Priority / Overdue tasks).
  2. **Offline Banner (`OfflineStatusBanner`):** Slides in smoothly when offline ("Offline mode — changes saved locally & will sync automatically").
  3. **Tier-1 Filter Dock (`FilterDock`):**
     - Row 1 (Status Segmented Pills): `All` | `Incomplete` | `Completed`
     - Row 2 (Priority Pills): `All` | `High` (coral dot) | `Medium` (amber dot) | `Low` (teal dot)
     - Shows active filter count + quick `Reset` chip if filtered results are empty.
  4. **Grouped Earliest-to-Latest Task List (`SliverList` of Tier-2 `LiquidGlassCard`):**
     - Section headers: `OVERDUE`, `TODAY`, `TOMORROW`, `UPCOMING` (only show non-empty sections).
     - Each `TaskTile`:
       - Left: 48x48dp touch area with animated circular glass checkbox (`HapticFeedback.lightImpact()`).
       - Center: Title (strikethrough + muted opacity when completed), 2-line description preview, due date/time chip (crimson if overdue & incomplete), priority glass badge.
       - Right: subtle edit chevron; tapping card opens `TaskEditorSheet` in edit mode.
       - Swipe Left (`Dismissible` with `DismissDirection.endToStart`): Coral glass delete background -> deletes task + displays Undo `SnackBar` for 4 seconds.
  5. **Floating Bottom Action Pill (Tier-1 `LiquidGlassChrome`):**
     - `+ New Task` elevated liquid glass pill positioned in bottom-right thumb zone.

### Screen C: Create / Edit Task Sheet (`TaskEditorSheet`)
- Modal bottom sheet (`isScrollControlled: true`, `backgroundColor: Colors.transparent`) wrapped in Tier-1 `LiquidGlassChrome` with top drag handle and `viewInsets.bottom` keyboard padding.
- Fields:
  - **Title** (required, max 100 chars)
  - **Description** (optional, multiline, max 500 chars)
  - **Due Date & Time** (interactive glass row opening native DatePicker + TimePicker; includes quick-select chips: `Today +2h`, `Tomorrow 9 AM`, `Custom`)
  - **Priority Selector** (3 animated glass chips: `Low`, `Medium`, `High` with color-coded glow)
  - **Action Row:** `Save Task` / `Update Task` primary pill (+ `Delete` text button in edit mode).