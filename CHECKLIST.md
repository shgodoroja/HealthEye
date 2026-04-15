# WatchHealthDataReader MVP Quality and Completeness Checklist

Last updated: 2026-04-15
Reference PRD: `/Users/stefangodoroja/Documents/Projects/WatchHealthDataReader/PRD.md`

How to use:
- Mark each item `[x]` only when all acceptance criteria pass.
- Add proof links/notes in the Evidence line.
- Do not skip blocked items; mark blockers explicitly.

---

## 0) Current Remediation Sequence

Use this section as the ordered execution plan for the current app state review. Do not mark later phases complete while an earlier blocking phase is still open.

### Phase 1: Import -> Derived Data -> Dashboard Coherence (P0)

- [ ] Import completion generates all required derived data
  - Acceptance criteria:
    - Successful import persists weekly completeness records for the affected client.
    - Successful import persists current-week attention score and alert records for the affected client.
    - Derived records are created without requiring the client detail screen to be opened.
  - Test coverage:
    - Unit test covers import -> completeness persistence.
    - Unit test covers import -> score/alert persistence.
    - Any uncovered behavior has documented manual validation.
  - Evidence:

- [ ] Dashboard triage refreshes after imports for existing clients
  - Acceptance criteria:
    - Importing new data for an existing client updates sidebar ranking in the same app session.
    - Attention-bucket filtering reflects the new score without relaunch.
    - Deleting or archiving a client still clears invalid selection state correctly.
  - Test coverage:
    - UI test covers existing-client import -> updated dashboard ordering where feasible.
    - If UI automation is not feasible yet, manual validation steps and outcomes are recorded.
  - Evidence:

- [ ] Main coach workflow no longer depends on opening client detail first
  - Acceptance criteria:
    - A newly imported client shows usable completeness/priority state directly in dashboard views.
    - Dashboard and client row badges do not default to misleading zero-completeness state after valid import.
  - Test coverage:
    - Unit or integration coverage exists for derived-data availability after import.
  - Evidence:

### Phase 2: Weekly Correctness and Score Trust (P0)

- [ ] Weekly report uses week-specific completeness
  - Acceptance criteria:
    - Report score and completeness are computed from the selected report week only.
    - Historical reports for different weeks can produce different completeness values when data differs.
    - Exported PDF and preview show the same week-specific result.
  - Test coverage:
    - Unit test covers two weeks with different completeness producing different report outputs.
  - Evidence:

- [ ] Attention score does not double-penalize missing data
  - Acceptance criteria:
    - Missing metric deltas do not independently add full urgency penalty on top of completeness penalty.
    - Sparse-data clients are not ranked above clearly declining clients solely due to missingness.
    - Score breakdown still explains incompleteness clearly.
  - Test coverage:
    - Unit tests cover sparse-data scenarios and compare them against real-decline scenarios.
  - Evidence:

- [ ] Weekly vs lifetime completeness semantics are explicit across the app
  - Acceptance criteria:
    - Dashboard, report, and client-detail “weekly” messaging uses week-specific completeness.
    - Any lifetime or historical-average completeness is explicitly labeled as such.
    - No coach-facing decision view mixes weekly trend with all-time completeness silently.
  - Test coverage:
    - Unit tests cover helper methods for week-specific and historical completeness selection.
    - UI verification exists where feasible for displayed labels/values.
  - Evidence:

### Phase 3: Build Safety and Automation (P1)

- [ ] Swift concurrency warnings in import/parser path are resolved
  - Acceptance criteria:
    - App-owned warnings tied to parser/import actor isolation are removed from build output.
    - Parser state mutation is isolation-safe and deterministic.
    - Import progress updates no longer rely on unsafe captured-main-actor patterns.
  - Test coverage:
    - Existing parser/import tests pass after refactor.
    - Any new concurrency-sensitive code paths have unit coverage where possible.
  - Evidence:

- [ ] UI test suite covers critical coach workflows
  - Acceptance criteria:
    - Automated UI tests cover import flow, dashboard triage update, report preview/export, and paywall gating where feasible.
    - UI test runner starts unattended without local-authentication interruption.
    - Release candidate runs record UI test results.
  - Test coverage:
    - This item is complete only when the UI test implementation itself exists and runs.
  - Evidence:

### Phase 4: Platform and Release Hardening (P2)

- [ ] Deployment target matches launch strategy
  - Acceptance criteria:
    - `MACOSX_DEPLOYMENT_TARGET` is intentionally chosen and documented.
    - Target version is not higher than necessary for the MVP feature set unless explicitly justified.
  - Test coverage:
    - Build/run validation is recorded for the chosen minimum supported macOS version where feasible.
  - Evidence:

- [ ] Review findings are reflected in release sign-off
  - Acceptance criteria:
    - No open P0 issue remains in phases 1-2 at go/no-go time.
    - Any waived P1/P2 issue includes owner, rationale, and mitigation.
  - Test coverage:
    - Final release candidate test results are linked in evidence.
  - Evidence:

---

## 1) Product Scope Completeness

- [ ] MVP scope matches PRD (no missing in-scope features, no accidental out-of-scope work)
  - Acceptance criteria:
    - In-scope features from PRD section 4 are implemented or intentionally deferred with documented reason.
    - Out-of-scope features from PRD section 4 are not shipped in MVP.
  - Evidence:

- [ ] Goals/non-goals are reflected in product behavior and copy
  - Acceptance criteria:
    - Product supports all PRD goals in section 2.
    - UI/report copy does not imply diagnosis or medical claims.
  - Evidence:

- [ ] Must-feature set (P0) is fully covered
  - Acceptance criteria:
    - Follows PRD section 4 `Must-feature set (P0)` with no missing items.
    - Any deferred P0 item has explicit sign-off and mitigation.
  - Evidence:

---

## 2) Data Import Quality (FR-001, FR-002)

- [ ] Apple Health file ingest works for supported formats
  - Acceptance criteria:
    - Accepts `export.xml` and zip containing `export.xml`.
    - Rejects unsupported files with actionable error message.
    - Import wizard includes clear iPhone export guidance.
  - Evidence:

- [ ] Import integrity and rollback are reliable
  - Acceptance criteria:
    - Failed import does not create partial records.
    - Import failure reason is visible in logs/UI.
  - Evidence:

- [ ] Duplicate import handling is correct
  - Acceptance criteria:
    - Duplicate file hash is detected.
    - User sees clear prompt to skip/re-import.
  - Evidence:

- [ ] Data completeness trust layer works end-to-end
  - Acceptance criteria:
    - Post-import completeness summary is shown per client.
    - Missing metrics are visible in dashboard/detail/report contexts.
  - Evidence:

- [ ] Client CRUD is complete and stable
  - Acceptance criteria:
    - Create, update, archive client all work.
    - Archived clients are hidden from default dashboard views.
  - Evidence:

---

## 3) Metric Engine Quality (FR-003, FR-004)

- [ ] Daily metric normalization is correct for all 5 core metrics
  - Acceptance criteria:
    - Sleep, HRV, resting HR, workout minutes, and steps are persisted as daily aggregates.
    - Unit handling is consistent and documented.
  - Evidence:

- [ ] Baseline and recent windows are implemented exactly as spec
  - Acceptance criteria:
    - Recent window = last 7 full days.
    - Baseline window = prior 28 full days, excluding recent window.
  - Evidence:

- [ ] Missing data handling is explicit
  - Acceptance criteria:
    - Missing metrics are shown as missing, not silently zeroed.
    - Completeness score is computed and used consistently.
  - Evidence:

---

## 4) Alert and Scoring Quality (FR-005, FR-006)

- [ ] All MVP alert rules are implemented and tested
  - Acceptance criteria:
    - AR-001 through AR-004 from PRD section 8 trigger correctly.
    - Each alert includes condition explanation and severity.
  - Evidence:

- [ ] Attention score is deterministic and explainable
  - Acceptance criteria:
    - Score output is reproducible from the same dataset.
    - Score breakdown (subscores and penalties) is visible in UI.
    - Score changes only when source data or scoring version changes.
  - Evidence:

- [ ] Attention bucket behavior is correct
  - Acceptance criteria:
    - 0-39 low, 40-69 medium, 70-100 high.
    - Dashboard filtering by attention bucket works.
  - Evidence:

- [ ] Score change driver visibility is complete
  - Acceptance criteria:
    - Client detail surfaces top metric deltas driving week-over-week score movement.
    - Score version metadata is available for debugging/audit.
  - Evidence:

---

## 4A) Complaint-Driven Guardrails

- [ ] Missing data is never silently converted to zero
  - Acceptance criteria:
    - UI and reports explicitly label missing/low-confidence inputs.
  - Evidence:

- [ ] Score changes are never presented without explanation
  - Acceptance criteria:
    - Any score delta shown to user includes visible metric-level explanation.
  - Evidence:

- [ ] Data portability and deletion are always user-accessible
  - Acceptance criteria:
    - User can export and delete data without contacting support.
  - Evidence:

- [ ] Weekly coach workflow stays low-friction
  - Acceptance criteria:
    - Coach can identify a high-priority client and export their weekly report in <=3 clicks from dashboard path.
  - Evidence:

---

## 5) Screen-by-Screen Completeness (S1-S9)

- [ ] S1 Welcome/Trial screen is complete
  - Acceptance criteria:
    - Trial starts successfully.
    - Persona selection event is captured.
  - Evidence:

- [ ] S2 Workspace setup is complete
  - Acceptance criteria:
    - Timezone and weekly report preferences save and persist.
  - Evidence:

- [ ] S3 Dashboard is complete
  - Acceptance criteria:
    - Client ranking defaults to highest attention score first.
    - Filters and bulk report generation are functional.
  - Evidence:

- [ ] S4 Client add/edit screen is complete
  - Acceptance criteria:
    - Validation works (name required).
    - Archive flow and list refresh are functional.
  - Evidence:

- [ ] S5 Import wizard is complete
  - Acceptance criteria:
    - Valid import path works end-to-end.
    - Invalid/duplicate/missing-data paths show correct states.
  - Evidence:

- [ ] S6 Client detail is complete
  - Acceptance criteria:
    - Trend cards, score breakdown, and alert explanations render correctly.
    - Suggested coach message copy action works.
    - `What changed this week` narrative appears with top deltas.
  - Evidence:

- [ ] S7 Report preview/export is complete
  - Acceptance criteria:
    - PDF preview matches exported PDF output.
    - Generation metadata and date ranges are included.
  - Evidence:

- [ ] S8 Billing screen is complete
  - Acceptance criteria:
    - Trial days remaining display correctly.
    - Trial expiration gates paid features as specified.
  - Evidence:

- [ ] S9 Settings/privacy is complete
  - Acceptance criteria:
    - Client/all-data deletion is available with confirmation.
    - Audit log visibility is available.
    - CSV/JSON data export is available and usable.
  - Evidence:

---

## 6) Reporting and Coach Workflow Value (FR-008, FR-009)

- [ ] Single-client weekly report generation delivers usable coaching output
  - Acceptance criteria:
    - Report includes trend summary, alerts, and recommended message content.
    - Coach can export PDF in <=3 clicks from client detail.
  - Evidence:

- [ ] Bulk weekly report workflow is reliable
  - Acceptance criteria:
    - Bulk generation handles target client volume without blocking/failing unpredictably.
    - Partial failures are isolated and visible per client.
  - Evidence:

- [ ] Coach messaging helper is practical
  - Acceptance criteria:
    - At least 2 context-specific messages are available when relevant alerts exist.
    - Copy-to-clipboard action is stable and quick.
  - Evidence:

---

## 7) Trial, Paywall, and Monetization Readiness (FR-010)

- [ ] Trial lifecycle is correct
  - Acceptance criteria:
    - Trial starts once and expires correctly.
    - Expired trial blocks report generation and bulk report features.
  - Evidence:

- [ ] Plan limits are enforced correctly
  - Acceptance criteria:
    - Solo and Pro client caps are enforced.
    - Upgrade immediately unlocks gated limits/features.
  - Evidence:

- [ ] Paywall timing and copy are value-aligned
  - Acceptance criteria:
    - Paywall appears at natural value moment(s), not before first meaningful insight.
    - Pricing and feature differentiation are clear.
  - Evidence:

---

## 8) Privacy, Security, and Compliance (NFR-003 + PRD section 14)

- [ ] Local-first data storage is implemented
  - Acceptance criteria:
    - Core workflows (import, analysis, report) work offline.
    - Sensitive data is not sent externally without explicit action.
  - Evidence:

- [ ] Data-at-rest protection is implemented
  - Acceptance criteria:
    - Local database encryption strategy is documented and active.
  - Evidence:

- [ ] Data deletion controls are complete
  - Acceptance criteria:
    - Client-level delete and full delete actually remove data and generated reports.
  - Evidence:

- [ ] Data portability controls are complete
  - Acceptance criteria:
    - Client/workspace export produces valid CSV/JSON outputs.
    - Export works without external support.
  - Evidence:

- [ ] Non-medical disclaimer is visible
  - Acceptance criteria:
    - Disclaimer appears in app settings and relevant report context.
    - Product language avoids diagnosis wording.
  - Evidence:

---

## 9) Performance and Reliability (NFR-001, NFR-002)

- [ ] Import performance meets target
  - Acceptance criteria:
    - 1 year of data for one client imports in <=15s on target baseline machine.
  - Evidence:

- [ ] Dashboard performance meets target
  - Acceptance criteria:
    - Dashboard loads in <=1.5s with 100 clients.
  - Evidence:

- [ ] Reliability under failure scenarios is acceptable
  - Acceptance criteria:
    - Corrupt file, interrupted import, and disk-full scenarios fail gracefully.
    - App remains usable after failed operations.
  - Evidence:

---

## 10) Analytics and Observability Completeness (PRD section 12)

- [ ] Core event instrumentation is implemented
  - Acceptance criteria:
    - Required events exist: trial, import, dashboard view, report export, paywall, upgrade, completeness viewed, score breakdown viewed, data exported.
  - Evidence:

- [ ] Event quality is usable for decision-making
  - Acceptance criteria:
    - Each event includes required dimensions (plan type, trial day, client count bucket, attention distribution).
    - No duplicate or missing critical conversion events in test runs.
  - Evidence:

- [ ] KPI dashboard can be calculated from events
  - Acceptance criteria:
    - Trial activation, report engagement, and trial-to-paid conversion can be computed accurately.
  - Evidence:

---

## 11) QA Completeness

- [ ] Unit test suite covers import/parser/score/alert core logic
  - Acceptance criteria:
    - Tests exist for parser correctness and alert/score determinism.
    - Test failures block release.
  - Evidence:

- [ ] UI test coverage exists for critical workflows where feasible
  - Acceptance criteria:
    - Automated UI tests cover import flow, dashboard triage, client detail insights, report export, and paywall gating.
    - UI test suite is run on release candidate and results are recorded.
  - Evidence:

- [ ] Integration tests cover critical flows
  - Acceptance criteria:
    - End-to-end import -> dashboard -> report export pass.
    - Trial expiration and paywall gating pass.
  - Evidence:

- [ ] Manual QA checklist executed on release candidate
  - Acceptance criteria:
    - All critical user flows are manually validated.
    - High-severity defects are zero at release decision time.
  - Evidence:

- [ ] Testing exceptions are explicitly documented when coverage is not feasible
  - Acceptance criteria:
    - Any missing unit/UI test includes a short reason and compensating manual validation evidence.
    - Exceptions are approved before release sign-off.
  - Evidence:

---

## 12) Beta Release Readiness

- [ ] Release notes and known limitations are documented
  - Acceptance criteria:
    - Clear beta scope and limitations shared with design partners.
  - Evidence:

- [ ] Support loop is prepared
  - Acceptance criteria:
    - Bug/feedback intake path exists.
    - Response SLA for beta participants is defined.
  - Evidence:

- [ ] Go/No-Go review completed
  - Acceptance criteria:
    - Product, engineering, and QA sign-off completed.
    - All P0/P1 issues resolved or explicitly waived with risk note.
  - Evidence:

---

## 13) Post-Launch Validation (First 30 days)

- [ ] Trial activation target is met
  - Acceptance criteria:
    - >=60% of trials import >=5 clients in week 1.
  - Evidence:

- [ ] Engagement target is met
  - Acceptance criteria:
    - >=40% of trials generate >=2 reports.
  - Evidence:

- [ ] Conversion target is met
  - Acceptance criteria:
    - >=20% trial-to-paid conversion by day 14.
  - Evidence:

- [ ] Qualitative PMF signals are present
  - Acceptance criteria:
    - Coaches report measurable time savings and workflow usefulness in interviews.
  - Evidence:
