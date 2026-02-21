# WatchHealthDataReader Product Requirements Document (PRD)

Last updated: 2026-02-20 (v2 feature-priority update)
Owner: Product/Founding Team
Status: Draft v2 (build-ready for MVP)

## 1) Product summary

WatchHealthDataReader is a coaches-first Mac app that converts Apple Watch/Apple Health exports into weekly client risk/recovery insights and one-click reports.

MVP business outcome:
- Help coaches identify which clients need attention this week and what message to send.

MVP user outcome:
- Reduce manual spreadsheet work and speed up check-ins.

## 2) Goals and non-goals

### Goals (MVP)
1. Import client Apple Health data reliably.
2. Calculate explainable trend signals for 5 core metrics.
3. Rank clients by attention priority.
4. Generate a one-click weekly PDF report + suggested coach message.
5. Convert free trial coaches into paid subscriptions.

### Non-goals (MVP)
1. Clinical diagnosis or regulated medical decision support.
2. Full third-party integrations marketplace.
3. Opaque ML/AI scoring that cannot be explained.
4. Native direct HealthKit-on-Mac ingestion.

## 3) Target users and jobs-to-be-done

Primary persona:
- Independent coach (fitness, wellness, nutrition), 20-100 active clients.

Core jobs:
1. "Show me which clients are at risk this week."
2. "Tell me what changed and why."
3. "Give me a report and a message I can send quickly."

Secondary persona (later):
- Prosumer athlete (individual self-analysis).

### Market-backed inputs (v2)

Best competitor features to borrow:
1. Automation and broad metric coverage from Apple Health export tools.
2. Workout intelligence depth from advanced fitness analytics apps.
3. Data portability and interoperability from workout data hub tools.
4. Coach operations patterns from coaching platforms (client overview + communication loops).

Top customer wants (coach-first):
1. Less import/cleanup friction.
2. Trustworthy and explainable scores.
3. Weekly "who needs attention now" prioritization.
4. One-click report output plus message-ready guidance.
5. Strong data ownership and deletion controls.

Common complaints to design against:
1. Fragmented workflows across too many tools.
2. Manual XML cleanup burden.
3. Missing/inconsistent metric handling.
4. Opaque or unstable scoring.
5. Perceived vendor lock-in and weak export controls.

## 4) Scope

### In scope
1. Mac app with local data store.
2. Import wizard for Apple Health export files per client.
3. Dashboard with attention score and metric trend snapshots.
4. Client detail with trend charts and explainable alert rules.
5. Weekly report generation (PDF) and copy-ready message.
6. Billing wall and trial tracking.

### Must-feature set (P0)
1. Frictionless iPhone-to-Mac ingest flow for Apple Health exports.
2. Data completeness and trust layer (explicit missing-data visibility).
3. Coach triage dashboard with attention-priority sorting.
4. Explainable and stable scoring with visible breakdown.
5. One-click weekly report plus suggested coach message.
6. Data ownership controls (export/delete/archive).

### Complaint-driven quality guardrails
1. Never silently replace missing data with zero.
2. Never show score changes without showing their metric-level drivers.
3. Never block customer portability; user export and deletion must remain available.
4. Keep weekly workflow to minimal clicks from dashboard to report.

### Out of scope
1. iOS native companion app.
2. Real-time wearable sync.
3. Team collaboration permissions/roles.
4. EHR/clinic system integrations.

## 5) Success metrics

Primary KPIs:
1. Trial activation: >=60% import >=5 clients in first 7 days.
2. Product engagement: >=40% generate >=2 reports during trial.
3. Conversion: >=20% trial-to-paid by day 14.

Secondary KPIs:
1. Weekly active coaches (WAU).
2. Reports generated per coach per week.
3. Alert-to-message usage rate.
4. 30/60/90-day paid retention.

## 6) Product requirements

### Functional requirements

FR-001 Data import
- The app must import Apple Health export files per client.
- Supported input formats:
  - Zip export containing `export.xml`.
  - Raw `export.xml`.
- The app must validate file integrity before ingest.

FR-002 Client management
- Coach can create, edit, archive client profiles.
- Each client has a unique internal ID and optional external reference.

FR-003 Metric normalization
- The app normalizes imported data into daily aggregates for:
  - Sleep duration
  - HRV (e.g., SDNN)
  - Resting heart rate
  - Workout duration/volume
  - Step count

FR-004 Baseline and trend engine
- For each metric, compute:
  - 7-day recent average
  - 28-day baseline average
  - Delta percentage and direction
- Missing data must be represented explicitly.

FR-005 Explainable alert rules
- Rule-based alerts with visible conditions.
- Each alert must include:
  - Trigger condition text
  - Metrics involved
  - Severity
  - Timestamp

FR-006 Attention score
- Each client receives a weekly attention score (0-100).
- Score is weighted combination of metric deviations and adherence drops.
- Score breakdown must be visible in UI.

FR-007 Dashboard ranking
- Dashboard defaults to sorting clients by attention score descending.
- Coach can filter by status: high/medium/low attention.

FR-008 Weekly report generation
- Generate PDF per client with:
  - Metric trend cards
  - Key changes this week
  - Alert summary
  - Suggested coach message
- Export path must be user-selectable.

FR-009 Message helper
- Provide 2-3 suggested message drafts based on alert profile.
- Coach can copy to clipboard with one click.

FR-010 Trial and billing
- 14-day trial enforced by account state.
- On expiration, report generation is locked behind paywall.
- Plans:
  - Solo Coach (<=30 clients)
  - Pro Coach (<=100 clients)

FR-011 Auditability
- Every generated report references input date range and generation timestamp.

FR-012 Data completeness trust layer
- The app must display metric completeness status per client and per week.
- Missing or low-confidence data must be labeled clearly in dashboard, detail, and reports.

FR-013 Data ownership and portability
- Coach can export client data and generated insights in machine-readable format (CSV/JSON).
- Coach can delete or archive client records and generated reports from settings.

FR-014 Score stability guardrail
- Attention score recalculation must be deterministic and stable.
- Score changes between runs require either new source data or versioned rule changes.
- Score change drivers must be visible in client detail.

FR-015 Guided ingest assistant
- Import wizard must provide clear guided steps for obtaining Apple Health export from iPhone.
- Wizard must warn about stale exports and show "last export date" from source payload when available.

FR-016 Weekly change narrative
- Client detail and report must include a concise "what changed this week" section summarizing main deltas.

### Non-functional requirements

NFR-001 Performance
- Import 1 year of data for one client in <=15 seconds on Apple Silicon baseline machine.
- Dashboard load <=1.5 seconds for 100 clients.

NFR-002 Reliability
- No partial writes on import failure.
- Failed imports must rollback transaction.

NFR-003 Privacy and security
- Local-first storage by default.
- Encrypt sensitive local database at rest.
- No data sharing without explicit user action.

NFR-004 Explainability
- All scores and alerts must be reproducible deterministically from stored data.

NFR-005 Accessibility
- Keyboard navigation support for key workflows.
- Dynamic type support for critical screens.

NFR-006 Workflow efficiency
- From dashboard, a coach must be able to identify top-priority clients and export a weekly report for one client in <=3 clicks.

NFR-007 Score transparency
- Every attention score update must be explainable by traceable metric inputs and rule/version metadata.

## 7) Data model (MVP)

### Entities

CoachAccount
- id (UUID)
- email
- plan_type (`trial`, `solo`, `pro`)
- trial_start_at
- trial_end_at
- status (`active`, `expired`, `past_due`)

Client
- id (UUID)
- coach_id (UUID)
- display_name
- timezone
- status (`active`, `archived`)
- created_at

ClientImport
- id (UUID)
- client_id (UUID)
- source_type (`apple_health_xml`)
- file_hash
- imported_at
- date_range_start
- date_range_end
- import_status (`success`, `failed`)
- failure_reason (nullable)

MetricDaily
- id (UUID)
- client_id (UUID)
- date
- sleep_minutes
- hrv_ms
- resting_hr_bpm
- workout_minutes
- steps
- completeness_score (0-1)

AlertEvent
- id (UUID)
- client_id (UUID)
- week_start
- rule_code
- severity (`low`, `medium`, `high`)
- explanation_text
- created_at

AttentionScore
- id (UUID)
- client_id (UUID)
- week_start
- score_total (0-100)
- score_sleep
- score_hrv
- score_resting_hr
- score_workout
- score_steps
- score_completeness_penalty
- score_version
- source_data_hash
- calculated_at

GeneratedReport
- id (UUID)
- client_id (UUID)
- week_start
- week_end
- pdf_path
- generated_at
- version

MetricCompleteness
- id (UUID)
- client_id (UUID)
- week_start
- has_sleep
- has_hrv
- has_resting_hr
- has_workout
- has_steps
- completeness_score (0-1)
- notes

## 8) Scoring and alert spec (MVP deterministic rules)

### Baseline windows
1. Recent window: last 7 full days.
2. Baseline window: prior 28 full days (excluding recent window).

### Alert rules (initial set)
AR-001 Recovery risk
- Trigger when:
  - HRV recent <= baseline by 12% or more, and
  - Resting HR recent >= baseline by 8% or more, and
  - Sleep recent <= baseline by 10% or more.
- Severity: high.

AR-002 Sleep adherence drop
- Trigger when sleep recent <= baseline by 15% or more.
- Severity: medium.

AR-003 Activity drop
- Trigger when workout minutes recent <= baseline by 20% or more.
- Severity: medium.

AR-004 Step adherence drop
- Trigger when steps recent <= baseline by 20% or more.
- Severity: low.

### Attention score (initial weights)
1. Recovery composite (HRV + resting HR + sleep): 45%
2. Workout trend: 25%
3. Step trend: 15%
4. Data completeness penalty: 15%

Score output:
- 0-39 low attention
- 40-69 medium attention
- 70-100 high attention

### Score stability and explainability rules
1. Same input data + same score version must always produce the same score.
2. Any score version change must be tracked and visible in app/report metadata.
3. Score change cards must list top 3 contributing metric deltas week-over-week.

## 9) Screen-by-screen specification

### Screen S1: Welcome and persona setup
Purpose:
- Start trial and orient user to coach workflow.

Primary UI:
- Headline value proposition.
- Email sign-up/sign-in.
- Persona selector (default: Coach).
- CTA: `Start 14-day trial`.

States:
- Empty: first launch.
- Error: auth failure.

Events:
- `trial_started`
- `persona_selected`

Acceptance criteria:
1. User can complete account setup in <=2 minutes.
2. Trial state is persisted and visible in header after onboarding.

### Screen S2: Workspace setup
Purpose:
- Establish default report preferences and timezone.

Primary UI:
- Timezone selector.
- Default weekly report day selector.
- Optional branding fields (coach name/logo).
- CTA: `Continue to client setup`.

States:
- Default prefilled from system locale.

Events:
- `workspace_config_saved`

Acceptance criteria:
1. Preferences save successfully and apply to generated reports.

### Screen S3: Client list (dashboard)
Purpose:
- Show weekly attention ranking.

Primary UI:
- Table/list of clients:
  - Name
  - Attention score
  - Top alert
  - Last import date
  - Report status
- Filters:
  - High/medium/low
  - Imported/not imported
- CTA buttons:
  - `Add client`
  - `Generate all weekly reports`

States:
- Empty (no clients): onboarding prompt.
- Loading.
- Error (data load failure).

Events:
- `dashboard_viewed`
- `filter_applied`
- `bulk_report_generation_started`

Acceptance criteria:
1. Ranking updates immediately after completed import.
2. Coach can identify high-attention clients without opening detail pages.

### Screen S4: Add/edit client
Purpose:
- Create and manage client profiles.

Primary UI:
- Client name
- Optional tags (e.g., performance, weight loss)
- Timezone
- Notes field
- CTA: `Save client`

States:
- Validation errors for missing name.

Events:
- `client_created`
- `client_updated`
- `client_archived`

Acceptance criteria:
1. New client appears in dashboard immediately.
2. Archived clients are hidden from default dashboard.

### Screen S5: Import wizard (per client)
Purpose:
- Guide import from Apple Health export file.

Primary UI:
- Drag/drop zone.
- File type guidance text.
- Date range preview.
- CTA: `Start import`.

States:
- Invalid file format.
- Duplicate import detection.
- Partial/missing metric warning.

Events:
- `import_started`
- `import_succeeded`
- `import_failed`

Acceptance criteria:
1. Successful import creates normalized daily metrics.
2. Duplicate file hash prompts user before re-import.
3. Wizard includes explicit "how to export from iPhone Health" guidance.
4. Completeness summary is shown immediately after import.

### Screen S6: Client detail and trends
Purpose:
- Explain changes and guide action for a single client.

Primary UI:
- Attention score card with breakdown.
- Weekly change narrative card (`What changed this week`).
- Metric cards (sleep, HRV, resting HR, workout, steps):
  - recent vs baseline delta
  - 8-week mini chart
- Alerts panel with trigger explanations.
- Message helper panel (copy buttons).
- CTA: `Generate weekly report`.

States:
- Missing data placeholders with explicit reason.

Events:
- `client_detail_viewed`
- `message_copied`
- `single_report_generation_started`

Acceptance criteria:
1. Coach can see why score is high (breakdown visible).
2. At least one copy-ready message appears when alerts are present.
3. Weekly change narrative summarizes top 3 changes with metric deltas.

### Screen S7: Report preview
Purpose:
- Review before export.

Primary UI:
- PDF preview pane.
- Date range selector.
- Include/exclude sections toggles.
- CTA: `Export PDF`.

States:
- Loading preview.
- Export error with retry.

Events:
- `report_preview_opened`
- `report_exported`

Acceptance criteria:
1. Exported file matches preview and contains generation metadata.

### Screen S8: Billing and plan management
Purpose:
- Convert trial users and manage limits.

Primary UI:
- Trial days remaining.
- Plan cards:
  - Solo Coach (<=30 clients)
  - Pro Coach (<=100 clients)
- Feature comparison.
- CTA: `Upgrade now`.

States:
- Trial active.
- Trial expired (feature lock banners).
- Payment failure.

Events:
- `paywall_viewed`
- `plan_selected`
- `upgrade_succeeded`
- `upgrade_failed`

Acceptance criteria:
1. Expired trial blocks report export and bulk generation.
2. Upgrade unlocks gated features immediately.

### Screen S9: Settings and privacy
Purpose:
- Control data retention and exports.

Primary UI:
- Local database location.
- Data deletion tools (client-level or all data).
- Data export tools (CSV/JSON export per client and workspace).
- Export audit log list.
- Disclaimer section (not medical advice).

Events:
- `data_deleted`
- `settings_updated`

Acceptance criteria:
1. User can permanently delete a client and related reports.
2. Destructive actions require explicit confirmation.
3. User can export machine-readable client data without support intervention.

## 10) User flows (critical)

Flow F1: First value in first session
1. Start trial (S1).
2. Configure workspace (S2).
3. Add first client (S4).
4. Import data (S5).
5. Review attention insights (S6).
6. Export first weekly report (S7).

Flow F2: Weekly coach routine
1. Open dashboard Monday (S3).
2. Filter high attention clients.
3. Open client detail (S6), copy message.
4. Generate/export report (S7).
5. Repeat for top flagged clients.

Flow F3: Conversion
1. Trial nearing expiration banner appears.
2. Coach attempts report generation.
3. Paywall (S8).
4. Upgrade and continue workflow.

## 11) Technical architecture (MVP)

Client application:
- macOS app (SwiftUI recommended).
- Local database (SQLite).
- Deterministic scoring/alert engine in-app.
- PDF rendering module for report generation.

Optional service components:
- Billing/license validation endpoint.
- Crash/error telemetry endpoint.

No-cloud mode requirement:
- Core import, scoring, dashboard, and report generation must work offline.

## 12) Instrumentation plan

Event taxonomy (minimum):
1. `trial_started`
2. `client_created`
3. `import_succeeded`
4. `dashboard_viewed`
5. `client_detail_viewed`
6. `message_copied`
7. `report_exported`
8. `paywall_viewed`
9. `upgrade_succeeded`
10. `completeness_viewed`
11. `score_breakdown_viewed`
12. `data_exported`

Dimensions:
- plan_type
- trial_day_number
- client_count_bucket
- attention_bucket_distribution

## 13) QA and test plan

### Unit tests
1. XML parser correctness for supported metric nodes.
2. Baseline/recent window calculations.
3. Alert rule trigger correctness.
4. Attention score determinism.
5. Completeness scoring and missing-data labeling logic.
6. Score stability across repeated recalculations.

### Integration tests
1. End-to-end import -> dashboard -> report export.
2. Trial expiration and paywall gating.
3. Archive/delete client data cascade behavior.
4. Data export (CSV/JSON) consistency and schema validation.

### Manual test checklist
1. Import valid zip export.
2. Import invalid file.
3. Duplicate import handling.
4. Generate single report and bulk reports.
5. Offline workflow.
6. Upgrade flow from expired trial.
7. Weekly change narrative readability and correctness.
8. Score change explanation visibility after new import.

## 14) Compliance and disclaimers

1. App must include clear non-medical disclaimer:
   - "This app provides wellness and coaching insights only and is not a medical device."
2. Avoid diagnosis language in UI and report copy.
3. Provide user-visible data deletion controls.

## 15) Release plan

Milestone M1 (Weeks 1-2):
- Core data model + guided import parser + completeness layer.

Milestone M2 (Weeks 3-4):
- Dashboard ranking + client detail + alert engine + score transparency.

Milestone M3 (Weeks 5-6):
- Report generation + weekly change narrative + message helper.

Milestone M4 (Weeks 7-8):
- Billing/paywall + portability controls + instrumentation + QA hardening.

Beta release target:
- End of week 8 with 20-30 design partner coaches.

## 16) Risks and mitigations

Risk R1:
- Data quality variability in exports.
Mitigation:
- Import validation, completeness score, explicit missing-data UI.

Risk R2:
- Users mistrust opaque scoring.
Mitigation:
- Full score breakdown and rule explanations.

Risk R3:
- Low trial conversion.
Mitigation:
- Trigger paywall after first insight value moment and run copy/pricing tests.

Risk R4:
- Users perceive lock-in risk and avoid onboarding many clients.
Mitigation:
- Ship explicit CSV/JSON export and transparent deletion controls in MVP.

Risk R5:
- Users mistrust score fluctuations.
Mitigation:
- Enforce deterministic scoring, versioning, and visible score-change drivers.

## 17) Open questions

1. Should report branding customization be included in MVP or moved to Pro-only?
2. Should bulk report generation be available during trial or paid-only?
3. Is CSV export needed in MVP or can it wait until post-beta?
4. Which billing provider is preferred for first release?

## 18) Build readiness checklist

1. Requirements IDs mapped to tickets.
2. Screen specs mapped to design files.
3. Scoring and alert rules signed off by product.
4. Analytics events implemented and validated.
5. QA checklist passes on target macOS versions.
6. Must-feature set (P0) is fully implemented or explicitly deferred with sign-off.
7. Complaint-driven quality guardrails pass QA validation.
