import SwiftUI

// MARK: - Measurements List
struct MeasurementsView: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText = ""
    @State private var selectedFilter: MeasurementFilter = .all
    @State private var selectedProjectFilter: UUID? = nil
    @State private var showAdd = false
    @State private var selectedMeasurement: Measurement? = nil
    @State private var sortOrder: SortOrder = .dateDesc
    
    enum MeasurementFilter: String, CaseIterable {
        case all = "All"
        case favorites = "Favorites"
    }
    
    enum SortOrder: String, CaseIterable {
        case dateDesc = "Newest"
        case dateAsc = "Oldest"
        case title = "A-Z"
    }
    
    var filtered: [Measurement] {
        var result = store.measurements
        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        if selectedFilter == .favorites {
            result = result.filter { $0.isFavorite }
        }
        if let pid = selectedProjectFilter {
            result = result.filter { $0.projectId == pid }
        }
        switch sortOrder {
        case .dateDesc: result.sort { $0.date > $1.date }
        case .dateAsc: result.sort { $0.date < $1.date }
        case .title: result.sort { $0.title < $1.title }
        }
        return result
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        HStack {
                            Text("Measurements")
                                .font(AppFont.rounded(26, weight: .bold))
                                .foregroundStyle(LinearGradient.cyanMint)
                            Spacer()
                            Menu {
                                ForEach(SortOrder.allCases, id: \.self) { order in
                                    Button(order.rawValue) { sortOrder = order }
                                }
                            } label: {
                                Image(systemName: "arrow.up.arrow.down")
                                    .foregroundColor(.textSecondary)
                                    .frame(width: 36, height: 36)
                                    .background(Color.bgCard)
                                    .clipShape(Circle())
                            }
                        }
                        
                        // Search
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.textSecondary)
                            TextField("Search measurements...", text: $searchText)
                                .font(AppFont.standard(15))
                                .foregroundColor(.white)
                                .accentColor(.accentCyan)
                            if !searchText.isEmpty {
                                Button { searchText = "" } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.textSecondary)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Filters
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(MeasurementFilter.allCases, id: \.self) { filter in
                                    FilterChip(label: filter.rawValue, isSelected: selectedFilter == filter) {
                                        withAnimation(.springyFast) { selectedFilter = filter }
                                    }
                                }
                                
                                Divider().frame(height: 20).background(Color.textTertiary)
                                
                                FilterChip(label: "All Projects", isSelected: selectedProjectFilter == nil) {
                                    withAnimation(.springyFast) { selectedProjectFilter = nil }
                                }
                                ForEach(store.projects) { project in
                                    FilterChip(label: project.name, isSelected: selectedProjectFilter == project.id, color: project.color) {
                                        withAnimation(.springyFast) {
                                            selectedProjectFilter = selectedProjectFilter == project.id ? nil : project.id
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    
                    // Stats bar
                    HStack(spacing: 16) {
                        StatBadge(label: "Total", value: "\(filtered.count)", color: .accentCyan)
                        StatBadge(label: "Favorites", value: "\(filtered.filter { $0.isFavorite }.count)", color: .warningYellow)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    
                    // List
                    if filtered.isEmpty {
                        EmptyStateView(icon: "ruler", message: searchText.isEmpty ? "No measurements yet.\nTap + to add one." : "No results found.")
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 10) {
                                ForEach(filtered) { m in
                                    MeasurementRow(measurement: m)
                                        .onTapGesture { selectedMeasurement = m }
                                        .padding(.horizontal, 16)
                                }
                            }
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAdd) { AddMeasurementView() }
        .sheet(item: $selectedMeasurement) { m in
            MeasurementDetailView(measurement: m)
        }
    }
}

// MARK: - Measurement Row
struct MeasurementRow: View {
    @EnvironmentObject var store: AppStore
    let measurement: Measurement
    @State private var showDetail = false
    
    var projectName: String {
        store.projects.first(where: { $0.id == measurement.projectId })?.name ?? ""
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(measurement.category.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: measurement.category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(measurement.category.color)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(measurement.title)
                    .font(AppFont.standard(15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if !projectName.isEmpty {
                        Text(projectName)
                            .font(AppFont.standard(11))
                            .foregroundColor(.accentCyan)
                    }
                    Text(measurement.category.rawValue)
                        .font(AppFont.standard(11))
                        .foregroundColor(.textSecondary)
                    Text("•")
                        .font(AppFont.standard(11))
                        .foregroundColor(.textTertiary)
                    Text(measurement.date, style: .date)
                        .font(AppFont.standard(11))
                        .foregroundColor(.textTertiary)
                }
            }
            
            Spacer()
            
            // Value + favorite
            VStack(alignment: .trailing, spacing: 4) {
                Text(measurement.fullDisplay)
                    .font(AppFont.mono(16, weight: .bold))
                    .foregroundColor(.white)
                if measurement.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.warningYellow)
                }
            }
        }
        .padding(14)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
        .contextMenu {
            Button {
                store.toggleFavorite(measurement)
            } label: {
                Label(measurement.isFavorite ? "Remove Favorite" : "Add to Favorites",
                      systemImage: measurement.isFavorite ? "star.slash" : "star")
            }
            Button {
                store.duplicateMeasurement(measurement)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            Button(role: .destructive) {
                store.deleteMeasurement(measurement)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .tapScale()
    }
}

// MARK: - Add Measurement
struct AddMeasurementView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var valueString = ""
    @State private var unit: MeasurementUnit = .cm
    @State private var category: MeasurementCategory = .general
    @State private var selectedProjectId: UUID? = nil
    @State private var note = ""
    @State private var isFavorite = false
    @State private var showImagePicker = false
    @State private var photoData: Data? = nil
    @State private var showValidation = false
    @State private var savedConfirmation = false
    
    var isValid: Bool { !title.isEmpty && Double(valueString) != nil }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Title
                        FormSection(title: "Measurement Details") {
                            VStack(spacing: 12) {
                                MXTextField(placeholder: "Title (e.g. Kitchen Wall)", text: $title, icon: "textformat")
                                
                                HStack(spacing: 12) {
                                    MXTextField(placeholder: "Value", text: $valueString, icon: "number", keyboardType: .decimalPad)
                                    
                                    // Unit picker
                                    Menu {
                                        ForEach(MeasurementUnit.allCases, id: \.self) { u in
                                            Button(u.symbol) { unit = u }
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text(unit.symbol)
                                                .font(AppFont.mono(16, weight: .bold))
                                                .foregroundColor(.accentCyan)
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 11))
                                                .foregroundColor(.textSecondary)
                                        }
                                        .padding(.horizontal, 16)
                                        .frame(height: 50)
                                        .background(Color.bgCard)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
                                    }
                                    .frame(width: 80)
                                }
                                
                                if showValidation && (title.isEmpty || Double(valueString) == nil) {
                                    Text("Please fill in title and a valid numeric value.")
                                        .font(AppFont.standard(12))
                                        .foregroundColor(.errorRed)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        
                        // Category
                        FormSection(title: "Category") {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 85))], spacing: 8) {
                                ForEach(MeasurementCategory.allCases, id: \.self) { cat in
                                    Button {
                                        withAnimation(.springyFast) { category = cat }
                                    } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 18))
                                                .foregroundColor(category == cat ? .bgPrimary : cat.color)
                                            Text(cat.rawValue)
                                                .font(AppFont.standard(11, weight: .medium))
                                                .foregroundColor(category == cat ? .bgPrimary : .textSecondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(category == cat ? cat.color : cat.color.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(NeonButtonStyle())
                                }
                            }
                        }
                        
                        // Project
                        FormSection(title: "Project (optional)") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    FilterChip(label: "None", isSelected: selectedProjectId == nil) {
                                        selectedProjectId = nil
                                    }
                                    ForEach(store.projects) { project in
                                        FilterChip(label: project.name, isSelected: selectedProjectId == project.id, color: project.color) {
                                            selectedProjectId = project.id
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Note
                        FormSection(title: "Note (optional)") {
                            ZStack(alignment: .topLeading) {
                                if note.isEmpty {
                                    Text("Add a note...")
                                        .font(AppFont.standard(15))
                                        .foregroundColor(.textTertiary)
                                        .padding(.top, 12)
                                        .padding(.leading, 4)
                                }
                                TextEditor(text: $note)
                                    .font(AppFont.standard(15))
                                    .foregroundColor(.white)
                                    .accentColor(.accentCyan)
                                    .frame(minHeight: 80)
                                    .scrollContentBackground(.hidden)
                            }
                            .padding(12)
                            .background(Color.bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
                        }
                        
                        // Favorite toggle
                        FormSection(title: "Options") {
                            Toggle(isOn: $isFavorite) {
                                HStack(spacing: 10) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.warningYellow)
                                    Text("Add to Favorites")
                                        .font(AppFont.standard(15))
                                        .foregroundColor(.white)
                                }
                            }
                            .tint(.warningYellow)
                            .padding(14)
                            .background(Color.bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Save
                        Button {
                            if isValid {
                                let m = Measurement(
                                    title: title,
                                    value: Double(valueString) ?? 0,
                                    unit: unit,
                                    projectId: selectedProjectId,
                                    category: category,
                                    note: note,
                                    photoData: photoData,
                                    isFavorite: isFavorite
                                )
                                store.addMeasurement(m)
                                withAnimation { savedConfirmation = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
                            } else {
                                withAnimation { showValidation = true }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if savedConfirmation {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.bgPrimary)
                                    Text("Saved!")
                                        .font(AppFont.rounded(17, weight: .semibold))
                                        .foregroundColor(.bgPrimary)
                                } else {
                                    Image(systemName: "square.and.arrow.down")
                                        .foregroundColor(.bgPrimary)
                                    Text("Save Measurement")
                                        .font(AppFont.rounded(17, weight: .semibold))
                                        .foregroundColor(.bgPrimary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(PrimaryButtonStyle(gradient: savedConfirmation ? LinearGradient(colors: [.resultGreen, .resultGreen.opacity(0.8)], startPoint: .leading, endPoint: .trailing) : .cyanMint))
                        .padding(.horizontal, 16)
                        .animation(.springy, value: savedConfirmation)
                        
                        Spacer(minLength: 60)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("New Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }
}

// MARK: - Measurement Detail
struct MeasurementDetailView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State var measurement: Measurement
    @State private var isEditing = false
    @State private var showConvert = false
    @State private var showDeleteConfirm = false
    
    var projectName: String {
        store.projects.first(where: { $0.id == measurement.projectId })?.name ?? "No Project"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Value hero
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(measurement.category.color.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                Image(systemName: measurement.category.icon)
                                    .font(.system(size: 34))
                                    .foregroundColor(measurement.category.color)
                            }
                            Text(measurement.fullDisplay)
                                .font(AppFont.mono(42, weight: .bold))
                                .foregroundColor(.white)
                                .glow(color: .accentCyan, radius: 8)
                            Text(measurement.title)
                                .font(AppFont.rounded(18, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, 16)
                        .slideIn()
                        
                        // Meta info
                        VStack(spacing: 0) {
                            DetailRow(label: "Category", value: measurement.category.rawValue, icon: measurement.category.icon)
                            Divider().background(Color.textTertiary.opacity(0.3))
                            DetailRow(label: "Project", value: projectName, icon: "folder")
                            Divider().background(Color.textTertiary.opacity(0.3))
                            DetailRow(label: "Date", value: measurement.date.formatted(date: .long, time: .omitted), icon: "calendar")
                            if !measurement.note.isEmpty {
                                Divider().background(Color.textTertiary.opacity(0.3))
                                DetailRow(label: "Note", value: measurement.note, icon: "note.text")
                            }
                        }
                        .cardStyle()
                        .padding(.horizontal, 16)
                        .slideIn(delay: 0.05)
                        
                        // Actions
                        VStack(spacing: 10) {
                            Button {
                                isEditing = true
                            } label: {
                                ActionRowButton(label: "Edit Measurement", icon: "pencil", color: .accentCyan)
                            }
                            Button {
                                store.toggleFavorite(measurement)
                                measurement.isFavorite.toggle()
                            } label: {
                                ActionRowButton(
                                    label: measurement.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                                    icon: measurement.isFavorite ? "star.slash" : "star",
                                    color: .warningYellow
                                )
                            }
                            Button {
                                store.duplicateMeasurement(measurement)
                                dismiss()
                            } label: {
                                ActionRowButton(label: "Duplicate", icon: "doc.on.doc", color: .accentMint)
                            }
                            Button {
                                showConvert = true
                            } label: {
                                ActionRowButton(label: "Convert Units", icon: "arrow.left.arrow.right", color: .accentViolet)
                            }
                            Button {
                                showDeleteConfirm = true
                            } label: {
                                ActionRowButton(label: "Delete", icon: "trash", color: .errorRed)
                            }
                        }
                        .padding(.horizontal, 16)
                        .slideIn(delay: 0.1)
                        
                        Spacer(minLength: 60)
                    }
                }
            }
            .navigationTitle(measurement.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.accentCyan)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditMeasurementView(measurement: $measurement)
        }
        .sheet(isPresented: $showConvert) {
            ConvertMeasurementView(measurement: measurement)
        }
        .alert("Delete Measurement?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                store.deleteMeasurement(measurement)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(.textSecondary)
                .frame(width: 22)
            Text(label)
                .font(AppFont.standard(14))
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(AppFont.standard(14, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}

struct ActionRowButton: View {
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            Text(label)
                .font(AppFont.standard(15, weight: .medium))
                .foregroundColor(label == "Delete" ? .errorRed : .white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundColor(.textTertiary)
        }
        .padding(16)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
        .tapScale()
    }
}

// MARK: - Edit Measurement
struct EditMeasurementView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @Binding var measurement: Measurement
    
    @State private var title: String
    @State private var valueString: String
    @State private var unit: MeasurementUnit
    @State private var category: MeasurementCategory
    @State private var note: String
    @State private var savedConfirmation = false
    
    init(measurement: Binding<Measurement>) {
        _measurement = measurement
        _title = State(initialValue: measurement.wrappedValue.title)
        _valueString = State(initialValue: measurement.wrappedValue.displayValue)
        _unit = State(initialValue: measurement.wrappedValue.unit)
        _category = State(initialValue: measurement.wrappedValue.category)
        _note = State(initialValue: measurement.wrappedValue.note)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        FormSection(title: "Edit Details") {
                            VStack(spacing: 12) {
                                MXTextField(placeholder: "Title", text: $title, icon: "textformat")
                                HStack(spacing: 12) {
                                    MXTextField(placeholder: "Value", text: $valueString, icon: "number", keyboardType: .decimalPad)
                                    Menu {
                                        ForEach(MeasurementUnit.allCases, id: \.self) { u in
                                            Button(u.symbol) { unit = u }
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text(unit.symbol)
                                                .font(AppFont.mono(16, weight: .bold))
                                                .foregroundColor(.accentCyan)
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 11))
                                                .foregroundColor(.textSecondary)
                                        }
                                        .padding(.horizontal, 16)
                                        .frame(height: 50)
                                        .background(Color.bgCard)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
                                    }
                                    .frame(width: 80)
                                }
                            }
                        }
                        
                        FormSection(title: "Note") {
                            MXTextField(placeholder: "Note", text: $note, icon: "note.text")
                        }
                        
                        Button {
                            guard !title.isEmpty, let val = Double(valueString) else { return }
                            measurement.title = title
                            measurement.value = val
                            measurement.unit = unit
                            measurement.category = category
                            measurement.note = note
                            store.updateMeasurement(measurement)
                            savedConfirmation = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { dismiss() }
                        } label: {
                            Text(savedConfirmation ? "Saved ✓" : "Save Changes")
                                .font(AppFont.rounded(16, weight: .semibold))
                                .foregroundColor(.bgPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Edit Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.textSecondary)
                }
            }
        }
    }
}

// MARK: - Convert Measurement Sheet
struct ConvertMeasurementView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let measurement: Measurement
    
    @State private var toUnit: ConvertUnit = .inch
    
    var fromUnit: ConvertUnit {
        ConvertUnit.allCases.first { $0.symbol == measurement.unit.symbol } ?? .cm
    }
    
    var result: Double? {
        ConversionService.convert(measurement.value, from: fromUnit, to: toUnit)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                VStack(spacing: 24) {
                    // From
                    VStack(spacing: 8) {
                        Text("Original Value")
                            .font(AppFont.standard(13))
                            .foregroundColor(.textSecondary)
                        Text(measurement.fullDisplay)
                            .font(AppFont.mono(36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Image(systemName: "arrow.down")
                        .font(.system(size: 24))
                        .foregroundColor(.accentCyan)
                    
                    // Target unit
                    VStack(spacing: 12) {
                        Text("Convert to")
                            .font(AppFont.standard(13))
                            .foregroundColor(.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(ConvertUnit.allCases.filter { $0.category == fromUnit.category }, id: \.self) { u in
                                    FilterChip(label: u.symbol, isSelected: toUnit == u) {
                                        withAnimation(.springyFast) { toUnit = u }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    
                    // Result
                    if let res = result {
                        VStack(spacing: 4) {
                            Text("Result")
                                .font(AppFont.standard(13))
                                .foregroundColor(.textSecondary)
                            Text(String(format: "%.4f", res).replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression) + " \(toUnit.symbol)")
                                .font(AppFont.mono(42, weight: .bold))
                                .foregroundColor(.resultGreen)
                                .glow(color: .resultGreen, radius: 6)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(Color.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.resultGreen.opacity(0.25), lineWidth: 1))
                        .padding(.horizontal, 16)
                        
                        Button {
                            store.addHistory(type: .convertedUnit, title: "\(measurement.title)", detail: "\(measurement.fullDisplay) → \(String(format: "%.4f", res)) \(toUnit.symbol)")
                            dismiss()
                        } label: {
                            Text("Log Conversion")
                                .font(AppFont.rounded(16, weight: .semibold))
                                .foregroundColor(.bgPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 16)
                    }
                    
                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationTitle("Convert Units")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.accentCyan)
                }
            }
        }
    }
}

// MARK: - Shared UI Components
struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = .accentCyan
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppFont.standard(13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .bgPrimary : .textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color.bgCard)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? Color.clear : Color.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(NeonButtonStyle())
    }
}

struct StatBadge: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Text(value)
                .font(AppFont.mono(14, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(AppFont.standard(12))
                .foregroundColor(.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFont.standard(12, weight: .semibold))
                .foregroundColor(.textSecondary)
                .padding(.horizontal, 16)
            content()
                .padding(.horizontal, 16)
        }
    }
}

struct MXTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(.textSecondary)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .font(AppFont.standard(15))
                .foregroundColor(.white)
                .accentColor(.accentCyan)
                .keyboardType(keyboardType)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}

struct EmptyStateView: View {
    let icon: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.textTertiary)
            Text(message)
                .font(AppFont.standard(15))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.vertical, 60)
    }
}
