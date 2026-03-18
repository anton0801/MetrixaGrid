import SwiftUI
import UIKit

struct TemplateFormView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    let template: MeasurementTemplate
    let projectId: UUID?

    @State private var fieldValues: [UUID: String] = [:]
    @State private var fieldUnits: [UUID: MeasurementUnit] = [:]
    @State private var savedConfirmation = false

    // MARK: - Derived

    private var filledCount: Int {
        template.fields.filter { field in
            let val = fieldValues[field.id] ?? ""
            return !val.isEmpty && Double(val) != nil
        }.count
    }

    private var totalCount: Int { template.fields.count }

    private var allValid: Bool {
        totalCount > 0 && filledCount == totalCount
    }

    private var templateColor: Color { Color(hex: template.color) }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Hero header ─────────────────────────────────────
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: template.icon)
                                .font(.system(size: 20))
                                .foregroundColor(templateColor)
                            Text(template.name)
                                .font(AppFont.rounded(20, weight: .bold))
                                .foregroundColor(.white)
                        }

                        Text("\(filledCount) of \(totalCount) filled")
                            .font(AppFont.standard(13))
                            .foregroundColor(.textSecondary)

                        ProgressView(
                            value: Double(filledCount),
                            total: Double(max(totalCount, 1))
                        )
                        .tint(.accentCyan)
                        .padding(.horizontal, 24)
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 16)

                    // ── Fields list ─────────────────────────────────────
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(template.fields) { field in
                                TemplateFieldRow(
                                    field: field,
                                    valueText: bindingFor(field),
                                    selectedUnit: unitBindingFor(field)
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 120)
                    }
                }

                // ── Sticky save button ───────────────────────────────────
                VStack {
                    Spacer()
                    VStack(spacing: 10) {
                        if savedConfirmation {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.resultGreen)
                                Text("All measurements saved!")
                                    .font(AppFont.standard(14))
                                    .foregroundColor(.resultGreen)
                            }
                            .transition(.opacity)
                        }

                        Button(action: saveAll) {
                            Text("Save All (\(totalCount) measurements)")
                                .font(AppFont.rounded(16, weight: .semibold))
                                .foregroundColor(allValid ? Color(hex: "#0F172A") : Color(hex: "#475569"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(allValid ? Color.accentCyan : Color.bgCard)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!allValid)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.bgPrimary.opacity(0), Color.bgPrimary],
                            startPoint: .top, endPoint: .center
                        )
                    )
                }
            }
            .navigationTitle("Fill Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }

    // MARK: - Bindings

    private func bindingFor(_ field: TemplateField) -> Binding<String> {
        Binding(
            get: { fieldValues[field.id] ?? "" },
            set: { fieldValues[field.id] = $0 }
        )
    }

    private func unitBindingFor(_ field: TemplateField) -> Binding<MeasurementUnit> {
        Binding(
            get: { fieldUnits[field.id] ?? (MeasurementUnit(rawValue: field.defaultUnit) ?? .cm) },
            set: { fieldUnits[field.id] = $0 }
        )
    }

    // MARK: - Save

    private func saveAll() {
        guard allValid else { return }
        let templateTag = template.name
        for field in template.fields {
            guard let valueStr = fieldValues[field.id],
                  let value = Double(valueStr) else { continue }
            let unit = fieldUnits[field.id] ?? (MeasurementUnit(rawValue: field.defaultUnit) ?? .cm)
            let m = Measurement(
                title: "\(templateTag) — \(field.label)",
                value: value,
                unit: unit,
                projectId: projectId,
                category: .general,
                note: "Template: \(templateTag)"
            )
            store.addMeasurement(m)
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation { savedConfirmation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
    }
}

// MARK: - Template Field Row

struct TemplateFieldRow: View {
    let field: TemplateField
    @Binding var valueText: String
    @Binding var selectedUnit: MeasurementUnit

    private var isFilled: Bool {
        !valueText.isEmpty && Double(valueText) != nil
    }

    private var unitOptions: [MeasurementUnit] {
        switch field.defaultUnit {
        case "mm", "cm", "m", "in", "ft":
            return MeasurementUnit.lengthUnits
        case "mm²", "cm²", "m²", "ft²":
            return MeasurementUnit.areaUnits
        case "m³", "L":
            return MeasurementUnit.volumeUnits
        default:
            return MeasurementUnit.allCases
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(field.label)
                    .font(AppFont.standard(12, weight: .medium))
                    .foregroundColor(.textSecondary)

                TextField(field.hint.isEmpty ? "Enter value" : field.hint, text: $valueText)
                    .font(AppFont.mono(17, weight: .semibold))
                    .foregroundColor(.white)
                    .accentColor(.accentCyan)
                    .keyboardType(.decimalPad)
            }

            Spacer()

            // Unit picker
            Menu {
                ForEach(unitOptions, id: \.self) { unit in
                    Button(unit.symbol) { selectedUnit = unit }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedUnit.symbol)
                        .font(AppFont.mono(14, weight: .bold))
                        .foregroundColor(.accentCyan)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.bgElevated)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(14)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isFilled ? Color.accentCyan.opacity(0.35) : Color.white.opacity(0.06),
                    lineWidth: 1
                )
        )
    }
}
