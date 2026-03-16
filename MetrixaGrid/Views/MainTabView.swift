import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showAddMeasurement = false
    
    let tabs: [(icon: String, label: String)] = [
        ("square.grid.2x2.fill", "Dashboard"),
        ("ruler.fill", "Measure"),
        ("folder.fill", "Projects"),
        ("function", "Calculate"),
        ("arrow.left.arrow.right", "Convert"),
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            ZStack {
                switch selectedTab {
                case 0: DashboardView(selectedTab: $selectedTab)
                case 1: MeasurementsView()
                case 2: ProjectsView()
                case 3: CalculatorsView()
                case 4: ConverterView()
                default: DashboardView(selectedTab: $selectedTab)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom tab bar
            CustomTabBar(selectedTab: $selectedTab, tabs: tabs, onAddTap: {
                showAddMeasurement = true
            })
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showAddMeasurement) {
            AddMeasurementView()
        }
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [(icon: String, label: String)]
    let onAddTap: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // First two tabs
            ForEach(0..<2, id: \.self) { i in
                TabBarItem(icon: tabs[i].icon, label: tabs[i].label, isSelected: selectedTab == i) {
                    withAnimation(.springy) { selectedTab = i }
                }
            }
            
            // Center add button
            Button(action: onAddTap) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.cyanMint)
                        .frame(width: 54, height: 54)
                        .glow(color: .accentCyan, radius: 8)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.bgPrimary)
                }
            }
            .buttonStyle(NeonButtonStyle())
            .offset(y: -10)
            .padding(.horizontal, 10)
            
            // Last three tabs
            ForEach(2..<tabs.count, id: \.self) { i in
                TabBarItem(icon: tabs[i].icon, label: tabs[i].label, isSelected: selectedTab == i) {
                    withAnimation(.springy) { selectedTab = i }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .padding(.top, 8)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.bgCard)
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.08), lineWidth: 1))
                .shadow(color: .black.opacity(0.4), radius: 20, y: -4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .accentCyan : .textTertiary)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                Text(label)
                    .font(AppFont.standard(9, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .accentCyan : .textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(NeonButtonStyle())
        .animation(.springyFast, value: isSelected)
    }
}
