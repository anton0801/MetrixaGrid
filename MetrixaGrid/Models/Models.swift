import Foundation
import SwiftUI

// MARK: - Measurement Model
struct Measurement: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var value: Double
    var unit: MeasurementUnit
    var projectId: UUID?
    var category: MeasurementCategory
    var note: String
    var photoData: Data?
    var date: Date = Date()
    var isFavorite: Bool = false
    
    var displayValue: String {
        if value == Double(Int(value)) {
            return "\(Int(value))"
        }
        return String(format: "%.2f", value).trimmingCharacters(in: CharacterSet(charactersIn: "0").union(.whitespaces))
    }
    
    var fullDisplay: String {
        "\(displayValue) \(unit.symbol)"
    }
}

// MARK: - Measurement Unit
enum MeasurementUnit: String, Codable, CaseIterable {
    case mm, cm, m, inch = "in", ft
    case squareMM = "mm²"
    case squareCM = "cm²"
    case squareM = "m²"
    case squareFt = "ft²"
    case cubicM = "m³"
    case liter = "L"
    
    var symbol: String { rawValue }
    
    var category: UnitCategory {
        switch self {
        case .mm, .cm, .m, .inch, .ft: return .length
        case .squareMM, .squareCM, .squareM, .squareFt: return .area
        case .cubicM, .liter: return .volume
        }
    }
    
    static var lengthUnits: [MeasurementUnit] { [.mm, .cm, .m, .inch, .ft] }
    static var areaUnits: [MeasurementUnit] { [.squareMM, .squareCM, .squareM, .squareFt] }
    static var volumeUnits: [MeasurementUnit] { [.cubicM, .liter] }
}

enum UnitCategory: String, CaseIterable {
    case length = "Length"
    case area = "Area"
    case volume = "Volume"
    case weight = "Weight"
}

// MARK: - Measurement Category
enum MeasurementCategory: String, Codable, CaseIterable {
    case wall = "Wall"
    case floor = "Floor"
    case ceiling = "Ceiling"
    case furniture = "Furniture"
    case door = "Door"
    case window = "Window"
    case general = "General"
    
    var icon: String {
        switch self {
        case .wall: return "rectangle.portrait"
        case .floor: return "square"
        case .ceiling: return "rectangle"
        case .furniture: return "sofa"
        case .door: return "door.right.hand.closed"
        case .window: return "window.ceiling"
        case .general: return "ruler"
        }
    }
    
    var color: Color {
        switch self {
        case .wall: return .accentCyan
        case .floor: return .accentMint
        case .ceiling: return .accentViolet
        case .furniture: return .warningYellow
        case .door: return .resultGreen
        case .window: return Color(hex: "#38BDF8")
        case .general: return .accentGray
        }
    }
}

// MARK: - Project Model
struct Project: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var colorHex: String
    var icon: String
    var date: Date = Date()
    var lastUpdated: Date = Date()
    
    var color: Color { Color(hex: colorHex) }
    
    static let defaultColors = ["#22D3EE", "#2DD4BF", "#A78BFA", "#F472B6", "#34D399", "#FACC15", "#F87171", "#60A5FA"]
    static let defaultIcons = ["house", "wrench.and.screwdriver", "paintbrush", "hammer", "archivebox", "star", "bolt", "leaf"]
}

// MARK: - History Event
struct HistoryEvent: Identifiable, Codable {
    var id: UUID = UUID()
    var type: HistoryEventType
    var title: String
    var detail: String
    var date: Date = Date()
}

enum HistoryEventType: String, Codable {
    case addedMeasurement = "Added measurement"
    case editedMeasurement = "Edited measurement"
    case deletedMeasurement = "Deleted measurement"
    case addedProject = "Added project"
    case editedProject = "Edited project"
    case deletedProject = "Deleted project"
    case convertedUnit = "Converted unit"
    case calculation = "Calculation"
    
    var icon: String {
        switch self {
        case .addedMeasurement, .addedProject: return "plus.circle.fill"
        case .editedMeasurement, .editedProject: return "pencil.circle.fill"
        case .deletedMeasurement, .deletedProject: return "trash.circle.fill"
        case .convertedUnit: return "arrow.left.arrow.right.circle.fill"
        case .calculation: return "function"
        }
    }
    
    var color: Color {
        switch self {
        case .addedMeasurement, .addedProject: return .resultGreen
        case .editedMeasurement, .editedProject: return .accentCyan
        case .deletedMeasurement, .deletedProject: return .errorRed
        case .convertedUnit: return .accentMint
        case .calculation: return .accentViolet
        }
    }
}

// MARK: - User Model
struct AppUser: Codable {
    var id: String
    var email: String
    var name: String
    var createdAt: Date
}

// MARK: - Calculator Result
struct CalculatorResult: Identifiable {
    var id = UUID()
    var type: CalculatorType
    var inputs: [String: Double]
    var result: Double
    var unit: String
    var date: Date = Date()
}

enum CalculatorType: String, CaseIterable {
    case area = "Area"
    case volume = "Volume"
    case paint = "Paint"
    case tile = "Tile"
    
    var icon: String {
        switch self {
        case .area: return "square"
        case .volume: return "cube"
        case .paint: return "paintbrush.pointed"
        case .tile: return "square.grid.3x3"
        }
    }
    
    var color: Color {
        switch self {
        case .area: return .accentCyan
        case .volume: return .accentMint
        case .paint: return .accentViolet
        case .tile: return .warningYellow
        }
    }
}

// MARK: - Converter Entry
struct ConverterEntry {
    var fromValue: String = ""
    var fromUnit: ConvertUnit = .cm
    var toUnit: ConvertUnit = .inch
    
    var result: Double? {
        guard let val = Double(fromValue) else { return nil }
        return ConversionService.convert(val, from: fromUnit, to: toUnit)
    }
}

enum ConvertUnit: String, CaseIterable {
    // Length
    case mm, cm, m, inch = "in", ft, km, mile
    // Area
    case sqCm = "cm²", sqM = "m²", sqFt = "ft²", sqIn = "in²"
    // Volume
    case ml = "mL", liter = "L", cubicM = "m³", gallon = "gal", flOz = "fl oz"
    // Weight
    case g, kg, lb, oz
    
    var symbol: String { rawValue }
    
    var category: UnitCategory {
        switch self {
        case .mm, .cm, .m, .inch, .ft, .km, .mile: return .length
        case .sqCm, .sqM, .sqFt, .sqIn: return .area
        case .ml, .liter, .cubicM, .gallon, .flOz: return .volume
        case .g, .kg, .lb, .oz: return .weight
        }
    }
    
    static func units(for category: UnitCategory) -> [ConvertUnit] {
        ConvertUnit.allCases.filter { $0.category == category }
    }
}

// MARK: - Conversion Service
struct ConversionService {
    static func convert(_ value: Double, from: ConvertUnit, to: ConvertUnit) -> Double? {
        guard from.category == to.category else { return nil }
        let baseValue = toBase(value, unit: from)
        return fromBase(baseValue, unit: to)
    }
    
    // Convert to SI base unit
    private static func toBase(_ value: Double, unit: ConvertUnit) -> Double {
        switch unit {
        case .mm: return value * 0.001
        case .cm: return value * 0.01
        case .m: return value
        case .inch: return value * 0.0254
        case .ft: return value * 0.3048
        case .km: return value * 1000
        case .mile: return value * 1609.344
        case .sqCm: return value * 0.0001
        case .sqM: return value
        case .sqFt: return value * 0.092903
        case .sqIn: return value * 0.00064516
        case .ml: return value * 0.001
        case .liter: return value
        case .cubicM: return value * 1000
        case .gallon: return value * 3.78541
        case .flOz: return value * 0.0295735
        case .g: return value * 0.001
        case .kg: return value
        case .lb: return value * 0.453592
        case .oz: return value * 0.0283495
        }
    }
    
    private static func fromBase(_ value: Double, unit: ConvertUnit) -> Double {
        switch unit {
        case .mm: return value / 0.001
        case .cm: return value / 0.01
        case .m: return value
        case .inch: return value / 0.0254
        case .ft: return value / 0.3048
        case .km: return value / 1000
        case .mile: return value / 1609.344
        case .sqCm: return value / 0.0001
        case .sqM: return value
        case .sqFt: return value / 0.092903
        case .sqIn: return value / 0.00064516
        case .ml: return value / 0.001
        case .liter: return value
        case .cubicM: return value / 1000
        case .gallon: return value / 3.78541
        case .flOz: return value / 0.0295735
        case .g: return value / 0.001
        case .kg: return value
        case .lb: return value / 0.453592
        case .oz: return value / 0.0283495
        }
    }
}
