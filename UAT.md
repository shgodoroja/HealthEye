# HealthEye MVP — User Acceptance Test

Last updated: 2026-02-22

## How to use

- Execute each scenario on a clean build (`xcodebuild clean build`).
- Mark each scenario Pass/Fail with the date and build version.
- A scenario passes only when **all** expected results are confirmed.
- If a scenario fails, record the actual result and file a defect.

---

## UAT-01: First Launch and Account Bootstrap

**Precondition:** App has never been launched (fresh install or cleared data).

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Launch HealthEye | App opens without crash. Main window shows `NavigationSplitView` with sidebar and detail pane. |
| 2 | Observe the sidebar | Shows "No Clients" empty state with icon, description "Add your first client to get started.", and an "Add Client" button. |
| 3 | Observe the detail pane | Shows "Select a Client" placeholder with person icon and description. |
| 4 | Click "Plans" in the toolbar | PaywallView sheet opens. Trial banner shows "14 days remaining in your free trial" (or 13 depending on launch time). |
| 5 | Close the PaywallView | Sheet dismisses cleanly. |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-02: Create a Client

**Precondition:** App is running, no clients exist.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click "Add Client" (toolbar `+` button) | ClientFormView sheet opens with title "New Client". |
| 2 | Leave Name field empty, observe "Add Client" button | Button is disabled (greyed out). |
| 3 | Type "Alice Johnson" in the Name field | "Add Client" button becomes enabled. |
| 4 | Select a timezone from the Timezone picker | Picker updates to the chosen timezone. |
| 5 | Type "Marathon training plan" in Notes | Text appears in the editor. |
| 6 | Click "Add Client" | Sheet dismisses. "Alice Johnson" appears in the sidebar. |
| 7 | Click "Alice Johnson" in the sidebar | Detail pane loads ClientDetailView showing the client name, timezone, and notes. |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-03: Edit a Client

**Precondition:** Client "Alice Johnson" exists.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select "Alice Johnson", click "Edit" in the detail header | ClientFormView sheet opens with title "Edit Client". Fields are pre-populated with existing values. |
| 2 | Change name to "Alice J." | Name field updates. |
| 3 | Click "Save Changes" | Sheet dismisses. Sidebar and detail header show "Alice J." |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-04: Archive a Client

**Precondition:** At least 2 clients exist (create a second client "Bob Smith" if needed).

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select "Bob Smith", click "Edit" | ClientFormView opens in edit mode. |
| 2 | Click "Archive Client" | Confirmation alert appears: "Archive Client?" with message "This client will be hidden from the dashboard. Their data will be preserved." |
| 3 | Click "Archive" | Sheet dismisses. "Bob Smith" disappears from the sidebar. Only "Alice J." remains. |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-05: Delete a Client Permanently (from Edit Form)

**Precondition:** At least 2 clients exist.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select a client, click "Edit" | ClientFormView opens in edit mode. |
| 2 | Click "Delete Permanently" | Confirmation alert appears: "Delete Client Permanently?" with message about irreversible deletion. |
| 3 | Click "Delete" | Sheet dismisses. Client disappears from sidebar. Detail pane returns to "Select a Client" placeholder. |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-06: Import Health Data — Happy Path

**Precondition:** A client exists. An Apple Health `export.zip` or `export.xml` file is available on disk.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select a client, click "Import Health Data" | ImportWizardView opens. Step indicator shows "1. Instructions" as active. Instructions list 5 numbered steps for exporting from iPhone. |
| 2 | Click "Continue" | Wizard advances to step 2. "2. Select File" is active. Drop zone shows "Drag & drop your export file here" with "Accepts .zip or .xml files". |
| 3 | Click "Browse..." | NSOpenPanel opens, filtering for .zip and .xml files. |
| 4 | Select the export file, click Open | File name appears in the drop zone with "Ready to import" in green. "Start Import" button appears. |
| 5 | Click "Start Import" | Wizard advances to step 3. Progress spinner shows status messages: "Validating file...", "Checking for duplicates...", "Parsing health data..." (with record count), "Saving records...". |
| 6 | Wait for import to complete | Wizard auto-advances to step 4. Shows "Import Successful" with green checkmark. Summary shows: days of data, records parsed, date range, and per-metric coverage (Sleep, HRV, Resting HR, Workout, Steps). |
| 7 | Click "Done" | Wizard dismisses. Client detail refreshes: metric trend cards, attention score, alerts, narrative, completeness, and import history all populate with data. |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-07: Import Health Data — Drag and Drop

**Precondition:** Same as UAT-06.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open the import wizard, advance to step 2 | Drop zone is visible. |
| 2 | Drag an `export.zip` file from Finder onto the drop zone | Drop zone border turns accent color. Background shows faint accent color. |
| 3 | Release the file | File name appears with "Ready to import" in green. "Start Import" button appears. |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-08: Import — Duplicate Detection

**Precondition:** A file has already been successfully imported for a client.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open the import wizard for the same client | Wizard opens normally. |
| 2 | Select the same file again and click "Start Import" | Import fails. Step 4 shows "Import Failed" with red X icon and message: "This file has already been imported for this client." |
| 3 | Click "Try Again" | Wizard returns to step 2 with file selection cleared. |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-09: Import — Invalid File

**Precondition:** A non-health-data file is available (e.g., a `.txt` or random `.zip`).

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open the import wizard, select an invalid file, click "Start Import" | Import fails. Step 4 shows "Import Failed" with an error message describing the failure. |
| 2 | Click "Done" | Wizard dismisses. No partial data was imported. Client metrics remain unchanged. |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-10: Client Detail — Scores and Alerts

**Precondition:** A client has imported health data with at least 35 days of metrics.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select the client in the sidebar | Detail pane loads. |
| 2 | Observe the Attention Score card | Shows a total score (0-100) with bucket label (Low/Medium/High) in a color-coded badge. Six subscore bars are visible: Recovery (Sleep), Recovery (HRV), Recovery (RHR), Workout, Steps, Completeness. Each bar has a numeric value. |
| 3 | Observe "What Changed This Week" section | Narrative summary describes the top metric changes (e.g., "HRV dropped 15% compared to the prior 4 weeks."). |
| 4 | Observe Metric Trends section | Five cards in a 2-column grid: Sleep (min), HRV (ms), Resting HR (bpm), Workout (min), Steps (steps). Each shows recent (7d) average, baseline (28d) average, and a percentage delta with directional arrow and color. |
| 5 | Observe Active Alerts section | If alert conditions are met: alert rows show severity icon, rule code (e.g., AR-001), severity badge, and explanation text. If no alerts: shows "No active alerts this week." |
| 6 | Observe Suggested Messages section (if alerts exist) | Shows context-specific coaching messages. Each has a "Copy" button. |
| 7 | Click "Copy" on a suggested message | Button changes to "Copied" with checkmark icon for ~2 seconds, then reverts. Pasting elsewhere produces the message text. |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-11: Client Detail — Weekly Data Completeness

**Precondition:** A client has imported data.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Scroll to "Weekly Data Completeness" section | Table with columns: Week, Sleep, HRV, RHR, Workout, Steps, Score. Rows appear in reverse chronological order. |
| 2 | Observe completeness values | Each metric column shows days-with-data count (e.g., "5/7"). Score column shows the weekly completeness percentage. Missing metrics are not shown as zero. |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-12: Dashboard — Attention Filtering and Sorting

**Precondition:** Multiple clients exist with imported data and different attention scores.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Observe sidebar client list | Clients are sorted by attention score descending (highest attention needed first). Each row shows the client name, top alert (if any) or last import date, and an attention score badge. |
| 2 | Click the "High" filter chip | Only clients with attention scores 70-100 appear. |
| 3 | Click the "Medium" filter chip | Only clients with attention scores 40-69 appear. |
| 4 | Click the "Low" filter chip | Only clients with attention scores 0-39 appear. |
| 5 | Click the "All" filter chip | All active clients appear, sorted by attention score. |
| 6 | If no clients match a filter | Shows "No Clients" with message "No clients match the selected filter." |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-13: Generate and Preview Report

**Precondition:** A client has imported data.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select a client, click "Generate Report" | ReportPreviewView sheet opens (min 700x600). Shows "Generating report..." spinner briefly, then renders a PDF preview. |
| 2 | Observe the PDF content | Report contains: client name, week date range, attention score with breakdown, narrative summary, metric trends table, alerts (if any), suggested messages (if any), and a footer. |
| 3 | Change the date using the "Week of" date picker | Date snaps to Monday of the selected week. Report regenerates automatically with data for the new week. |
| 4 | Click "Close" | Sheet dismisses. |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-14: Export Report as PDF

**Precondition:** A report preview is open with a generated PDF.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click "Export PDF" | NSSavePanel opens with default filename `ClientName_Week_yyyy-MM-dd.pdf`. |
| 2 | Choose a save location, click Save | Banner appears at the bottom: green checkmark with "Saved to: [path]". |
| 3 | Open the saved PDF in Finder/Preview | PDF opens correctly and matches the in-app preview content. |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-15: 3-Click Report Workflow

**Precondition:** Dashboard has clients with data. No sheets are open.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click a client in the sidebar (click 1) | Detail pane loads with client data. |
| 2 | Click "Generate Report" (click 2) | Report preview opens with generated PDF. |
| 3 | Click "Export PDF" (click 3) | Save panel opens. After saving, PDF is exported. |

**Validates:** Coach can identify and export a weekly report in 3 clicks from dashboard.

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-16: Trial Lifecycle — Active Trial

**Precondition:** Fresh app launch (trial just started, 14 days remaining).

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click "Plans" in the toolbar | PaywallView opens. Orange banner shows "14 days remaining in your free trial" (or 13). |
| 2 | Observe plan cards | Two cards: Solo ($39/mo, up to 30 clients) and Pro ($79/mo, up to 100 clients). Neither shows "Current Plan". Both have "Choose Solo" / "Choose Pro" buttons. |
| 3 | Click "Generate Report" for a client | ReportPreviewView opens normally (not blocked). |
| 4 | Click "Export PDF" | Export works normally (not blocked). |
| 5 | Close all sheets, click "Settings" | Settings shows Plan: "Trial", trial days remaining in orange, and active client count. |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-17: Trial Lifecycle — Expired Trial

**Precondition:** Trial has expired (trialEndAt is in the past). To simulate, use a CoachAccount with `trialEndAt` set to yesterday.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click "Plans" in the toolbar | PaywallView opens. Red banner shows "Your trial has expired. Choose a plan to continue." |
| 2 | Close PaywallView. Select a client, click "Generate Report" | PaywallView opens instead of the report preview (feature is gated). |
| 3 | In the PaywallView, click "Choose Solo" | PaywallView updates: green banner shows "You are on the Solo plan". Solo card shows "Current Plan". |
| 4 | Close PaywallView. Click "Generate Report" again | ReportPreviewView opens normally (feature is now unlocked). |
| 5 | Click "Settings" | Settings shows Plan: "Solo". Trial row is no longer visible. |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-18: Client Limit Enforcement

**Precondition:** Account is on Trial or Solo plan (limit: 30 clients).

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create clients until the count reaches 30 | Each client is created successfully. |
| 2 | Click "Add Client" (toolbar `+`) | PaywallView opens instead of the create form (client limit reached). |
| 3 | In PaywallView, click "Choose Pro" | Plan updates to Pro (limit: 100). |
| 4 | Close PaywallView. Click "Add Client" again | ClientFormView opens normally (limit increased to 100). |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-19: Data Export — CSV

**Precondition:** At least one client with imported data exists.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click "Settings", go to "Data Export" section | Client picker and export buttons are visible. |
| 2 | Select a client from the picker | "Export CSV" and "Export JSON" buttons become enabled. |
| 3 | Click "Export CSV" | NSSavePanel opens with filename `ClientName_export.csv`. |
| 4 | Save the file. Open in a text editor | File starts with header: `client,date,sleepMinutes,hrvMs,restingHrBpm,workoutMinutes,steps`. Data rows follow with one row per day. Missing metric values are empty (not zero). |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-20: Data Export — JSON

**Precondition:** Same as UAT-19.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | In Settings > Data Export, select a client | Client is selected. |
| 2 | Click "Export JSON" | NSSavePanel opens with filename `ClientName_export.json`. |
| 3 | Save the file. Open in a text editor or JSON viewer | Valid JSON object with keys: `displayName`, `timezone`, `createdAt`, `metrics` (array). Each metric has: `date`, `sleepMinutes`, `hrvMs`, `restingHrBpm`, `workoutMinutes`, `steps`. Null values for missing metrics. |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-21: Data Export — All Clients

**Precondition:** Multiple clients with data exist.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | In Settings > Data Export, click "Export All Clients (CSV)" | NSSavePanel opens with filename `healtheye_export.csv`. |
| 2 | Save and open the file | CSV contains rows from all active clients, each prefixed with the client name. |
| 3 | Click "Export All Clients (JSON)" | NSSavePanel opens with filename `healtheye_export.json`. |
| 4 | Save and open the file | Valid JSON array of client objects, each with metadata and metrics. |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-22: Delete Client from Settings

**Precondition:** Multiple clients exist.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click "Settings", go to "Data Management" section | Client picker for deletion and "Delete All Data" button are visible. |
| 2 | Select a client from the "Client to delete" picker | "Delete Client Permanently" button becomes enabled. |
| 3 | Click "Delete Client Permanently" | Alert: "Delete Client?" with message including the client name. |
| 4 | Click "Delete" | Client disappears from the sidebar and from the Settings picker. |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-23: Delete All Data

**Precondition:** Multiple clients exist (including any archived clients).

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | In Settings > Data Management, click "Delete All Data" | First alert: "Delete All Data?" with "Continue" and "Cancel". |
| 2 | Click "Continue" | Second alert: "Final Confirmation" with "Delete Everything" and "Cancel". |
| 3 | Click "Delete Everything" | All clients removed. Sidebar shows "No Clients" empty state. Settings Data Export section shows no clients available. |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-24: Non-Medical Disclaimer

**Precondition:** App is running.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click "Settings", scroll to "About" section | Disclaimer text is visible: "HealthEye is designed for coaching insights only. It does not provide medical advice, diagnosis, or treatment. Always consult a qualified healthcare professional for medical decisions." |
| 2 | Observe version | Shows "1.0.0". |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-25: Score Determinism

**Precondition:** A client with imported data exists. Note the current attention score and all subscores.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Navigate away from the client (select another or deselect) | Detail pane changes. |
| 2 | Navigate back to the same client | Attention score, all subscores, alerts, and narrative are identical to the values noted before. |
| 3 | Quit and relaunch the app, select the same client | All scores, alerts, and narrative match exactly. |

**Validates:** Same input + same version = same score always.

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-26: Import History Persistence

**Precondition:** A client has one or more successful imports.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select the client, scroll to "Import History" | Each import shows: green checkmark icon, timestamp, date range, and "Success" badge. |
| 2 | Quit and relaunch the app, check the same client | Import history entries persist and display identically. |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-27: Offline Operation

**Precondition:** App is running with clients and data. Disconnect from the internet.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select a client, review scores and alerts | All data displays correctly. |
| 2 | Import a new health data file | Import completes successfully. |
| 3 | Generate and export a PDF report | Report generates and exports to disk. |
| 4 | Export client data as CSV/JSON from Settings | Export completes and produces valid files. |

**Validates:** Core workflows (import, analysis, report) work offline.

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-28: Client Detail — No Data State

**Precondition:** A client exists with no imported data.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select the client | Detail pane shows client name, timezone, and notes. |
| 2 | Observe the scoring sections | No attention score card, no narrative, no metric trends (these sections are hidden when data is absent). |
| 3 | Observe alerts section | Shows "No active alerts this week." |
| 4 | Observe import history | Shows "No imports yet. Import health data to see metrics." |
| 5 | Observe completeness section | Section is not shown (empty). |

**Validates:** Empty state is handled gracefully without crashes or misleading data.

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-29: Report Generation — Error Recovery

**Precondition:** A client exists with no data, or select a week with no metrics.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click "Generate Report" | ReportPreviewView opens. Report may show minimal/empty content or an error state. |
| 2 | If error state shown: click "Retry" | Report generation re-attempts. |
| 3 | Change date picker to a week with data | Report regenerates with the correct week's data. |

**Result:** ______ **Date:** ______ **Tester:** ______

---

## UAT-30: Stale Selection After Deletion

**Precondition:** Two or more clients exist. One client is selected in the sidebar.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | With a client selected, click "Edit" | ClientFormView opens. |
| 2 | Click "Delete Permanently", confirm deletion | Sheet dismisses. |
| 3 | Observe the detail pane | Shows "Select a Client" placeholder (not a blank/crashed view). The deleted client is gone from the sidebar. |

**Result:** ______ **Date:** ______ **Tester:** ______
