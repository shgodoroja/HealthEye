import SwiftUI

struct MetricCompletenessRowView: View {
    let week: WeeklyCompleteness

    var body: some View {
        HStack {
            Text(week.weekStart, format: .dateTime.month(.abbreviated).day())
                .frame(width: 100, alignment: .leading)
                .font(.callout)

            metricIcon(days: week.daysWithSleep)
                .frame(width: 50)
            metricIcon(days: week.daysWithHRV)
                .frame(width: 50)
            metricIcon(days: week.daysWithRestingHR)
                .frame(width: 50)
            metricIcon(days: week.daysWithWorkout)
                .frame(width: 60)
            metricIcon(days: week.daysWithSteps)
                .frame(width: 50)

            Text(String(format: "%.0f%%", week.score * 100))
                .frame(width: 60)
                .font(.callout)
                .fontWeight(.medium)
        }
        .padding(.vertical, 2)
        .help(week.notes)
    }

    private func metricIcon(days: Int) -> some View {
        Group {
            if days == 7 {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if days > 0 {
                Text("\(days)/7")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                Image(systemName: "minus.circle")
                    .foregroundStyle(.red.opacity(0.5))
            }
        }
    }
}
