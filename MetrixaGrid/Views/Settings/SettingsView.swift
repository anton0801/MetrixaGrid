import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("unitsSystem") var unitsSystem: String = "metric"
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = false
    @State private var showExportSheet = false
    @State private var exportText = ""
    @State private var showDeleteConfirm = false
    @State private var showClearDataConfirm = false
    @State private var showNotifPermAlert = false
    @State private var backupSuccess = false
    @State private var notifStatus = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Profile card
                        ProfileCard()
                        
                        // Units
                        SettingsSection(title: "Units System") {
                            VStack(spacing: 0) {
                                SettingsOptionRow(
                                    label: "Metric",
                                    subtitle: "mm, cm, m, kg, L",
                                    icon: "ruler",
                                    iconColor: .accentCyan,
                                    isSelected: unitsSystem == "metric"
                                ) {
                                    withAnimation(.springyFast) { unitsSystem = "metric" }
                                }
                                Divider().background(Color.white.opacity(0.06)).padding(.leading, 52)
                                SettingsOptionRow(
                                    label: "Imperial",
                                    subtitle: "inch, ft, lb, gal",
                                    icon: "ruler",
                                    iconColor: .accentMint,
                                    isSelected: unitsSystem == "imperial"
                                ) {
                                    withAnimation(.springyFast) { unitsSystem = "imperial" }
                                }
                            }
                            .background(Color.bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        // Theme
                        SettingsSection(title: "Theme") {
                            VStack(spacing: 0) {
                                SettingsOptionRow(
                                    label: "Dark",
                                    subtitle: "Dark blue background",
                                    icon: "moon.fill",
                                    iconColor: .accentViolet,
                                    isSelected: themeManager.themeMode == "dark"
                                ) {
                                    withAnimation(.springy) { themeManager.themeMode = "dark" }
                                }
                                Divider().background(Color.white.opacity(0.06)).padding(.leading, 52)
                                SettingsOptionRow(
                                    label: "Midnight",
                                    subtitle: "Pure black OLED",
                                    icon: "moon.stars.fill",
                                    iconColor: Color(hex: "#6366F1"),
                                    isSelected: themeManager.themeMode == "midnight"
                                ) {
                                    withAnimation(.springy) { themeManager.themeMode = "midnight" }
                                }
                                Divider().background(Color.white.opacity(0.06)).padding(.leading, 52)
                                SettingsOptionRow(
                                    label: "Light",
                                    subtitle: "Clean light mode",
                                    icon: "sun.max.fill",
                                    iconColor: .warningYellow,
                                    isSelected: themeManager.themeMode == "light"
                                ) {
                                    withAnimation(.springy) { themeManager.themeMode = "light" }
                                }
                            }
                            .background(Color.bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        // Notifications
                        SettingsSection(title: "Notifications") {
                            VStack(spacing: 0) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.accentCyan.opacity(0.15))
                                            .frame(width: 34, height: 34)
                                        Image(systemName: "bell.fill")
                                            .font(.system(size: 15))
                                            .foregroundColor(.accentCyan)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Daily Reminders")
                                            .font(AppFont.standard(15))
                                            .foregroundColor(.white)
                                        Text(notifStatus.isEmpty ? "Get reminded to log measurements" : notifStatus)
                                            .font(AppFont.standard(12))
                                            .foregroundColor(notifStatus.contains("✓") ? .resultGreen : .textSecondary)
                                    }
                                    Spacer()
                                    Toggle("", isOn: Binding(
                                        get: { notificationsEnabled },
                                        set: { newValue in
                                            if newValue {
                                                requestNotifications()
                                            } else {
                                                store.cancelNotifications()
                                                notificationsEnabled = false
                                                notifStatus = "Disabled"
                                            }
                                        }
                                    ))
                                    .tint(.accentCyan)
                                }
                                .padding(14)
                            }
                            .background(Color.bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        // Data Management
                        SettingsSection(title: "Data") {
                            VStack(spacing: 0) {
                                SettingsActionRow(label: "Export to CSV", icon: "square.and.arrow.up", iconColor: .accentMint) {
                                    exportText = store.exportCSV()
                                    showExportSheet = true
                                }
                                Divider().background(Color.white.opacity(0.06)).padding(.leading, 52)
                                SettingsActionRow(
                                    label: backupSuccess ? "Backup Saved ✓" : "Backup Data",
                                    icon: backupSuccess ? "checkmark.circle" : "externaldrive.fill",
                                    iconColor: backupSuccess ? .resultGreen : .accentViolet
                                ) {
                                    // Simulate backup by saving all data
                                    let csv = store.exportCSV()
                                    UserDefaults.standard.set(csv, forKey: "metrixa_backup_\(Date().timeIntervalSince1970)")
                                    withAnimation { backupSuccess = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation { backupSuccess = false }
                                    }
                                }
                                Divider().background(Color.white.opacity(0.06)).padding(.leading, 52)
                                SettingsActionRow(label: "Clear All Data", icon: "trash", iconColor: .warningYellow) {
                                    showClearDataConfirm = true
                                }
                            }
                            .background(Color.bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        // Stats
                        SettingsSection(title: "Your Stats") {
                            HStack(spacing: 0) {
                                StatItem(value: "\(store.measurements.count)", label: "Measurements", color: .accentCyan)
                                Divider().frame(width: 1, height: 50).background(Color.white.opacity(0.06))
                                StatItem(value: "\(store.projects.count)", label: "Projects", color: .accentMint)
                                Divider().frame(width: 1, height: 50).background(Color.white.opacity(0.06))
                                StatItem(value: "\(store.history.count)", label: "History", color: .accentViolet)
                            }
                            .background(Color.bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        // Account
                        SettingsSection(title: "Account") {
                            VStack(spacing: 0) {
                                SettingsActionRow(label: "Sign Out", icon: "arrow.right.circle", iconColor: .textSecondary) {
                                    store.signOut()
                                    dismiss()
                                }
                                Divider().background(Color.white.opacity(0.06)).padding(.leading, 52)
                                SettingsActionRow(label: "Delete Account", icon: "person.crop.circle.badge.minus", iconColor: .errorRed, isDestructive: true) {
                                    showDeleteConfirm = true
                                }
                            }
                            .background(Color.bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        // App info
                        VStack(spacing: 4) {
                            Text("Metrixa Grid")
                                .font(AppFont.rounded(14, weight: .semibold))
                                .foregroundColor(.textSecondary)
                            Text("Version 1.0.0")
                                .font(AppFont.standard(12))
                                .foregroundColor(.textTertiary)
                        }
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.accentCyan)
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ExportView(csvText: exportText)
        }
        .alert("Delete Account", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                store.deleteAccount()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and all data. This action cannot be undone.")
        }
        .alert("Clear All Data?", isPresented: $showClearDataConfirm) {
            Button("Clear All", role: .destructive) {
                store.clearAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All measurements, projects, and history will be permanently deleted.")
        }
    }
    
    private func requestNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .authorized {
                    notificationsEnabled = true
                    store.scheduleReminderNotification()
                    notifStatus = "✓ Daily reminders enabled"
                } else if settings.authorizationStatus == .denied {
                    notificationsEnabled = false
                    notifStatus = "Permission denied in Settings"
                } else {
                    store.requestNotificationPermission()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        UNUserNotificationCenter.current().getNotificationSettings { s in
                            DispatchQueue.main.async {
                                if s.authorizationStatus == .authorized {
                                    notificationsEnabled = true
                                    store.scheduleReminderNotification()
                                    notifStatus = "✓ Daily reminders enabled"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Profile Card
struct ProfileCard: View {
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient.cyanMint)
                    .frame(width: 60, height: 60)
                Text(String(store.currentUser?.name.prefix(1).uppercased() ?? "U"))
                    .font(AppFont.rounded(26, weight: .bold))
                    .foregroundColor(.bgPrimary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(store.currentUser?.name ?? "User")
                    .font(AppFont.rounded(18, weight: .bold))
                    .foregroundColor(.white)
                Text(store.currentUser?.email ?? "")
                    .font(AppFont.standard(13))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 22))
                .foregroundStyle(LinearGradient.cyanMint)
        }
        .padding(16)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(LinearGradient.cyanMint.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Settings Components
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(AppFont.standard(11, weight: .semibold))
                .foregroundColor(.textSecondary)
                .tracking(1)
            content()
        }
    }
}

struct SettingsOptionRow: View {
    let label: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundColor(iconColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(AppFont.standard(15))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(AppFont.standard(12))
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(LinearGradient.cyanMint)
                }
            }
            .padding(14)
        }
        .buttonStyle(NeonButtonStyle())
    }
}

struct SettingsActionRow: View {
    let label: String
    let icon: String
    let iconColor: Color
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundColor(iconColor)
                }
                Text(label)
                    .font(AppFont.standard(15))
                    .foregroundColor(isDestructive ? .errorRed : .white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(.textTertiary)
            }
            .padding(14)
        }
        .buttonStyle(NeonButtonStyle())
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppFont.mono(22, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(AppFont.standard(11))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

// MARK: - Export View
struct ExportView: View {
    @Environment(\.dismiss) var dismiss
    let csvText: String
    @State private var copied = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.accentMint)
                        Text("CSV Export")
                            .font(AppFont.rounded(16, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(csvText.components(separatedBy: "\n").count - 1) rows")
                            .font(AppFont.mono(12))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(14)
                    .background(Color.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    ScrollView(showsIndicators: true) {
                        Text(csvText)
                            .font(AppFont.mono(11))
                            .foregroundColor(.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                    }
                    .background(Color.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxHeight: 300)
                    
                    Button {
                        UIPasteboard.general.string = csvText
                        withAnimation { copied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { copied = false }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: copied ? "checkmark" : "doc.on.clipboard")
                            Text(copied ? "Copied to Clipboard!" : "Copy to Clipboard")
                                .font(AppFont.rounded(16, weight: .semibold))
                        }
                        .foregroundColor(.bgPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(PrimaryButtonStyle(gradient: copied
                        ? LinearGradient(colors: [.resultGreen, .resultGreen.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        : .cyanMint))
                    .animation(.springy, value: copied)
                    
                    ShareLink(item: csvText, subject: Text("Metrixa Grid Export"), message: Text("My measurements exported from Metrixa Grid")) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share CSV File")
                                .font(AppFont.rounded(15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.bgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.accentCyan)
                }
            }
        }
    }
}
