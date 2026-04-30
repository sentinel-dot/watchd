import Foundation

@MainActor
final class AddPartnerViewModel: ObservableObject {
    @Published var codeInput: String = ""
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?

    static let codeLength = 8
    private static let allowedAlphabet = Set("0123456789ABCDEFGHJKMNPQRSTVWXYZ")

    init(initialCode: String = "") {
        codeInput = Self.normalize(initialCode)
    }

    static func normalize(_ raw: String) -> String {
        let upper = raw.uppercased()
        return String(upper.unicodeScalars.compactMap { scalar -> Character? in
            let char = Character(scalar)
            return allowedAlphabet.contains(char) ? char : nil
        }).prefix(codeLength).description
    }

    var isValid: Bool {
        Self.normalize(codeInput).count == Self.codeLength
    }

    func submit(onSuccess: @escaping (Partnership) -> Void) async {
        let normalized = Self.normalize(codeInput)
        guard normalized.count == Self.codeLength else {
            errorMessage = "Bitte gib einen 8-stelligen Code ein."
            return
        }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let response = try await APIService.shared.requestPartnership(shareCode: normalized)
            onSuccess(response.partnership)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
