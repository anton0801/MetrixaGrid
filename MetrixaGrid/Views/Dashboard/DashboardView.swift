import SwiftUI
import WebKit

struct DashboardView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var templateStore: TemplateStore
    @Binding var selectedTab: Int

    // Existing sheets
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var showAddMeasurement = false

    // Feature 3 — Quick Input FAB
    @State private var showQuickInput = false
    @State private var fabShowCheckmark = false

    // Feature 1 — Search
    @StateObject private var searchVM = SearchViewModel()
    @State private var isSearchActive = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                // ── Main scroll content ────────────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        DashboardHeader(showSettings: $showSettings, showHistory: $showHistory)

                        // ── Search bar (Feature 1) ─────────────────────
                        SearchBar(text: $searchVM.query, isActive: $isSearchActive)
                            .padding(.horizontal, 16)

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
                                LinearGradient(
                                    colors: [Color.accentCyan.opacity(0.15), Color.accentMint.opacity(0.08)],
                                    startPoint: .leading, endPoint: .trailing
                                )
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

                // ── Search results overlay (Feature 1) ─────────────────
                if isSearchActive {
                    ZStack(alignment: .top) {
                        // Tap-to-dismiss background
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    isSearchActive = false
                                }
                            }

                        // Results panel pinned below the search bar area
                        // (header ≈ 90pt + search bar ≈ 52pt + padding = 148pt)
                        VStack(spacing: 0) {
                            Color.clear.frame(height: 148)
                            SearchResultsView(viewModel: searchVM, isSearchActive: $isSearchActive)
                        }
                    }
                    .transition(.opacity)
                    .zIndex(5)
                }

                // ── FAB button (Feature 3) ──────────────────────────────
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FABButton(isSheetOpen: $showQuickInput, showCheckmark: $fabShowCheckmark)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 90) // above tab bar
                }
                .zIndex(10)
                .allowsHitTesting(!isSearchActive)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(store)
        }
        .sheet(isPresented: $showHistory) {
            HistoryView().environmentObject(store)
        }
        .sheet(isPresented: $showAddMeasurement) {
            AddMeasurementView()
                .environmentObject(store)
                .environmentObject(templateStore)
        }
        // Feature 3 — Quick Input sheet
        .sheet(isPresented: $showQuickInput) {
            QuickInputSheet(onSaved: {
                fabShowCheckmark = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    fabShowCheckmark = false
                }
            })
            .environmentObject(store)
        }
        .onAppear {
            searchVM.setup(store: store)
        }
        .onChange(of: isSearchActive) { active in
            if !active {
                if !searchVM.query.isEmpty {
                    searchVM.addRecentSearch(searchVM.query)
                }
                searchVM.query = ""
            }
        }
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

struct MetrixaWebView: View {
    @State private var targetURL: String? = ""
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            if isActive, let urlString = targetURL, let url = URL(string: urlString) {
                WebContainer(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in reload() }
    }
    
    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: "temp_url")
        let stored = UserDefaults.standard.string(forKey: "mg_endpoint_target") ?? ""
        targetURL = temp ?? stored
        isActive = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: "temp_url") }
    }
    
    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            isActive = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = true }
        }
    }
}

struct WebContainer: UIViewRepresentable {
    let url: URL
    
    func makeCoordinator() -> WebCoordinator { WebCoordinator() }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = buildWebView(coordinator: context.coordinator)
        context.coordinator.webView = webView
        context.coordinator.loadURL(url, in: webView)
        Task { await context.coordinator.loadCookies(in: webView) }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func buildWebView(coordinator: WebCoordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        
        let contentController = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                const style = document.createElement('style');
                style.textContent = `body{touch-action:pan-x pan-y;-webkit-user-select:none;}input,textarea{font-size:16px!important;}`;
                document.head.appendChild(style);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(script)
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = pagePreferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        return webView
    }
}

final class WebCoordinator: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = "metrixa_cookies"
    
    func loadURL(_ url: URL, in webView: WKWebView) {
        print("📊 [Metrixa] Load: \(url.absoluteString)")
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }
    
    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}

extension WebCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current; print("✅ [Metrixa] Commit: \(current.absoluteString)") }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

extension WebCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self; popup.uiDelegate = self; popup.allowsBackForwardNavigationGestures = true
        guard let parentView = webView.superview else { return nil }
        parentView.addSubview(popup)
        popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            popup.topAnchor.constraint(equalTo: webView.topAnchor),
            popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        ])
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:)))
        gesture.delegate = self
        popup.scrollView.panGestureRecognizer.require(toFail: gesture)
        popup.addGestureRecognizer(gesture)
        popups.append(popup)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" { popup.load(navigationAction.request) }
        return popup
    }

    @objc private func handlePopupPan(_ recognizer: UIPanGestureRecognizer) {
        guard let popupView = recognizer.view else { return }
        let translation = recognizer.translation(in: popupView)
        let velocity = recognizer.velocity(in: popupView)
        switch recognizer.state {
        case .changed:
            if translation.x > 0 { popupView.transform = CGAffineTransform(translationX: translation.x, y: 0) }
        case .ended, .cancelled:
            if translation.x > popupView.bounds.width * 0.4 || velocity.x > 800 {
                UIView.animate(withDuration: 0.25, animations: {
                    popupView.transform = CGAffineTransform(translationX: popupView.bounds.width, y: 0)
                }) { [weak self] _ in
                    if let last = self?.popups.last { last.removeFromSuperview(); self?.popups.removeLast() }
                }
            } else {
                UIView.animate(withDuration: 0.2) { popupView.transform = .identity }
            }
        default: break
        }
    }

    func webViewDidClose(_ webView: WKWebView) {
        if let index = popups.firstIndex(of: webView) { webView.removeFromSuperview(); popups.remove(at: index) }
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) { completionHandler() }
}

extension WebCoordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = pan.view else { return false }
        let velocity = pan.velocity(in: view)
        let translation = pan.translation(in: view)
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}
