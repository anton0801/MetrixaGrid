import Foundation
import SwiftUI
import Combine
import UserNotifications

class AppStore: ObservableObject {
    // MARK: - Published State
    @Published var measurements: [Measurement] = []
    @Published var projects: [Project] = []
    @Published var history: [HistoryEvent] = []
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: AppUser? = nil
    
    // MARK: - Settings (AppStorage backed)
    @AppStorage("unitsSystem") var unitsSystem: String = "metric"
    @AppStorage("themeMode") var themeMode: String = "dark"
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = false
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("userEmail") var savedEmail: String = ""
    @AppStorage("userName") var savedName: String = ""
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    // MARK: - Persistence Keys
    private let measurementsKey = "metrixa_measurements"
    private let projectsKey = "metrixa_projects"
    private let historyKey = "metrixa_history"
    
    init() {
        loadData()
        checkAuth()
        if measurements.isEmpty { loadSampleData() }
    }
    
    // MARK: - Auth
    func checkAuth() {
        isAuthenticated = isLoggedIn
        if isLoggedIn {
            currentUser = AppUser(id: UUID().uuidString, email: savedEmail, name: savedName, createdAt: Date())
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool, String) -> Void) {
        guard !email.isEmpty, email.contains("@") else {
            completion(false, "Invalid email address"); return
        }
        guard password.count >= 6 else {
            completion(false, "Password must be at least 6 characters"); return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.savedEmail = email
            self.savedName = String(email.split(separator: "@").first ?? "User")
            self.isLoggedIn = true
            self.isAuthenticated = true
            self.currentUser = AppUser(id: UUID().uuidString, email: email, name: self.savedName, createdAt: Date())
            completion(true, "")
        }
    }
    
    func signUp(name: String, email: String, password: String, completion: @escaping (Bool, String) -> Void) {
        guard !name.isEmpty else { completion(false, "Name is required"); return }
        guard !email.isEmpty, email.contains("@") else { completion(false, "Invalid email"); return }
        guard password.count >= 6 else { completion(false, "Password too short"); return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.savedEmail = email
            self.savedName = name
            self.isLoggedIn = true
            self.isAuthenticated = true
            self.currentUser = AppUser(id: UUID().uuidString, email: email, name: name, createdAt: Date())
            completion(true, "")
        }
    }
    
    func signOut() {
        withAnimation(.springy) {
            isLoggedIn = false
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    func deleteAccount() {
        signOut()
        clearAllData()
        savedEmail = ""
        savedName = ""
    }
    
    // MARK: - Measurements CRUD
    func addMeasurement(_ m: Measurement) {
        measurements.insert(m, at: 0)
        saveData()
        addHistory(type: .addedMeasurement, title: m.title, detail: m.fullDisplay)
    }
    
    func updateMeasurement(_ m: Measurement) {
        guard let idx = measurements.firstIndex(where: { $0.id == m.id }) else { return }
        measurements[idx] = m
        saveData()
        addHistory(type: .editedMeasurement, title: m.title, detail: m.fullDisplay)
    }
    
    func deleteMeasurement(_ m: Measurement) {
        measurements.removeAll { $0.id == m.id }
        saveData()
        addHistory(type: .deletedMeasurement, title: m.title, detail: m.fullDisplay)
    }
    
    func toggleFavorite(_ m: Measurement) {
        guard let idx = measurements.firstIndex(where: { $0.id == m.id }) else { return }
        measurements[idx].isFavorite.toggle()
        saveData()
    }
    
    func duplicateMeasurement(_ m: Measurement) {
        var copy = m
        copy.id = UUID()
        copy.title = "\(m.title) (copy)"
        copy.date = Date()
        addMeasurement(copy)
    }
    
    // MARK: - Projects CRUD
    func addProject(_ p: Project) {
        projects.insert(p, at: 0)
        saveData()
        addHistory(type: .addedProject, title: p.name, detail: p.description)
    }
    
    func updateProject(_ p: Project) {
        guard let idx = projects.firstIndex(where: { $0.id == p.id }) else { return }
        projects[idx] = p
        saveData()
        addHistory(type: .editedProject, title: p.name, detail: "Updated")
    }
    
    func deleteProject(_ p: Project) {
        projects.removeAll { $0.id == p.id }
        measurements.removeAll { $0.projectId == p.id }
        saveData()
        addHistory(type: .deletedProject, title: p.name, detail: "Removed")
    }
    
    func measurements(for project: Project) -> [Measurement] {
        measurements.filter { $0.projectId == project.id }
    }
    
    // MARK: - History
    func addHistory(type: HistoryEventType, title: String, detail: String) {
        let event = HistoryEvent(type: type, title: title, detail: detail)
        history.insert(event, at: 0)
        if history.count > 200 { history = Array(history.prefix(200)) }
        saveData()
    }
    
    func clearHistory() {
        history.removeAll()
        saveData()
    }
    
    // MARK: - Computed
    var favoriteMeasurements: [Measurement] {
        measurements.filter { $0.isFavorite }
    }
    
    var recentMeasurements: [Measurement] {
        Array(measurements.prefix(5))
    }
    
    // MARK: - Notifications
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
            }
        }
    }
    
    func scheduleReminderNotification() {
        guard notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "Metrixa Grid"
        content.body = "Don't forget to save your measurements today!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 86400, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
    }
    
    // MARK: - Export
    func exportCSV() -> String {
        var csv = "Title,Value,Unit,Project,Category,Date,Note\n"
        for m in measurements {
            let projectName = projects.first(where: { $0.id == m.projectId })?.name ?? ""
            let dateStr = ISO8601DateFormatter().string(from: m.date)
            csv += "\"\(m.title)\",\(m.value),\(m.unit.symbol),\"\(projectName)\",\(m.category.rawValue),\(dateStr),\"\(m.note)\"\n"
        }
        return csv
    }
    
    // MARK: - Persistence
    private func saveData() {
        if let data = try? JSONEncoder().encode(measurements) {
            UserDefaults.standard.set(data, forKey: measurementsKey)
        }
        if let data = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(data, forKey: projectsKey)
        }
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: measurementsKey),
           let items = try? JSONDecoder().decode([Measurement].self, from: data) {
            measurements = items
        }
        if let data = UserDefaults.standard.data(forKey: projectsKey),
           let items = try? JSONDecoder().decode([Project].self, from: data) {
            projects = items
        }
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let items = try? JSONDecoder().decode([HistoryEvent].self, from: data) {
            history = items
        }
    }
    
    func clearAllData() {
        measurements.removeAll()
        projects.removeAll()
        history.removeAll()
        UserDefaults.standard.removeObject(forKey: measurementsKey)
        UserDefaults.standard.removeObject(forKey: projectsKey)
        UserDefaults.standard.removeObject(forKey: historyKey)
    }
    
    private func loadSampleData() {
        let kitchen = Project(name: "Kitchen Renovation", description: "Full kitchen remodel", colorHex: "#22D3EE", icon: "house")
        let workshop = Project(name: "Workshop Layout", description: "Tool organization", colorHex: "#A78BFA", icon: "wrench.and.screwdriver")
        projects = [kitchen, workshop]
        
        measurements = [
            Measurement(title: "Kitchen Wall Width", value: 4.8, unit: .m, projectId: kitchen.id, category: .wall, note: "North wall"),
            Measurement(title: "Desk Width", value: 120, unit: .cm, projectId: workshop.id, category: .furniture, note: "Main workbench"),
            Measurement(title: "Room Height", value: 2.7, unit: .m, projectId: kitchen.id, category: .ceiling, note: "Standard height"),
            Measurement(title: "Shelf Depth", value: 30, unit: .cm, projectId: workshop.id, category: .furniture, note: "Wall shelves"),
            Measurement(title: "Window Width", value: 90, unit: .cm, projectId: kitchen.id, category: .window, note: "Above sink"),
        ]
        measurements[0].isFavorite = true
        measurements[1].isFavorite = true
        saveData()
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @AppStorage("themeMode") var themeMode: String = "dark" {
        didSet { objectWillChange.send() }
    }
    
    var colorScheme: ColorScheme? {
        switch themeMode {
        case "light": return .light
        case "dark": return .dark
        default: return .dark
        }
    }
}
