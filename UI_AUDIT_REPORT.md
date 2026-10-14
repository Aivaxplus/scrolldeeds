# UI Audit Report — Pre-Redesign

Read-only audit of `scrolldeeds/`, `ScrollDeedsMonitor/`, `ScrollDeedsShield/` before the heart-centered dashboard elevation. No functionality was analyzed for removal — UI layer only.

---

## 1. Unused UI (verified by cross-file reference search)

### High confidence — safe to remove
| File | Symbol | Evidence |
|------|--------|----------|
| `scrolldeeds/LockedAppTile.swift` | `LockedAppTile` (both variants) | Never instantiated; dashboard uses `LockedAppRow` |
| `scrolldeeds/Theme.swift` | `SDSectionHeader`, `SDSheetChrome`, `SDPrimaryButton`, `SDGoldButton`, `SDSecondaryButton` | Zero call sites; `PrimaryButtonStyle`/`SecondaryButtonStyle` are the live button APIs |
| `scrolldeeds/HardPaywallView.swift` | `ResultRow` (~L2135), `PaywallResultRow` (~L2482) | Twin structs, both definition-only |
| `scrolldeeds/ContentView.swift` | `readyCard` (L992–1147) | Dead twin of the CTA block inside `dashboardCard` |
| `scrolldeeds/ContentView.swift` | `languageSelectorButton` (L605), `stat(_:_:_:)` (~L1584) | Never called |

### Medium confidence — KEPT (per safety rule)
| File | Symbol | Why kept |
|------|--------|----------|
| `DeleteInterventionReasonView/WhyPaidView/ShaytaanView.swift` | 3 views | Only `#Preview` refs, but conceptually tied to quick actions — uncertain |
| `RememberVaultDetailView.swift` | `RememberVaultDetailView` | Store + models exist and are live; view may be wired later |
| `PushupCameraPreviewView.swift` | `PushupCameraPreviewRepresentable` | Orphaned, but tied to potential deed type |

---

## 2. Duplicate styling / design-token underuse

| Signal | Count | Notes |
|--------|-------|-------|
| `RoundedRectangle(cornerRadius: <literal>)` | 132 | QuestionnaireView 40, ContentView 23, HardPaywallView 19 |
| Hardcoded `Color(red:green:blue:)` outside Theme | 49 | Brand green `0.231/0.706/0.471` repeated 8× in ContentView alone |
| Ad-hoc `.shadow(` | 112 | Repeated dual-shadow "premium card" pattern copied 4× on dashboard |
| `font(.system(size:` | 556 | vs ~11 uses of `AppTypography` tokens |
| `AppSpacing.*` adoption | 1 use | Effectively unused |
| `AppRadius.*` adoption | ~7 uses | Effectively unused |

**Overlapping component families:** two button APIs (ButtonStyles vs unused SD* wrappers) · inline card chrome copied across `dashboardCard`/`lockedApps`/`progressCard`/`readyCard` instead of a shared modifier · paywall has two plan-card implementations · `LockedAppTile` vs `LockedAppRow`.

---

## 3. Dashboard structure (ContentView.swift)

Order: `logoHeader` → `GamifiedStreakView` → separator → scroll [`timeRemainingCard` (if unlocked) → `dashboardCard` (status hero + unlock CTA) → `lockedApps` → `progressCard`] → `customBottomNavigationBar`.

Driven by: `isUnlockActive`, `unlockEndsAt`, `unlockBudgetMinutes`, `currentTime`, `shieldManager.isShieldActive/selected*`, `userDataManager.todaySessions/todayMinutes/currentStreak`, `subscriptionManager`.

---

## 4. Heart state → existing observable state (presentation-only binding)

| Heart state | Derived from (no logic changes) |
|-------------|--------------------------------|
| Heavy (locked) | `shieldManager.isShieldActive && !isUnlockActive` |
| Lighter (after deed) | `isUnlockActive == true` |
| Fed / glowing | `isUnlockActive && userDataManager.todaySessions >= 2` |
| Peaceful (strongest) | `isUnlockActive && userDataManager.dailyGoalCompleted` or streak-boosted |
| Too much noise | locked again after sessions today (`todaySessions > 0 && !isUnlockActive`) |

Long-term vitality (weeks of gradual improvement): derived from `currentStreak` + `totalSessions` → drives saturation/glow intensity only.

---

## 5. Actions taken in this pass

- Removed only the **high-confidence** items in §1.
- Added elevation/card tokens to `Theme.swift`; new dashboard surfaces use them.
- No business logic, flows, navigation, Screen Time, notifications, analytics, or subscription code touched.
