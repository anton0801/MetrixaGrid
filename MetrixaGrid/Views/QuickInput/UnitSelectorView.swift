import SwiftUI
import UIKit

/// Segmented unit picker for the Quick Input sheet.
/// Automatically converts the current entered value when the unit changes.
struct UnitSelectorView: View {
    @Binding var selectedUnit: MeasurementUnit
    @Binding var valueString: String

    private let units: [MeasurementUnit] = [.mm, .cm, .m, .inch, .ft]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(units, id: \.self) { unit in
                Button {
                    guard unit != selectedUnit else { return }
                    let feedback = UISelectionFeedbackGenerator()
                    feedback.selectionChanged()
                    autoConvert(to: unit)
                    withAnimation(.springyFast) {
                        selectedUnit = unit
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(unit.symbol)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedUnit == unit ? Color.accentCyan : Color(hex: "#64748B"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)

                        Rectangle()
                            .fill(selectedUnit == unit ? Color.accentCyan : Color.clear)
                            .frame(height: 1.5)
                    }
                }
                .buttonStyle(NeonButtonStyle())
            }
        }
        .background(Color.bgCard.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Conversion

    private func autoConvert(to newUnit: MeasurementUnit) {
        guard let val = Double(valueString), val > 0,
              let converted = convertLength(val, from: selectedUnit, to: newUnit) else { return }
        let formatted: String
        if converted == Double(Int(converted)) {
            formatted = "\(Int(converted))"
        } else {
            // Trim trailing zeros but keep up to 4 decimal places
            formatted = String(format: "%.4f", converted)
                .trimmingCharacters(in: CharacterSet(charactersIn: "0"))
                .trimmingCharacters(in: CharacterSet(charactersIn: "."))
        }
        valueString = formatted.isEmpty ? "0" : formatted
    }

    private func convertLength(_ value: Double, from: MeasurementUnit, to: MeasurementUnit) -> Double? {
        guard from.category == .length, to.category == .length else { return nil }
        // To metres
        let metres: Double
        switch from {
        case .mm:    metres = value / 1000
        case .cm:    metres = value / 100
        case .m:     metres = value
        case .inch:  metres = value * 0.0254
        case .ft:    metres = value * 0.3048
        default:     return nil
        }
        // From metres
        switch to {
        case .mm:    return metres * 1000
        case .cm:    return metres * 100
        case .m:     return metres
        case .inch:  return metres / 0.0254
        case .ft:    return metres / 0.3048
        default:     return nil
        }
    }
}
