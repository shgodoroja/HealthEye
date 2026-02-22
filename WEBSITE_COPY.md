# WatchHealthDataReader Website Content Spec (Homepage + First 3 SEO Pages)

Last updated: 2026-02-22
Based on: `/Users/stefangodoroja/Documents/Projects/WatchHealthDataReader/WEBSITE_PLAN.md`
Purpose: Build-ready website wireframe + exact copy optimized for SEO and download conversion.

## 0) Assumptions

- Working product name in this document: `WatchHealthDataReader`.
- Primary audience: independent coaches using Apple Watch / Apple Health data with clients.
- Primary website goal: drive Mac app downloads.
- Dual-layer site strategy is enforced:
  - Conversion pages (homepage/features/download/pricing)
  - SEO pages (guides/comparisons/use-cases) that route to conversion pages

If the final brand name changes (for example to `HealthEye`), update only:
- page titles
- hero headline mentions
- CTA labels
- schema `name`

Keep page structure and copy logic the same.

---

## 1) Global Site Structure (Dual-Layer Recommendation Applied)

### Conversion Layer (download-focused)
- `/` Homepage
- `/features`
- `/for-coaches`
- `/pricing`
- `/download`
- `/sample-report`
- `/privacy`

### SEO Layer (intent capture)
- `/guides/apple-health-export-to-csv`
- `/guides/apple-health-export-to-excel`
- `/guides/analyze-apple-watch-health-data-on-mac`
- (later) comparisons/use-cases/docs/release notes

### Required cross-linking rule

Every SEO page must link to:
1. `/download`
2. `/features`
3. `/sample-report` (or report section on homepage if that ships first)
4. at least one other SEO page in the same cluster

This preserves crawlability and pushes high-intent traffic toward download CTAs.

---

## 2) Global Nav / Footer Copy

### Header nav (desktop)
- Logo: `WatchHealthDataReader`
- Links: `Features`, `For Coaches`, `Sample Report`, `Pricing`, `Guides`, `Download`
- Primary CTA button: `Download for Mac`

### Header nav (mobile)
- Same items in drawer
- Sticky footer CTA (mobile only): `Download for Mac`

### Footer columns (suggested)
- Product: `Features`, `Pricing`, `Download`, `Sample Report`
- Guides: `Export to CSV`, `Export to Excel`, `Analyze on Mac`
- Trust: `Privacy`, `FAQ`, `Contact`
- Legal: `Terms`, `Privacy`, `Medical Disclaimer`

### Footer microcopy
`WatchHealthDataReader helps coaches review Apple Health data and generate weekly client reports. Privacy-first. Local analysis. Not a medical device.`

---

## 3) Homepage (`/`) Wireframe + Exact Copy

## 3.1 SEO Metadata

- URL: `/`
- Primary intent: coaches evaluating software for Apple Watch/Apple Health data analysis and weekly reporting
- Title tag:
  - `WatchHealthDataReader for Coaches | Apple Watch Health Data Analysis on Mac`
- Meta description:
  - `Analyze Apple Watch and Apple Health exports on Mac, spot clients who need attention, and generate weekly coaching reports in minutes. Privacy-first and explainable.`
- H1:
  - `Spot which clients need attention this week and generate reports in minutes.`

Optional OG tags:
- OG title:
  - `Apple Health Data Analysis for Coaches on Mac`
- OG description:
  - `Turn Apple Health exports into weekly client insights, explainable scores, and coach-ready reports.`

## 3.2 Page Wireframe (Desktop and Mobile Order)

Section order (same on mobile, stacked):
1. Hero
2. Outcome bullets + trust row
3. How it works (3 steps)
4. Core feature grid
5. Data trust / explainability section
6. Sample report preview
7. Coach workflow ROI section
8. Testimonials / beta proof
9. FAQ
10. Final CTA

## 3.3 Exact Homepage Copy

### Section 1: Hero (above the fold)

Eyebrow:
`For Independent Coaches`

H1:
`Spot which clients need attention this week and generate reports in minutes.`

Subheadline:
`WatchHealthDataReader turns Apple Health exports from iPhone into a Mac dashboard with explainable client scores, trend changes, and one-click weekly coaching reports.`

Primary CTA button:
`Download for Mac`

Secondary CTA button:
`Watch 90-Second Demo`

Secondary text links (small):
- `View Sample Report`
- `See How Import Works`

Trust microcopy (under CTA row):
`Privacy-first. Local analysis. Data export and deletion controls included. Not a medical device.`

Hero visual caption (for screenshot/video):
`Your Monday coaching dashboard: ranked clients, clear score breakdowns, and report status at a glance.`

### Section 2: Why coaches buy this (outcomes, not features)

Section heading:
`Built for the weekly coaching workflow, not spreadsheet cleanup`

Intro copy:
`Most coaches do not need another data app. They need a faster way to answer three questions every week: Who needs attention now? What changed? What should I send this client today?`

Three outcome cards:

Card 1 title:
`See who needs attention first`

Card 1 copy:
`Rank clients by attention score so you can start with the people most likely to need a check-in this week.`

Card 2 title:
`Understand what changed`

Card 2 copy:
`Review sleep, HRV, resting heart rate, activity, and steps with clear recent vs baseline deltas and visible rule triggers.`

Card 3 title:
`Send something useful fast`

Card 3 copy:
`Generate a weekly report and copy a coach-ready message without rebuilding charts in Excel.`

### Section 3: How it works (3 steps)

Section heading:
`How it works`

Step 1 title:
`1. Export from Apple Health on iPhone`

Step 1 copy:
`Your client exports their Apple Health data from iPhone. We guide the process and support Apple Health export files, including zip exports with export.xml.`

Step 2 title:
`2. Import into WatchHealthDataReader on Mac`

Step 2 copy:
`Import the file, review metric completeness, and immediately see what data is available for analysis before you rely on a score.`

Step 3 title:
`3. Review weekly changes and generate a report`

Step 3 copy:
`Use the dashboard to prioritize clients, inspect score drivers, and export a weekly report with a suggested coach message.`

Inline CTA after steps:
`See a Sample Weekly Report`

### Section 4: Core features (P0 feature grid)

Section heading:
`Everything needed for a coach-first Apple Health workflow`

Feature 1 title:
`Client Triage Dashboard`

Feature 1 copy:
`A ranked client list built for Monday check-ins, with attention score, top alert, last import date, and report status in one view.`

Feature 2 title:
`Explainable Scoring`

Feature 2 copy:
`Scores are not black-box. See metric-level drivers, recent vs baseline deltas, and rule explanations before acting on a recommendation.`

Feature 3 title:
`Data Completeness Checks`

Feature 3 copy:
`Know what is missing before you interpret trends. We show metric completeness so you can trust what is on screen.`

Feature 4 title:
`Weekly Change Narrative`

Feature 4 copy:
`Get a concise "what changed this week" summary to reduce analysis time and support consistent check-ins.`

Feature 5 title:
`One-Click Weekly Reports`

Feature 5 copy:
`Export a client-ready PDF report with trend summaries, alerts, and a coach message draft.`

Feature 6 title:
`Data Ownership Controls`

Feature 6 copy:
`Export machine-readable data, archive clients, and delete records when needed. No lock-in workflow.`

CTA row:
- Primary: `Download for Mac`
- Secondary: `Compare Features`

### Section 5: Data trust and explainability (objection handling)

Section heading:
`Why coaches trust the output`

Lead copy:
`Health data is messy. Missing metrics, incomplete exports, and unstable scores create bad coaching decisions. WatchHealthDataReader is built to make data quality visible before it becomes a problem.`

Bullet list:
- `Metric completeness is shown per client and per week`
- `Missing data is labeled, not silently treated as zero`
- `Score breakdown shows what moved the result`
- `Score changes are traceable to new data or scoring-rule version updates`

Support line:
`You should never have to guess whether a client is flagged because of a real change or a messy import.`

### Section 6: Sample report preview

Section heading:
`See the weekly report coaches send to clients`

Copy:
`Open a sample report to review layout, trend summaries, alert explanations, and coach-ready messaging. This is the fastest way to evaluate whether the workflow fits your business.`

Primary CTA:
`View Sample Report`

Secondary CTA:
`Download for Mac`

Caption under preview image:
`Includes date range, trend deltas, alert summary, and a suggested next-step message.`

### Section 7: Coach workflow ROI (time + consistency)

Section heading:
`Designed to reduce weekly admin time`

Copy:
`If you are manually exporting data, cleaning XML or CSV files, rebuilding charts, and writing updates from scratch, your reporting workflow is doing the wrong work. WatchHealthDataReader focuses on triage, explanation, and repeatable reporting so your coaching time goes into decisions and communication.`

ROI bullets:
- `Prioritize high-attention clients first`
- `Reduce spreadsheet cleanup and repetitive chart building`
- `Standardize report quality across clients`
- `Improve consistency of weekly coach communication`

### Section 8: Founder context / product proof (no testimonials yet)

Section heading:
`Built with coach workflows in mind`

Copy:
`HealthEye is brand new and currently founder-built. Instead of padded testimonials, this page shows the real workflow: import guidance, completeness checks, explainable scoring, and a sample weekly report you can evaluate before downloading.`

Proof bullets:
- `Sample report preview (real output format)`
- `Feature-level explanations with visible score drivers`
- `Privacy and data ownership controls documented`
- `Guides for Apple Health export and Mac analysis workflows`

### Section 9: FAQ (visible + SEO helpful)

FAQ heading:
`Frequently asked questions`

Q1:
`Does this work with Apple Health exports from iPhone?`

A1:
`Yes. WatchHealthDataReader is built for Apple Health export files from iPhone, including zip exports that contain export.xml. The app guides the import process on Mac.`

Q2:
`Do I need to be technical to use it?`

A2:
`No. The workflow is designed for coaches, not developers. The app guides import, shows data completeness, and explains score changes in plain language.`

Q3:
`Is this a medical app?`

A3:
`No. WatchHealthDataReader provides wellness and coaching insights only. It is not a medical device and does not provide diagnosis or medical treatment advice.`

Q4:
`Can I export or delete client data?`

A4:
`Yes. Data ownership controls are included so you can export machine-readable data and remove client records when needed.`

Q5:
`Does it require an internet connection?`

A5:
`Core workflows are designed to work locally on Mac, including import, analysis, and report generation.`

### Section 10: Final CTA block

Heading:
`Start with one client and see the workflow in minutes`

Copy:
`Download WatchHealthDataReader for Mac, import an Apple Health export, and evaluate the weekly triage and report workflow with your real data.`

Primary CTA:
`Download for Mac`

Secondary CTA:
`View Sample Report`

Fine-print trust line:
`Privacy-first. Local analysis. Explainable output.`

## 3.4 Homepage Internal Linking Requirements

Mandatory internal links from homepage:
- `/features`
- `/for-coaches`
- `/download`
- `/sample-report`
- `/privacy`
- `/guides/apple-health-export-to-csv`
- `/guides/apple-health-export-to-excel`
- `/guides/analyze-apple-watch-health-data-on-mac`

Footer SEO teaser block copy:
`New to Apple Health exports? Start with our guides for CSV, Excel, and Mac analysis workflows.`

---

## 4) SEO Page #1: `/guides/apple-health-export-to-csv`

## 4.1 SEO Metadata

- URL: `/guides/apple-health-export-to-csv`
- Search intent: how to export Apple Health / Apple Watch health data to CSV
- Title tag:
  - `How to Export Apple Health Data to CSV (Apple Watch Included) | Mac Guide`
- Meta description:
  - `Learn how to export Apple Health data and turn Apple Watch health metrics into CSV for analysis. Includes Apple Health export steps, CSV options, and a faster Mac workflow.`
- H1:
  - `How to Export Apple Health Data to CSV (Including Apple Watch Data)`

## 4.2 Conversion Role (Dual-Layer Strategy)

This page is an SEO entry page. It must:
- solve the immediate user problem
- acknowledge XML friction honestly
- introduce WatchHealthDataReader as the faster analysis workflow
- drive clicks to `/download` and `/sample-report`

## 4.3 Exact Page Copy

Intro note (small):
`If you found this page because Apple Health export gave you a large XML file, you are not alone.`

H1:
`How to Export Apple Health Data to CSV (Including Apple Watch Data)`

Intro paragraph:
`Apple Health lets you export your data from iPhone, but the default export is usually a zip file with an export.xml file inside. That works for data portability, but it is not convenient if you want to review trends in Excel, create reports, or analyze Apple Watch metrics on a Mac. This guide explains the Apple Health export process, what the XML file contains, and practical ways to get your data into a CSV-friendly workflow.`

Quick answer box heading:
`Quick answer`

Quick answer copy:
`Apple Health exports data as an XML file (often inside a zip). To get CSV, you usually need a converter or an analysis tool that imports the Apple Health export and then exports or visualizes the metrics you need. If you are a coach, the fastest path is often to import the export on Mac and generate a report directly instead of rebuilding everything in spreadsheets.`

Section H2:
`What is included in an Apple Health export?`

Paragraph:
`An Apple Health export can include records, workouts, and other health-related entries collected by iPhone, Apple Watch, and approved apps that write to Apple Health. The exact fields available vary by device, permissions, and what your client has enabled. That is one reason CSV conversions can feel inconsistent across people.`

Bullet list:
- `Records (for example, steps, heart rate-related entries, and other health measurements)`
- `Workout data and timestamps`
- `Metadata and source information`
- `Export.xml inside a compressed archive in many cases`

Section H2:
`How to export Apple Health data from iPhone`

Step list:
1. `Open the Health app on iPhone.`
2. `Tap your profile picture in the top-right corner.`
3. `Scroll down and choose Export All Health Data.`
4. `Confirm the export and save/share the resulting file.`
5. `Transfer the export to your Mac for analysis.`

Callout:
`Tip: The export may be large. If you plan to review multiple clients, organize exports by client name and export date before importing them into your Mac workflow.`

Section H2:
`Why Apple Health export to CSV is harder than people expect`

Paragraph:
`The main issue is not that Apple blocks access to your data. The issue is format and scale. XML is portable but verbose, and most people looking for "Apple Health CSV" really want one of these outcomes: a clean table for a few metrics, a weekly trend summary, or a report they can send to someone else.`

Pain-point bullets:
- `XML is not convenient to inspect manually`
- `Different metrics matter for different goals`
- `Missing or incomplete fields can create confusing tables`
- `Spreadsheets become time-consuming when repeated every week`

Section H2:
`3 ways to work with Apple Health data in CSV-friendly form`

Subheading H3:
`Option 1: Manual XML conversion to CSV`

Copy:
`You can parse export.xml and convert it into CSV tables. This gives you control, but it is usually the slowest option and requires repeated cleanup when you only need a few coach-relevant metrics.`

Subheading H3:
`Option 2: Export utility apps`

Copy:
`Some tools focus on converting Apple Health exports into CSV or JSON. This can reduce technical effort, but you may still end up doing analysis and report formatting manually in Excel or another tool.`

Subheading H3:
`Option 3: Mac analysis workflow (recommended for coaches)`

Copy:
`If your real goal is weekly coaching decisions, use a Mac workflow that imports Apple Health exports, shows metric completeness, explains trend changes, and generates reports directly. This removes most of the spreadsheet cleanup while still preserving export and data ownership controls.`

CTA block heading:
`Skip spreadsheet cleanup and go straight to weekly coaching reports`

CTA block copy:
`WatchHealthDataReader imports Apple Health exports on Mac, shows what data is available, and helps you generate explainable weekly reports with coach-ready messaging.`

CTA buttons:
- `Download for Mac`
- `View Sample Report`

Section H2:
`What to check before you trust a CSV or report`

Paragraph:
`No matter which workflow you use, check data completeness before interpreting trends. A missing week of sleep or HRV data can make a score or chart look more dramatic than it really is.`

Checklist bullets:
- `Export date and date range`
- `Which metrics are actually present`
- `Missing-data handling (labeled vs silently zeroed)`
- `Units and consistency`
- `Whether trend baselines are explained`

Section H2:
`If you are a coach, the better question is usually not "How do I get CSV?"`

Paragraph:
`The better question is: "How do I turn Apple Health exports into a repeatable weekly client workflow?" CSV is useful for portability, but weekly coaching usually needs triage, explanation, and communication more than raw tables.`

Paragraph:
`That is the gap WatchHealthDataReader is built for: Apple Health export on iPhone, analysis on Mac, and a weekly report you can actually send.`

CTA row:
- `Download for Mac`
- `See Features for Coaches`

FAQ heading:
`FAQ: Apple Health export to CSV`

Q1:
`Does Apple Health export directly to CSV?`

A1:
`Apple Health exports are commonly delivered as an XML-based export (often in a zip archive). Many users use a converter or analysis app to create CSV-friendly outputs.`

Q2:
`Does this include Apple Watch data?`

A2:
`Apple Watch data that is written into Apple Health and included in the export can be part of the workflow. Exact fields vary by permissions and what was tracked.`

Q3:
`Can I use Excel after exporting?`

A3:
`Yes. CSV is commonly used for Excel. If your goal is repeated weekly review or client reporting, a Mac analysis workflow may save time compared with rebuilding reports in spreadsheets.`

Final CTA block:
`Need more than a CSV file? Analyze Apple Health exports on Mac and generate weekly client reports with WatchHealthDataReader.`

Buttons:
- `Download for Mac`
- `Analyze Apple Watch Data on Mac`

## 4.4 Internal Links (required on page)

Must link to:
- `/download`
- `/features`
- `/sample-report`
- `/guides/apple-health-export-to-excel`
- `/guides/analyze-apple-watch-health-data-on-mac`

---

## 5) SEO Page #2: `/guides/apple-health-export-to-excel`

## 5.1 SEO Metadata

- URL: `/guides/apple-health-export-to-excel`
- Search intent: how to open/export Apple Health data in Excel
- Title tag:
  - `How to Export Apple Health Data to Excel (Without Spreadsheet Chaos)`
- Meta description:
  - `Need Apple Health data in Excel? Learn the export process, common XML-to-Excel problems, and a Mac workflow that reduces cleanup for weekly reporting and analysis.`
- H1:
  - `How to Export Apple Health Data to Excel (Without Spreadsheet Chaos)`

## 5.2 Conversion Role (Dual-Layer Strategy)

This page captures users who specifically want Excel. It should:
- respect the Excel use case (don’t dismiss it)
- show why Excel gets painful for recurring reporting
- position the app as an analysis and reporting shortcut

## 5.3 Exact Page Copy

Intro line:
`Excel is a valid goal. The problem is the time you lose rebuilding the same views every week.`

H1:
`How to Export Apple Health Data to Excel (Without Spreadsheet Chaos)`

Intro paragraph:
`Many people search for "Apple Health export to Excel" because they want charts, summaries, or a client-ready report. The challenge is that Apple Health exports are typically XML-based, which means the path to Excel usually includes conversion, cleanup, filtering, and reformatting. If you only need one report once, Excel may be enough. If you need a repeatable weekly workflow, there is a faster way.`

Quick answer heading:
`Quick answer`

Quick answer copy:
`Apple Health does not usually hand you a clean Excel workbook directly. The common workflow is: export Apple Health from iPhone -> convert or import the XML-based export -> create CSV/Excel tables -> build charts and summaries. Coaches often save time by using a Mac app to analyze the export first, then exporting a report or machine-readable data only when needed.`

Section H2:
`Why people want Apple Health data in Excel`

Paragraph:
`Excel is familiar and flexible. It is useful for quick charts, manual calculations, and sharing data with people who do not use Apple Health. For coaches, it is also a common stopgap when client reporting software does not handle Apple Watch and Apple Health data well.`

Bullet list:
- `Custom tables and formulas`
- `Simple charting`
- `Client progress summaries`
- `Archive and portability`

Section H2:
`Where the Excel workflow usually breaks down`

Paragraph:
`Excel is powerful, but repeated Apple Health reporting can become a maintenance task. Coaches often spend more time cleaning exports than reviewing client changes.`

Breakdown bullets:
- `Importing XML output is not a clean one-click spreadsheet experience`
- `Large exports are difficult to navigate`
- `Metric selection and filtering take time`
- `Missing data can silently distort charts`
- `Weekly report formatting becomes repetitive work`

Section H2:
`A better workflow for coaches: analyze first, export second`

Paragraph:
`If your goal is better coaching, not just a spreadsheet file, analyze the Apple Health export on Mac first. A coach-first workflow should help you see who needs attention, explain what changed, and generate a report. Excel can still be part of the process for auditing or custom analysis, but it should not be the center of your weekly workflow.`

Conversion callout heading:
`Built for coaches who are done rebuilding the same spreadsheet every week`

Callout copy:
`WatchHealthDataReader imports Apple Health exports on Mac, shows data completeness, explains score and trend changes, and generates a weekly client report with a coach-ready message.`

CTA buttons:
- `Download for Mac`
- `View Sample Report`

Section H2:
`What to keep in Excel vs what to move out`

Paragraph:
`Excel is still useful when you need custom calculations or a one-off audit. But repeated coaching tasks are usually better handled in a workflow that is built for triage and communication.`

Two-column content (copy):

Keep in Excel:
- `One-off custom analysis`
- `Ad hoc formulas`
- `Data audits`
- `Special client requests`

Move out of Excel:
- `Weekly triage`
- `Repeated trend summaries`
- `Client-ready report formatting`
- `Coach message drafting`

Section H2:
`How to reduce mistakes when using Excel with health exports`

Paragraph:
`The biggest errors happen when missing data looks like zero activity, when date ranges shift, or when a chart mixes inconsistent units. A reliable workflow should show these issues before a coach interprets the result.`

Checklist:
- `Verify export date and covered time range`
- `Confirm which metrics are present`
- `Check how missing values are represented`
- `Keep units consistent (especially for heart-rate-related metrics)`
- `Document your baseline window when showing trend changes`

Section H2:
`When to use WatchHealthDataReader instead of Excel`

Paragraph:
`Use WatchHealthDataReader when you need a repeatable weekly workflow for multiple clients. It is especially useful when your current process is "export -> clean -> chart -> write message" and you want to replace that with "import -> review -> send report."`

CTA block:
Heading:
`Use Excel when you want. Stop relying on it for every weekly check-in.`

Body:
`Download WatchHealthDataReader for Mac to import Apple Health exports, review explainable changes, and generate weekly reports faster.`

Buttons:
- `Download for Mac`
- `See Features`

FAQ heading:
`FAQ: Apple Health export to Excel`

Q1:
`Can I open Apple Health export directly in Excel?`

A1:
`Apple Health exports are commonly XML-based and may require conversion or an intermediate tool before you get a clean spreadsheet layout for analysis.`

Q2:
`Can I still export data for Excel if I use WatchHealthDataReader?`

A2:
`Yes. Data ownership and portability are part of the product direction, including machine-readable exports for workflows that still require spreadsheets.`

Q3:
`Is this only for coaches?`

A3:
`The website and product positioning are coach-first, but the export and analysis workflow is also useful for advanced individual users who want a cleaner Mac-based process.`

Final CTA:
`Want an Apple Health workflow that starts on iPhone and becomes useful on Mac?`

Buttons:
- `Download for Mac`
- `Read: Analyze Apple Watch Data on Mac`

## 5.4 Internal Links (required on page)

Must link to:
- `/download`
- `/features`
- `/sample-report`
- `/guides/apple-health-export-to-csv`
- `/guides/analyze-apple-watch-health-data-on-mac`

---

## 6) SEO Page #3: `/guides/analyze-apple-watch-health-data-on-mac`

## 6.1 SEO Metadata

- URL: `/guides/analyze-apple-watch-health-data-on-mac`
- Search intent: analyze Apple Watch / Apple Health data on Mac
- Title tag:
  - `How to Analyze Apple Watch Health Data on Mac (Coach-Friendly Workflow)`
- Meta description:
  - `Learn a practical Mac workflow to analyze Apple Watch and Apple Health exports, review trends like sleep and HRV, and generate weekly reports without spreadsheet-heavy work.`
- H1:
  - `How to Analyze Apple Watch Health Data on Mac (A Coach-Friendly Workflow)`

## 6.2 Conversion Role (Dual-Layer Strategy)

This is the highest-converting SEO page in the first cluster. It should:
- align directly to the product outcome
- emphasize coach workflow and trust
- send strong CTAs to `/download` and `/sample-report`

## 6.3 Exact Page Copy

Intro line:
`If your current workflow is export, clean, chart, and rewrite the same report every week, this page is for you.`

H1:
`How to Analyze Apple Watch Health Data on Mac (A Coach-Friendly Workflow)`

Intro paragraph:
`Apple Watch and Apple Health can capture a lot of useful client data, but the default export format and iPhone-first experience can make deeper review hard. For coaches, the real need is not "more data." It is a repeatable Mac workflow that helps you prioritize clients, understand trend changes, and send useful updates without spreadsheet-heavy work.`

Quick answer heading:
`Quick answer`

Quick answer copy:
`A practical Mac workflow looks like this: export Apple Health data from iPhone -> import on Mac -> check metric completeness -> review recent vs baseline changes -> prioritize clients -> generate a weekly report. The key is using a workflow that explains scores and missing data instead of hiding them.`

Section H2:
`Why analyze Apple Watch health data on Mac?`

Paragraph:
`Mac workflows are easier for larger screens, multi-client review, and report preparation. If you coach multiple clients, a Mac dashboard can dramatically reduce the time spent switching between apps, exports, and spreadsheet tabs.`

Benefits bullets:
- `More screen space for trends and comparisons`
- `Faster weekly triage across multiple clients`
- `Better report preparation workflow`
- `Easier file organization for recurring exports`

Section H2:
`What coaches actually need from Apple Health analysis`

Paragraph:
`The most useful workflow is usually not a giant table of every metric. It is a weekly coaching view that highlights what changed and why.`

Coach-needs list:
- `A ranked list of clients who need attention`
- `Clear trend deltas (recent vs baseline)`
- `Explainable scoring and rule triggers`
- `Data completeness visibility`
- `A report format that can be sent quickly`

Section H2:
`Recommended coach workflow on Mac (step by step)`

H3:
`Step 1: Get the Apple Health export from iPhone`

Copy:
`Start with the iPhone Health export. Save the file using a naming pattern that includes client name and export date so your weekly process stays organized.`

H3:
`Step 2: Import and validate data completeness`

Copy:
`Before looking at scores, confirm which metrics are present. Missing HRV or sleep data can make trends misleading if your workflow does not show completeness clearly.`

H3:
`Step 3: Review recent vs baseline changes`

Copy:
`Compare the most recent period to a baseline window, and review the change in sleep, HRV, resting heart rate, activity, and steps. A good workflow explains why a client moved into a higher-priority bucket.`

H3:
`Step 4: Prioritize weekly check-ins`

Copy:
`Use an attention ranking to decide who to review first. This is where a dashboard saves time compared with opening individual spreadsheets one by one.`

H3:
`Step 5: Generate and send a weekly report`

Copy:
`Export a report with trend summary, alert explanations, and a suggested coach message so you can move quickly from analysis to communication.`

Section H2:
`What makes Apple Watch data analysis trustworthy`

Paragraph:
`Trust comes from transparency. If a workflow cannot show missing data, explain score changes, or identify what actually moved the result, it is easy to overreact to noise.`

Trust checklist:
- `Missing data is labeled`
- `Score breakdown is visible`
- `Score changes are traceable`
- `Date ranges are explicit`
- `Reports include generation timestamps`

Conversion block heading:
`This is the workflow WatchHealthDataReader is built for`

Conversion block copy:
`WatchHealthDataReader gives coaches a Mac dashboard for Apple Health exports with client triage, explainable scoring, weekly change summaries, and one-click report generation.`

Buttons:
- `Download for Mac`
- `View Sample Report`

Section H2:
`When a spreadsheet is still useful`

Paragraph:
`Spreadsheets are still useful for ad hoc calculations and custom analysis. The problem is using them as the center of a recurring client-reporting workflow. The best setup is often: Mac analysis workflow for weekly decisions, spreadsheet export only when needed.`

Section H2:
`Start with one client before changing your full workflow`

Paragraph:
`If you are evaluating tools, do not migrate everything at once. Start with one Apple Watch client, import a recent export, and compare your normal weekly process against a Mac dashboard + report workflow. You will know quickly whether the time savings and clarity are worth it.`

CTA block heading:
`Try the workflow with one client this week`

CTA block copy:
`Download WatchHealthDataReader for Mac, import an Apple Health export, and test the weekly triage + reporting flow with your real coaching process.`

Buttons:
- `Download for Mac`
- `See Features`

FAQ heading:
`FAQ: Analyze Apple Watch health data on Mac`

Q1:
`Can I analyze Apple Watch data on Mac directly?`

A1:
`A common workflow is to export data from Apple Health on iPhone and analyze the export on Mac. Many users choose a Mac app or tool because it is better for larger screens and multi-client review.`

Q2:
`What metrics are most useful for coaching?`

A2:
`That depends on the coaching model, but weekly workflows often focus on sleep, HRV, resting heart rate, activity/workout volume, and step trends because they support fast review and consistent check-ins.`

Q3:
`How do I avoid overreacting to noisy health data?`

A3:
`Use recent-vs-baseline comparisons, check data completeness first, and rely on workflows that explain score changes instead of hiding the inputs.`

Final CTA:
`Need a Mac workflow built for coach decisions, not spreadsheet cleanup?`

Buttons:
- `Download for Mac`
- `Export to CSV Guide`

## 6.4 Internal Links (required on page)

Must link to:
- `/download`
- `/features`
- `/sample-report`
- `/guides/apple-health-export-to-csv`
- `/guides/apple-health-export-to-excel`

---

## 7) Shared SEO/Conversion Implementation Notes (for dev + content team)

## 7.1 Page template requirements (all 4 pages in this spec)

- Server-rendered or statically rendered HTML for primary content
- Unique title/meta/canonical
- H1 + descriptive H2/H3 hierarchy
- Visible primary CTA above the fold
- Secondary CTA to sample report/demo
- Internal links to conversion + related SEO pages
- Breadcrumbs on guide pages
- Author/date block (helps trust and freshness)
- FAQ visible in HTML (not hidden-only accordions for primary content)

## 7.2 Suggested schema per page

Homepage:
- `SoftwareApplication`
- `Organization`
- `WebSite`

Guide pages:
- `Article`
- `BreadcrumbList`
- `FAQPage` (only if visible FAQ is retained on page)

## 7.3 Tracking events to implement on website

Global:
- `nav_download_click`
- `footer_download_click`

Homepage:
- `hero_download_click`
- `hero_demo_click`
- `sample_report_click`
- `faq_expand`

Guide pages:
- `guide_cta_download_click`
- `guide_cta_sample_report_click`
- `guide_internal_link_click`

## 7.4 A/B test starting points (homepage)

Test 1 hero headline:
- Variant A: `Spot which clients need attention this week and generate reports in minutes.`
- Variant B: `Turn Apple Health exports into weekly coaching reports on Mac.`

Test 2 hero CTA:
- Variant A: `Download for Mac`
- Variant B: `See the Workflow`

Test 3 hero visual:
- Variant A: dashboard screenshot first
- Variant B: sample report preview first

---

## 8) Content Production Checklist (for these pages)

- [ ] Add founder transparency note (no testimonials until real users exist)
- [ ] Record and embed 90-second demo
- [ ] Create sample weekly report preview page
- [ ] Add real product screenshots with descriptive alt text
- [ ] Implement title/meta/canonical tags exactly
- [ ] Add internal links as listed
- [ ] Add structured data and validate
- [ ] Add analytics events
- [ ] Review all copy for medical-claim safety
- [ ] Review Apple naming and badge usage before launch
