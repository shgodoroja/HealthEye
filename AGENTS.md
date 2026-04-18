# AGENTS.md

Project: Arclens (repo: WatchHealthDataReader)
Path: /Users/stefangodoroja/Documents/Projects/WatchHealthDataReader

## Purpose

Build a coaches-first product that turns Apple Watch/Apple Health data into actionable weekly insights and report outputs.

## Primary objective

Deliver and iterate a monetizable MVP for independent coaches:
- Client data ingest.
- Attention-priority dashboard.
- One-click weekly report generation.
- Explainable trend/alert logic.

## Product principles

1. Coach outcome over generic analytics.
2. Explainable insights over black-box scoring.
3. Privacy-first defaults (minimal data retention, explicit consent).
4. Fast time-to-value (first useful report within first session).

## Target users (priority order)

1. Independent performance/wellness/nutrition coaches (20-100 clients).
2. Prosumer athletes (phase 2).
3. Clinician/cohort workflows (phase 3).

## MVP scope guardrails

Include:
- Apple Health data ingestion and normalization.
- Weekly client trend summaries.
- Report export (PDF) and coach message helper.
- Simple interpretable alert rules.

Exclude (for MVP):
- Clinical diagnosis workflows.
- Large connector marketplace.
- Complex ML models requiring opaque scoring.

## Monetization assumptions

Initial packaging:
- Solo Coach: $39/month up to 30 clients.
- Pro Coach: $79/month up to 100 clients.
- 14-day free trial.

Success gates:
- >60% of trials import 5+ clients in week 1.
- >40% generate 2+ reports during trial.
- >20% trial-to-paid conversion by day 14.

## Engineering workflow

1. Keep changes small and testable.
2. Prefer clear, deterministic transformations for health metrics.
3. Add lightweight docs when adding data models or scoring rules.
4. Preserve backward compatibility for exported report formats.
5. Add or update tests for every behavior change when feasible.

## Testing policy

1. Cover new core logic with unit tests whenever possible.
2. Cover critical user flows with UI tests whenever possible (import, dashboard triage, report generation, paywall gating).
3. If a change cannot be covered by unit/UI tests, document why in the change notes and add manual validation steps.
4. Do not mark work complete unless test outcomes (or justified exceptions) are recorded.

## Documentation requirements

When adding major features, update:
- /Users/stefangodoroja/Documents/Projects/WatchHealthDataReader/MVP.md (strategy and scope impact)
- Implementation notes/readme files introduced by the change

## Decision policy

When tradeoffs arise:
1. Choose the option that improves coach weekly workflow speed.
2. If equal, choose the lower-complexity implementation.
3. If still equal, choose the option with stronger privacy guarantees.

## Current planning source

Reference baseline:
- /Users/stefangodoroja/Documents/Projects/WatchHealthDataReader/MVP.md
