import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: AppStore
    @Binding var selectedTab: Int
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var showFavorites = false
    @State private var showAddMeasurement = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        DashboardHeader(showSettings: $showSettings, showHistory: $showHistory)
                        
                        // Quick add button
                        Button {
                            showAddMeasurement = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(LinearGradient.cyanMint)
                                Text("Quick Add Measurement")
                                    .font(AppFont.rounded(15, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13))
                                    .foregroundColor(.textSecondary)
                            }
                            .padding(16)
                            .background(
                                LinearGradient(colors: [Color.accentCyan.opacity(0.15), Color.accentMint.opacity(0.08)],
                                             startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.accentCyan.opacity(0.25), lineWidth: 1))
                        }
                        .tapScale()
                        .padding(.horizontal, 16)
                        .slideIn(delay: 0.05)
                        
                        // Recent Measurements
                        if !store.recentMeasurements.isEmpty {
                            DashboardSectionHeader(title: "Recent Measurements", action: "See all") {
                                selectedTab = 1
                            }
                            .padding(.horizontal, 16)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(store.recentMeasurements.enumerated()), id: \.1.id) { i, m in
                                        RecentMeasurementCard(measurement: m)
                                            .slideIn(delay: Double(i) * 0.05)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        // Quick Calculators
                        DashboardSectionHeader(title: "Quick Calculators", action: "All") {
                            selectedTab = 3
                        }
                        .padding(.horizontal, 16)
                        
                        QuickCalculatorsGrid(onSelectCalc: { selectedTab = 3 })
                            .padding(.horizontal, 16)
                            .slideIn(delay: 0.1)
                        
                        // Projects
                        if !store.projects.isEmpty {
                            DashboardSectionHeader(title: "Projects", action: "See all") {
                                selectedTab = 2
                            }
                            .padding(.horizontal, 16)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(store.projects.prefix(4).enumerated()), id: \.1.id) { i, p in
                                        ProjectMiniCard(project: p, count: store.measurements(for: p).count)
                                            .slideIn(delay: Double(i) * 0.06)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        // Unit Converter Quick
                        DashboardSectionHeader(title: "Quick Convert", action: "Open") {
                            selectedTab = 4
                        }
                        .padding(.horizontal, 16)
                        
                        QuickConverterCard()
                            .padding(.horizontal, 16)
                            .slideIn(delay: 0.15)
                        
                        // Favorites
                        if !store.favoriteMeasurements.isEmpty {
                            DashboardSectionHeader(title: "Favorites", action: nil) { }
                                .padding(.horizontal, 16)
                            
                            VStack(spacing: 8) {
                                ForEach(store.favoriteMeasurements.prefix(3)) { m in
                                    FavoriteMeasurementRow(measurement: m)
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showHistory) { HistoryView() }
        .sheet(isPresented: $showAddMeasurement) { AddMeasurementView() }
    }
}

// MARK: - Dashboard Header
struct DashboardHeader: View {
    @EnvironmentObject var store: AppStore
    @Binding var showSettings: Bool
    @Binding var showHistory: Bool
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hello, \(store.currentUser?.name ?? "there") 👋")
                    .font(AppFont.standard(13))
                    .foregroundColor(.textSecondary)
                Text("Metrixa Grid")
                    .font(AppFont.rounded(24, weight: .bold))
                    .foregroundStyle(LinearGradient.cyanMint)
            }
            Spacer()
            HStack(spacing: 12) {
                Button { showHistory = true } label: {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 17))
                        .foregroundColor(.textSecondary)
                        .frame(width: 38, height: 38)
                        .background(Color.bgCard)
                        .clipShape(Circle())
                }
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 17))
                        .foregroundColor(.textSecondary)
                        .frame(width: 38, height: 38)
                        .background(Color.bgCard)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

struct DashboardSectionHeader: View {
    let title: String
    let action: String?
    let onAction: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.rounded(17, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            if let action = action {
                Button(action: onAction) {
                    Text(action)
                        .font(AppFont.standard(13, weight: .medium))
                        .foregroundColor(.accentCyan)
                }
            }
        }
    }
}

// MARK: - Recent Measurement Card
struct RecentMeasurementCard: View {
    let measurement: Measurement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: measurement.category.icon)
                .font(.system(size: 20))
                .foregroundColor(measurement.category.color)
                .frame(width: 36, height: 36)
                .background(measurement.category.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Text(measurement.title)
                .font(AppFont.standard(12, weight: .medium))
                .foregroundColor(.textSecondary)
                .lineLimit(1)
            
            Text(measurement.fullDisplay)
                .font(AppFont.mono(18, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(14)
        .frame(width: 140)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
        .tapScale()
    }
}

// MARK: - Quick Calculators Grid
struct QuickCalculatorsGrid: View {
    let onSelectCalc: () -> Void
    
    let items = CalculatorType.allCases
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(items, id: \.self) { calc in
                Button(action: onSelectCalc) {
                    VStack(spacing: 6) {
                        Image(systemName: calc.icon)
                            .font(.system(size: 20))
                            .foregroundColor(calc.color)
                        Text(calc.rawValue)
                            .font(AppFont.standard(10, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(calc.color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(calc.color.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(NeonButtonStyle())
            }
        }
    }
}

// MARK: - Project Mini Card
struct ProjectMiniCard: View {
    let project: Project
    let count: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: project.icon)
                    .font(.system(size: 16))
                    .foregroundColor(project.color)
                Spacer()
                Text("\(count)")
                    .font(AppFont.mono(13, weight: .bold))
                    .foregroundColor(project.color)
            }
            Text(project.name)
                .font(AppFont.rounded(13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .padding(14)
        .frame(width: 130)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(project.color.opacity(0.2), lineWidth: 1)
        )
        .tapScale()
    }
}

// MARK: - Quick Converter Card
struct QuickConverterCard: View {
    @State private var inputValue = "100"
    @State private var fromUnit: ConvertUnit = .cm
    @State private var toUnit: ConvertUnit = .inch
    
    var result: String {
        guard let val = Double(inputValue),
              let res = ConversionService.convert(val, from: fromUnit, to: toUnit) else { return "—" }
        if res == Double(Int(res)) { return "\(Int(res))" }
        return String(format: "%.4f", res).replacingOccurrences(of: "0*$", with: "", options: .regularExpression)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("From")
                        .font(AppFont.standard(11))
                        .foregroundColor(.textSecondary)
                    TextField("Value", text: $inputValue)
                        .font(AppFont.mono(20, weight: .bold))
                        .foregroundColor(.white)
                        .accentColor(.accentCyan)
                        .keyboardType(.decimalPad)
                }
                
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 16))
                    .foregroundColor(.accentCyan)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Result")
                        .font(AppFont.standard(11))
                        .foregroundColor(.textSecondary)
                    Text(result)
                        .font(AppFont.mono(20, weight: .bold))
                        .foregroundColor(.resultGreen)
                        .glow(color: .resultGreen, radius: 4)
                }
            }
            
            HStack(spacing: 8) {
                UnitPicker(selectedUnit: $fromUnit, units: ConvertUnit.units(for: .length))
                Image(systemName: "arrow.right")
                    .font(.system(size: 12))
                    .foregroundColor(.textTertiary)
                UnitPicker(selectedUnit: $toUnit, units: ConvertUnit.units(for: .length))
                Spacer()
            }
        }
        .padding(16)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}

struct UnitPicker: View {
    @Binding var selectedUnit: ConvertUnit
    let units: [ConvertUnit]
    
    var body: some View {
        Menu {
            ForEach(units, id: \.self) { unit in
                Button(unit.symbol) { selectedUnit = unit }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedUnit.symbol)
                    .font(AppFont.mono(13, weight: .semibold))
                    .foregroundColor(.accentCyan)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9))
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Favorite Row
struct FavoriteMeasurementRow: View {
    @EnvironmentObject var store: AppStore
    let measurement: Measurement
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.system(size: 14))
                .foregroundColor(.warningYellow)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(measurement.title)
                    .font(AppFont.standard(14, weight: .medium))
                    .foregroundColor(.white)
                Text(measurement.category.rawValue)
                    .font(AppFont.standard(11))
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Text(measurement.fullDisplay)
                .font(AppFont.mono(15, weight: .bold))
                .foregroundColor(.accentCyan)
        }
        .padding(14)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.warningYellow.opacity(0.15), lineWidth: 1))
    }
}
