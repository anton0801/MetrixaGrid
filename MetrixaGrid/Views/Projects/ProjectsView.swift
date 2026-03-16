import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false
    @State private var selectedProject: Project? = nil
    @State private var searchText = ""
    
    var filtered: [Project] {
        if searchText.isEmpty { return store.projects }
        return store.projects.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Projects")
                            .font(AppFont.rounded(26, weight: .bold))
                            .foregroundStyle(LinearGradient.cyanMint)
                        Spacer()
                        Button {
                            showAdd = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.bgPrimary)
                                .frame(width: 34, height: 34)
                                .background(LinearGradient.cyanMint)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    // Search
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundColor(.textSecondary)
                        TextField("Search projects...", text: $searchText)
                            .font(AppFont.standard(15)).foregroundColor(.white).accentColor(.accentCyan)
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.textSecondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    
                    if filtered.isEmpty {
                        EmptyStateView(icon: "folder", message: "No projects yet.\nTap + to create one.")
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(filtered.enumerated()), id: \.1.id) { i, project in
                                    ProjectCard(project: project, measurementCount: store.measurements(for: project).count)
                                        .onTapGesture { selectedProject = project }
                                        .slideIn(delay: Double(i) * 0.05)
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
        .sheet(isPresented: $showAdd) { AddProjectView() }
        .sheet(item: $selectedProject) { p in
            ProjectDetailView(project: p)
        }
    }
}

// MARK: - Project Card
struct ProjectCard: View {
    @EnvironmentObject var store: AppStore
    let project: Project
    let measurementCount: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(project.color.opacity(0.15))
                    .frame(width: 52, height: 52)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(project.color.opacity(0.3), lineWidth: 1))
                Image(systemName: project.icon)
                    .font(.system(size: 22))
                    .foregroundColor(project.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(AppFont.rounded(16, weight: .semibold))
                    .foregroundColor(.white)
                Text(project.description.isEmpty ? "No description" : project.description)
                    .font(AppFont.standard(12))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Label("\(measurementCount) measurements", systemImage: "ruler")
                        .font(AppFont.standard(11))
                        .foregroundColor(.textTertiary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundColor(.textTertiary)
        }
        .padding(16)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(project.color.opacity(0.15), lineWidth: 1)
        )
        .tapScale()
    }
}

// MARK: - Add Project
struct AddProjectView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedColor = Project.defaultColors[0]
    @State private var selectedIcon = Project.defaultIcons[0]
    @State private var showValidation = false
    @State private var savedConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Preview
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(hex: selectedColor).opacity(0.15))
                                .frame(width: 80, height: 80)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: selectedColor).opacity(0.4), lineWidth: 2))
                            Image(systemName: selectedIcon)
                                .font(.system(size: 36))
                                .foregroundColor(Color(hex: selectedColor))
                        }
                        .padding(.top, 16)
                        .animation(.springy, value: selectedColor)
                        .animation(.springy, value: selectedIcon)
                        
                        FormSection(title: "Project Details") {
                            VStack(spacing: 12) {
                                MXTextField(placeholder: "Project Name", text: $name, icon: "folder")
                                MXTextField(placeholder: "Description (optional)", text: $description, icon: "text.alignleft")
                                if showValidation && name.isEmpty {
                                    Text("Project name is required.")
                                        .font(AppFont.standard(12))
                                        .foregroundColor(.errorRed)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        
                        FormSection(title: "Color") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                                ForEach(Project.defaultColors, id: \.self) { hex in
                                    Button {
                                        withAnimation(.springyFast) { selectedColor = hex }
                                    } label: {
                                        Circle()
                                            .fill(Color(hex: hex))
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Circle().stroke(Color.white, lineWidth: selectedColor == hex ? 2 : 0)
                                            )
                                            .scaleEffect(selectedColor == hex ? 1.15 : 1.0)
                                    }
                                    .buttonStyle(NeonButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        FormSection(title: "Icon") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                                ForEach(Project.defaultIcons, id: \.self) { icon in
                                    Button {
                                        withAnimation(.springyFast) { selectedIcon = icon }
                                    } label: {
                                        Image(systemName: icon)
                                            .font(.system(size: 18))
                                            .foregroundColor(selectedIcon == icon ? Color(hex: selectedColor) : .textSecondary)
                                            .frame(width: 36, height: 36)
                                            .background(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.15) : Color.bgCard)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(NeonButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        Button {
                            if name.isEmpty {
                                withAnimation { showValidation = true }
                            } else {
                                let p = Project(name: name, description: description, colorHex: selectedColor, icon: selectedIcon)
                                store.addProject(p)
                                savedConfirmation = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { dismiss() }
                            }
                        } label: {
                            Text(savedConfirmation ? "Created ✓" : "Create Project")
                                .font(AppFont.rounded(16, weight: .semibold))
                                .foregroundColor(.bgPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 16)
                        
                        Spacer(minLength: 60)
                    }
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.textSecondary)
                }
            }
        }
    }
}

// MARK: - Project Detail
struct ProjectDetailView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State var project: Project
    @State private var showEdit = false
    @State private var showAddMeasurement = false
    @State private var showDeleteConfirm = false
    @State private var selectedMeasurement: Measurement? = nil
    
    var measurements: [Measurement] { store.measurements(for: project) }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header card
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(project.color.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                Image(systemName: project.icon)
                                    .font(.system(size: 34))
                                    .foregroundColor(project.color)
                            }
                            Text(project.name)
                                .font(AppFont.rounded(22, weight: .bold))
                                .foregroundColor(.white)
                            if !project.description.isEmpty {
                                Text(project.description)
                                    .font(AppFont.standard(14))
                                    .foregroundColor(.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            HStack(spacing: 16) {
                                StatBadge(label: "measurements", value: "\(measurements.count)", color: project.color)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(Color.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 16)
                        
                        // Add measurement button
                        Button { showAddMeasurement = true } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(project.color)
                                Text("Add Measurement to Project")
                                    .font(AppFont.rounded(15, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(16)
                            .background(project.color.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(project.color.opacity(0.25), lineWidth: 1))
                        }
                        .tapScale()
                        .padding(.horizontal, 16)
                        
                        // Measurements list
                        if !measurements.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Measurements")
                                    .font(AppFont.standard(12, weight: .semibold))
                                    .foregroundColor(.textSecondary)
                                    .padding(.horizontal, 16)
                                ForEach(measurements) { m in
                                    MeasurementRow(measurement: m)
                                        .padding(.horizontal, 16)
                                        .onTapGesture { selectedMeasurement = m }
                                }
                            }
                        } else {
                            EmptyStateView(icon: "ruler", message: "No measurements in this project.")
                        }
                        
                        // Delete project
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            Text("Delete Project")
                                .font(AppFont.standard(15, weight: .medium))
                                .foregroundColor(.errorRed)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.errorRed.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 16)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(project.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.accentCyan)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Edit") { showEdit = true }.foregroundColor(.accentCyan)
                }
            }
        }
        .sheet(isPresented: $showEdit) { EditProjectView(project: $project) }
        .sheet(isPresented: $showAddMeasurement) { AddMeasurementView() }
        .sheet(item: $selectedMeasurement) { m in MeasurementDetailView(measurement: m) }
        .alert("Delete Project?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                store.deleteProject(project)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All measurements in this project will also be deleted.")
        }
    }
}

struct EditProjectView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @Binding var project: Project
    
    @State private var name: String
    @State private var description: String
    @State private var selectedColor: String
    @State private var selectedIcon: String
    
    init(project: Binding<Project>) {
        _project = project
        _name = State(initialValue: project.wrappedValue.name)
        _description = State(initialValue: project.wrappedValue.description)
        _selectedColor = State(initialValue: project.wrappedValue.colorHex)
        _selectedIcon = State(initialValue: project.wrappedValue.icon)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        FormSection(title: "Details") {
                            VStack(spacing: 12) {
                                MXTextField(placeholder: "Project Name", text: $name, icon: "folder")
                                MXTextField(placeholder: "Description", text: $description, icon: "text.alignleft")
                            }
                        }
                        
                        FormSection(title: "Color") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                                ForEach(Project.defaultColors, id: \.self) { hex in
                                    Button { withAnimation(.springyFast) { selectedColor = hex } } label: {
                                        Circle().fill(Color(hex: hex)).frame(width: 32, height: 32)
                                            .overlay(Circle().stroke(Color.white, lineWidth: selectedColor == hex ? 2 : 0))
                                            .scaleEffect(selectedColor == hex ? 1.15 : 1.0)
                                    }.buttonStyle(NeonButtonStyle())
                                }
                            }.padding(.horizontal, 16)
                        }
                        
                        Button {
                            guard !name.isEmpty else { return }
                            project.name = name
                            project.description = description
                            project.colorHex = selectedColor
                            project.icon = selectedIcon
                            project.lastUpdated = Date()
                            store.updateProject(project)
                            dismiss()
                        } label: {
                            Text("Save Changes")
                                .font(AppFont.rounded(16, weight: .semibold))
                                .foregroundColor(.bgPrimary)
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.textSecondary)
                }
            }
        }
    }
}
