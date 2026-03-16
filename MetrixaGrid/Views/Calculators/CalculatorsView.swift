import SwiftUI

struct CalculatorsView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedCalc: CalculatorType = .area
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Calculators")
                            .font(AppFont.rounded(26, weight: .bold))
                            .foregroundStyle(LinearGradient.violetCyan)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    
                    // Tab picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(CalculatorType.allCases, id: \.self) { type in
                                Button {
                                    withAnimation(.springy) { selectedCalc = type }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 14))
                                        Text(type.rawValue)
                                            .font(AppFont.rounded(14, weight: .semibold))
                                    }
                                    .foregroundColor(selectedCalc == type ? .bgPrimary : type.color)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedCalc == type ? type.color : type.color.opacity(0.12))
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(NeonButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 16)
                    
                    // Calculator content
                    ScrollView(showsIndicators: false) {
                        Group {
                            switch selectedCalc {
                            case .area:
                                AreaCalculatorView()
                            case .volume:
                                VolumeCalculatorView()
                            case .paint:
                                PaintCalculatorView()
                            case .tile:
                                TileCalculatorView()
                            }
                        }
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                        .id(selectedCalc)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Area Calculator
struct AreaCalculatorView: View {
    @EnvironmentObject var store: AppStore
    @State private var length = ""
    @State private var width = ""
    @State private var unit: MeasurementUnit = .m
    @State private var showResult = false
    
    var result: Double? {
        guard let l = Double(length), let w = Double(width) else { return nil }
        return l * w
    }
    
    var resultUnit: String {
        switch unit {
        case .mm: return "mm²"
        case .cm: return "cm²"
        case .m: return "m²"
        case .ft: return "ft²"
        case .inch: return "in²"
        default: return "m²"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            CalcHeader(type: .area, subtitle: "Length × Width")
            
            // Visual
            GeometryReader { geo in
                ZStack {
                    let l = max(0.1, Double(length) ?? 1)
                    let w = max(0.1, Double(width) ?? 1)
                    let ratio = min(1.0, l / max(l, w))
                    let ratioW = min(1.0, w / max(l, w))
                    let maxW = geo.size.width - 40
                    let maxH: CGFloat = 120
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentCyan.opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentCyan.opacity(0.4), lineWidth: 1.5))
                        .frame(width: maxW * CGFloat(ratio), height: maxH * CGFloat(ratioW))
                        .animation(.springy, value: length)
                        .animation(.springy, value: width)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 140)
            .padding(.horizontal, 16)
            
            CalcInputRow(label: "Length", value: $length, unit: $unit, unitOptions: MeasurementUnit.lengthUnits)
            CalcInputRow(label: "Width", value: $width, unit: .constant(unit), unitOptions: MeasurementUnit.lengthUnits)
            
            ResultCard(value: result, unit: resultUnit, label: "Area") {
                if let r = result {
                    store.addHistory(type: .calculation, title: "Area Calculation", detail: "\(length) × \(width) \(unit.symbol) = \(String(format: "%.4f", r)) \(resultUnit)")
                }
            }
            
            SaveResultButton(result: result, unit: resultUnit, title: "Calculated Area") { m in
                store.addMeasurement(m)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Volume Calculator
struct VolumeCalculatorView: View {
    @EnvironmentObject var store: AppStore
    @State private var length = ""
    @State private var width = ""
    @State private var height = ""
    @State private var unit: MeasurementUnit = .m
    
    var result: Double? {
        guard let l = Double(length), let w = Double(width), let h = Double(height) else { return nil }
        return l * w * h
    }
    
    var body: some View {
        VStack(spacing: 20) {
            CalcHeader(type: .volume, subtitle: "Length × Width × Height")
            
            // 3D cube illustration
            CubeIllustration(
                l: Double(length) ?? 1,
                w: Double(width) ?? 1,
                h: Double(height) ?? 1
            )
            .frame(height: 140)
            .padding(.horizontal, 16)
            
            CalcInputRow(label: "Length", value: $length, unit: $unit, unitOptions: MeasurementUnit.lengthUnits)
            CalcInputRow(label: "Width", value: $width, unit: .constant(unit), unitOptions: MeasurementUnit.lengthUnits)
            CalcInputRow(label: "Height", value: $height, unit: .constant(unit), unitOptions: MeasurementUnit.lengthUnits)
            
            ResultCard(value: result, unit: "m³", label: "Volume") {
                if let r = result {
                    store.addHistory(type: .calculation, title: "Volume Calculation", detail: "\(length) × \(width) × \(height) \(unit.symbol) = \(String(format: "%.4f", r)) m³")
                }
            }
            
            SaveResultButton(result: result, unit: "m²", title: "Calculated Volume") { m in
                store.addMeasurement(m)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Paint Calculator
struct PaintCalculatorView: View {
    @EnvironmentObject var store: AppStore
    @State private var wallWidth = ""
    @State private var wallHeight = ""
    @State private var paintCoverage = "10"  // m² per liter
    @State private var coats = 2
    
    var area: Double? {
        guard let w = Double(wallWidth), let h = Double(wallHeight) else { return nil }
        return w * h
    }
    
    var result: Double? {
        guard let a = area, let cov = Double(paintCoverage), cov > 0 else { return nil }
        return (a * Double(coats)) / cov
    }
    
    var body: some View {
        VStack(spacing: 20) {
            CalcHeader(type: .paint, subtitle: "Wall Area ÷ Coverage")
            
            // Paint can visual
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.accentViolet.opacity(0.08))
                    .frame(height: 100)
                HStack(spacing: 20) {
                    Image(systemName: "paintbrush.pointed.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(LinearGradient.violetCyan)
                        .rotationEffect(.degrees(-30))
                    if let r = result {
                        VStack(spacing: 4) {
                            Text(String(format: "%.1f", r))
                                .font(AppFont.mono(36, weight: .bold))
                                .foregroundColor(.accentViolet)
                                .glow(color: .accentViolet, radius: 6)
                            Text("liters")
                                .font(AppFont.standard(13))
                                .foregroundColor(.textSecondary)
                        }
                    } else {
                        Text("—")
                            .font(AppFont.mono(36, weight: .bold))
                            .foregroundColor(.textTertiary)
                    }
                }
            }
            .padding(.horizontal, 16)
            
            CalcInputRow(label: "Wall Width", value: $wallWidth, unit: .constant(.m), unitOptions: MeasurementUnit.lengthUnits)
            CalcInputRow(label: "Wall Height", value: $wallHeight, unit: .constant(.m), unitOptions: MeasurementUnit.lengthUnits)
            CalcInputRow(label: "Coverage (m²/L)", value: $paintCoverage, unit: .constant(.m), unitOptions: [.m])
            
            // Coats stepper
            HStack {
                Text("Number of Coats")
                    .font(AppFont.standard(15))
                    .foregroundColor(.textSecondary)
                Spacer()
                HStack(spacing: 16) {
                    Button {
                        if coats > 1 { withAnimation(.springyFast) { coats -= 1 } }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.accentViolet)
                    }
                    Text("\(coats)")
                        .font(AppFont.mono(20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28)
                    Button {
                        if coats < 5 { withAnimation(.springyFast) { coats += 1 } }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.accentViolet)
                    }
                }
            }
            .padding(14)
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            ResultCard(value: result, unit: "L", label: "Paint Needed") {
                if let r = result {
                    store.addHistory(type: .calculation, title: "Paint Calculation", detail: "Need \(String(format: "%.1f", r))L for wall \(wallWidth)×\(wallHeight)m")
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Tile Calculator
struct TileCalculatorView: View {
    @EnvironmentObject var store: AppStore
    @State private var roomWidth = ""
    @State private var roomHeight = ""
    @State private var tileWidth = "30"
    @State private var tileHeight = "30"
    @State private var wastePercent = 10.0
    
    var roomArea: Double? {
        guard let w = Double(roomWidth), let h = Double(roomHeight) else { return nil }
        return w * h
    }
    
    var tileArea: Double? {
        guard let tw = Double(tileWidth), let th = Double(tileHeight) else { return nil }
        return (tw / 100) * (th / 100)
    }
    
    var result: Double? {
        guard let ra = roomArea, let ta = tileArea, ta > 0 else { return nil }
        return ceil(ra / ta * (1 + wastePercent / 100))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            CalcHeader(type: .tile, subtitle: "Room Area ÷ Tile Area + Waste")
            
            // Grid visualization
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.warningYellow.opacity(0.06))
                    .frame(height: 100)
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(16), spacing: 4), count: 8), spacing: 4) {
                    ForEach(0..<32, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.warningYellow.opacity(0.4))
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    CalcField(label: "Room Width (m)", value: $roomWidth)
                    CalcField(label: "Room Height (m)", value: $roomHeight)
                }
                HStack(spacing: 12) {
                    CalcField(label: "Tile Width (cm)", value: $tileWidth)
                    CalcField(label: "Tile Height (cm)", value: $tileHeight)
                }
            }
            
            // Waste slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Waste / Cuts: \(Int(wastePercent))%")
                        .font(AppFont.standard(14))
                        .foregroundColor(.textSecondary)
                    Spacer()
                }
                Slider(value: $wastePercent, in: 0...25, step: 1)
                    .accentColor(.warningYellow)
            }
            .padding(14)
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            ResultCard(value: result, unit: "tiles", label: "Tiles Needed") {
                if let r = result {
                    store.addHistory(type: .calculation, title: "Tile Calculation", detail: "Need \(Int(r)) tiles for \(roomWidth)×\(roomHeight)m room")
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Shared Calculator Components
struct CalcHeader: View {
    let type: CalculatorType
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(type.color.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: type.icon)
                    .font(.system(size: 22))
                    .foregroundColor(type.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(type.rawValue + " Calculator")
                    .font(AppFont.rounded(18, weight: .bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(AppFont.standard(12))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
        }
    }
}

struct CalcInputRow: View {
    let label: String
    @Binding var value: String
    @Binding var unit: MeasurementUnit
    let unitOptions: [MeasurementUnit]
    
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(AppFont.standard(14))
                .foregroundColor(.textSecondary)
                .frame(width: 100, alignment: .leading)
            Spacer()
            TextField("0", text: $value)
                .font(AppFont.mono(18, weight: .semibold))
                .foregroundColor(.white)
                .accentColor(.accentCyan)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Menu {
                ForEach(unitOptions, id: \.self) { u in
                    Button(u.symbol) { unit = u }
                }
            } label: {
                Text(unit.symbol)
                    .font(AppFont.mono(13, weight: .semibold))
                    .foregroundColor(.accentCyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.bgElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(14)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CalcField: View {
    let label: String
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(AppFont.standard(11))
                .foregroundColor(.textSecondary)
            TextField("0", text: $value)
                .font(AppFont.mono(18, weight: .semibold))
                .foregroundColor(.white)
                .accentColor(.accentCyan)
                .keyboardType(.decimalPad)
        }
        .padding(14)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ResultCard: View {
    let value: Double?
    let unit: String
    let label: String
    let onLog: () -> Void
    
    private func formatValue(_ v: Double) -> String {
        if unit == "tiles" { return "\(Int(v))" }
        if v == Double(Int(v)) { return "\(Int(v))" }
        return String(format: "%.4f", v).replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(label)
                    .font(AppFont.standard(13))
                    .foregroundColor(.textSecondary)
                Spacer()
                if value != nil {
                    Button(action: onLog) {
                        Label("Log", systemImage: "clock.badge.plus")
                            .font(AppFont.standard(12))
                            .foregroundColor(.accentCyan)
                    }
                }
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if let v = value {
                    Text(formatValue(v))
                        .font(AppFont.mono(40, weight: .bold))
                        .foregroundColor(.resultGreen)
                        .glow(color: .resultGreen, radius: 6)
                    Text(unit)
                        .font(AppFont.mono(18))
                        .foregroundColor(.resultGreen.opacity(0.7))
                } else {
                    Text("—")
                        .font(AppFont.mono(40, weight: .bold))
                        .foregroundColor(.textTertiary)
                    Text("Enter values above")
                        .font(AppFont.standard(13))
                        .foregroundColor(.textTertiary)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(value != nil ? Color.resultGreen.opacity(0.08) : Color.bgCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(value != nil ? Color.resultGreen.opacity(0.25) : Color.white.opacity(0.06), lineWidth: 1)
        )
        .animation(.springy, value: value != nil)
    }
}

struct SaveResultButton: View {
    @EnvironmentObject var store: AppStore
    let result: Double?
    let unit: String
    let title: String
    let onSave: (Measurement) -> Void
    @State private var saved = false
    
    var body: some View {
        if let r = result {
            Button {
                let mUnit = MeasurementUnit.allCases.first { $0.symbol == unit } ?? .m
                let m = Measurement(title: title, value: r, unit: mUnit, projectId: nil, category: .general, note: "Calculated")
                onSave(m)
                withAnimation { saved = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { saved = false }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: saved ? "checkmark.circle.fill" : "square.and.arrow.down")
                        .font(.system(size: 16))
                    Text(saved ? "Saved to Measurements!" : "Save Result")
                        .font(AppFont.rounded(15, weight: .semibold))
                }
                .foregroundColor(saved ? .bgPrimary : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(saved ? Color.resultGreen : Color.bgElevated)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .animation(.springy, value: saved)
            .tapScale()
        }
    }
}

// MARK: - Cube Illustration
struct CubeIllustration: View {
    let l: Double
    let w: Double
    let h: Double
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.accentMint.opacity(0.06))
                .frame(height: 120)
            
            let maxDim = max(l, w, h, 0.1)
            let lN = CGFloat(l / maxDim)
            let wN = CGFloat(w / maxDim)
            let hN = CGFloat(h / maxDim)
            let baseW = 100 * lN
            let baseH = 60 * wN
            let topH = 80 * hN
            
            // Isometric cube
            Path { path in
                // Front face
                let x: CGFloat = 130
                let y: CGFloat = 80
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x + baseW, y: y))
                path.addLine(to: CGPoint(x: x + baseW, y: y + topH))
                path.addLine(to: CGPoint(x: x, y: y + topH))
                path.closeSubpath()
            }
            .fill(Color.accentMint.opacity(0.15))
            
            Path { path in
                let x: CGFloat = 130
                let y: CGFloat = 80
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x + baseW, y: y))
                path.addLine(to: CGPoint(x: x + baseW, y: y + topH))
                path.addLine(to: CGPoint(x: x, y: y + topH))
                path.closeSubpath()
            }
            .stroke(Color.accentMint.opacity(0.5), lineWidth: 1.5)
            
            // Top face (parallelogram)
            Path { path in
                let x: CGFloat = 130
                let y: CGFloat = 80
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x + baseW, y: y))
                path.addLine(to: CGPoint(x: x + baseW + baseH, y: y - baseH * 0.5))
                path.addLine(to: CGPoint(x: x + baseH, y: y - baseH * 0.5))
                path.closeSubpath()
            }
            .fill(Color.accentCyan.opacity(0.12))
            
            Path { path in
                let x: CGFloat = 130
                let y: CGFloat = 80
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x + baseW, y: y))
                path.addLine(to: CGPoint(x: x + baseW + baseH, y: y - baseH * 0.5))
                path.addLine(to: CGPoint(x: x + baseH, y: y - baseH * 0.5))
                path.closeSubpath()
            }
            .stroke(Color.accentCyan.opacity(0.5), lineWidth: 1.5)
        }
        .animation(.springy, value: l)
        .animation(.springy, value: w)
        .animation(.springy, value: h)
    }
}
