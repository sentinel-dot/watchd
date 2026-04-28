import SwiftUI
import UIKit

// UIViewRepresentable wrapper around UITextField.
// Bypasses SwiftUI's TextField rendering pipeline — eliminates first-keystroke input delay.

struct NativeTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var textContentType: UITextContentType? = nil
    var returnKeyType: UIReturnKeyType = .done
    var autocapitalizationType: UITextAutocapitalizationType = .none
    var autocorrectionType: UITextAutocorrectionType = .no
    var spellCheckingType: UITextSpellCheckingType = .no
    var accessibilityLabel: String? = nil
    var accessibilityHint: String? = nil
    var passwordRulesDescriptor: String? = nil
    var uiFont: UIFont = .systemFont(ofSize: 15)
    var textColor: UIColor = .white
    var placeholderColor: UIColor = UIColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 1)
    var onSubmit: (() -> Void)? = nil
    var isFocused: Binding<Bool>? = nil

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.delegate = context.coordinator
        tf.keyboardType = keyboardType
        tf.isSecureTextEntry = isSecure
        tf.textContentType = textContentType
        tf.returnKeyType = returnKeyType
        tf.autocapitalizationType = autocapitalizationType
        tf.autocorrectionType = autocorrectionType
        tf.spellCheckingType = spellCheckingType
        tf.smartQuotesType = .no
        tf.smartDashesType = .no
        tf.enablesReturnKeyAutomatically = true
        tf.font = uiFont
        tf.textColor = textColor
        tf.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: placeholderColor]
        )
        tf.accessibilityTraits.insert(.updatesFrequently)
        tf.setContentHuggingPriority(.defaultLow, for: .horizontal)
        tf.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tf.setContentHuggingPriority(.required, for: .vertical)
        tf.setContentCompressionResistancePriority(.required, for: .vertical)
        tf.addTarget(context.coordinator,
                     action: #selector(Coordinator.textChanged(_:)),
                     for: .editingChanged)
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self

        if uiView.text != text { uiView.text = text }
        uiView.keyboardType = keyboardType
        uiView.isSecureTextEntry = isSecure
        uiView.textContentType = textContentType
        uiView.returnKeyType = returnKeyType
        uiView.autocapitalizationType = autocapitalizationType
        uiView.autocorrectionType = autocorrectionType
        uiView.spellCheckingType = spellCheckingType
        uiView.accessibilityLabel = accessibilityLabel ?? placeholder
        uiView.accessibilityHint = accessibilityHint
        uiView.passwordRules = passwordRulesDescriptor.map(UITextInputPasswordRules.init(descriptor:))

        if let isFocused {
            if isFocused.wrappedValue, !uiView.isFirstResponder {
                DispatchQueue.main.async { uiView.becomeFirstResponder() }
            } else if !isFocused.wrappedValue, uiView.isFirstResponder {
                DispatchQueue.main.async { uiView.resignFirstResponder() }
            }
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: NativeTextField

        init(parent: NativeTextField) { self.parent = parent }

        @objc func textChanged(_ sender: UITextField) {
            parent.text = sender.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.isFocused?.wrappedValue = true
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isFocused?.wrappedValue = false
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onSubmit?()
            return true
        }
    }
}
