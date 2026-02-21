import SwiftUI

struct AttentionFilterView: View {
    @Binding var selectedFilter: AttentionBucket?

    var body: some View {
        HStack(spacing: 6) {
            filterChip(label: "All", bucket: nil)
            filterChip(label: "High", bucket: .high)
            filterChip(label: "Medium", bucket: .medium)
            filterChip(label: "Low", bucket: .low)
        }
        .padding(.vertical, 4)
    }

    private func filterChip(label: String, bucket: AttentionBucket?) -> some View {
        let isSelected = selectedFilter == bucket

        return Button {
            selectedFilter = bucket
        } label: {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    isSelected
                        ? chipColor(bucket).opacity(0.2)
                        : Color.secondary.opacity(0.1),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? chipColor(bucket) : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func chipColor(_ bucket: AttentionBucket?) -> Color {
        guard let bucket = bucket else { return .accentColor }
        switch bucket {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}
