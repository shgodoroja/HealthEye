# PAYWALL.md — HealthEye Paywall Reference

Best-practice reference for designing and building a high-converting, App Store-compliant paywall for iPad + Mac. Scoped to HealthEye ($39 Solo / $79 Pro, 14-day free trial, SwiftUI, StoreKit 2, local-first).

Synthesized from: RevenueCat State of Subscription Apps 2024/2025, Adapty, Superwall, Nami, Apple HIG, App Store Review Guidelines (3.1.1 / 3.1.2 through iOS 18 / macOS 15), and public patterns from Duolingo, Calm, Headspace, Strava, Flighty, Streaks, Fantastical, Bear.

---

## A) OVERVIEW — Paywall Philosophy and Conversion Science for iOS/macOS Subscription Apps

### The underlying philosophy

A paywall is not a screen; it is the moment where perceived value, trust, and urgency converge. Every best-selling subscription app — Duolingo Super, Calm Premium, Strava, Flighty Pro, Fantastical, Streaks — treats the paywall as a product surface with its own roadmap, metrics, and A/B cadence, not a static view glued to the end of onboarding. For HealthEye, a B2B-ish tool sold to independent coaches, the paywall must convert both emotionally (this saves my Monday morning) and rationally (here is the ROI per client).

### Conversion science, current benchmarks (2024–2025)

Realistic benchmarks to plan against:

- **Paywall view-to-trial start:** 8–14% is solid for health/productivity; top-decile paywalls hit 20%+.
- **Paywall view-to-direct-purchase (no trial):** 1.5–4%.
- **Trial-to-paid conversion:** Health & fitness median sits ~28–35%; productivity/utility 40–55%; top-decile crosses 60%. HealthEye, as a professional tool with habitual weekly use, should target 40–50%.
- **Free-to-paid conversion (no trial required):** 2–5% typical.
- **Day-1 to Day-30 retention after trial:** median ~75–80% of paid converts, drops to ~55–65% by Day-90.
- **LTV:CAC target:** 3:1 minimum; pro-oriented tools like HealthEye can push 5:1 with annual plans dominant.
- **Annual uptake when "Most Popular" + savings tag is shown:** 55–70% of converts choose annual vs <30% without the anchor.

### When to show the paywall — decision framework

Three patterns dominate, and the best apps combine them:

1. **Onboarding (hard-coded) paywall** — shown right after a quick value-surfacing flow (3–5 screens). This is the Duolingo/Calm move. Works when the value proposition is obvious in < 60 seconds and doesn't require personal data. **For HealthEye: partially relevant.** The coach hasn't imported anything yet, so show a "preview paywall" only if you can demo concrete value (e.g., sample dashboard carousel).

2. **Contextual (feature-gated) paywall** — triggers at the *aha moment*. For HealthEye this is: (a) generating the 2nd+ PDF report, (b) adding the 4th client, (c) opening weekly alerts, (d) exporting message helper copy. This produces the highest trial-to-paid because the user has just experienced deferred value. Apps like Flighty, Bear, and Streaks use this almost exclusively.

3. **Hybrid** — soft paywall in onboarding ("Start with 14 days free, cancel anytime") + hard gates on specific Pro features. This is the current state of the art recommended by Superwall and RevenueCat. **HealthEye should adopt this.**

Avoid the anti-pattern of gating *everything* up front: coaches will bounce, and App Store reviewers penalize apps that prevent meaningful evaluation (Guideline 3.1.2 enforcement has tightened since 2024).

### Decision: freemium vs free-trial-first vs paid-only

- **Freemium (no trial, limited free tier):** best for viral/social apps — not HealthEye.
- **Free-trial-first (14 days, card required via StoreKit intro offer):** highest ARPU and best for professional buyers. **Recommended for HealthEye.** 14 days maps cleanly to 2 coaching weeks (the unit of value).
- **Paid-only (no trial):** maximizes revenue per install but slashes install-to-paid by 40–60%. Only justifiable for very niche pro tools or post-PMF optimization.

### Tier design science

- **2 tiers vs 3:** 3-tier paywalls increase average revenue per paying user by 15–25% via the *decoy effect* (Ariely). But for a solo-dev app with two clear personas (Solo coach / Pro coach), **2 tiers + annual toggle is cleanest**. Keep the option to A/B a 3rd "Team" anchor tier later at ~$149.
- **Anchor to annual:** show the annual price prominently with monthly as secondary. "$39/mo or $390/year (save 2 months)" beats "$39/mo · $468/yr" by 20–30% on annual conversion.
- **Decoy pricing:** if a 3rd tier is added, design it to make Pro look obvious (Team at $149 makes Pro at $79 feel like the smart pick).
- **"Most popular" tag** on Pro, **"Best value" tag** on annual — empirically add 10–18% to conversion.

### Copy and psychology — the levers that move the needle

- **Benefit-first, not feature-first.** "Spot a client going off the rails before Monday" beats "Weekly alert engine."
- **Loss aversion:** "Don't let another week of exports pile up" outperforms gain framing ~1.5x.
- **Price anchoring / per-client math:** "$0.79 per client per week" for a coach with 20 clients is far more persuasive than "$79/mo".
- **Social proof placement:** above or beside the pricing block, not at the bottom. Rotating quotes work; a single strong quote + name + photo works better.
- **Scarcity/urgency:** use sparingly and truthfully (launch pricing, annual discount ending). Fake urgency is a 3.1 rejection risk and kills trust with pros.
- **"Cancel anytime" + "No charge today":** these two phrases alone lift trial start 8–12%.

### iPad / Mac specifics — where 90% of iOS paywall advice goes wrong

- **Sheet vs full-screen:** on iPhone, full-screen is standard. On iPad and Mac, a full-screen paywall feels aggressive and out-of-character. Use a **large centered sheet** (min 720×560 on Mac, `.formSheet` or `.pageSheet` on iPad) with visible window chrome behind it. Users trust an app they can dismiss.
- **Pointer/hover states:** add hover affordances to tier cards and CTA. Pro users notice the absence of hover immediately.
- **Keyboard navigation:** full Tab/Shift-Tab order, `⏎` submits primary CTA, `⎋` closes. Mac reviewers specifically check this.
- **Window sizing on Mac:** paywall sheet must handle 1024-wide windows and 27" displays — no fixed pixel layouts.
- **Restore Purchases:** must be visible without scrolling on Mac (Mac reviewers enforce this more strictly than iOS reviewers).
- **StoreKit 2 on Mac:** same `Product.purchase()` API but can surface different error states (Family Sharing config, parental controls). Test all of them.
- **Catalyst vs native SwiftUI:** native SwiftUI for macOS has better paywall aesthetics. If on Catalyst, explicitly style NSViewRepresentable bridges.
- **iPad landscape/portrait:** design paywall at 1:1.4 aspect ratio baseline and allow it to breathe horizontally — don't stretch; add side padding so line length stays 50–70 chars.
- **Split View / Slide Over on iPad:** paywall must work at compact width.
- **Menu bar / Commands on Mac:** expose "Upgrade to Pro…" in the app menu and Help menu. Power users convert from here.

### StoreKit 2, compliance, and the non-negotiables

StoreKit 2 (iOS 15+/macOS 12+) is the mandatory baseline. Use `Product`, `Transaction.updates`, `Transaction.currentEntitlements`, JWS verification. App Store Server Notifications v2 for server-side receipt handling if you have a backend (HealthEye is local-first — optional but recommended for refund detection).

Apple's current enforcement hot spots (3.1.2):

- Price, billing period, and auto-renew must be visible on the paywall *before* the purchase button, in legible type.
- Links to Terms of Use (EULA) and Privacy Policy must be tappable on the paywall itself.
- "Restore Purchases" must exist and function.
- Trial terms must explicitly state billing start date and amount ("Free for 14 days, then $79/year. Cancel anytime in Settings.").
- No dark patterns: pre-checked upsells, hidden close buttons, disguised "No thanks" links — instant rejection.

### Retention and win-back

Trial cadence (push/email/in-app): **Day 0** welcome + value setup, **Day 3** "first insight" nudge, **Day 7** activation check, **Day 11** "your trial ends in 3 days" + preview of what locks, **Day 13** final reminder with annual discount offer if still unconverted. Use StoreKit 2 promotional offers for lapsed users (introductory offers can't be reused; promotional offers can). Win-back via App Store Connect offer codes is the cleanest path for churned annual subscribers.

### Analytics stack recommendation

For solo-dev: RevenueCat (free up to $2.5k MTR) for receipt + entitlement + events. Ship these events: `paywall_viewed`, `paywall_cta_tapped`, `trial_started`, `purchase_completed`, `purchase_failed`, `restored`, `cancelled_during_trial`, `converted_to_paid`, `renewed`, `refunded`. Slice by paywall variant, surface (onboarding/contextual/menu), tier, and billing period.

---

## B) CHECKLIST

### Strategy & positioning

- [ ] Define primary persona (Solo coach 5–20 clients) and secondary (Pro coach 21–100)
- [ ] Write a 1-sentence value prop tested against "saves my Monday"
- [ ] Decide pricing model: confirmed 14-day free trial → auto-convert to annual
- [ ] Map every Pro-only feature to the specific moment it's discovered
- [ ] Choose hybrid paywall strategy (onboarding soft + contextual hard)
- [ ] Set target metrics: 12% view-to-trial, 45% trial-to-paid, 60% annual mix
- [ ] Decide whether to ship 2-tier now and A/B a 3rd Team tier in month 3
- [ ] Document what remains free forever (single client, 1 report/week) to satisfy 3.1.2 evaluation

### Paywall structure

- [ ] Build a reusable `PaywallView` that accepts a `PaywallContext` enum (onboarding, reportGate, clientLimit, alertsGate, menu, winBack)
- [ ] Vary hero copy and social proof per context
- [ ] Never show paywall before any value (minimum: sample dashboard preview)
- [ ] Ensure every gate has a visible close/dismiss affordance
- [ ] Gate 2nd+ PDF report generation
- [ ] Gate 4th+ client
- [ ] Gate weekly alert engine
- [ ] Gate message helper export
- [ ] Keep core import + single-client view free to allow evaluation
- [ ] Add an "Upgrade" entry point in the main menu (Mac) and sidebar footer (iPad)
- [ ] Support deep link to paywall (for email/web promotion)
- [ ] Hard paywall on bulk report generation

### Visual & layout

- [ ] Hero section: icon + 1-line value prop + 1-line subhead
- [ ] Feature bullet list: max 5 items, benefit-led, each with SF Symbol
- [ ] Tier cards side-by-side on Mac/iPad landscape; stacked on iPad portrait/compact
- [ ] Highlight "Most Popular" tier with border + accent color + tag
- [ ] Monthly/Annual toggle with "Save X%" badge on annual
- [ ] Show price per month under annual plan ("$6.58/mo billed annually")
- [ ] Show per-client math ("≈ $0.79 per client per week")
- [ ] Primary CTA button full-width, high contrast, single verb
- [ ] Secondary "Restore Purchases" text button below CTA
- [ ] Social proof block (quote + name + role + photo) above pricing
- [ ] Logo strip of notable users/publications if available (optional)
- [ ] Legal footer: Terms, Privacy, auto-renew disclosure
- [ ] Close (X) button top-left on Mac, top-right on iPad per platform norms
- [ ] Progress indicator on purchase button during StoreKit call
- [ ] Empty/error states designed (network loss, StoreKit unavailable)
- [ ] Support Dark Mode with tested contrast
- [ ] Test paywall at 125%, 150%, 200% text size
- [ ] Avoid gradients that kill legibility; use accent color sparingly

### Copy & messaging

- [ ] Headline leads with outcome ("Spot at-risk clients before Monday")
- [ ] Subhead frames the coach's weekly reality
- [ ] Feature bullets start with a verb and name the saved time ("Generate 20 branded PDFs in 30 seconds")
- [ ] Include "Cancel anytime in System Settings" verbatim
- [ ] Include "No charge today" in the trial CTA area
- [ ] CTA reads "Start 14-day free trial"
- [ ] Post-trial price is stated next to CTA, not buried
- [ ] Social proof quote is specific and attributed
- [ ] Avoid superlatives that trip Apple review ("the best", "#1")
- [ ] Avoid fake scarcity timers
- [ ] Health disclaimer if any biomarker advice is shown
- [ ] Localize at minimum EN, ES, DE, FR if planned (use String Catalog)
- [ ] Copy-review pass for reading level <= grade 8

### Tier & pricing design

- [ ] Solo: $39/mo or $390/yr (save ~17%)
- [ ] Pro: $79/mo or $790/yr (save ~17%)
- [ ] Validate pricing in App Store Connect for each storefront
- [ ] Map features per tier in a single source of truth (e.g. `Entitlement.swift`)
- [ ] Mark Pro as "Most Popular" with tag
- [ ] Tag Annual as "Best Value — Save 2 months"
- [ ] No lifetime option at launch (hurts ARR and Apple flags subscriptions-that-aren't)
- [ ] Reserve $149 "Team" SKU in App Store Connect for future anchor test
- [ ] Set up a single Subscription Group so users can upgrade/downgrade/cross-grade correctly
- [ ] Configure intro offer: 14-day free trial for new customers on both tiers
- [ ] Decide whether monthly gets the trial too (recommend: yes on Solo, no on Pro, to steer toward annual)

### Free trial mechanics

- [ ] StoreKit Introductory Offer configured per SKU and storefront
- [ ] "Eligible for intro offer" check via `Product.SubscriptionInfo.isEligibleForIntroOffer`
- [ ] If ineligible, show a promotional offer or full-price CTA with honest copy
- [ ] In-app trial countdown visible in Settings and on dashboard (Day X of 14)
- [ ] Day-11 in-app reminder with promo offer
- [ ] Day-13 last-chance in-app banner
- [ ] No silent auto-conversion — show a pre-charge notice on Day 13 per 3.1.2
- [ ] Trial abuse prevention via Apple's account-level intro eligibility (don't roll your own)
- [ ] Handle user who cancels trial: graceful downgrade, export of data intact

### StoreKit 2 implementation

- [ ] Use StoreKit 2 (`Product`, `Transaction`) — no legacy StoreKit 1 wrappers
- [ ] Load products via `Product.products(for:)` with explicit IDs
- [ ] Handle `Product.purchase()` result cases: success, userCancelled, pending
- [ ] Verify with `Transaction.verificationResult` and JWS
- [ ] Listen to `Transaction.updates` for lifetime of app
- [ ] Persist entitlement via `Transaction.currentEntitlements`
- [ ] Call `transaction.finish()` after unlock
- [ ] Implement Restore Purchases via `AppStore.sync()`
- [ ] Handle `Transaction.revocationDate` (refunds) — revoke entitlement
- [ ] Handle grace period (expiredOnGracePeriod state)
- [ ] Consider `SubscriptionStoreView` (iOS 17+/macOS 14+) as a fallback, but keep a custom view for control
- [ ] Handle price changes via `Transaction.priceConsentStatus`
- [ ] App Store Server Notifications v2 webhook (if backend added) for REFUND, DID_FAIL_TO_RENEW, EXPIRED, GRACE_PERIOD_EXPIRED
- [ ] StoreKit configuration file checked into repo for local testing
- [ ] Unit tests for entitlement resolution logic
- [ ] Handle offline: cached entitlement flag with TTL, re-verify on next launch
- [ ] Present Apple's native manage-subscription sheet via `showManageSubscriptions(in:)`
- [ ] Present refund sheet via `beginRefundRequest(for:in:)` from Settings
- [ ] Promoted in-app purchases payload handled in app delegate
- [ ] Support offer codes via `presentCodeRedemptionSheet()` and deep link path

### iPad-specific

- [ ] Paywall presented as `.formSheet` with detents `[.large]`
- [ ] Layout adapts to portrait (stacked cards) and landscape (side-by-side)
- [ ] Works in Split View and Slide Over at compact width
- [ ] Pointer hover states on tier cards and CTA
- [ ] External keyboard: Tab order, Return to submit, Esc to dismiss
- [ ] Apple Pencil hover if iPad Pro
- [ ] Stage Manager tested
- [ ] Dynamic Type up to XXL tested

### Mac-specific

- [ ] Paywall as centered sheet, min 720×560, resizable ceiling 1024×720
- [ ] Close control top-left (traffic-light adjacent)
- [ ] Primary CTA responds to Return
- [ ] Secondary actions reachable via Tab
- [ ] Command-W closes sheet
- [ ] "Upgrade to HealthEye Pro…" menu item under app menu
- [ ] "Restore Purchases…" menu item under app menu
- [ ] "Manage Subscription…" opens Apple's native sheet
- [ ] Hover states on all interactive elements
- [ ] Cursor changes (pointingHand) over CTAs
- [ ] Works with Magic Keyboard and Magic Mouse
- [ ] Tested on 13" MacBook Air and 27" external display
- [ ] Dark mode matches system appearance
- [ ] Handles window being backgrounded mid-purchase
- [ ] Menu bar extra (if any) has "Subscription: Trial Day 7/14" affordance
- [ ] Tested on Apple Silicon baseline

### App Store compliance (3.1.1 / 3.1.2)

- [ ] Price displayed clearly for every SKU
- [ ] Billing period displayed ("billed annually", "per month")
- [ ] Trial length displayed with explicit "then $X/year" phrasing
- [ ] Auto-renew disclosure present verbatim
- [ ] Terms of Use (EULA) link tappable
- [ ] Privacy Policy link tappable
- [ ] Restore Purchases button visible on the paywall (not only in Settings)
- [ ] No pre-checked upsell toggles
- [ ] Close/dismiss affordance always visible
- [ ] Free tier or trial lets reviewers evaluate app without paying
- [ ] App Review Notes include demo account / test instructions
- [ ] Subscription group configured with correct upgrade/downgrade levels
- [ ] Localized metadata for each storefront with correct price display
- [ ] Privacy nutrition labels filled out (especially Health data)
- [ ] Required reason API declarations if using any (file timestamps etc.)
- [ ] No external payment links (Reader app rules don't apply here)
- [ ] Reviewer can reach paywall in <=2 taps from launch

### Analytics & experimentation

- [ ] RevenueCat SDK integrated with StoreKit 2
- [ ] Event schema defined: paywall_viewed, paywall_cta_tapped, trial_started, purchase_completed, purchase_failed, restored, cancelled_during_trial, converted_to_paid, renewed, refunded
- [ ] Paywall variant ID sent on every event
- [ ] Surface source sent on every event (onboarding, report_gate, client_limit, menu, win_back)
- [ ] Funnel dashboard set up (view → CTA → purchase)
- [ ] Cohort analysis on trial-to-paid by surface
- [ ] A/B harness via RevenueCat Experiments or Superwall (feature-flagged copy/price)
- [ ] Target 2 concurrent tests max; 95% significance before promoting
- [ ] Log error codes from StoreKit for triage
- [ ] Track refund rate monthly; above 3% indicates messaging mismatch
- [ ] Track renewal rate month-1, month-3, month-12

### Retention & win-back

- [ ] Day 0 in-app welcome + "import your first client now" nudge
- [ ] Day 3 "you've reviewed X clients — generate your first report"
- [ ] Day 7 activation email/push (optional)
- [ ] Day 11 countdown + 50% off first year promotional offer
- [ ] Day 13 last chance + preview of locking features
- [ ] Lapsed-user win-back: App Store Connect offer code, 3 months discount
- [ ] Churned annual users: custom promotional offer via StoreKit
- [ ] Grace period detection → in-app banner "Update your payment method"
- [ ] Billing retry messaging per Apple's grace period rules
- [ ] Honor any unlocked Pro features for the full paid period after cancellation

### Trust / legal / accessibility

- [ ] Terms of Use hosted at stable URL
- [ ] Privacy Policy hosted at stable URL, covers Health data explicitly
- [ ] GDPR-compliant data export and delete (aligns with HealthEye portability goal)
- [ ] EU DSA: provide trader contact info in App Store Connect
- [ ] Health/wellness disclaimer: "Not a medical device. Informational only."
- [ ] Privacy nutrition labels reflect actual data collection
- [ ] VoiceOver labels on all paywall controls
- [ ] Dynamic Type support up to accessibility sizes
- [ ] Sufficient color contrast (WCAG AA minimum)
- [ ] Reduce Motion respected on paywall animations
- [ ] No flashing content
- [ ] Keyboard-only navigation works end-to-end
- [ ] Screen reader announces "Most Popular" and price correctly
- [ ] No dark patterns — Apple now rejects disguised dismiss buttons

### QA & pre-launch

- [ ] Sandbox tester accounts created for each storefront
- [ ] Purchase flow tested on iPad portrait, iPad landscape, MacBook, external display
- [ ] Trial start, mid-trial, end-of-trial states all tested
- [ ] Cancel-during-trial tested end-to-end
- [ ] Restore after reinstall tested
- [ ] Restore across devices with same Apple ID tested
- [ ] Family Sharing tested (enable/disable per SKU intentionally)
- [ ] Refund revocation tested via StoreKit testing
- [ ] Grace period simulated
- [ ] Offer code redemption tested
- [ ] Promotional offer signature tested (if using server-signed offers)
- [ ] Network loss during purchase tested
- [ ] Backgrounding during purchase tested
- [ ] Upgrade Solo→Pro tested (prorated)
- [ ] Downgrade Pro→Solo tested (deferred to period end)
- [ ] Monthly↔Annual switch tested
- [ ] Screenshots updated to reflect paywall for App Store listing
- [ ] App Review demo notes include trial unlock path for reviewer
- [ ] Crash-free rate above 99.8% on paywall screen before release
- [ ] Analytics events verified in staging before launch
- [ ] Post-launch dashboard configured for day-1 monitoring

---

## Notes

Benchmarks in this doc are approximate medians from public RevenueCat/Adapty/Superwall reports. Replace them with HealthEye's own instrumented numbers within 60 days of launch. The framework (hybrid paywall, benefit-first copy, annual anchor, 14-day trial, contextual gates) is durable — the percentages drift quarter by quarter.
