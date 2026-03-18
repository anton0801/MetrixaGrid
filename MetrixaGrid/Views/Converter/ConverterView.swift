import SwiftUI



struct UnavailableView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(geometry.size.width > geometry.size.height ? "issues_w_wifi_bg_land" : "issues_w_wifi_bg")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                
                Image("issues_w_wifi_a")
                    .resizable()
                    .frame(width: 250, height: 220)
            }
        }
        .ignoresSafeArea()
    }
}

struct ConverterView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedCategory: UnitCategory = .length
    @State private var fromUnit: ConvertUnit = .cm
    @State private var toUnit: ConvertUnit = .inch
    @State private var inputValue = ""
    @State private var swapRotation: Double = 0
    
    var result: Double? {
        guard let val = Double(inputValue) else { return nil }
        return ConversionService.convert(val, from: fromUnit, to: toUnit)
    }
    
    var resultString: String {
        guard let r = result else { return "—" }
        if r == Double(Int(r)) && r < 1_000_000 { return "\(Int(r))" }
        if r > 1000 { return String(format: "%.2f", r) }
        if r > 0.01 { return String(format: "%.4f", r) }
        return String(format: "%.6f", r)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            Text("Converter")
                                .font(AppFont.rounded(26, weight: .bold))
                                .foregroundStyle(LinearGradient(colors: [.accentMint, .accentCyan], startPoint: .leading, endPoint: .trailing))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        
                        // Category selector
                        HStack(spacing: 8) {
                            ForEach(UnitCategory.allCases, id: \.self) { cat in
                                Button {
                                    withAnimation(.springy) {
                                        selectedCategory = cat
                                        let units = ConvertUnit.units(for: cat)
                                        fromUnit = units.first ?? .cm
                                        toUnit = units.dropFirst().first ?? .cm
                                        inputValue = ""
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: categoryIcon(cat))
                                            .font(.system(size: 16))
                                        Text(cat.rawValue)
                                            .font(AppFont.standard(11, weight: .medium))
                                    }
                                    .foregroundColor(selectedCategory == cat ? .bgPrimary : .textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selectedCategory == cat ? Color.accentMint : Color.bgCard)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(NeonButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Main converter card
                        VStack(spacing: 0) {
                            // From
                            ConverterField(
                                label: "From",
                                value: $inputValue,
                                selectedUnit: $fromUnit,
                                units: ConvertUnit.units(for: selectedCategory),
                                color: .accentCyan
                            )
                            
                            // Swap button
                            ZStack {
                                Rectangle()
                                    .fill(Color.bgElevated)
                                    .frame(height: 1)
                                Button {
                                    withAnimation(.springy) {
                                        let temp = fromUnit
                                        fromUnit = toUnit
                                        toUnit = temp
                                        swapRotation += 180
                                        if let res = result {
                                            inputValue = resultString
                                        }
                                    }
                                } label: {
                                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(LinearGradient.cyanMint)
                                        .background(Color.bgPrimary)
                                        .clipShape(Circle())
                                        .rotationEffect(.degrees(swapRotation))
                                }
                            }
                            .padding(.vertical, 4)
                            
                            // To
                            ConverterResultField(
                                label: "To",
                                resultString: resultString,
                                selectedUnit: $toUnit,
                                units: ConvertUnit.units(for: selectedCategory),
                                color: .resultGreen
                            )
                        }
                        .padding(16)
                        .background(Color.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
                        .padding(.horizontal, 16)
                        
                        // Quick conversions for current category
                        QuickConversionsGrid(category: selectedCategory)
                            .padding(.horizontal, 16)
                        
                        // Conversion history
                        if !store.history.filter({ $0.type == .convertedUnit }).isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Recent Conversions")
                                    .font(AppFont.standard(13, weight: .semibold))
                                    .foregroundColor(.textSecondary)
                                    .padding(.horizontal, 16)
                                
                                ForEach(store.history.filter { $0.type == .convertedUnit }.prefix(5)) { event in
                                    HStack(spacing: 10) {
                                        Image(systemName: "arrow.left.arrow.right.circle.fill")
                                            .foregroundColor(.accentMint)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(event.title)
                                                .font(AppFont.standard(13, weight: .medium))
                                                .foregroundColor(.white)
                                            Text(event.detail)
                                                .font(AppFont.mono(12))
                                                .foregroundColor(.textSecondary)
                                        }
                                        Spacer()
                                        Text(event.date, style: .time)
                                            .font(AppFont.standard(11))
                                            .foregroundColor(.textTertiary)
                                    }
                                    .padding(12)
                                    .background(Color.bgCard)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func categoryIcon(_ cat: UnitCategory) -> String {
        switch cat {
        case .length: return "ruler"
        case .area: return "square"
        case .volume: return "cube"
        case .weight: return "scalemass"
        }
    }
}

struct ConverterField: View {
    let label: String
    @Binding var value: String
    @Binding var selectedUnit: ConvertUnit
    let units: [ConvertUnit]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(AppFont.standard(12))
                .foregroundColor(.textSecondary)
            HStack(alignment: .bottom) {
                TextField("0", text: $value)
                    .font(AppFont.mono(38, weight: .bold))
                    .foregroundColor(.white)
                    .accentColor(color)
                    .keyboardType(.decimalPad)
                    .minimumScaleFactor(0.5)
                
                Spacer()
                
                Menu {
                    ForEach(units, id: \.self) { unit in
                        Button(unit.symbol) { selectedUnit = unit }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedUnit.symbol)
                            .font(AppFont.mono(18, weight: .semibold))
                            .foregroundColor(color)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct ConverterResultField: View {
    let label: String
    let resultString: String
    @Binding var selectedUnit: ConvertUnit
    let units: [ConvertUnit]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(AppFont.standard(12))
                .foregroundColor(.textSecondary)
            HStack(alignment: .bottom) {
                Text(resultString)
                    .font(AppFont.mono(38, weight: .bold))
                    .foregroundColor(resultString == "—" ? .textTertiary : color)
                    .glow(color: resultString == "—" ? .clear : color, radius: 4)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                Spacer()
                
                Menu {
                    ForEach(units, id: \.self) { unit in
                        Button(unit.symbol) { selectedUnit = unit }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedUnit.symbol)
                            .font(AppFont.mono(18, weight: .semibold))
                            .foregroundColor(color)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct QuickConversionsGrid: View {
    let category: UnitCategory
    
    var pairs: [(from: ConvertUnit, to: ConvertUnit)] {
        switch category {
        case .length:
            return [(.cm, .inch), (.m, .ft), (.km, .mile), (.inch, .cm)]
        case .area:
            return [(.sqM, .sqFt), (.sqCm, .sqIn)]
        case .volume:
            return [(.liter, .gallon), (.ml, .flOz)]
        case .weight:
            return [(.kg, .lb), (.g, .oz)]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Reference")
                .font(AppFont.standard(13, weight: .semibold))
                .foregroundColor(.textSecondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(pairs, id: \.from.symbol) { pair in
                    QuickConversionCard(from: pair.from, to: pair.to)
                }
            }
        }
    }
}

struct QuickConversionCard: View {
    let from: ConvertUnit
    let to: ConvertUnit
    
    var conversionFactor: String {
        guard let r = ConversionService.convert(1, from: from, to: to) else { return "—" }
        if r >= 100 { return String(format: "%.1f", r) }
        if r >= 1 { return String(format: "%.4f", r) }
        return String(format: "%.6f", r)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("1 \(from.symbol)")
                    .font(AppFont.mono(12, weight: .semibold))
                    .foregroundColor(.accentCyan)
                Image(systemName: "arrow.right")
                    .font(.system(size: 10))
                    .foregroundColor(.textTertiary)
                Text(to.symbol)
                    .font(AppFont.mono(12, weight: .semibold))
                    .foregroundColor(.accentMint)
            }
            Text(conversionFactor)
                .font(AppFont.mono(15, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(12)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}
