import Foundation
import SwiftUI
import Combine

class TemplateStore: ObservableObject {
    @Published var customTemplates: [MeasurementTemplate] = []

    private let persistenceKey = "metrixa_custom_templates"

    // MARK: - Built-in templates

    static let builtIn: [MeasurementTemplate] = [
        MeasurementTemplate(
            name: "Room",
            icon: "square.dashed",
            color: "#22D3EE",
            fields: [
                TemplateField(label: "Length",       defaultUnit: "m",  hint: "Room length"),
                TemplateField(label: "Width",         defaultUnit: "m",  hint: "Room width"),
                TemplateField(label: "Height",        defaultUnit: "m",  hint: "Ceiling height"),
                TemplateField(label: "Window width",  defaultUnit: "cm", hint: "Window opening"),
                TemplateField(label: "Door width",    defaultUnit: "cm", hint: "Door opening"),
            ]
        ),
        MeasurementTemplate(
            name: "Door Frame",
            icon: "rectangle.portrait",
            color: "#2DD4BF",
            fields: [
                TemplateField(label: "Width",      defaultUnit: "cm", hint: "Opening width"),
                TemplateField(label: "Height",     defaultUnit: "cm", hint: "Opening height"),
                TemplateField(label: "Thickness",  defaultUnit: "mm", hint: "Door thickness"),
                TemplateField(label: "Frame depth",defaultUnit: "cm", hint: "Reveal depth"),
            ]
        ),
        MeasurementTemplate(
            name: "Furniture",
            icon: "chair.lounge",
            color: "#A78BFA",
            fields: [
                TemplateField(label: "Width",       defaultUnit: "cm", hint: "Overall width"),
                TemplateField(label: "Depth",        defaultUnit: "cm", hint: "Overall depth"),
                TemplateField(label: "Height",       defaultUnit: "cm", hint: "Overall height"),
                TemplateField(label: "Seat height",  defaultUnit: "cm", hint: "Floor to seat"),
            ]
        ),
        MeasurementTemplate(
            name: "Countertop",
            icon: "rectangle.fill",
            color: "#34D399",
            fields: [
                TemplateField(label: "Length",    defaultUnit: "cm", hint: "Worktop length"),
                TemplateField(label: "Width",     defaultUnit: "cm", hint: "Worktop width"),
                TemplateField(label: "Thickness", defaultUnit: "mm", hint: "Material thickness"),
            ]
        ),
        MeasurementTemplate(
            name: "Window",
            icon: "window.casement",
            color: "#FACC15",
            fields: [
                TemplateField(label: "Width",       defaultUnit: "cm", hint: "Frame width"),
                TemplateField(label: "Height",      defaultUnit: "cm", hint: "Frame height"),
                TemplateField(label: "Sill depth",  defaultUnit: "cm", hint: "Sill projection"),
                TemplateField(label: "Glass width", defaultUnit: "cm", hint: "Glass pane width"),
            ]
        ),
        // "Custom" is always last — has no pre-defined fields
        MeasurementTemplate(
            name: "Custom",
            icon: "plus.circle.dashed",
            color: "#CBD5E1",
            fields: [],
            isCustom: true
        ),
    ]

    // MARK: - Convenience

    /// All templates shown in the picker: built-ins (minus "Custom"), then user templates, then "Custom" last.
    var allForPicker: [MeasurementTemplate] {
        let builtInRegular = Self.builtIn.filter { !$0.isCustom }
        let customEntry    = Self.builtIn.last! // the "Custom" blank slate
        return builtInRegular + customTemplates + [customEntry]
    }

    // MARK: - Init

    init() { loadCustomTemplates() }

    // MARK: - CRUD

    func saveCustomTemplate(_ template: MeasurementTemplate) {
        customTemplates.insert(template, at: 0)
        persist()
    }

    func deleteCustomTemplate(_ template: MeasurementTemplate) {
        customTemplates.removeAll { $0.id == template.id }
        persist()
    }

    // MARK: - Persistence

    private func persist() {
        if let data = try? JSONEncoder().encode(customTemplates) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    private func loadCustomTemplates() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let templates = try? JSONDecoder().decode([MeasurementTemplate].self, from: data) else { return }
        customTemplates = templates
    }
}
