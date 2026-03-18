import SwiftUI

struct LiveValueDisplay: View {
    let value: String
    let unit: String

    @State private var pulse = false

    private var isEmpty: Bool { value.isEmpty }
    private var displayValue: String { value.isEmpty ? "0" : value }

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 6) {
            Text(displayValue)
                .font(.system(size: 32, weight: .semibold, design: .monospaced))
                .foregroundColor(isEmpty ? Color(hex: "#475569") : Color.accentCyan)
                .glow(color: isEmpty ? .clear : .accentCyan, radius: 4)

            Text(unit)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(hex: "#64748B"))
        }
        .scaleEffect(pulse ? 1.04 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: pulse)
        .onChange(of: value) { _ in
            pulse = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                pulse = false
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(hex: "#243448").opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
