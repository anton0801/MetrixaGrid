import SwiftUI

// MARK: - Color System
extension Color {
    // Backgrounds
    static let bgPrimary = Color(hex: "#0F172A")
    static let bgCard = Color(hex: "#1E293B")
    static let bgElevated = Color(hex: "#263448")
    
    // Accents
    static let accentCyan = Color(hex: "#22D3EE")
    static let accentMint = Color(hex: "#2DD4BF")
    static let accentViolet = Color(hex: "#A78BFA")
    static let accentGray = Color(hex: "#CBD5E1")
    
    // Semantic
    static let resultGreen = Color(hex: "#34D399")
    static let warningYellow = Color(hex: "#FACC15")
    static let errorRed = Color(hex: "#F87171")
    
    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#94A3B8")
    static let textTertiary = Color(hex: "#475569")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let cyanMint = LinearGradient(colors: [.accentCyan, .accentMint], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let violetCyan = LinearGradient(colors: [.accentViolet, .accentCyan], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let bgDeep = LinearGradient(colors: [Color(hex: "#0F172A"), Color(hex: "#0D1B2E")], startPoint: .top, endPoint: .bottom)
    static let cardShimmer = LinearGradient(colors: [Color.white.opacity(0.0), Color.white.opacity(0.05), Color.white.opacity(0.0)], startPoint: .leading, endPoint: .trailing)
}

// MARK: - Typography
struct AppFont {
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.system(size: size, weight: weight, design: .monospaced)
    }
    static func rounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.system(size: size, weight: weight, design: .rounded)
    }
    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.system(size: size, weight: weight, design: .serif)
    }
    static func standard(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.system(size: size, weight: weight, design: .default)
    }
}

// MARK: - Animation
extension Animation {
    static let springy = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let springyFast = Animation.spring(response: 0.3, dampingFraction: 0.8)
    static let smooth = Animation.easeInOut(duration: 0.25)
}

// MARK: - Custom Button Style
struct NeonButtonStyle: ButtonStyle {
    var color: Color = .accentCyan
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.springyFast, value: configuration.isPressed)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var gradient: LinearGradient = .cyanMint
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.springyFast, value: configuration.isPressed)
    }
}

// MARK: - Card Style
struct CardModifier: ViewModifier {
    var padding: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

// MARK: - Tap Scale Effect
struct TapScaleModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.springyFast, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    func tapScale() -> some View {
        modifier(TapScaleModifier())
    }
}

// MARK: - Slide In Modifier
struct SlideInModifier: ViewModifier {
    @State private var appeared = false
    var delay: Double = 0
    var from: Edge = .bottom
    
    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(
                x: from == .leading ? (appeared ? 0 : -30) : from == .trailing ? (appeared ? 0 : 30) : 0,
                y: from == .bottom ? (appeared ? 0 : 20) : from == .top ? (appeared ? 0 : -20) : 0
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.springy) {
                        appeared = true
                    }
                }
            }
    }
}

extension View {
    func slideIn(delay: Double = 0, from: Edge = .bottom) -> some View {
        modifier(SlideInModifier(delay: delay, from: from))
    }
}

// MARK: - Glow Modifier
struct GlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 8
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius)
            .shadow(color: color.opacity(0.3), radius: radius * 2)
    }
}

extension View {
    func glow(color: Color, radius: CGFloat = 8) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}
