import SwiftUI

struct TemplatesGridView: View {
    @ObservedObject var templateStore: TemplateStore
    @Binding var selectedTemplate: MeasurementTemplate?
    let onSkip: () -> Void
    let onUseTemplate: () -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ──────────────────────────────────────────────
                VStack(spacing: 6) {
                    Text("Choose a Template")
                        .font(AppFont.rounded(22, weight: .bold))
                        .foregroundColor(.white)
                    Text("Start from a preset or add manually")
                        .font(AppFont.standard(14))
                        .foregroundColor(.textSecondary)
                }
                .padding(.top, 28)
                .padding(.bottom, 20)

                // ── Grid ────────────────────────────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {

                        // Built-in section
                        sectionLabel("BUILT-IN")

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(TemplateStore.builtIn.filter { !$0.isCustom }) { template in
                                TemplateCard(
                                    template: template,
                                    isSelected: selectedTemplate?.id == template.id
                                ) {
                                    withAnimation(.springyFast) { selectedTemplate = template }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Custom templates section
                        if !templateStore.customTemplates.isEmpty {
                            sectionLabel("YOUR TEMPLATES")
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(templateStore.customTemplates) { template in
                                    TemplateCard(
                                        template: template,
                                        isSelected: selectedTemplate?.id == template.id,
                                        showCustomBadge: true
                                    ) {
                                        withAnimation(.springyFast) { selectedTemplate = template }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // "Custom" blank-slate card
                        sectionLabel("FROM SCRATCH")
                        LazyVGrid(columns: columns, spacing: 12) {
                            if let customCard = TemplateStore.builtIn.last {
                                TemplateCard(
                                    template: customCard,
                                    isSelected: selectedTemplate?.id == customCard.id
                                ) {
                                    withAnimation(.springyFast) { selectedTemplate = customCard }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 24)
                }

                Spacer(minLength: 0)

                // ── Footer ───────────────────────────────────────────────
                VStack(spacing: 12) {
                    if selectedTemplate != nil {
                        Button(action: onUseTemplate) {
                            Text("Use Template")
                                .font(AppFont.rounded(16, weight: .semibold))
                                .foregroundColor(Color(hex: "#0F172A"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.accentCyan)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Button(action: onSkip) {
                        Text("Skip — enter manually")
                            .font(AppFont.standard(14))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.bottom, 20)
                }
                .animation(.springy, value: selectedTemplate?.id)
            }
        }
    }

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(AppFont.standard(11, weight: .semibold))
            .foregroundColor(.textTertiary)
            .padding(.horizontal, 16)
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: MeasurementTemplate
    let isSelected: Bool
    var showCustomBadge: Bool = false
    let onTap: () -> Void

    private var templateColor: Color { Color(hex: template.color) }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Image(systemName: template.icon)
                        .font(.system(size: 22))
                        .foregroundColor(templateColor)
                    Spacer()
                    if showCustomBadge {
                        Text("Custom")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.bgElevated)
                            .clipShape(Capsule())
                    }
                }

                Text(template.name)
                    .font(AppFont.rounded(14, weight: .semibold))
                    .foregroundColor(.white)

                Text(template.fields.isEmpty ? "Build custom" : "\(template.fields.count) fields")
                    .font(AppFont.standard(11))
                    .foregroundColor(.textSecondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? Color.accentCyan : Color.white.opacity(0.06),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.springyFast, value: isSelected)
        }
        .buttonStyle(NeonButtonStyle())
    }
}
