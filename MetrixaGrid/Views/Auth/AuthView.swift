import SwiftUI

struct AuthView: View {
    @State private var isLogin = true
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            
            // Background glow
            RadialGradient(
                gradient: Gradient(colors: [Color.accentCyan.opacity(0.1), Color.clear]),
                center: .init(x: 0.5, y: 0.2),
                startRadius: 0,
                endRadius: 400
            ).ignoresSafeArea()
            
            VStack {
                // Logo area
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.bgCard)
                            .frame(width: 64, height: 64)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(LinearGradient.cyanMint.opacity(0.5), lineWidth: 1.5))
                        Image(systemName: "ruler.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(LinearGradient.cyanMint)
                    }
                    Text("Metrixa Grid")
                        .font(AppFont.rounded(22, weight: .bold))
                        .foregroundStyle(LinearGradient.cyanMint)
                }
                .padding(.top, 60)
                .slideIn(from: .top)
                
                Spacer()
                
                // Auth form card
                VStack(spacing: 0) {
                    // Tabs
                    HStack(spacing: 0) {
                        AuthTabButton(label: "Sign In", isSelected: isLogin) {
                            withAnimation(.springy) { isLogin = true }
                        }
                        AuthTabButton(label: "Sign Up", isSelected: !isLogin) {
                            withAnimation(.springy) { isLogin = false }
                        }
                    }
                    .background(Color.bgElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    
                    if isLogin {
                        LoginFormView()
                            .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                    } else {
                        SignUpFormView()
                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

struct AuthTabButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppFont.rounded(15, weight: .semibold))
                .foregroundColor(isSelected ? .bgPrimary : .textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? LinearGradient.cyanMint : LinearGradient(colors: [.clear, .clear], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(3)
        }
    }
}

// MARK: - Login Form
struct LoginFormView: View {
    @EnvironmentObject var store: AppStore
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error = ""
    @State private var showPassword = false
    
    var body: some View {
        VStack(spacing: 16) {
            AuthTextField(placeholder: "Email", text: $email, icon: "envelope", keyboardType: .emailAddress)
            
            HStack {
                AuthTextField(placeholder: "Password", text: $password, icon: "lock", isSecure: !showPassword)
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.textSecondary)
                        .frame(width: 44, height: 44)
                }
                .padding(.trailing, 8)
            }
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
            
            if !error.isEmpty {
                Text(error)
                    .font(AppFont.standard(13))
                    .foregroundColor(.errorRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
            
            Button {
                signIn()
            } label: {
                ZStack {
                    if isLoading {
                        ProgressView()
                            .tint(Color.bgPrimary)
                    } else {
                        Text("Sign In")
                            .font(AppFont.rounded(16, weight: .semibold))
                            .foregroundColor(.bgPrimary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading)
        }
        .padding(.horizontal, 24)
    }
    
    private func signIn() {
        error = ""
        isLoading = true
        store.signIn(email: email, password: password) { success, msg in
            isLoading = false
            if !success { error = msg }
        }
    }
}

// MARK: - Sign Up Form
struct SignUpFormView: View {
    @EnvironmentObject var store: AppStore
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var error = ""
    
    var body: some View {
        VStack(spacing: 16) {
            AuthTextField(placeholder: "Full Name", text: $name, icon: "person")
            AuthTextField(placeholder: "Email", text: $email, icon: "envelope", keyboardType: .emailAddress)
            AuthTextField(placeholder: "Password (min 6 chars)", text: $password, icon: "lock", isSecure: true)
            AuthTextField(placeholder: "Confirm Password", text: $confirmPassword, icon: "lock.fill", isSecure: true)
            
            if !error.isEmpty {
                Text(error)
                    .font(AppFont.standard(13))
                    .foregroundColor(.errorRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
            
            Button {
                signUp()
            } label: {
                ZStack {
                    if isLoading {
                        ProgressView().tint(Color.bgPrimary)
                    } else {
                        Text("Create Account")
                            .font(AppFont.rounded(16, weight: .semibold))
                            .foregroundColor(.bgPrimary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading)
        }
        .padding(.horizontal, 24)
    }
    
    private func signUp() {
        error = ""
        guard password == confirmPassword else {
            error = "Passwords don't match"
            return
        }
        isLoading = true
        store.signUp(name: name, email: email, password: password) { success, msg in
            isLoading = false
            if !success { error = msg }
        }
    }
}

// MARK: - Auth Text Field
struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.textSecondary)
                .frame(width: 20)
                .padding(.leading, 14)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(AppFont.standard(15))
                    .foregroundColor(.white)
                    .accentColor(.accentCyan)
                    .padding(.vertical, 14)
            } else {
                TextField(placeholder, text: $text)
                    .font(AppFont.standard(15))
                    .foregroundColor(.white)
                    .accentColor(.accentCyan)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.vertical, 14)
            }
        }
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}
