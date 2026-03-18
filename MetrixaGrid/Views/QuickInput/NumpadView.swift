import SwiftUI
import UIKit

struct NumpadView: View {
    let onTap: (String) -> Void
    let onBackspace: () -> Void
    let onClear: () -> Void

    private let rows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"],
    ]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        NumpadKeyButton(
                            key: key,
                            onTap: onTap,
                            onBackspace: onBackspace,
                            onClear: onClear
                        )
                    }
                }
            }
        }
    }
}

private struct NumpadKeyButton: View {
    let key: String
    let onTap: (String) -> Void
    let onBackspace: () -> Void
    let onClear: () -> Void

    var isAction: Bool { key == "⌫" }

    /// Decimal separator from locale — replaces the "." key on display
    var displayKey: String {
        if key == "." {
            return Locale.current.decimalSeparator ?? "."
        }
        return key
    }

    var body: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            if key == "⌫" {
                onBackspace()
            } else if key == "." {
                onTap(Locale.current.decimalSeparator ?? ".")
            } else {
                onTap(key)
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isAction ? Color(hex: "#1E293B") : Color(hex: "#243448"))

                if key == "⌫" {
                    Image(systemName: "delete.backward")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(hex: "#F1F5F9"))
                } else {
                    Text(displayKey)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(Color(hex: "#F1F5F9"))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
        }
        .buttonStyle(NeonButtonStyle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    if key == "⌫" {
                        let impact = UINotificationFeedbackGenerator()
                        impact.notificationOccurred(.warning)
                        onClear()
                    }
                }
        )
    }
}
