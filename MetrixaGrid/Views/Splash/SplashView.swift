import SwiftUI

struct SplashView: View {
    @State private var gridOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var particles: [SplashParticle] = SplashParticle.generate(count: 20)
    
    var body: some View {
        ZStack {
            // Background
            Color.bgPrimary.ignoresSafeArea()
            
            // Gradient radial glow
            RadialGradient(
                gradient: Gradient(colors: [Color.accentCyan.opacity(0.15), Color.clear]),
                center: .center,
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()
            
            // Animated grid
            GeometryReader { geo in
                GridBackground(opacity: gridOpacity)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            
            // Floating measurement particles
            ForEach(particles) { particle in
                ParticleView(particle: particle)
            }
            
            // Center content
            VStack(spacing: 12) {
                Spacer()
                
                // Logo container
                ZStack {
                    // Pulse rings
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Color.accentCyan.opacity(0.15 - Double(i) * 0.04), lineWidth: 1)
                            .frame(width: CGFloat(90 + i * 30), height: CGFloat(90 + i * 30))
                            .scaleEffect(pulseScale + CGFloat(i) * 0.05)
                    }
                    
                    // Logo background
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(colors: [Color.bgCard, Color(hex: "#263448")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(LinearGradient.cyanMint.opacity(0.5), lineWidth: 1.5)
                        )
                    
                    // Logo icon
                    VStack(spacing: 2) {
                        Image(systemName: "ruler.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(LinearGradient.cyanMint)
                        
                        Text("MG")
                            .font(AppFont.mono(10, weight: .bold))
                            .foregroundColor(.accentCyan)
                    }
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                // App name
                VStack(spacing: 4) {
                    HStack(spacing: 2) {
                        Text("Metrixa")
                            .font(AppFont.rounded(38, weight: .bold))
                            .foregroundStyle(LinearGradient.cyanMint)
                            .glow(color: .accentCyan, radius: 6)
                        
                        Text(" Grid")
                            .font(AppFont.rounded(38, weight: .light))
                            .foregroundColor(.white)
                    }
                    
                    Text("Smart measurement notes.")
                        .font(AppFont.mono(13))
                        .foregroundColor(.textSecondary)
                        .tracking(2)
                }
                .opacity(logoOpacity)
                
                Spacer()
                
                // Bottom indicator
                HStack(spacing: 6) {
                    ForEach(0..<3) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentCyan.opacity(0.4 + Double(i) * 0.2))
                            .frame(width: i == 1 ? 20 : 6, height: 4)
                    }
                }
                .opacity(subtitleOpacity)
                .padding(.bottom, 50)
            }
        }
        .onAppear { startAnimations() }
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) { gridOpacity = 1 }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.4)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        withAnimation(.easeIn(duration: 0.5).delay(0.9)) { subtitleOpacity = 1 }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) {
            pulseScale = 1.08
        }
    }
}

// MARK: - Grid Background
struct GridBackground: View {
    var opacity: Double
    let gridSpacing: CGFloat = 40
    
    var body: some View {
        Canvas { ctx, size in
            let rows = Int(size.height / gridSpacing) + 2
            let cols = Int(size.width / gridSpacing) + 2
            
            // Draw grid lines
            for row in 0...rows {
                let y = CGFloat(row) * gridSpacing
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                ctx.stroke(path, with: .color(Color.accentCyan.opacity(0.07)), lineWidth: 0.5)
            }
            for col in 0...cols {
                let x = CGFloat(col) * gridSpacing
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                ctx.stroke(path, with: .color(Color.accentCyan.opacity(0.07)), lineWidth: 0.5)
            }
            
            // Dot intersections
            for row in 0...rows {
                for col in 0...cols {
                    let x = CGFloat(col) * gridSpacing
                    let y = CGFloat(row) * gridSpacing
                    let dotRect = CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3)
                    ctx.fill(Path(ellipseIn: dotRect), with: .color(Color.accentCyan.opacity(0.2)))
                }
            }
        }
        .opacity(opacity)
    }
}

// MARK: - Particle
struct SplashParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var label: String
    var opacity: Double
    var scale: CGFloat
    
    static func generate(count: Int) -> [SplashParticle] {
        let labels = ["4.8 m", "120 cm", "2.7 m", "30 cm", "90 cm", "1.2 m", "45°", "3.6 m²", "0.5 m³"]
        return (0..<count).map { i in
            SplashParticle(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                label: labels[i % labels.count],
                opacity: Double.random(in: 0.1...0.35),
                scale: CGFloat.random(in: 0.7...1.1)
            )
        }
    }
}

struct ParticleView: View {
    let particle: SplashParticle
    @State private var floatOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            Text(particle.label)
                .font(AppFont.mono(10))
                .foregroundColor(.accentCyan)
                .opacity(particle.opacity)
                .scaleEffect(particle.scale)
                .position(
                    x: particle.x * geo.size.width,
                    y: particle.y * geo.size.height + floatOffset
                )
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: true)
                    ) {
                        floatOffset = CGFloat.random(in: -10...10)
                    }
                }
        }
    }
}
