import SwiftUI

/// Horizontal row of filter chips shown below the search bar when search is active.
struct SearchFilterChipsView: View {
    @ObservedObject var viewModel: SearchViewModel
    let projects: [Project]

    private let staticChips = ["All", "Length", "Area", "Volume", "This Week", "This Month"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Static chips
                ForEach(staticChips, id: \.self) { chip in
                    SearchFilterChip(
                        label: chip,
                        isActive: viewModel.activeFilters.contains(chip)
                    ) {
                        viewModel.toggleFilter(chip)
                    }
                }

                // Project picker
                if !projects.isEmpty {
                    Menu {
                        Button("Clear project filter") { viewModel.toggleFilter("All") }
                        Divider()
                        ForEach(projects) { project in
                            Button(project.name) {
                                viewModel.toggleFilter("project:\(project.id)")
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "folder")
                                .font(.system(size: 11))
                            Text("+ Project")
                                .font(AppFont.standard(13))
                        }
                        .foregroundColor(Color(hex: "#CBD5E1"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.bgCard)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Single Chip

struct SearchFilterChip: View {
    let label: String
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(AppFont.standard(13))
                .foregroundColor(isActive ? Color(hex: "#0F172A") : Color(hex: "#CBD5E1"))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isActive ? Color.accentCyan : Color.bgCard)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            isActive ? Color.clear : Color.white.opacity(0.12),
                            lineWidth: 0.5
                        )
                )
        }
        .buttonStyle(NeonButtonStyle())
    }
}
