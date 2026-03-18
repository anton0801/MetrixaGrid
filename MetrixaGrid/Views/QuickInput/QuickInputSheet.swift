import SwiftUI
import UIKit

struct QuickInputSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    var onSaved: (() -> Void)? = nil

    @State private var title = ""
    @State private var valueString = ""
    @State private var selectedUnit: MeasurementUnit = .cm
    @State private var selectedProjectId: UUID? = nil
    @State private var showSuggestions = false

    @FocusState private var titleFocused: Bool
    @State private var selectedDetent: PresentationDetent = .fraction(0.72)

    // MARK: - Derived

    private var suggestions: [String] {
        guard title.count >= 1 else { return [] }
        var seen = Set<String>()
        return store.measurements
            .map { $0.title }
            .filter { $0.localizedCaseInsensitiveContains(title) && $0.lowercased() != title.lowercased() }
            .filter { seen.insert($0).inserted }
            .prefix(4)
            .map { $0 }
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !valueString.isEmpty &&
        Double(valueString) != nil
    }

    private var selectedProjectName: String {
        store.projects.first { $0.id == selectedProjectId }?.name ?? "Project"
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "#1E293B").ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag handle
                Capsule()
                    .fill(Color(hex: "#475569"))
                    .frame(width: 36, height: 4)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {

                        // ── Row 1: Title + Project ──────────────────────
                        HStack(alignment: .top, spacing: 10) {
                            ZStack(alignment: .topLeading) {
                                TextField("Measurement name...", text: $title)
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(hex: "#F1F5F9"))
                                    .accentColor(.accentCyan)
                                    .focused($titleFocused)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 13)
                                    .background(Color(hex: "#263448"))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(titleFocused ? Color.accentCyan.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
                                    )
                                    .onChange(of: title) { newVal in
                                        showSuggestions = newVal.count >= 1 && !suggestions.isEmpty
                                    }

                                if showSuggestions {
                                    TitleSuggestionsView(suggestions: suggestions) { selected in
                                        title = selected
                                        showSuggestions = false
                                        titleFocused = false
                                    }
                                    .offset(y: 46)
                                    .zIndex(10)
                                }
                            }
                            .zIndex(showSuggestions ? 10 : 0)

                            // Project picker
                            Menu {
                                Button("No Project") { selectedProjectId = nil }
                                Divider()
                                ForEach(store.projects) { project in
                                    Button(project.name) { selectedProjectId = project.id }
                                }
                            } label: {
                                VStack(spacing: 2) {
                                    Image(systemName: "folder")
                                        .font(.system(size: 13))
                                    Text(selectedProjectId != nil ? selectedProjectName : "Project")
                                        .font(.system(size: 11, weight: .medium))
                                        .lineLimit(1)
                                }
                                .foregroundColor(selectedProjectId != nil ? .accentCyan : .textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 13)
                                .frame(width: 80)
                                .background(Color(hex: "#263448"))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 16)

                        // ── Divider ─────────────────────────────────────
                        Divider()
                            .background(Color.white.opacity(0.06))
                            .padding(.horizontal, 16)

                        // ── Unit selector ───────────────────────────────
                        UnitSelectorView(selectedUnit: $selectedUnit, valueString: $valueString)
                            .padding(.horizontal, 16)

                        // ── Divider ─────────────────────────────────────
                        Divider()
                            .background(Color.white.opacity(0.06))
                            .padding(.horizontal, 16)

                        // ── Live value display ──────────────────────────
                        LiveValueDisplay(value: valueString, unit: selectedUnit.symbol)
                            .padding(.horizontal, 16)

                        // ── Numpad ──────────────────────────────────────
                        NumpadView(
                            onTap: { key in
                                appendKey(key)
                            },
                            onBackspace: {
                                if !valueString.isEmpty { valueString.removeLast() }
                            },
                            onClear: {
                                valueString = ""
                            }
                        )
                        .padding(.horizontal, 16)

                        // ── Divider ─────────────────────────────────────
                        Divider()
                            .background(Color.white.opacity(0.06))
                            .padding(.horizontal, 16)

                        // ── Save button ─────────────────────────────────
                        Button(action: saveMeasurement) {
                            Text("Save Measurement")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(isValid ? Color(hex: "#0F172A") : Color(hex: "#475569"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(isValid ? Color.accentCyan : Color(hex: "#263448"))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!isValid)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .presentationDetents([.fraction(0.72), .large], selection: $selectedDetent)
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(20)
        .presentationBackground(Color(hex: "#1E293B"))
        .onChange(of: titleFocused) { focused in
            withAnimation(.springy) {
                selectedDetent = focused ? .large : .fraction(0.72)
            }
        }
    }

    // MARK: - Helpers

    private func appendKey(_ key: String) {
        let sep = Locale.current.decimalSeparator ?? "."
        // Prevent duplicate decimal separators
        if key == sep && valueString.contains(sep) { return }
        // Limit length
        if valueString.count >= 10 { return }
        // Prevent leading zeros (except "0.")
        if valueString == "0" && key != sep { valueString = key; return }
        valueString += key
    }

    private func saveMeasurement() {
        guard isValid, let value = Double(valueString) else { return }
        let m = Measurement(
            title: title.trimmingCharacters(in: .whitespaces),
            value: value,
            unit: selectedUnit,
            projectId: selectedProjectId,
            category: .general,
            note: ""
        )
        store.addMeasurement(m)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onSaved?()
        dismiss()
    }
}
