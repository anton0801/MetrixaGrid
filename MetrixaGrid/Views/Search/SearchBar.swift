import SwiftUI

/// Collapsible search bar — shows a magnifier icon when inactive,
/// expands with a spring animation when tapped.
struct SearchBar: View {
    @Binding var text: String
    @Binding var isActive: Bool

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            // ── Input field ──────────────────────────────────────────────
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundColor(isActive ? Color.accentCyan : Color.textSecondary)

                if isActive {
                    TextField("Search measurements, projects...", text: $text)
                        .font(AppFont.standard(15))
                        .foregroundColor(.white)
                        .accentColor(.accentCyan)
                        .focused($isFocused)
                        .submitLabel(.search)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: isActive ? .infinity : 44)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color.accentCyan.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1)
            )
            .onTapGesture {
                guard !isActive else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isActive = true
                }
                // Small delay so layout settles before focus
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isFocused = true
                }
            }

            // ── Cancel button ────────────────────────────────────────────
            if isActive {
                Button("Cancel") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isActive = false
                        text = ""
                    }
                    isFocused = false
                }
                .font(AppFont.standard(14))
                .foregroundColor(.accentCyan)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isActive)
        .onChange(of: isActive) { active in
            if !active { isFocused = false }
        }
    }
}
