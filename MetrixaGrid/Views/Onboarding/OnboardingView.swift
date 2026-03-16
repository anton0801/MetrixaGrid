import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Save measurements\ninstantly",
            subtitle: "Store dimensions, distances and areas in seconds.",
            icon: "ruler.fill",
            accent: Color.accentCyan,
            illustration: .ruler
        ),
        OnboardingPage(
            title: "Organize by\nprojects",
            subtitle: "Group measurements for rooms, furniture or equipment.",
            icon: "folder.fill",
            accent: Color.accentMint,
            illustration: .projects
        ),
        OnboardingPage(
            title: "Use built-in\ncalculators",
            subtitle: "Quickly calculate area, volume and material coverage.",
            icon: "function",
            accent: Color.accentViolet,
            illustration: .calculators
        )
    ]
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            
            // Background gradient for current page
            RadialGradient(
                gradient: Gradient(colors: [pages[currentPage].accent.opacity(0.15), Color.clear]),
                center: .init(x: 0.5, y: 0.3),
                startRadius: 0,
                endRadius: 350
            )
            .ignoresSafeArea()
            .animation(.smooth, value: currentPage)
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation(.springy) { hasCompletedOnboarding = true }
                        }
                        .font(AppFont.standard(15, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    } else {
                        Color.clear.frame(height: 44).padding(.top, 20)
                    }
                }
                
                // Pages
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        OnboardingPageView(page: pages[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.springy, value: currentPage)
                
                // Bottom controls
                VStack(spacing: 28) {
                    // Dot indicators
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(i == currentPage ? pages[currentPage].accent : Color.textTertiary)
                                .frame(width: i == currentPage ? 24 : 8, height: 6)
                                .animation(.springy, value: currentPage)
                        }
                    }
                    
                    // Action button
                    Button {
                        withAnimation(.springy) {
                            if currentPage < pages.count - 1 {
                                currentPage += 1
                            } else {
                                hasCompletedOnboarding = true
                            }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Text(currentPage < pages.count - 1 ? "Next" : "Start")
                                .font(AppFont.rounded(17, weight: .semibold))
                                .foregroundColor(.bgPrimary)
                            Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.bgPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(PrimaryButtonStyle(gradient: LinearGradient(
                        colors: [pages[currentPage].accent, pages[currentPage].accent.opacity(0.7)],
                        startPoint: .leading, endPoint: .trailing
                    )))
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Page Data
enum OnboardingIllustration {
    case ruler, projects, calculators
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let illustration: OnboardingIllustration
}

// MARK: - Single Page
struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var appeared = false
    @State private var tapCount = 0
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Illustration
            ZStack {
                switch page.illustration {
                case .ruler: RulerIllustration(accent: page.accent, tapCount: $tapCount)
                case .projects: ProjectsIllustration(accent: page.accent)
                case .calculators: CalculatorsIllustration(accent: page.accent)
                }
            }
            .frame(height: 240)
            .onTapGesture { withAnimation(.springy) { tapCount += 1 } }
            
            // Text
            VStack(spacing: 12) {
                Text(page.title)
                    .font(AppFont.rounded(30, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .slideIn(delay: 0.1)
                
                Text(page.subtitle)
                    .font(AppFont.standard(16))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .slideIn(delay: 0.2)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Illustrations
struct RulerIllustration: View {
    let accent: Color
    @Binding var tapCount: Int
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Ruler body
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.bgCard)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(accent.opacity(0.4), lineWidth: 1.5))
                .frame(width: 260, height: 52)
            
            // Tick marks
            HStack(spacing: 0) {
                ForEach(0..<13) { i in
                    VStack {
                        Rectangle()
                            .fill(accent.opacity(i % 5 == 0 ? 0.8 : 0.3))
                            .frame(width: 1, height: i % 5 == 0 ? 16 : 8)
                        if i % 5 == 0 {
                            Text("\(i)")
                                .font(AppFont.mono(8))
                                .foregroundColor(accent.opacity(0.6))
                        }
                    }
                    .frame(width: 20)
                }
            }
            .frame(width: 260)
            
            // Measurement arrow
            HStack(spacing: 0) {
                Image(systemName: "arrowtriangle.left.fill")
                    .font(.system(size: 8))
                    .foregroundColor(accent)
                Rectangle()
                    .fill(accent)
                    .frame(width: 100 + CGFloat(tapCount % 4) * 20, height: 2)
                Image(systemName: "arrowtriangle.right.fill")
                    .font(.system(size: 8))
                    .foregroundColor(accent)
            }
            .offset(y: 30)
            .animation(.springy, value: tapCount)
            
            // Marker pin
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(accent)
                .glow(color: accent, radius: 6)
                .offset(x: 30 + CGFloat(tapCount % 4) * 10, y: -30)
                .animation(.springy, value: tapCount)
        }
    }
}

struct ProjectsIllustration: View {
    let accent: Color
    
    let cards = [
        ("Kitchen", "4.8 m", "#22D3EE"),
        ("Workshop", "2.4 m", "#A78BFA"),
        ("Office", "3.6 m", "#2DD4BF"),
    ]
    
    var body: some View {
        VStack(spacing: -12) {
            ForEach(Array(cards.enumerated()), id: \.0) { i, card in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(hex: card.2).opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "folder.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: card.2))
                        )
                    Text(card.0)
                        .font(AppFont.rounded(14, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(card.1)
                        .font(AppFont.mono(14, weight: .bold))
                        .foregroundColor(Color(hex: card.2))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.bgCard.opacity(0.9 - Double(i) * 0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: card.2).opacity(0.2), lineWidth: 1))
                .padding(.horizontal, CGFloat(i) * 8)
                .slideIn(delay: Double(i) * 0.1)
                .zIndex(Double(3 - i))
            }
        }
        .padding(.horizontal, 20)
    }
}

struct CalculatorsIllustration: View {
    let accent: Color
    @State private var value: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ForEach([("Area", "square", Color.accentCyan), ("Volume", "cube", Color.accentMint), ("Paint", "paintbrush.pointed", Color.accentViolet)], id: \.0) { item in
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(item.2.opacity(0.15))
                                .frame(width: 56, height: 56)
                            Image(systemName: item.1)
                                .font(.system(size: 24))
                                .foregroundColor(item.2)
                        }
                        Text(item.0)
                            .font(AppFont.rounded(11, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                    .slideIn(delay: 0.1)
                }
            }
            
            // Mini result display
            HStack {
                Text("Area =")
                    .font(AppFont.mono(13))
                    .foregroundColor(.textSecondary)
                Text(String(format: "%.2f m²", 4.8 * 3.2))
                    .font(AppFont.mono(18, weight: .bold))
                    .foregroundColor(.resultGreen)
                    .glow(color: .resultGreen, radius: 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.resultGreen.opacity(0.3), lineWidth: 1))
        }
    }
}
