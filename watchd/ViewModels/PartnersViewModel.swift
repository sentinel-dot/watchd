import Foundation
import Combine

@MainActor
final class PartnersViewModel: ObservableObject {
    @Published var incoming: [Partnership] = []
    @Published var outgoing: [Partnership] = []
    @Published var active: [Partnership] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var hasLoadedOnce = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        SocketService.shared.partnershipRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { await self?.loadPartnerships(animated: false) }
            }
            .store(in: &cancellables)

        SocketService.shared.partnershipAcceptedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleAccepted(event: event)
            }
            .store(in: &cancellables)

        SocketService.shared.partnershipEndedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] partnershipId in
                self?.handleEnded(partnershipId: partnershipId)
            }
            .store(in: &cancellables)
    }

    func loadPartnerships(animated: Bool = true) async {
        let start = ContinuousClock.now
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await APIService.shared.fetchPartnerships()
            incoming = response.incoming
            outgoing = response.outgoing
            active = response.active
            hasLoadedOnce = true

            if animated {
                let elapsed = ContinuousClock.now - start
                let minDuration: Duration = .milliseconds(450)
                if elapsed < minDuration {
                    try? await Task.sleep(for: minDuration - elapsed)
                }
            }
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            hasLoadedOnce = true
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func acceptRequest(id: Int) async {
        do {
            let response = try await APIService.shared.acceptPartnership(id: id)
            if let index = incoming.firstIndex(where: { $0.id == id }) {
                incoming.remove(at: index)
            }
            if !active.contains(where: { $0.id == id }) {
                active.insert(response.partnership, at: 0)
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func declineRequest(id: Int) async {
        do {
            _ = try await APIService.shared.declinePartnership(id: id)
            incoming.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func cancelRequest(id: Int) async {
        do {
            _ = try await APIService.shared.cancelPartnershipRequest(id: id)
            outgoing.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func deletePartnership(id: Int) async {
        do {
            _ = try await APIService.shared.deletePartnership(id: id)
            active.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func updateFilters(id: Int, filters: PartnershipFilters) async {
        do {
            let response = try await APIService.shared.updatePartnershipFilters(id: id, filters: filters)
            if let index = active.firstIndex(where: { $0.id == id }) {
                let existing = active[index]
                active[index] = Partnership(
                    id: existing.id,
                    status: existing.status,
                    requesterId: existing.requesterId,
                    addresseeId: existing.addresseeId,
                    filters: response.filters,
                    partner: existing.partner,
                    createdAt: existing.createdAt,
                    acceptedAt: existing.acceptedAt,
                    lastActivityAt: existing.lastActivityAt
                )
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func handleAccepted(event: PartnershipAcceptedSocketEvent) {
        outgoing.removeAll { $0.id == event.partnershipId }
        Task { await loadPartnerships(animated: false) }
    }

    private func handleEnded(partnershipId: Int) {
        active.removeAll { $0.id == partnershipId }
        incoming.removeAll { $0.id == partnershipId }
        outgoing.removeAll { $0.id == partnershipId }
    }
}
