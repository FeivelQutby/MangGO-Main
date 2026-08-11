//
//  StationSync.swift
//  MangGO
//
//  Created by Rizki Hidayatul Laeli on 11/08/26.
//

import Foundation
import MultipeerConnectivity
import Observation

@MainActor
@Observable
final class StationSync: NSObject {

    enum Role: Sendable { case station, display }

    /// Harus sama persis dengan NSBonjourServices di Info.plist.
    static let serviceType = "manggo-sync"

    private(set) var snapshot: StationSnapshot = .idle
    private(set) var peerCount = 0

    /// Kegagalan advertise/browse tidak melempar error — biasanya izin
    /// Local Network ditolak atau kunci NSBonjourServices hilang. Tanpa ini
    /// gejalanya cuma "iPad tidak pernah ketemu" tanpa petunjuk apa pun.
    private(set) var lastError: String?

    var isLinked: Bool { peerCount > 0 }

    nonisolated(unsafe) private let session: MCSession
    nonisolated(unsafe) private let peerID: MCPeerID
    nonisolated private let role: Role

    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    nonisolated init(role: Role, name: String = StationSync.storedPeerName()) {
        self.role = role
        self.peerID = MCPeerID(displayName: String(name.prefix(60)))
        self.session = MCSession(peer: peerID, securityIdentity: nil,
                                 encryptionPreference: .required)
        super.init()
        session.delegate = self
    }

    /// UIDevice.current.name mengembalikan nama model sejak iOS 16, jadi dua
    /// device sejenis akan bertabrakan.
    nonisolated static func storedPeerName() -> String {
        let key = "manggo.peerName"
        if let saved = UserDefaults.standard.string(forKey: key), !saved.isEmpty {
            return saved
        }
        let name = "MangGO-\(UUID().uuidString.prefix(4))"
        UserDefaults.standard.set(name, forKey: key)
        return name
    }

    func start() {
        guard advertiser == nil, browser == nil else { return }
        lastError = nil
        switch role {
        case .station:
            advertiser = MCNearbyServiceAdvertiser(
                peer: peerID, discoveryInfo: nil, serviceType: Self.serviceType)
            advertiser?.delegate = self
            advertiser?.startAdvertisingPeer()
        case .display:
            browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
            browser?.delegate = self
            browser?.startBrowsingForPeers()
        }
    }

    func stop() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        advertiser = nil
        browser = nil
        session.disconnect()
        peerCount = 0
    }

    /// No-op kalau iPad tidak tersambung — siklus grading tidak boleh menunggu.
    func publish(_ new: StationSnapshot) {
        snapshot = new
        guard role == .station, !session.connectedPeers.isEmpty,
              let data = try? JSONEncoder().encode(new) else { return }
        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }

    fileprivate func receive(_ incoming: StationSnapshot) {
        guard incoming.updatedAt >= snapshot.updatedAt else { return }
        snapshot = incoming
    }

    fileprivate func setPeers(_ count: Int, connected: Bool) {
        peerCount = count
        if connected { lastError = nil }
        // Snapshot terakhir dikirim ulang begitu peer masuk, supaya iPad yang
        // baru menyambung langsung sinkron tanpa menunggu buah berikutnya.
        if role == .station, connected { publish(snapshot) }
    }

    fileprivate func setError(_ message: String) {
        lastError = message
    }
}

extension StationSync: MCSessionDelegate {

    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID,
                             didChange state: MCSessionState) {
        let count = session.connectedPeers.count
        let connected = state == .connected
        Task { @MainActor [weak self] in self?.setPeers(count, connected: connected) }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data,
                             fromPeer peerID: MCPeerID) {
        guard let snap = try? JSONDecoder().decode(StationSnapshot.self, from: data)
        else { return }
        Task { @MainActor [weak self] in self?.receive(snap) }
    }

    nonisolated func session(_ s: MCSession, didReceive stream: InputStream,
                             withName name: String, fromPeer peer: MCPeerID) {}
    nonisolated func session(_ s: MCSession, didStartReceivingResourceWithName name: String,
                             fromPeer peer: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ s: MCSession, didFinishReceivingResourceWithName name: String,
                             fromPeer peer: MCPeerID, at url: URL?, withError error: Error?) {}
}

extension StationSync: MCNearbyServiceAdvertiserDelegate {

    nonisolated func advertiser(_ a: MCNearbyServiceAdvertiser,
                                didReceiveInvitationFromPeer peer: MCPeerID,
                                withContext context: Data?,
                                invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }

    nonisolated func advertiser(_ a: MCNearbyServiceAdvertiser,
                                didNotStartAdvertisingPeer error: Error) {
        let message = error.localizedDescription
        Task { @MainActor [weak self] in self?.setError(message) }
    }
}

extension StationSync: MCNearbyServiceBrowserDelegate {

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peer: MCPeerID,
                             withDiscoveryInfo info: [String: String]?) {
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 15)
    }

    nonisolated func browser(_ b: MCNearbyServiceBrowser, lostPeer peer: MCPeerID) {}

    nonisolated func browser(_ b: MCNearbyServiceBrowser,
                             didNotStartBrowsingForPeers error: Error) {
        let message = error.localizedDescription
        Task { @MainActor [weak self] in self?.setError(message) }
    }
}
