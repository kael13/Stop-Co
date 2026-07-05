# MVP UI Overhaul Plan

## Goal
Polish the Stop-Co interface into a clean, minimal, production-ready MVP by removing visual complexity, dead code, and over-engineered animations.

## Phases

### Phase 1: Nav bar uniformity
**File:** `lib/features/home/presentation/main_shell.dart`

| Step | Change | Details |
|------|--------|---------|
| 1.1 | Remove `isMiddle` parameter | From `_NavBarItem`, `_TabItem`, and the build call |
| 1.2 | Remove gradient-pill branch | Delete the `if (widget.isMiddle)` special treatment block — all tabs use simple icon + label |
| 1.3 | Reorder `_tabs` | `Trips` → `Saved` → `Simulate` → `Settings` (Trips first, index 0 is home) |
| 1.4 | Reorder `_pages` | Match the new tab order |
| 1.5 | Set `_currentIndex = 0` | Default landing page is Trips |

---

### Phase 2: Animation reduction
**File:** `lib/features/home/presentation/main_shell.dart`

| Step | Change | Details |
|------|--------|---------|
| 2.1 | Remove `_HomeTab` entrance animation | Strip `.animate().fadeIn().slideY()` on the main tab container |
| 2.2 | Remove child entrance animations | Replace `.fadeSlideUp(delay: ...)` and `.cardEntrance()` with bare widgets (4 occurrences) |
| 2.3 | Remove destination card stagger | Strip `.fadeSlideUp()` on destination cards |
| 2.4 | Remove trip card stagger | Strip `.fadeSlideUp()` on trip cards |

---

### Phase 3: Shimmer removal
**File:** `lib/features/home/presentation/main_shell.dart`

| Step | Change | Details |
|------|--------|---------|
| 3.1 | Rewrite `_DestinationsSkeleton` | Replace shimmer layout with `CircularProgressIndicator` |
| 3.2 | Rewrite `_RecentTripsSkeleton` | Same — simple centered spinner |

---

### Phase 4: Hero transition removal

| Step | File | Change |
|------|------|--------|
| 4.1 | `main_shell.dart:721` | Remove `Hero(tag: 'active-trip-distance')` |
| 4.2 | `main_shell.dart:1225-1228` | Remove `Hero(tag: 'trip-${trip.id}')` |
| 4.3 | `active_trip_screen.dart:641-645` | Remove `Hero(tag: 'active-trip-distance')` |
| 4.4 | `trip_detail_screen.dart:123-127` | Remove `Hero(tag: 'trip-${trip.id}-distance')` |
| 4.5 | `trip_detail_screen.dart:186,336-343,394-395` | Remove `heroTag` parameter and Hero gate on `StatTile` |

---

### Phase 5: Auth screen compact header
**File:** `lib/features/auth/presentation/auth_screen.dart`

| Step | Change | Details |
|------|--------|---------|
| 5.1 | Reduce `headerHeight` | `maxHeight * 0.38` → `maxHeight * 0.15` |
| 5.2 | Simplify `_BrandHeader` | Remove large decorative circle + border; keep bell icon + app name |
| 5.3 | Adjust offset | `headerHeight - 60` → `headerHeight - 20` |

---

### Phase 6: Verification banner text
**File:** `lib/features/auth/presentation/auth_screen.dart`

| Step | Change |
|------|--------|
| 6.1 | `'Verify your email to post in Community'` → `'Verify your email address'` |
| 6.2 | `'Check your inbox and tap the verification link, then refresh.'` → `'Check your inbox for the verification link, then tap refresh.'` |

---

### Phase 7: Settings animation cleanup
**File:** `lib/features/settings/presentation/settings_screen.dart`

| Step | Change |
|------|--------|
| 7.1 | Strip all 15 `.animate().fadeIn().slideX/Y()` calls from section headers and tiles |

---

## Files not touched
- `lib/features/community/` — preserved for future use
- `lib/core/animation/animation_presets.dart` — kept (`scaleTapHaptic`, `subtleShimmerSweep` used elsewhere)
- `lib/features/trip/presentation/active_trip_screen.dart` — only the Hero wrapper removed
- `lib/features/trip/presentation/trip_detail_screen.dart` — only Hero/heroTag removed

## Effort summary

| Phase | Files | Changes | Effort |
|-------|-------|---------|--------|
| 1 | 1 | ~60 lines removed, 5 changed | Low |
| 2 | 1 | ~8 lines removed | Low |
| 3 | 1 | ~30 lines rewritten | Low |
| 4 | 3 | ~20 lines removed | Low |
| 5 | 1 | ~10 lines changed | Low |
| 6 | 1 | 2 lines changed | Trivial |
| 7 | 1 | ~15 lines stripped | Low |
