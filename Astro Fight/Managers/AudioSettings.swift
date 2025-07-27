//
//  AudioSettings.swift
//  Astro Fight
//
//  Created by Copilot on 28/07/25.
//

import Foundation
import AVFoundation

class AudioSettings: ObservableObject {
    static let shared = AudioSettings()
    
    @Published var isBGMEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBGMEnabled, forKey: "BGMEnabled")
            if isBGMEnabled {
                startBackgroundMusic()
            } else {
                stopBackgroundMusic()
            }
        }
    }
    
    @Published var isSFXEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSFXEnabled, forKey: "SFXEnabled")
        }
    }
    
    private var backgroundMusicPlayer: AVAudioPlayer?
    
    private init() {
        // Load settings from UserDefaults
        self.isBGMEnabled = UserDefaults.standard.object(forKey: "BGMEnabled") as? Bool ?? true
        self.isSFXEnabled = UserDefaults.standard.object(forKey: "SFXEnabled") as? Bool ?? true
        
        setupBackgroundMusic()
        
        // Start background music if enabled
        if isBGMEnabled {
            startBackgroundMusic()
        }
    }
    
    private func setupBackgroundMusic() {
        guard let path = Bundle.main.path(forResource: "background_music", ofType: "mp3") else {
            print("Background music file not found")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.numberOfLoops = -1 // Loop indefinitely
            backgroundMusicPlayer?.volume = 0.3 // Set a comfortable volume
            backgroundMusicPlayer?.prepareToPlay()
        } catch {
            print("Error setting up background music: \(error)")
        }
    }
    
    func startBackgroundMusic() {
        guard isBGMEnabled, let player = backgroundMusicPlayer else { return }
        
        if !player.isPlaying {
            player.play()
        }
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
    }
    
    func pauseBackgroundMusic() {
        backgroundMusicPlayer?.pause()
    }
    
    func resumeBackgroundMusic() {
        guard isBGMEnabled else { return }
        backgroundMusicPlayer?.play()
    }
    
    func setBGMVolume(_ volume: Float) {
        backgroundMusicPlayer?.volume = volume
    }
    
    // Method to check if SFX should play
    func shouldPlaySFX() -> Bool {
        return isSFXEnabled
    }
}
