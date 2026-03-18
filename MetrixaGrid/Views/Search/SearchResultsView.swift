import SwiftUI

struct SearchResultsView: View {
    @EnvironmentObject var store: AppStore
    @ObservedObject var viewModel: SearchViewModel
    @Binding var isSearchActive: Bool

    var body: some View {
        resultsPanel
    }

    @ViewBuilder
    private var resultsPanel: some View {
        VStack(spacing: 0) {
            // Filter chips (only when there's a query)
            if !viewModel.query.isEmpty {
                SearchFilterChipsView(viewModel: viewModel, projects: store.projects)
                    .padding(.top, 8)
                    .background(Color.bgPrimary)
            }

            // Content area
            Group {
                if viewModel.isLoading {
                    skeletonView
                } else if viewModel.query.isEmpty {
                    recentSearchesView
                } else if viewModel.results.isEmpty {
                    emptyState
                } else {
                    resultsList
                }
            }
            .background(Color.bgPrimary)
        }
        .background(Color.bgPrimary)
    }

    // MARK: - Loading skeleton

    private var skeletonView: some View {
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { _ in ShimmerCell() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Recent searches

    private var recentSearchesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent Searches")
                    .font(AppFont.rounded(15, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                if !viewModel.recentSearches.isEmpty {
                    Button("Clear all") { viewModel.clearRecentSearches() }
                        .font(AppFont.standard(13))
                        .foregroundColor(.accentCyan)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            if viewModel.recentSearches.isEmpty {
                Text("No recent searches")
                    .font(AppFont.standard(14))
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentSearches, id: \.self) { search in
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 13))
                                .foregroundColor(.textSecondary)
                            Text(search)
                                .font(AppFont.standard(14))
                                .foregroundColor(.white)
                            Spacer()
                            Button {
                                viewModel.removeRecentSearch(search)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textTertiary)
                                    .padding(4)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.query = search
                        }

                        Divider()
                            .background(Color.white.opacity(0.05))
                    }
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 38))
                .foregroundColor(.textTertiary)
            Text("Nothing found for «\(viewModel.query)»")
                .font(AppFont.rounded(16, weight: .semibold))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            Text("Try different keywords or adjust filters")
                .font(AppFont.standard(13))
                .foregroundColor(.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Results list

    private var resultsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                if !viewModel.projectResults.isEmpty {
                    SearchResultSection(title: "Projects") {
                        ForEach(viewModel.projectResults) { result in
                            SearchResultCell(result: result, query: viewModel.query, projectName: "")
                        }
                    }
                }

                if !viewModel.measurementResults.isEmpty {
                    SearchResultSection(title: "Measurements") {
                        ForEach(viewModel.measurementResults) { result in
                            if case .measurement(let m) = result.kind {
                                let projName = store.projects.first { $0.id == m.projectId }?.name ?? ""
                                SearchResultCell(result: result, query: viewModel.query, projectName: projName)
                            }
                        }
                    }
                }

                if !viewModel.recentResults.isEmpty {
                    SearchResultSection(title: "Recent Activity") {
                        ForEach(viewModel.recentResults) { result in
                            SearchResultCell(result: result, query: viewModel.query, projectName: "")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Section wrapper

private struct SearchResultSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(AppFont.standard(11, weight: .semibold))
                .foregroundColor(.textTertiary)
                .padding(.leading, 4)
            VStack(spacing: 8) { content }
        }
    }
}

// MARK: - Shimmer skeleton cell

struct ShimmerCell: View {
    @State private var shimmerX: CGFloat = -200

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.bgCard)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.bgCard)
                    .frame(height: 13)
                    .frame(maxWidth: 180)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.bgCard)
                    .frame(height: 10)
                    .frame(maxWidth: 110)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.bgCard.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(shimmerOverlay)
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                shimmerX = 400
            }
        }
    }

    private var shimmerOverlay: some View {
        GeometryReader { _ in
            LinearGradient(
                colors: [Color.clear, Color(hex: "#243448").opacity(0.6), Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 100)
            .offset(x: shimmerX)
            .clipped()
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
