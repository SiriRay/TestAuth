import SwiftUI

struct LoginOrSignupView: View {
  @Binding var isAuthenticated: Bool
  @Binding var showCreateProfile: Bool
  @StateObject private var vm = AuthViewModel()

  // MARK: – Cursor Blinking
  @State private var isCursorBlinking = false
  private let blinkTimer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()

  // MARK: – Resend timer
  @State private var remainingSeconds = 0
  private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

  // Fixed width for all components
  private let componentWidth: CGFloat = 325

  // MARK: – Single hidden OTP field
  @State private var otpCode: String = ""
  @FocusState private var isOTPFieldFocused: Bool

  var body: some View {
    VStack(spacing: 20) {
      // ─── HEADER ───────────────────────────────────────────────────────
      Text("Login or Signup")
        .font(.title2).fontWeight(.semibold).multilineTextAlignment(.center).bold().padding(25.0)

      // ─── Phone number + Send/Resend OTP ─────────────────────────────
      VStack(alignment: .leading, spacing: 7) {
        HStack(spacing: 8) {
          Text("🇺🇸")
          Text("+1")
          Divider().frame(height: 24)
          TextField("Phone Number", text: $vm.phoneNumber)
            .keyboardType(.phonePad)
        }
        .padding(.horizontal, 12)
        .frame(width: componentWidth, height: 44)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))

        HStack {
          Spacer()
          Button {
            vm.sendVerificationCode()
            startTimer()
          } label: {
            Text(
              vm.isVerificationSent
                ? (remainingSeconds > 0
                  ? "Resend OTP in \(remainingSeconds)s"
                  : "Resend OTP")
                : "Send OTP"
            )
            .underline()
          }
          .disabled(
            vm.phoneNumber.count < 10 ||
              (vm.isVerificationSent && remainingSeconds > 0)
          )
          .foregroundColor(
            (vm.isVerificationSent && remainingSeconds > 0)
              ? .gray
              : .blue
          )
        }
        .frame(width: componentWidth)
      }

      // ─── SIX-BOX OTP INPUT ──────────────────────────────────────────
      ZStack {
        // Hidden text field
          // In LoginOrSignupView -> body -> ZStack for OTP input

          // Hidden text field
          TextField("", text: $otpCode)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .focused($isOTPFieldFocused)
            .onChange(of: otpCode) {
              // keep digits only, max 6
              let filtered = otpCode.filter { $0.isNumber }
              let truncated = String(filtered.prefix(6))
              if truncated != otpCode {
                  otpCode = truncated
              }
              vm.verificationCode = truncated // Use the sanitized value
              if truncated.count == 6 {
                isOTPFieldFocused = false
              }
            }
            .accentColor(.clear)
            .foregroundColor(.clear)
            .disabled(!vm.isVerificationSent)

        // Visible boxes
        HStack(spacing: 12) {
          ForEach(0..<6) { i in
            ZStack {
              RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .frame(width: 44, height: 44)
              Text(character(at: i))
                .font(.title2)

              // Blinking Cursor
              if i == otpCode.count && isOTPFieldFocused {
                Rectangle()
                  .frame(width: 2, height: 24)
                  .foregroundColor(.pink)
                  .opacity(isCursorBlinking ? 1 : 0)
              }
            }
            .disabled(!vm.isVerificationSent)
            .opacity(vm.isVerificationSent ? 1 : 0.5)
          }
        }
        .contentShape(Rectangle())
        .onTapGesture {
          guard vm.isVerificationSent else { return }
          isOTPFieldFocused = true
        }
      }
      .frame(width: 325.0, height: 44)
      .onChange(of: vm.isVerificationSent) { sent in
        if sent {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isOTPFieldFocused = true
          }
        }
      }

      // ─── Verify button ──────────────────────────────────────────────
      Button("Verify") {
        vm.verifyCode()
      }
      .disabled(!vm.isVerificationSent || otpCode.count < 6)
      .buttonStyle(.borderedProminent)
      .tint(Color.pink)
      .frame(width: componentWidth, height: 44)

      // ─── Error message ──────────────────────────────────────────────
      if let error = vm.errorMessage {
        Text(error)
          .foregroundColor(.red)
          .multilineTextAlignment(.center)
          .frame(width: componentWidth)
      }
    }
    .padding(.top, 40)
    .onReceive(timer) { _ in
      if remainingSeconds > 0 {
        remainingSeconds -= 1
      }
    }
    .onReceive(blinkTimer) { _ in
        isCursorBlinking.toggle()
    }
    .onDisappear {
      timer.upstream.connect().cancel()
      blinkTimer.upstream.connect().cancel()
    }
    .onChange(of: vm.didAuthenticate) { _, newValue in
      isAuthenticated = newValue
    }
    .onChange(of: vm.shouldShowCreateProfile) { _, newValue in
      showCreateProfile = newValue
    }
  }

  private func startTimer() {
    remainingSeconds = 30
  }

  private func character(at index: Int) -> String {
    guard index < otpCode.count else { return "" }
    let idx = otpCode.index(otpCode.startIndex, offsetBy: index)
    return String(otpCode[idx])
  }
}

struct LoginOrSignupView_Previews: PreviewProvider {
  static var previews: some View {
    LoginOrSignupView(
      isAuthenticated: .constant(false),
      showCreateProfile: .constant(false)
    )
  }
}
