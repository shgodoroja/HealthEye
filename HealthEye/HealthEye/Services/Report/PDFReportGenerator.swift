import Foundation
import CoreGraphics
import CoreText
import PDFKit

// Cross-platform font and color aliases — CoreText/CoreGraphics drawing works
// identically on macOS and iPadOS; only the high-level wrapper types differ.
#if canImport(AppKit)
import AppKit
private typealias PlatformFont  = NSFont
private typealias PlatformColor = NSColor
#elseif canImport(UIKit)
import UIKit
private typealias PlatformFont  = UIFont
private typealias PlatformColor = UIColor
#endif

struct ReportData {
    let clientName: String
    let weekStart: Date
    let weekEnd: Date
    let trend: MetricTrend
    let scoreResult: AttentionScoreResult
    let alerts: [AlertResult]
    let narrative: NarrativeResult
    let completenessScore: Double
}

struct PDFReportGenerator {

    // Page dimensions: US Letter (612 x 792 points)
    private nonisolated static let pageWidth: CGFloat = 612
    private nonisolated static let pageHeight: CGFloat = 792
    private nonisolated static let margin: CGFloat = 50
    private nonisolated static let contentWidth: CGFloat = 612 - 100 // pageWidth - 2 * margin

    private nonisolated static var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }

    /// Generates PDF data from report data.
    nonisolated static func generate(data: ReportData) -> Data {
        let pdfData = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return Data()
        }

        var currentY: CGFloat = 0
        var pageStarted = false

        func beginPage() {
            context.beginPDFPage(nil)
            pageStarted = true
            currentY = pageHeight - margin
        }

        func endPage() {
            if pageStarted {
                context.endPDFPage()
                pageStarted = false
            }
        }

        func ensureSpace(_ needed: CGFloat) {
            if !pageStarted || currentY - needed < margin {
                if pageStarted { endPage() }
                beginPage()
            }
        }

        // --- Page 1 ---
        beginPage()

        // Header
        currentY = drawHeader(context: context, data: data, y: currentY)
        currentY -= 20

        // Attention Score
        ensureSpace(80)
        currentY = drawAttentionScore(context: context, data: data, y: currentY)
        currentY -= 20

        // What Changed This Week
        ensureSpace(60)
        currentY = drawNarrative(context: context, data: data, y: currentY)
        currentY -= 20

        // Metric Trends Table
        ensureSpace(140)
        currentY = drawMetricTrends(context: context, data: data, y: currentY)
        currentY -= 20

        // Active Alerts
        if !data.alerts.isEmpty {
            ensureSpace(60)
            currentY = drawAlerts(context: context, data: data, y: currentY)
            currentY -= 20
        }

        // Suggested Messages
        if !data.narrative.suggestedMessages.isEmpty {
            ensureSpace(80)
            currentY = drawMessages(context: context, data: data, y: currentY)
        }

        // Footer
        drawFooter(context: context)

        endPage()
        context.closePDF()

        return pdfData as Data
    }

    /// Saves PDF data to the specified file URL.
    nonisolated static func save(data: Data, to url: URL) throws {
        try data.write(to: url, options: .atomic)
    }

    // MARK: - Drawing Sections

    private nonisolated static func drawHeader(context: CGContext, data: ReportData, y: CGFloat) -> CGFloat {
        var currentY = y

        // Title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: PlatformFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: PlatformColor.black,
        ]
        let title = "Weekly Health Report"
        drawText(title, at: CGPoint(x: margin, y: currentY - 22), attributes: titleAttrs, context: context)
        currentY -= 32

        // Client name
        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: PlatformFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: PlatformColor.darkGray,
        ]
        drawText(data.clientName, at: CGPoint(x: margin, y: currentY - 16), attributes: nameAttrs, context: context)
        currentY -= 26

        // Week range and generation info
        let infoAttrs: [NSAttributedString.Key: Any] = [
            .font: PlatformFont.systemFont(ofSize: 11),
            .foregroundColor: PlatformColor.gray,
        ]
        let weekRange = "Week: \(dateFormatter.string(from: data.weekStart)) – \(dateFormatter.string(from: data.weekEnd))"
        drawText(weekRange, at: CGPoint(x: margin, y: currentY - 11), attributes: infoAttrs, context: context)
        currentY -= 18

        let generated = "Generated: \(dateFormatter.string(from: Date()))  •  Score version: 1.0"
        drawText(generated, at: CGPoint(x: margin, y: currentY - 11), attributes: infoAttrs, context: context)
        currentY -= 18

        // Divider line
        currentY -= 4
        context.setStrokeColor(CGColor(gray: 0.75, alpha: 1.0))
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: margin, y: currentY))
        context.addLine(to: CGPoint(x: pageWidth - margin, y: currentY))
        context.strokePath()
        currentY -= 4

        return currentY
    }

    private nonisolated static func drawAttentionScore(context: CGContext, data: ReportData, y: CGFloat) -> CGFloat {
        var currentY = y

        // Section title
        currentY = drawSectionTitle("Attention Score", context: context, y: currentY)

        let score = data.scoreResult
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: PlatformFont.systemFont(ofSize: 13),
            .foregroundColor: PlatformColor.black,
        ]

        let scoreLine = String(format: "Score: %.0f / 100  —  %@", score.total, score.bucket.displayName)
        drawText(scoreLine, at: CGPoint(x: margin, y: currentY - 13), attributes: bodyAttrs, context: context)
        currentY -= 22

        let detailAttrs: [NSAttributedString.Key: Any] = [
            .font: PlatformFont.systemFont(ofSize: 11),
            .foregroundColor: PlatformColor.darkGray,
        ]
        let breakdown = String(
            format: "Recovery (Sleep: %.1f, HRV: %.1f, RHR: %.1f)  •  Workout: %.1f  •  Steps: %.1f  •  Completeness penalty: %.1f",
            score.recoverySleep, score.recoveryHrv, score.recoveryRestingHr,
            score.workout, score.steps, score.completenessPenalty
        )
        drawText(breakdown, at: CGPoint(x: margin, y: currentY - 11), attributes: detailAttrs, context: context)
        currentY -= 18

        return currentY
    }

    private nonisolated static func drawNarrative(context: CGContext, data: ReportData, y: CGFloat) -> CGFloat {
        var currentY = y

        currentY = drawSectionTitle("What Changed This Week", context: context, y: currentY)

        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: PlatformFont.systemFont(ofSize: 12),
            .foregroundColor: PlatformColor.black,
        ]

        let lines = wrapText(data.narrative.summary, maxWidth: contentWidth, font: PlatformFont.systemFont(ofSize: 12))
        for line in lines {
            drawText(line, at: CGPoint(x: margin, y: currentY - 12), attributes: bodyAttrs, context: context)
            currentY -= 18
        }

        return currentY
    }

    private nonisolated static func drawMetricTrends(context: CGContext, data: ReportData, y: CGFloat) -> CGFloat {
        var currentY = y

        currentY = drawSectionTitle("Metric Trends", context: context, y: currentY)

        // Table header
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: PlatformFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: PlatformColor.darkGray,
        ]
        let colX: [CGFloat] = [margin, margin + 120, margin + 240, margin + 380]
        let headers = ["Metric", "Recent Avg (7d)", "Baseline Avg (28d)", "Change"]

        for (i, header) in headers.enumerated() {
            drawText(header, at: CGPoint(x: colX[i], y: currentY - 11), attributes: headerAttrs, context: context)
        }
        currentY -= 18

        // Divider
        context.setStrokeColor(CGColor(gray: 0.75, alpha: 1.0))
        context.setLineWidth(0.3)
        context.move(to: CGPoint(x: margin, y: currentY))
        context.addLine(to: CGPoint(x: pageWidth - margin, y: currentY))
        context.strokePath()
        currentY -= 6

        let rowAttrs: [NSAttributedString.Key: Any] = [
            .font: PlatformFont.systemFont(ofSize: 11),
            .foregroundColor: PlatformColor.black,
        ]

        let trend = data.trend
        let metrics: [(String, Double?, Double?, Double?)] = [
            ("Sleep (min)", trend.recent.sleepAvg, trend.baseline.sleepAvg, trend.sleepDelta),
            ("HRV (ms)", trend.recent.hrvAvg, trend.baseline.hrvAvg, trend.hrvDelta),
            ("Resting HR (bpm)", trend.recent.restingHrAvg, trend.baseline.restingHrAvg, trend.restingHrDelta),
            ("Workout (min)", trend.recent.workoutAvg, trend.baseline.workoutAvg, trend.workoutDelta),
            ("Steps", trend.recent.stepsAvg, trend.baseline.stepsAvg, trend.stepsDelta),
        ]

        for (name, recent, baseline, delta) in metrics {
            drawText(name, at: CGPoint(x: colX[0], y: currentY - 11), attributes: rowAttrs, context: context)
            drawText(formatOptional(recent), at: CGPoint(x: colX[1], y: currentY - 11), attributes: rowAttrs, context: context)
            drawText(formatOptional(baseline), at: CGPoint(x: colX[2], y: currentY - 11), attributes: rowAttrs, context: context)
            drawText(formatDelta(delta), at: CGPoint(x: colX[3], y: currentY - 11), attributes: rowAttrs, context: context)
            currentY -= 18
        }

        return currentY
    }

    private nonisolated static func drawAlerts(context: CGContext, data: ReportData, y: CGFloat) -> CGFloat {
        var currentY = y

        currentY = drawSectionTitle("Active Alerts", context: context, y: currentY)

        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: PlatformFont.systemFont(ofSize: 11),
            .foregroundColor: PlatformColor.black,
        ]
        let severityAttrs: [NSAttributedString.Key: Any] = [
            .font: PlatformFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: PlatformColor.black,
        ]

        for alert in data.alerts {
            let severityLabel = "[\(alert.severity.rawValue.uppercased())]"
            drawText(severityLabel, at: CGPoint(x: margin, y: currentY - 11), attributes: severityAttrs, context: context)
            drawText(alert.explanation, at: CGPoint(x: margin + 60, y: currentY - 11), attributes: bodyAttrs, context: context)
            currentY -= 18
        }

        return currentY
    }

    private nonisolated static func drawMessages(context: CGContext, data: ReportData, y: CGFloat) -> CGFloat {
        var currentY = y

        currentY = drawSectionTitle("Suggested Messages", context: context, y: currentY)

        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: PlatformFont.systemFont(ofSize: 11),
            .foregroundColor: PlatformColor.black,
        ]

        for (index, message) in data.narrative.suggestedMessages.enumerated() {
            let prefix = "\(index + 1). "
            let lines = wrapText(prefix + message, maxWidth: contentWidth - 10, font: PlatformFont.systemFont(ofSize: 11))
            for line in lines {
                drawText(line, at: CGPoint(x: margin + 5, y: currentY - 11), attributes: bodyAttrs, context: context)
                currentY -= 16
            }
            currentY -= 4
        }

        return currentY
    }

    private nonisolated static func drawFooter(context: CGContext) {
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: PlatformFont.systemFont(ofSize: 9),
            .foregroundColor: PlatformColor.gray,
        ]
        drawText(
            "Generated by Arclens  •  Confidential  •  Not medical advice — for coaching insights only",
            at: CGPoint(x: margin, y: 30),
            attributes: footerAttrs,
            context: context
        )
    }

    // MARK: - Drawing Helpers

    private nonisolated static func drawSectionTitle(_ title: String, context: CGContext, y: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: PlatformFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: PlatformColor.black,
        ]
        drawText(title, at: CGPoint(x: margin, y: y - 14), attributes: attrs, context: context)
        return y - 24
    }

    private nonisolated static func drawText(_ text: String, at point: CGPoint, attributes: [NSAttributedString.Key: Any], context: CGContext) {
        let attrString = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attrString)

        context.saveGState()
        context.textPosition = point
        CTLineDraw(line, context)
        context.restoreGState()
    }

    private nonisolated static func wrapText(_ text: String, maxWidth: CGFloat, font: PlatformFont) -> [String] {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let attrString = NSAttributedString(string: text, attributes: attrs)
        let size = attrString.size()

        if size.width <= maxWidth {
            return [text]
        }

        // Simple word-wrap
        let words = text.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        var lines: [String] = []
        var currentLine = ""

        for word in words {
            let testLine = currentLine.isEmpty ? word : currentLine + " " + word
            let testAttr = NSAttributedString(string: testLine, attributes: attrs)
            if testAttr.size().width > maxWidth && !currentLine.isEmpty {
                lines.append(currentLine)
                currentLine = word
            } else {
                currentLine = testLine
            }
        }
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }

        return lines
    }

    private nonisolated static func formatOptional(_ value: Double?) -> String {
        guard let v = value else { return "—" }
        return String(format: "%.1f", v)
    }

    private nonisolated static func formatDelta(_ value: Double?) -> String {
        guard let v = value else { return "—" }
        let sign = v >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, v)
    }
}
