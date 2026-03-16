import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var showClearConfirm = false
    @State private var filterType: HistoryEventType? = nil
    
    var filtered: [HistoryEvent] {
        guard let type = filterType else { return store.history }
        return store.history.filter { $0.type == type }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", isSelected: filterType == nil) {
                                withAnimation(.springyFast) { filterType = nil }
                            }
                            ForEach([HistoryEventType.addedMeasurement, .editedMeasurement, .deletedMeasurement, .addedProject, .convertedUnit, .calculation], id: \.self) { type in
                                FilterChip(label: type.rawValue.replacingOccurrences(of: " ", with: "\n"), isSelected: filterType == type, color: type.color) {
                                    withAnimation(.springyFast) {
                                        filterType = filterType == type ? nil : type
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    
                    if filtered.isEmpty {
                        EmptyStateView(icon: "clock", message: "No history yet.")
                    } else {
                        ScrollView(showsIndicators: false) {
                            // Group by date
                            LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
                                ForEach(groupedHistory, id: \.0) { date, events in
                                    Section {
                                        ForEach(events) { event in
                                            HistoryEventRow(event: event)
                                                .padding(.horizontal, 16)
                                        }
                                    } header: {
                                        HStack {
                                            Text(date)
                                                .font(AppFont.standard(12, weight: .semibold))
                                                .foregroundColor(.textSecondary)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 6)
                                            Spacer()
                                        }
                                        .background(Color.bgPrimary.opacity(0.95))
                                    }
                                }
                            }
                            .padding(.bottom, 60)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }.foregroundColor(.accentCyan)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !store.history.isEmpty {
                        Button {
                            showClearConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.errorRed)
                        }
                    }
                }
            }
        }
        .alert("Clear History?", isPresented: $showClearConfirm) {
            Button("Clear All", role: .destructive) { store.clearHistory() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all history.")
        }
    }
    
    var groupedHistory: [(String, [HistoryEvent])] {
        let grouped = Dictionary(grouping: filtered) { event -> String in
            let cal = Calendar.current
            if cal.isDateInToday(event.date) { return "Today" }
            if cal.isDateInYesterday(event.date) { return "Yesterday" }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: event.date)
        }
        return grouped.sorted { $0.key > $1.key }.map { ($0.key, $0.value) }
    }
}

struct HistoryEventRow: View {
    let event: HistoryEvent
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(event.type.color.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: event.type.icon)
                    .font(.system(size: 15))
                    .foregroundColor(event.type.color)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(event.type.rawValue)
                    .font(AppFont.standard(13, weight: .semibold))
                    .foregroundColor(event.type.color)
                Text(event.title)
                    .font(AppFont.standard(14))
                    .foregroundColor(.white)
                Text(event.detail)
                    .font(AppFont.mono(12))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(event.date, style: .time)
                .font(AppFont.standard(11))
                .foregroundColor(.textTertiary)
        }
        .padding(12)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
}
