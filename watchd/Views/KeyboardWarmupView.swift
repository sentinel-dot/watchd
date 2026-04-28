import SwiftUI
import UIKit

struct KeyboardWarmupView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isHidden = true
        view.isUserInteractionEnabled = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            KeyboardWarmup.shared.primeIfNeeded(from: view)
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        KeyboardWarmup.shared.primeIfNeeded(from: uiView)
    }
}

@MainActor
final class KeyboardWarmup {
    static let shared = KeyboardWarmup()

    private var hasPrimed = false

    private init() {}

    func primeIfNeeded(from hostView: UIView) {
        guard !hasPrimed else { return }
        guard let window = hostView.window ?? activeWindow() else { return }

        hasPrimed = true

        let textField = UITextField(frame: CGRect(x: -2000, y: -2000, width: 1, height: 1))
        textField.textContentType = .username
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.spellCheckingType = .no
        textField.smartDashesType = .no
        textField.smartQuotesType = .no
        textField.inputView = UIView(frame: .zero)

        window.addSubview(textField)

        DispatchQueue.main.async {
            textField.becomeFirstResponder()
            textField.resignFirstResponder()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                textField.removeFromSuperview()
            }
        }
    }

    private func activeWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }
}
