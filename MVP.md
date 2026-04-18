# Arclens MVP Research and Plan

Last updated: 2026-02-20

## 1) Executive summary

There is a real, monetizable niche for a Mac-oriented Apple Watch/Health data analysis product, but export utilities are becoming crowded. The strongest first monetization target is independent coaches (fitness, wellness, nutrition), with prosumer athletes as the second segment.

Core opportunity:
- Most tools emphasize export and raw files.
- Coaches pay for time-saving, retention-improving workflows.
- A focused product can win on "actionable weekly client intelligence" rather than generic charts.

Recommended first wedge:
- One-click weekly client recovery/risk reports for coaches.

## 2) Demand research synthesis

### Market and platform realities
- Apple Health remains primarily iPhone/iPad oriented.
- Mac-native direct HealthKit usage is constrained relative to iOS/watchOS.
- Practical workflow for this product is iPhone ingest + Mac analysis/reporting.

### User pain signals from communities
- Users repeatedly ask for:
  - Better export formats than default XML.
  - Desktop analysis workflows.
  - Meaningful insights without manual spreadsheet work.
- Common frustration themes:
  - Data portability friction.
  - Too much manual cleaning.
  - Fragmented tooling between Apple Health and third-party services.

### YouTube and forum intent
- Repeated tutorial demand around exporting Apple Health data to CSV and visualizing trends.
- Ongoing discussions in Reddit and Apple/Mac forums indicate persistent unmet needs for interpretable analytics.

## 3) Competitive landscape (top 10 tracked)

Direct/adjacent competitors tracked in research:
1. Health Auto Export
2. Health Data Export AI Analyzer
3. Health Analytics Export
4. Health Export CSV
5. Health App Data Export Tool
6. HealthSync Export
7. Health Records Export
8. HLExport
9. HealthFit
10. RunGap

Observed cluster:
- Strong on data export and sync.
- Weaker on coach workflow outcomes:
  - Client-level triage.
  - Explainable anomaly/risk narratives.
  - One-click weekly report workflows.

Positioning gap:
- "Coach command center for Apple Watch recovery and adherence" with fast reporting and message-ready recommendations.

## 4) Best monetization entry segment

Preferred segment: independent coaches (performance + wellness/nutrition).

Why this is highest priority:
- Higher willingness-to-pay than generic consumer segment.
- Clear ROI framing: save coach time, improve client adherence, reduce churn.
- Easier B2B-lite packaging (seat/client limits) vs broad consumer freemium competition.

Secondary expansion segment:
- Prosumer athletes (individual paid plan after coach wedge is validated).

## 5) Coaches-first MVP (buy-trigger version)

### MVP promise
"Give coaches a weekly client risk/recovery report in one click."

### Target user profile
- Solo or small-team remote coaches with 20-100 active clients.
- Current workflow includes Apple Watch users and manual check-ins.

### Core MVP scope (must-have)
1. Client ingest
- Import Apple Health export data per client.
- Normalize key metrics into a standard schema.

2. Coach Monday dashboard
- Client list sorted by attention priority.
- Show only 5 core metrics:
  - Sleep trend
  - HRV trend
  - Resting heart rate trend
  - Workout volume trend
  - Step adherence trend

3. Weekly report generator
- One-click PDF report per client.
- Include trend chart, short insight summary, and a suggested coach message.

4. Explainable alerts
- Trigger visible rules for notable changes.
- Example rule:
  - HRV down + resting HR up + sleep down across recent baseline window.

5. Coach communication helper
- Copy-ready message snippets aligned to detected trend patterns.

### Explicitly out of MVP
- Full clinical diagnostics.
- Broad third-party connector ecosystem.
- Complex AI "black-box" scoring without interpretability.

## 6) Recommended pricing and packaging (initial)

Trial:
- 14-day free trial.

Plans:
- Solo Coach: $39/month, up to 30 clients.
- Pro Coach: $79/month, up to 100 clients.
- Founding cohort offer: $29/month (time-limited, locked price).

Consumer follow-on (phase 2):
- Individual Pro plan for athletes/longevity users after coach PMF signals are positive.

## 7) MVP success metrics (purchase motivation validation)

Activation and conversion targets:
- >60% of trials import at least 5 clients within 7 days.
- >40% of trials generate 2+ weekly reports during trial.
- >20% trial-to-paid conversion by day 14.
- NPS >30 among paying coaches.

Retention and product value:
- Weekly report generation frequency per coach.
- Alert-to-message usage rate.
- Coach churn rate at 30/60/90 days.

## 8) 90-day experiment plan

### Experiment A: Packaging structure
Hypothesis:
- Coaches prefer clear client-cap plans over generic "pro" labels.

Variants:
- A1: Solo/Pro tiers (30 and 100 clients).
- A2: Seat-based + client add-on pricing.

Primary KPI:
- Trial-to-paid conversion and 60-day retention.

Scale rule:
- Keep variant with >=15% better D35 revenue per trial and no retention deterioration.

### Experiment B: Paywall timing
Hypothesis:
- Conversion improves if paywall appears after first "insight moment."

Variants:
- B1: Immediate paywall after onboarding.
- B2: Paywall after first report generation.

Primary KPI:
- Trial starts, completion, paid conversion.

Scale rule:
- Keep variant with strongest D35 paid conversion and acceptable refund rate.

### Experiment C: Persona-led onboarding copy
Hypothesis:
- "Performance coach" vs "wellness coach" onboarding language changes conversion.

Variants:
- C1: Performance framing.
- C2: Wellness/adherence framing.

Primary KPI:
- Onboarding completion and paywall conversion.

Scale rule:
- Keep copy set with >=20% conversion lift.

## 9) Product messaging options (coach-first)

Positioning line options:
1. "The weekly recovery command center for Apple Watch coaching clients."
2. "Turn Apple Health data into client actions, not spreadsheets."
3. "Spot at-risk clients in minutes and send guidance instantly."

Core value proof:
- "What changed this week?"
- "Who needs attention now?"
- "What should I message this client today?"

## 10) Source list captured in this research round

### Apple / platform references
- https://www.apple.com/health/
- https://developer.apple.com/health-fitness/
- https://developer.apple.com/help/account/reference/supported-capabilities-macos/
- https://developer.apple.com/help/account/reference/supported-capabilities-ios
- https://support.apple.com/en-afri/guide/iphone/iph5ede58c3d/26/ios/26

### App growth / marketing references
- https://appmasters.com/
- https://appmasters.com/articles/the-10-commandments-of-app-store-optimization/
- https://appmasters.com/articles/apple-search-ads/
- https://ads.apple.com/app-store/help/campaigns/0006-understand-search-match
- https://ads.apple.com/app-store/help/keywords/0060-use-negative-keywords
- https://developer.apple.com/help/app-store-connect/create-product-page-optimization-tests/overview-of-product-page-optimization
- https://developer.apple.com/app-store/custom-product-pages/

### Community demand signals
- https://www.reddit.com/r/AppleWatch/comments/1irkloq
- https://www.reddit.com/r/AppleWatch/comments/ysq39o
- https://www.reddit.com/r/AppleWatch/comments/15ulltl
- https://www.reddit.com/r/AppleWatch/comments/15mvgxi
- https://www.reddit.com/r/QuantifiedSelf/comments/1miaqby
- https://www.reddit.com/r/QuantifiedSelf/comments/1qstjdk/the_health_tracking_ecosystem_is_so_fragmented/
- https://forums.macrumors.com/threads/getting-data-off-the-health-app.2423453/
- https://discussions.apple.com/thread/255193699
- https://discussions.apple.com/thread/254821672

### YouTube demand examples
- https://www.youtube.com/watch?v=gvVo5gQR3Gs
- https://www.youtube.com/shorts/Yktm1jXhXMo
- https://www.youtube.com/watch?v=5FCFRYbXHjg

### Competitor references
- https://apps.apple.com/us/app/health-auto-export-json-csv/id1115567069
- https://apps.apple.com/us/app/health-data-export-ai-analyzer/id6749297170
- https://apps.apple.com/us/app/health-analytics-export/id6757945914
- https://apps.apple.com/us/app/health-export-csv/id1477944755
- https://apps.apple.com/us/app/health-app-data-export-tool/id1625921705
- https://apps.apple.com/us/app/healthsync-export/id6758282290
- https://apps.apple.com/us/app/health-records-export/id6757396043
- https://apps.apple.com/us/app/hlexport/id6745495959
- https://apps.apple.com/us/app/healthfit/id1202650514
- https://apps.apple.com/us/app/rungap-workout-data-manager/id534460198

### Monetization benchmarks and channel references
- https://www.revenuecat.com/state-of-subscription-apps-2025/
- https://www.trainerize.com/pricing/
- https://nudgecoach.com/pricing
- https://help.practicebetter.io/hc/en-us/articles/360007910332-Updating-Your-Practice-Better-Subscription-Plan
- https://www.bls.gov/ooh/personal-care-and-service/fitness-trainers-and-instructors.htm
- https://www.bls.gov/ooh/healthcare/dietitians-and-nutritionists.htm
- https://ouraring.com/membership
- https://setapp.com/developers
- https://docs.setapp.com/docs/setapp-marketplace-overview
- https://docs.setapp.com/docs/preparing-your-application-for-setapp

## 11) Build order recommendation

1. Implement import + normalization for coach-useful metrics only.
2. Build client triage dashboard with clear explainable flags.
3. Ship one-click weekly PDF report + coach message helper.
4. Launch closed beta with 20-30 coaches.
5. Run pricing/package experiments before broad consumer expansion.
