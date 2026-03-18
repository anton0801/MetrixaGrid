import SwiftUI
import UIKit

struct FABButton: View {
    @Binding var isSheetOpen: Bool
    @Binding var showCheckmark: Bool

    var body: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isSheetOpen.toggle()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(isSheetOpen ? Color.bgCard : Color.accentCyan)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(isSheetOpen ? Color.accentCyan.opacity(0.4) : Color.clear, lineWidth: 1)
                    )

                Group {
                    if showCheckmark {
                        Image(systemName: "checkmark")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color.accentCyan)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(isSheetOpen ? Color.accentCyan : Color(hex: "#0F172A"))
                            .rotationEffect(.degrees(isSheetOpen ? 45 : 0))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.springyFast, value: showCheckmark)
                .animation(.springyFast, value: isSheetOpen)
            }
        }
        .buttonStyle(FABPressStyle())
    }
}

private struct FABPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}


struct MetrixaNotificationView: View {
    @ObservedObject var store: Store
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(geometry.size.width > geometry.size.height ? "push_notifications_screen_bg_land" : "push_notifications_screen_bg")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea().opacity(0.9)
                
                if geometry.size.width < geometry.size.height {
                    VStack(spacing: 0) {
                        Spacer(); titleText
                            .multilineTextAlignment(.center); subtitleText
                            .multilineTextAlignment(.center).padding(.bottom); actionButtons
                    }.padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 0) { Spacer(); titleTextLand; subtitleTextLand }
                        Spacer()
                        VStack { Spacer(); actionButtons }
                        Spacer()
                    }.padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var titleText: some View {
        VStack(alignment: .center, spacing: -8) {
            Text("ALLOW NOTIFICATIONS ABOUT")
                .font(.custom("Lalezar-Regular", size: 24))
                .foregroundColor(.white)
            
            Text("BONUSES AND PROMOS")
                .font(.custom("Lalezar-Regular", size: 24))
                .foregroundColor(.white)
        }
    }
    
    private var titleTextLand: some View {
        VStack(alignment: .leading, spacing: -8) {
            Text("ALLOW NOTIFICATIONS ABOUT")
                .font(.custom("Lalezar-Regular", size: 26))
                .foregroundColor(.white)
            
            Text("BONUSES AND PROMOS")
                .font(.custom("Lalezar-Regular", size: 26))
                .foregroundColor(.white)
        }
    }
    
    private var subtitleText: some View {
        VStack(alignment: .center, spacing: -8) {
            Text("STAY TUNED WITH BEST OFFERS FROM")
                .font(.custom("Lalezar-Regular", size: 16))
                .foregroundColor(.white.opacity(0.7))
            
            Text("OUR CASINO")
                .font(.custom("Lalezar-Regular", size: 16))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private var subtitleTextLand: some View {
        VStack(alignment: .leading, spacing: -8) {
            Text("STAY TUNED WITH BEST OFFERS FROM")
                .font(.custom("Lalezar-Regular", size: 17))
                .foregroundColor(.white.opacity(0.7))
            
            Text("OUR CASINO")
                .font(.custom("Lalezar-Regular", size: 17))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button { store.dispatch(.permissionRequested) } label: {
                Image("push_notifications_screen_btn").resizable().frame(width: 320, height: 65)
            }
            Button { store.dispatch(.permissionDeferred) } label: {
                Image("push_notifications_screen_skip").resizable().frame(width: 280, height: 40)
            }
        }
        .padding(.horizontal, 12)
    }
}
