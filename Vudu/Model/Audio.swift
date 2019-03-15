//
//  Audio.swift
//  Vudo
//
//  Created by Umar Qattan on 2/16/19.
//  Copyright © 2019 ukaton. All rights reserved.
//

import Foundation
import AVFoundation

class Audio {
    
    var player: AVAudioPlayer
    var sesion: AVAudioSession = AVAudioSession.sharedInstance()
    
    init(fileURL: URL) throws {
        do {
            player = try AVAudioPlayer(contentsOf: fileURL)
        } catch {
            throw error
        }
    }
    
    func play() {
        
        guard !player.isPlaying else {
            print("Player is already playing...")
            return
        }
        
        player.play()
    }
    
    func pause() {
        guard player.isPlaying else {
            print("Player is not playing...")
            return
        }
        
        player.pause()
    }
    
    func setPan(_ pan: Float) {
        player.pan = pan
    }
    
    func timeRemaining() -> TimeInterval {
        return player.duration - player.currentTime
    }
    
    
}
