import SwiftUI
import SwiftData

struct ClientDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [CoachAccount]
    let client: Client
    let isBulkGenerating: Bool
    let onGenerateAllReports: () -> Void
    let onShowSettings: () -> Void

    @State private var showingImportWizard = false
    @State private var showingEditForm = false
    @State private var showingReportPreview = false
    @State private var showingPaywall = false
    @State private var weeklyCompleteness: [WeeklyCompleteness] = []

    // M2 state
    @State private var metricTrend: MetricTrend?
    @State private var attentionResult: AttentionScoreResult?
    @State private var activeAlerts: [AlertResult] = []
    @State private var narrative: NarrativeResult?

    private var account: CoachAccount? {
        accounts.first
    }

    private var sortedImports: [ClientImport] {
        client.imports.sorted { $0.importedAt > $1.importedAt }
    }

    init(
        client: Client,
        isBulkGenerating: Bool = false,
        onGenerateAllReports: @escaping () -> Void = {},
        onShowSettings: @escaping () -> Void = {}
    ) {
        self.client = client
        self.isBulkGenerating = isBulkGenerating
        self.onGenerateAllReports = onGenerateAllReports
        self.onShowSettings = onShowSettings
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection

#if os(iOS)
                iPadWorkspaceActions
#endif

                Divider()

                // Attention Score Card
                if let result = attentionResult {
                    ScoreBreakdownView(result: result)
                }

                // Weekly Narrative
                if let narrative = narrative {
                    WeeklyNarrativeView(narrative: narrative.summary)
                }

                // Metric Trend Cards
                if let trend = metricTrend {
                    metricTrendSection(trend: trend)
                }

                // Alerts Panel
                AlertPanelView(alerts: activeAlerts)

                // Message Helper
                if let narrative = narrative, !narrative.suggestedMessages.isEmpty {
                    MessageHelperView(messages: narrative.suggestedMessages)
                }

                Divider()

                // Import History
                importHistorySection

                // Weekly Completeness
                if !weeklyCompleteness.isEmpty {
                    completenessSection
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $showingImportWizard, onDismiss: refreshAll) {
            ImportWizardView(client: client)
        }
        .sheet(isPresented: $showingEditForm) {
            ClientFormView(mode: .edit(client))
        }
        .sheet(isPresented: $showingReportPreview) {
            ReportPreviewView(client: client)
        }
        .sheet(isPresented: $showingPaywall) {
            if let account {
                PaywallView(account: account)
            } else {
                Text("Loading…").onAppear { showingPaywall = false }
            }
        }
        .onAppear {
            refreshAll()
            AnalyticsService.track("client_detail_viewed", account: account)
        }
        .onChange(of: attentionResult == nil) { _, isNil in
            if !isNil {
                AnalyticsService.track("score_breakdown_viewed", account: account)
            }
        }
        .onChange(of: weeklyCompleteness.isEmpty) { _, isEmpty in
            if !isEmpty {
                AnalyticsService.track("completeness_viewed", account: account)
            }
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(client.displayName)
                    .font(.title)
                    .fontWeight(.bold)

                Text(client.timezone)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let notes = client.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }

            Spacer()

            Button("Generate Report") {
                if let account, TrialManager.canGenerateReports(account: account) {
                    showingReportPreview = true
                } else {
                    showingPaywall = true
                }
            }
            .accessibilityIdentifier("generate-report-button")

            Button("Edit") {
                showingEditForm = true
            }
            .accessibilityIdentifier("edit-client-button")

            Button("Import Health Data") {
                showingImportWizard = true
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("import-health-data-button")
        }
    }

#if os(iOS)
    private var iPadWorkspaceActions: some View {
        HStack(spacing: 12) {
            Button {
                onGenerateAllReports()
            } label: {
                if isBulkGenerating {
                    ProgressView()
                        .controlSize(.small)
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Generate All Reports", systemImage: "doc.badge.arrow.up")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .disabled(isBulkGenerating)
            .accessibilityIdentifier("generate-all-reports-button")

            Button {
                onShowSettings()
            } label: {
                Label("Settings", systemImage: "gearshape")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("toolbar-settings")
        }
    }
#endif

    private func metricTrendSection(trend: MetricTrend) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Metric Trends")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 8) {
                MetricTrendCardView(
                    metricName: "Sleep",
                    unit: "min",
                    recentAvg: trend.recent.sleepAvg,
                    baselineAvg: trend.baseline.sleepAvg,
                    delta: trend.sleepDelta
                )

                MetricTrendCardView(
                    metricName: "HRV",
                    unit: "ms",
                    recentAvg: trend.recent.hrvAvg,
                    baselineAvg: trend.baseline.hrvAvg,
                    delta: trend.hrvDelta
                )

                MetricTrendCardView(
                    metricName: "Resting HR",
                    unit: "bpm",
                    recentAvg: trend.recent.restingHrAvg,
                    baselineAvg: trend.baseline.restingHrAvg,
                    delta: trend.restingHrDelta
                )

                MetricTrendCardView(
                    metricName: "Workout",
                    unit: "min",
                    recentAvg: trend.recent.workoutAvg,
                    baselineAvg: trend.baseline.workoutAvg,
                    delta: trend.workoutDelta
                )

                MetricTrendCardView(
                    metricName: "Steps",
                    unit: "steps",
                    recentAvg: trend.recent.stepsAvg,
                    baselineAvg: trend.baseline.stepsAvg,
                    delta: trend.stepsDelta
                )
            }
        }
    }

    private var importHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Import History")
                .font(.headline)

            if sortedImports.isEmpty {
                Text("No imports yet. Import health data to see metrics.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(sortedImports, id: \.id) { importRecord in
                    HStack {
                        Image(systemName: importRecord.importStatus == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(importRecord.importStatus == .success ? .green : .red)

                        Text(importRecord.importedAt, format: .dateTime.month(.abbreviated).day().year().hour().minute())

                        Spacer()

                        if let start = importRecord.dateRangeStart, let end = importRecord.dateRangeEnd {
                            Text("\(start.formatted(.dateTime.month(.abbreviated).day())) — \(end.formatted(.dateTime.month(.abbreviated).day().year()))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(importRecord.importStatus.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                importRecord.importStatus == .success
                                    ? Color.green.opacity(0.1)
                                    : Color.red.opacity(0.1),
                                in: Capsule()
                            )
                    }
                    .padding(.vertical, 4)

                    if let reason = importRecord.failureReason {
                        Text(reason)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    private var completenessSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Data Completeness")
                .font(.headline)

            // Table header
            HStack {
                Text("Week")
                    .frame(width: 100, alignment: .leading)
                Text("Sleep")
                    .frame(width: 50)
                Text("HRV")
                    .frame(width: 50)
                Text("RHR")
                    .frame(width: 50)
                Text("Workout")
                    .frame(width: 60)
                Text("Steps")
                    .frame(width: 50)
                Text("Score")
                    .frame(width: 60)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            ForEach(weeklyCompleteness.reversed(), id: \.weekStart) { week in
                MetricCompletenessRowView(week: week)
            }
        }
    }

    private func refreshAll() {
        do {
            let snapshot = try ClientInsightsRefreshService.refresh(
                client: client,
                context: modelContext
            )
            weeklyCompleteness = snapshot.weeklyCompleteness
            metricTrend = snapshot.trend
            attentionResult = snapshot.attentionResult
            activeAlerts = snapshot.alerts
            narrative = snapshot.narrative
        } catch {
            refreshCompleteness()
            refreshScoring()
        }
    }

    private func refreshCompleteness() {
        let metrics = client.metrics
        weeklyCompleteness = CompletenessCalculator.calculateWeeklyCompleteness(metrics: metrics)

        do {
            try CompletenessCalculator.saveCompleteness(
                weeklyData: weeklyCompleteness,
                client: client,
                context: modelContext
            )
        } catch {
            // Non-fatal
        }
    }

    private func refreshScoring() {
        let metrics = client.metrics
        let trend = BaselineEngine.computeTrend(metrics: metrics)
        self.metricTrend = trend

        let currentWeekStart = CompletenessCalculator.mondayOfWeek(containing: Date())
        let completeness = CompletenessCalculator.score(
            for: currentWeekStart,
            metrics: metrics
        )

        // Attention score
        let scoreResult = AttentionScoreCalculator.calculate(
            trend: trend,
            completenessScore: completeness
        )
        self.attentionResult = scoreResult

        // Alerts
        let alerts = AlertRuleEngine.evaluate(trend: trend)
        self.activeAlerts = alerts

        // Narrative
        let narrativeResult = WeeklyNarrativeGenerator.generate(trend: trend, alerts: alerts)
        self.narrative = narrativeResult

        // Persist
        do {
            try AttentionScoreCalculator.saveScore(
                result: scoreResult,
                client: client,
                weekStart: currentWeekStart,
                context: modelContext
            )
            try AlertRuleEngine.saveAlerts(
                alerts: alerts,
                client: client,
                weekStart: currentWeekStart,
                context: modelContext
            )
        } catch {
            // Non-fatal
        }
    }
}
