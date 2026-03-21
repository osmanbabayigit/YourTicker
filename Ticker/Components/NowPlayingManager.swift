import Foundation
import AppKit
import SwiftUI
import Combine

// MARK: - Now Playing bilgisi

struct NowPlayingInfo {
    var title: String = ""
    var artist: String = ""
    var album: String = ""
    var isPlaying: Bool = false
    var elapsed: Double = 0
    var duration: Double = 0
    var artworkData: Data? = nil

    var progressRatio: Double {
        guard duration > 0 else { return 0 }
        return min(elapsed / duration, 1.0)
    }

    var elapsedString: String { formatTime(elapsed) }
    var durationString: String { formatTime(duration) }

    var isEmpty: Bool { title.isEmpty && artist.isEmpty }

    private func formatTime(_ seconds: Double) -> String {
        let s = Int(seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

// MARK: - Now Playing Manager
// macOS MediaRemote framework üzerinden çalışır (private API ama sandbox'ta çalışır)

class NowPlayingManager: ObservableObject {
    static let shared = NowPlayingManager()

    @Published var info = NowPlayingInfo()
    @Published var isAvailable = false

    private var timer: Timer?
    private var mrBundle: CFBundle?
    private var getInfoFunc: ((CFDictionary?) -> Void)?

    // MediaRemote function pointers
    private typealias MRMediaRemoteGetNowPlayingInfo = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    private typealias MRMediaRemoteGetNowPlayingApplicationIsPlaying = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void

    private var getNowPlayingInfo: MRMediaRemoteGetNowPlayingInfo?
    private var getIsPlaying: MRMediaRemoteGetNowPlayingApplicationIsPlaying?

    private init() {
        loadMediaRemote()
        if isAvailable { startPolling() }
    }

    private func loadMediaRemote() {
        guard let bundle = CFBundleCreate(
            kCFAllocatorDefault,
            NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")
        ) else { return }

        mrBundle = bundle

        if let ptr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) {
            getNowPlayingInfo = unsafeBitCast(ptr, to: MRMediaRemoteGetNowPlayingInfo.self)
            isAvailable = true
        }

        if let ptr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying" as CFString) {
            getIsPlaying = unsafeBitCast(ptr, to: MRMediaRemoteGetNowPlayingApplicationIsPlaying.self)
        }
    }

    func startPolling() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() {
        guard let getNowPlayingInfo else { return }

        getNowPlayingInfo(.main) { [weak self] dict in
            guard let self else { return }

            let title  = dict["kMRMediaRemoteNowPlayingInfoTitle"]  as? String ?? ""
            let artist = dict["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
            let album  = dict["kMRMediaRemoteNowPlayingInfoAlbum"]  as? String ?? ""
            let elapsed  = dict["kMRMediaRemoteNowPlayingInfoElapsedTime"]  as? Double ?? 0
            let duration = dict["kMRMediaRemoteNowPlayingInfoDuration"] as? Double ?? 0
            let artworkData = dict["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data

            var newInfo = NowPlayingInfo(
                title: title, artist: artist, album: album,
                isPlaying: false,
                elapsed: elapsed, duration: duration,
                artworkData: artworkData
            )

            self.getIsPlaying?(.main) { isPlaying in
                newInfo.isPlaying = isPlaying
                DispatchQueue.main.async {
                    self.info = newInfo
                }
            }
        }
    }

    deinit { stopPolling() }
}
