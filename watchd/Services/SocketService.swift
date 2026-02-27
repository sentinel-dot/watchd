import Foundation
import Combine

@MainActor
final class SocketService: ObservableObject {
    static let shared = SocketService()

    private var manager: SocketManager?
    private var socket: SocketIOClient?

    let matchPublisher = PassthroughSubject<SocketMatchEvent, Never>()
    let filtersUpdatedPublisher = PassthroughSubject<RoomFilters, Never>()
    let partnerLeftPublisher = PassthroughSubject<Int, Never>()
    let partnerJoinedPublisher = PassthroughSubject<Int, Never>()
    let roomDissolvedPublisher = PassthroughSubject<Int, Never>()

    @Published var isConnected = false

    private init() {}

    func connect(token: String, roomId: Int) {
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
                self?.socket?.emit("join", ["token": token, "roomId": roomId])
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
            guard let filters = try? decoder.decode(RoomFilters.self, from: jsonData) else { return }
            Task { @MainActor [weak self] in
                self?.filtersUpdatedPublisher.send(filters)
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
        
        socket?.on("room_dissolved") { [weak self] data, _ in
            guard let dict = data.first as? [String: Any],
                  let roomId = dict["roomId"] as? Int else { return }
            Task { @MainActor [weak self] in
                self?.roomDissolvedPublisher.send(roomId)
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
