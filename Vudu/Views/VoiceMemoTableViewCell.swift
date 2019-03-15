//
//  VoiceMemoTableViewCell.swift
//  Vudo
//
//  Created by Umar Qattan on 2/9/19.
//  Copyright © 2019 ukaton. All rights reserved.
//

import UIKit
import AVFoundation

protocol VoiceMemoTableViewCellDelegate: class {
    func didTapPlay(_ sender: VoiceMemoTableViewCell)
    func didTapPause(_ sender: VoiceMemoTableViewCell)
}

class VoiceMemoTableViewCell: UITableViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var coordinatesLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var playBackView: UIView!
    @IBOutlet weak var playButton: UIBarButtonItem!
    @IBOutlet weak var pauseButton: UIBarButtonItem!
    
    var voiceMemo: VoiceMemo?
    weak var delegate: VoiceMemoTableViewCellDelegate?
    var currentTime: TimeInterval = 0
    var timer: Timer?
    
    func configure(voiceMemo: VoiceMemo) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        self.dateLabel.text = "\(dateFormatter.string(from: voiceMemo.date))"
        self.durationLabel.text = "\(voiceMemo.audio.player.duration.toTime())"
        self.locationLabel.text = voiceMemo.location
        self.coordinatesLabel.text = String(
            format: "Lat: %.5f\nLon: %.5f",
            arguments: [voiceMemo.coordinates.coordinate.latitude, voiceMemo.coordinates.coordinate.longitude]
        )
        
        // set the voiceMemoViewModel after configuring
        voiceMemo.audio.player.delegate = self
        self.voiceMemo = voiceMemo
        
        // toggle play and pause buttons
        self.reset(voiceMemo: voiceMemo)
    }
    
    func reset(voiceMemo: VoiceMemo) {
        voiceMemo.audio.pause()
        
        self.playButton.isEnabled = true
        self.pauseButton.isEnabled = false
        self.currentTime = 0
        self.durationLabel.text = voiceMemo.audio.player.duration.toTime()
        self.timer?.invalidate()
    }

    @IBAction func deleteVoiceMemo(_ sender: UIBarButtonItem) {
    }
    
    @IBAction func fastForward(_ sender: UIBarButtonItem) {
    }
    
    @IBAction func pause(_ sender: Any) {
        guard let voiceMemo = self.voiceMemo, voiceMemo.audio.player.isPlaying else { return }
        
        self.delegate?.didTapPause(self)
        
        voiceMemo.audio.pause()
        
        self.currentTime = voiceMemo.audio.player.currentTime
        self.playButton.isEnabled = true
        self.pauseButton.isEnabled = false
        self.timer?.invalidate()
    }
    
    @IBAction func play(_ sender: Any) {
        guard let voiceMemo = voiceMemo, !voiceMemo.audio.player.isPlaying else { return }
        
        self.delegate?.didTapPlay(self)
        
        voiceMemo.audio.play()
        voiceMemo.audio.player.currentTime = currentTime
        
        self.playButton.isEnabled = false
        self.pauseButton.isEnabled = true
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
    @IBAction func rewind(_ sender: Any) {
        guard let voiceMemo = voiceMemo else { return }
        
        if voiceMemo.audio.player.isPlaying {
            voiceMemo.audio.pause()
        }
        
        voiceMemo.audio.player.currentTime = 0
        let timeRemaining = voiceMemo.audio.timeRemaining()
        self.durationLabel.text = timeRemaining.toTime()
        
        self.playButton.isEnabled = true
        self.pauseButton.isEnabled = false
        self.timer?.invalidate()
    }

    
    @IBAction func actions(_ sender: UIBarButtonItem) {
    }
    
    @objc func updateTimer() {
        guard let voiceMemo = voiceMemo else { return }
        let timeRemaining = voiceMemo.audio.timeRemaining()
        durationLabel.text = timeRemaining.toTime()
    }
}

extension VoiceMemoTableViewCell: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard flag, let voiceMemo = voiceMemo else { return }
        
        self.reset(voiceMemo: voiceMemo)
    }
    
}

