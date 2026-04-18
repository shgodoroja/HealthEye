# CLAUDE.md

## Project overview

**Arclens** (repo: WatchHealthDataReader) is a macOS SwiftUI app that turns Apple Watch / Apple Health exports into actionable weekly coaching insights and one-click PDF reports. The primary users are independent coaches (fitness, wellness, nutrition) managing 20-100 clients.

## Repository layout

```
HealthEye/                        # Xcode project root (Arclens app target)
  HealthEye.xcodeproj/            # Xcode project file
  HealthEye/                      # App source (SwiftUI)
  HealthEyeTests/                 # Unit tests
  HealthEyeUITests/               # UI tests
AGENTS.md                         # Agent behavior and project principles
PRD.md                            # Full product requirements document (v2)
MVP.md                            # MVP research, strategy, and scope
CHECKLIST.md                      # Quality and completeness checklist
```

## Tech stack

- **Platform:** macOS (Apple Silicon baseline)
- **UI:** SwiftUI
- **Database:** SQLite (local-first, encrypted at rest)
- **Language:** Swift
- **PDF:** In-app PDF rendering for report generation
- **Build:** Xcode

## Key product concepts

- **5 core metrics:** Sleep duration, HRV (SDNN), Resting HR, Workout minutes, Step count
- **Baseline windows:** Recent = last 7 full days; Baseline = prior 28 full days
- **Attention score:** 0-100, weighted: Recovery composite 45%, Workout 25%, Steps 15%, Completeness penalty 15%
- **Attention buckets:** 0-39 low, 40-69 medium, 70-100 high
- **Alert rules:** AR-001 Recovery risk (high), AR-002 Sleep drop (medium), AR-003 Activity drop (medium), AR-004 Step drop (low)
- **Score stability:** Same input + same version = same score always

## Data model entities

CoachAccount, Client, ClientImport, MetricDaily, AlertEvent, AttentionScore, GeneratedReport, MetricCompleteness (see PRD.md section 7 for full schema)

## Engineering principles

1. Keep changes small and testable.
2. Prefer clear, deterministic transformations for health metrics.
3. Add lightweight docs when adding data models or scoring rules.
4. Preserve backward compatibility for exported report formats.
5. Add or update tests for every behavior change when feasible.
6. Never silently replace missing data with zero.
7. Never show score changes without metric-level explanation.
8. Core workflows (import, analysis, report) must work offline.

## Testing policy

- Cover new core logic with unit tests (parser, scoring, alerts).
- Cover critical user flows with UI tests (import, dashboard, report, paywall).
- If a change cannot be tested, document why and add manual validation steps.
- Do not mark work complete unless test outcomes are recorded.

## Decision policy (when tradeoffs arise)

1. Choose the option that improves coach weekly workflow speed.
2. If equal, choose the lower-complexity implementation.
3. If still equal, choose the option with stronger privacy guarantees.

## Build milestones

- **M1 (Weeks 1-2):** Core data model + guided import parser + completeness layer
- **M2 (Weeks 3-4):** Dashboard ranking + client detail + alert engine + score transparency
- **M3 (Weeks 5-6):** Report generation + weekly change narrative + message helper
- **M4 (Weeks 7-8):** Billing/paywall + portability controls + instrumentation + QA

## Important commands

```bash
# Build the project
xcodebuild -project HealthEye/HealthEye.xcodeproj -scheme HealthEye build

# Run unit tests
xcodebuild -project HealthEye/HealthEye.xcodeproj -scheme HealthEye test

# Run UI tests
xcodebuild -project HealthEye/HealthEye.xcodeproj -scheme HealthEyeUITests test
```

## Reference docs

- `PRD.md` — Full product requirements, data model, screen specs, scoring rules
- `MVP.md` — Market research, competitive landscape, pricing strategy
- `CHECKLIST.md` — Quality and completeness checklist with acceptance criteria
- `AGENTS.md` — Agent behavior guidelines and project principles
