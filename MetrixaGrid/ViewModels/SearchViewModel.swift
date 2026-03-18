import Foundation
import SwiftUI
import Combine

// MARK: - Search Result

struct SearchResult: Identifiable {
    enum ResultKind {
        case measurement(Measurement)
        case project(Project)
        case recent(HistoryEvent)
    }
    let id: UUID
    let kind: ResultKind
}

// MARK: - Search ViewModel

class SearchViewModel: ObservableObject {
    // MARK: Published
    @Published var query: String = ""
    @Published var results: [SearchResult] = []
    @Published var isLoading: Bool = false
    @Published var activeFilters: Set<String> = ["All"]
    @Published var recentSearches: [String] = []

    // MARK: Private
    private var cancellables = Set<AnyCancellable>()
    private weak var store: AppStore?
    private let recentSearchesKey = "metrixa_recent_searches"

    // MARK: Init

    init() {
        loadRecentSearches()

        $query
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] q in
                self?.performSearch(query: q)
            }
            .store(in: &cancellables)
    }

    func setup(store: AppStore) {
        self.store = store
    }

    // MARK: Search

    func performSearch(query: String) {
        guard !query.isEmpty else {
            results = []
            isLoading = false
            return
        }
        isLoading = true

        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self, let store = self.store else { return }
            let q = query.lowercased()

            // ── Measurements ────────────────────────────────────────────
            var mResults = store.measurements.filter { m in
                m.title.lowercased().contains(q) ||
                m.displayValue.contains(q) ||
                String(m.value).contains(q) ||
                m.unit.symbol.lowercased().contains(q) ||
                m.note.lowercased().contains(q)
            }

            // Apply unit-category filters
            if self.activeFilters.contains("Length") {
                mResults = mResults.filter { $0.unit.category == .length }
            } else if self.activeFilters.contains("Area") {
                mResults = mResults.filter { $0.unit.category == .area }
            } else if self.activeFilters.contains("Volume") {
                mResults = mResults.filter { $0.unit.category == .volume }
            }

            // Apply time filters
            let now = Date()
            let cal = Calendar.current
            if self.activeFilters.contains("This Week") {
                let weekAgo = cal.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
                mResults = mResults.filter { $0.date >= weekAgo }
            } else if self.activeFilters.contains("This Month") {
                let monthAgo = cal.date(byAdding: .month, value: -1, to: now) ?? now
                mResults = mResults.filter { $0.date >= monthAgo }
            }

            // Apply project filters
            for filter in self.activeFilters {
                if filter.hasPrefix("project:") {
                    let idStr = String(filter.dropFirst("project:".count))
                    if let projectId = UUID(uuidString: idStr) {
                        mResults = mResults.filter { $0.projectId == projectId }
                    }
                }
            }

            // ── Projects ────────────────────────────────────────────────
            let pResults = store.projects.filter { p in
                p.name.lowercased().contains(q) ||
                p.description.lowercased().contains(q)
            }

            // ── Recent history (last 5) ──────────────────────────────────
            let recentEvents = Array(store.history.prefix(5))

            var combined: [SearchResult] = []
            combined += pResults.map { SearchResult(id: $0.id, kind: .project($0)) }
            combined += mResults.map { SearchResult(id: $0.id, kind: .measurement($0)) }
            combined += recentEvents.map { SearchResult(id: $0.id, kind: .recent($0)) }

            DispatchQueue.main.async {
                self.results = combined
                self.isLoading = false
            }
        }
    }

    // MARK: Filters

    func toggleFilter(_ label: String) {
        if label == "All" {
            activeFilters = ["All"]
        } else {
            activeFilters.remove("All")
            if activeFilters.contains(label) {
                activeFilters.remove(label)
                if activeFilters.isEmpty { activeFilters = ["All"] }
            } else {
                activeFilters.insert(label)
            }
        }
        performSearch(query: query)
    }

    // MARK: Grouped results

    var projectResults: [SearchResult] {
        results.filter { if case .project = $0.kind { return true }; return false }
    }

    var measurementResults: [SearchResult] {
        results.filter { if case .measurement = $0.kind { return true }; return false }
    }

    var recentResults: [SearchResult] {
        results.filter { if case .recent = $0.kind { return true }; return false }
    }

    // MARK: Recent searches

    func addRecentSearch(_ query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        recentSearches.removeAll { $0 == query }
        recentSearches.insert(query, at: 0)
        if recentSearches.count > 10 { recentSearches = Array(recentSearches.prefix(10)) }
        saveRecentSearches()
    }

    func removeRecentSearch(_ query: String) {
        recentSearches.removeAll { $0 == query }
        saveRecentSearches()
    }

    func clearRecentSearches() {
        recentSearches.removeAll()
        saveRecentSearches()
    }

    // MARK: Persistence

    private func saveRecentSearches() {
        if let data = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(data, forKey: recentSearchesKey)
        }
    }

    private func loadRecentSearches() {
        guard let data = UserDefaults.standard.data(forKey: recentSearchesKey),
              let saved = try? JSONDecoder().decode([String].self, from: data) else { return }
        recentSearches = saved
    }
}
