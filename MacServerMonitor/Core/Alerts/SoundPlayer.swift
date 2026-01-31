//
//  SoundPlayer.swift
//  MacServerMonitor
//
//  System sound playback for alerts
//

import AppKit

/// Sound player for alert sounds
final class SoundPlayer {
    // MARK: - Singleton
    static let shared = SoundPlayer()

    private init() {}

    // MARK: - Public Methods

    /// Play system alert sound
    func play() {
        DispatchQueue.main.async {
            NSSound.beep()
        }
    }
}
