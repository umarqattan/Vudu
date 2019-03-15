//
//  VoiceMemoViewController.swift
//  Vudo
//
//  Created by Umar Qattan on 2/9/19.
//  Copyright © 2019 ukaton. All rights reserved.
//

import UIKit
import CoreLocation
import AVFoundation
import BoseWearable

struct VoiceMemo {
    var location: String
    var coordinates: CLLocation
    var date: Date
    var duration: TimeInterval
    var fileURL: URL
    var audio: Audio
    
    init(location: String, coordinates: CLLocation, date: Date, duration: TimeInterval, fileURL: URL) {
        self.location = location
        self.coordinates = coordinates
        self.date = date
        self.duration = duration
        self.fileURL = fileURL
        self.audio = try! Audio(fileURL: self.fileURL)
    }
}

class VoiceMemoViewController: UITableViewController {

    
    /// Set by the showing/presenting code.
    var session: WearableDeviceSession!
    
    /// Retained for the lifetime of this object. When deallocated, deregisters
    /// this object as a WearableDeviceEvent listener.
    var token: ListenerToken?
    
    /// Used to block the UI during connection.
    private var activityIndicator: ActivityIndicator?
    
    // We create the SensorDispatch without any reference to a session or a device.
    // We provide a queue on which the sensor data events are dispatched on.
    let sensorDispatch = SensorDispatch(queue: .main)

    private var currentlyPlayingVoiceMemoIndexPath: IndexPath?
    
    private var voiceMemos = [
        VoiceMemo(location: "San Francisco",
                  coordinates: CLLocation(latitude: 37.774929, longitude: -122.419418),
                  date: Date(),
                  duration: 89,
                  fileURL: URL(fileURLWithPath: Bundle.main.path(forResource: "deadly", ofType: "mp3")!)
        ),
        VoiceMemo(
            location: "New York City",
            coordinates: CLLocation(latitude: 40.712776, longitude: -74.005974),
            date: Date(timeIntervalSince1970: 1549498644),
            duration: 102,
            fileURL: URL(fileURLWithPath: Bundle.main.path(forResource: "obscure", ofType: "mp3")!)
            ),
        VoiceMemo(
            location: "Miami",
            coordinates: CLLocation(latitude: 25.761681, longitude: -80.191788),
            date: Date(timeIntervalSince1970: 1549239444),
            duration: 54,
            fileURL: URL(fileURLWithPath: Bundle.main.path(forResource: "jokes", ofType: "mp3")!)
        ),
        VoiceMemo(
            location: "London",
            coordinates: CLLocation(latitude: 51.507351, longitude: -0.127758),
            date: Date(timeIntervalSince1970: 1549066644),
            duration: 71,
            fileURL: URL(fileURLWithPath: Bundle.main.path(forResource: "check", ofType: "mp3")!)
        )
        
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        tableView.delegate = self
        tableView.dataSource = self
        
        setupViews()
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioRouteChange(_:)), name: AVAudioSession.routeChangeNotification, object: AVAudioSession.sharedInstance())
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.allowBluetoothA2DP, .defaultToSpeaker])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return voiceMemos.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "voiceMemoCell", for: indexPath) as! VoiceMemoTableViewCell
        cell.configure(voiceMemo: voiceMemos[indexPath.section])
        cell.delegate = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard section < voiceMemos.count - 1 else { return 10 }
        return 5
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section > 0 else { return 10 }
        return 5
    }

}

extension VoiceMemoViewController: VoiceMemoTableViewCellDelegate {

    func didTapPlay(_ sender: VoiceMemoTableViewCell) {
        guard let selectedIndexPath = tableView.indexPath(for: sender), let voiceMemo = sender.voiceMemo else { return }
        
        currentlyPlayingVoiceMemoIndexPath = selectedIndexPath

        // pause current player(s)
        let currentPlayers = voiceMemos.map( { $0.audio }).filter( { $0.player.isPlaying })
        currentPlayers.forEach({
            $0.pause()
            
        })
        
        if let visibleCells = tableView.visibleCells as? [VoiceMemoTableViewCell] {
            visibleCells.forEach { (cell) in
                if cell != sender {
                    cell.pauseButton.isEnabled = false
                    cell.playButton.isEnabled = true
                } else {
                    cell.pauseButton.isEnabled = true
                    cell.playButton.isEnabled = false
                }
            }
        }
        
        
    }
    
    func didTapPause(_ sender: VoiceMemoTableViewCell) {
        if let visibleCells = tableView.visibleCells as? [VoiceMemoTableViewCell] {
            visibleCells.forEach { (cell) in
                if cell != sender {
                    cell.pauseButton.isEnabled = false
                    cell.playButton.isEnabled = true
                }
            }
        }
    }
}

extension VoiceMemoViewController {
    private func setupViews() {
        let recordButton = UIButton(type: UIButton.ButtonType.custom)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.setImage(UIImage(named: "record")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate), for: UIControl.State.normal)
        recordButton.addTarget(self, action: #selector(tappedRecord(_:)), for: UIControl.Event.touchUpInside)
        recordButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        recordButton.heightAnchor.constraint(equalTo: recordButton.widthAnchor).isActive = true
        recordButton.tintColor = .red
        recordButton.contentMode = .scaleAspectFit
        let recordBarButtonItem = UIBarButtonItem(customView: recordButton)
        var currentNavigationButtons = navigationItem.rightBarButtonItems
        currentNavigationButtons?.append(recordBarButtonItem)
        navigationItem.setRightBarButtonItems(currentNavigationButtons, animated: true)
    }
    
    @objc func tappedRecord(_ sender: UIButton) {
        guard let image = sender.image(for: UIControl.State.normal) else { return }
        
        if image == UIImage(named: "record") {
            sender.setImage(UIImage(named: "pause")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate), for: UIControl.State.normal)
        } else if image == UIImage(named: "pause") {
            sender.setImage(UIImage(named: "record")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate), for: UIControl.State.normal)
        }
    }
}

extension VoiceMemoViewController: WearableDeviceSessionDelegate {
    
    // Error handler function called at various points in this class.  If an error
    // occurred, show it in an alert. When the alert is dismissed, this function
    // dismisses this view controller by popping to the root view controller (we are
    // assumed to be on a navigation stack).
    private func dismiss(dueTo error: Error?, isClosing: Bool = false) {
        // Common dismiss handler passed to show()/showAlert().
        let popToRoot = { [weak self] in
            DispatchQueue.main.async {
                self?.navigationController?.popToRootViewController(animated: true)
            }
        }
        
        // If the connection did close and it was not due to an error, just show
        // an appropriate message.
        if isClosing && error == nil {
            navigationController?.showAlert(title: "Disconnected", message: "The connection was closed", dismissHandler: popToRoot)
        }
            // Show an error alert.
        else {
            navigationController?.show(error, dismissHandler: popToRoot)
        }
    }
    
    private func listenForWearableDeviceEvents() {
        // Listen for incoming wearable device events. Retain the ListenerToken.
        // When the ListenerToken is deallocated, this object is automatically
        // removed as an event listener.
        self.token = session.device?.addEventListener(queue: .main) { [weak self] event in
            self?.wearableDeviceEvent(event)
        }
    }
    
    private func wearableDeviceEvent(_ event: WearableDeviceEvent) {
        // We are only interested in the event that the sensor configuration could
        // not be updated. In this case, show the error to the user. Otherwise,
        // ignore the event.
        guard case .didFailToWriteSensorConfiguration(let error) = event else {
            return
        }
        show(error)
    }
    
    private func listenForSensors() {
        // Configure sensors at 50 Hz (a 20 ms sample period)
        session.device?.configureSensors { config in
            
            // Here, config is the current sensor config. We begin by turning off
            // all sensors, allowing us to start with a "clean slate."
            config.disableAll()
            
            // Enable the rotation and accelerometer sensors
            config.enable(sensor: .rotation, at: ._20ms)
            config.enable(sensor: .accelerometer, at: ._20ms)
        }
    }
    
    func sessionDidOpen(_ session: WearableDeviceSession) {
        // The session opened successfully.
        
        // Listen for wearable device events.
        listenForWearableDeviceEvents()
        
        // Listen for sensor data.
        listenForSensors()
        
        // Unblock this view controller's UI.
        activityIndicator?.removeFromSuperview()
    }
    
    func session(_ session: WearableDeviceSession, didFailToOpenWithError error: Error?) {
        // The session failed to open due to an error.
        dismiss(dueTo: error)
        
        // Unblock this view controller's UI.
        activityIndicator?.removeFromSuperview()
        
    }
    
    func session(_ session: WearableDeviceSession, didCloseWithError error: Error?) {
        // The session was closed, possibly due to an error.
        dismiss(dueTo: error, isClosing: true)
        
        // Unblock this view controller's UI.
        activityIndicator?.removeFromSuperview()
    }
    
    
}

extension VoiceMemoViewController: SensorDispatchHandler {
    
    func receivedRotation(quaternion: Quaternion, accuracy: QuaternionAccuracy, timestamp: SensorTimestamp) {
        
        if let currentlySelectedVoiceMemoIndexPath = self.currentlyPlayingVoiceMemoIndexPath,
            let selectedVoiceMemoCell = self.tableView.cellForRow(at: currentlySelectedVoiceMemoIndexPath) as? VoiceMemoTableViewCell, let voiceMemo = selectedVoiceMemoCell.voiceMemo {
            
            let currentLocation = CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 37.3952, longitude: 122.0792),
                altitude: 0,
                horizontalAccuracy: 0,
                verticalAccuracy: 0,
                timestamp: Date()
            )
            
            let memoLocation = voiceMemo.coordinates
            
            let yaw = quaternion.yaw.toDegrees()
            let bearing: Float = Float(currentLocation.bearing(to: memoLocation) + yaw) / 180.0
            voiceMemo.audio.setPan(bearing)
        }
    }
    
    func receivedAccelerometer(vector: Vector, accuracy: VectorAccuracy, timestamp: SensorTimestamp) {

    }
}

extension VoiceMemoViewController {
    
    @objc func handleAudioRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue:reasonValue) else {
                return
        }
        switch reason {
        case .newDeviceAvailable:
            let session = AVAudioSession.sharedInstance()
            for output in session.currentRoute.outputs {
                if output.portType == .bluetoothA2DP {
                    self.playReReoutedPlayer()
                    break
                }
                if output.portType == .builtInSpeaker {
                    self.pauseReReoutedPlayer()
                    break
                }
            }
        case .oldDeviceUnavailable:
            if let previousRoute =
                userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                for output in previousRoute.outputs where (output.portType == AVAudioSession.Port.bluetoothA2DP || output.portType == AVAudioSession.Port.builtInReceiver || output.portType == AVAudioSession.Port.builtInSpeaker) {
                    self.pauseReReoutedPlayer()
                    break
            }
        }
        default: ()
        }
    }
    
    func pauseReReoutedPlayer() {
        DispatchQueue.main.async {
            [weak self] in
            guard let `self` = self else { return }
            if let currentlySelectedVoiceMemoIndexPath = self.currentlyPlayingVoiceMemoIndexPath,
                let selectedVoiceMemoCell = self.tableView.cellForRow(at: currentlySelectedVoiceMemoIndexPath) as? VoiceMemoTableViewCell {
                selectedVoiceMemoCell.pause(self)
            }
        }
    }
    
    func playReReoutedPlayer() {
        DispatchQueue.main.async {
            [weak self] in
            guard let `self` = self else { return }
            if let currentlySelectedVoiceMemoIndexPath = self.currentlyPlayingVoiceMemoIndexPath,
                let selectedVoiceMemoCell = self.tableView.cellForRow(at: currentlySelectedVoiceMemoIndexPath) as? VoiceMemoTableViewCell {
                selectedVoiceMemoCell.play(self)
            }
        }
    }
}
