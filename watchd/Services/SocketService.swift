import Foundation
import Combine

@MainActor
final class SocketService: ObservableObject {
    static let shared = SocketService()

    private var manager: SocketManager?
    private var socket: SocketIOClient?

    let matchPublisher = PassthroughSubject<SocketMatchEvent, Never>()
    let partnerFiltersUpdatedPublisher = PassthroughSubject<PartnershipFilters, Never>()
    let partnerLeftPublisher = PassthroughSubject<Int, Never>()
    let partnerJoinedPublisher = PassthroughSubject<Int, Never>()
    let partnershipRequestPublisher = PassthroughSubject<PartnershipRequestSocketEvent, Never>()
    let partnershipAcceptedPublisher = PassthroughSubject<PartnershipAcceptedSocketEvent, Never>()
    let partnershipEndedPublisher = PassthroughSubject<Int, Never>()

    @Published var isConnected = false

    private init() {}

    func connect(token: String, partnershipId: Int? = nil) {
        var payload: [String: Any] = ["token": token]
        if let partnershipId = partnershipId {
            payload["partnershipId"] = partnershipId
        }
        connect(token: token, joinPayload: payload)
    }

    private func connect(token: String, joinPayload: [String: Any]) {
        disconnect()

        guard let url = URL(string: APIConfig.socketURL) else { return }

        manager = SocketManager(socketURL: url, config: [
            .log(false),
            .compress,
            .reconnects(true),
            .reconnectAttempts(5),
            .reconnectWait(2)
        ])

        socket = manager?.defaultSocket

        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.isConnected = true
                self?.socket?.emit("join", joinPayload)
            }
        }

        socket?.on(clientEvent: .disconnect) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.isConnected = false
            }
        }

        socket?.on("match") { [weak self] data, _ in
            guard let dict = data.first as? [String: Any],
                  let jsonData = try? JSONSerialization.data(withJSONObject: dict) else { return }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            guard let event = try? decoder.decode(SocketMatchEvent.self, from: jsonData) else { return }
            Task { @MainActor [weak self] in
                self?.matchPublisher.send(event)
            }
        }

        socket?.on("filters_updated") { [weak self] data, _ in
            guard let dict = data.first as? [String: Any],
                  let filtersDict = dict["filters"] as? [String: Any],
                  let jsonData = try? JSONSerialization.data(withJSONObject: filtersDict) else { return }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            if let partnershipFilters = try? decoder.decode(PartnershipFilters.self, from: jsonData) {
                Task { @MainActor [weak self] in
                    self?.partnerFiltersUpdatedPublisher.send(partnershipFilters)
                }
            }
        }

        socket?.on("partner_left") { [weak self] data, _ in
            guard let dict = data.first as? [String: Any],
                  let userId = dict["userId"] as? Int else { return }
            Task { @MainActor [weak self] in
                self?.partnerLeftPublisher.send(userId)
            }
        }

        socket?.on("partner_joined") { [weak self] data, _ in
            guard let dict = data.first as? [String: Any],
                  let userId = dict["userId"] as? Int else { return }
            Task { @MainActor [weak self] in
                self?.partnerJoinedPublisher.send(userId)
            }
        }

        socket?.on("partnership_request") { [weak self] data, _ in
            guard let dict = data.first as? [String: Any],
                  let jsonData = try? JSONSerialization.data(withJSONObject: dict) else { return }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            guard let event = try? decoder.decode(PartnershipRequestSocketEvent.self, from: jsonData) else { return }
            Task { @MainActor [weak self] in
                self?.partnershipRequestPublisher.send(event)
            }
        }

        socket?.on("partnership_accepted") { [weak self] data, _ in
            guard let dict = data.first as? [String: Any],
                  let jsonData = try? JSONSerialization.data(withJSONObject: dict) else { return }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            guard let event = try? decoder.decode(PartnershipAcceptedSocketEvent.self, from: jsonData) else { return }
            Task { @MainActor [weak self] in
                self?.partnershipAcceptedPublisher.send(event)
            }
        }

        socket?.on("partnership_ended") { [weak self] data, _ in
            guard let dict = data.first as? [String: Any],
                  let partnershipId = dict["partnershipId"] as? Int else { return }
            Task { @MainActor [weak self] in
                self?.partnershipEndedPublisher.send(partnershipId)
            }
        }

        socket?.connect()
    }

    func disconnect() {
        socket?.removeAllHandlers()
        socket?.disconnect()
        socket = nil
        manager = nil
        isConnected = false
    }
}
