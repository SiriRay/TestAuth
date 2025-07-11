import SwiftUI

struct LoginOrSignupView: View {
  @Binding var isAuthenticated: Bool
  @Binding var showCreateProfile: Bool
  @StateObject private var vm = AuthViewModel()

  // MARK: – Resend timer
  @State private var remainingSeconds = 0
  private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

  // Fixed width for all components
  private let componentWidth: CGFloat = 325

  // MARK: – Six-digit input state
  @State private var codeDigits = Array(repeating: "", count: 6)
  @FocusState private var focusedIndex: Int?

  private func updateVMCode() {
    vm.verificationCode = codeDigits.joined()
  }

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

      // ─── Six-box OTP input ──────────────────────────────────────────
      HStack(spacing: 12) {
        ForEach(0..<6) { i in
          TextField("", text: $codeDigits[i])
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .focused($focusedIndex, equals: i)
            .frame(width: 44, height: 44)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .disabled(!vm.isVerificationSent)
            .opacity(vm.isVerificationSent ? 1 : 0.5)
            .onChange(of: codeDigits[i]) { oldValue, newValue in
              // Handle input (typing)
              if newValue.count > 1 {
                codeDigits[i] = String(newValue.suffix(1))
              }
              
              // Handle backspace (deletion)
              if newValue.isEmpty && !oldValue.isEmpty {
                // User deleted content, move to previous box
                if i > 0 {
                  focusedIndex = i - 1
                }
              } else if codeDigits[i].count == 1 {
                // User entered a digit, move to next box
                focusedIndex = (i < 5 ? i + 1 : nil)
              }
              
              updateVMCode()
            }
        }
      }
      .onChange(of: vm.isVerificationSent) {
          focusedIndex = vm.isVerificationSent ? 0 : nil
      }


      // ─── Verify button ──────────────────────────────────────────────
      Button("Verify") {
        vm.verifyCode()
      }
      .disabled(!vm.isVerificationSent || vm.verificationCode.count < 6)
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
    .onDisappear {
      timer.upstream.connect().cancel()
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
}

struct LoginOrSignupView_Previews: PreviewProvider {
  static var previews: some View {
    LoginOrSignupView(
      isAuthenticated: .constant(false),
      showCreateProfile: .constant(false)
    )
  }
}
