//
//  Audiobus.swift
//  HOWL
//
//  Created by Daniel Clelland on 2/06/16.
//  Copyright © 2016 Daniel Clelland. All rights reserved.
//

import AudioKit
import AudioUnitExtensions

class Audiobus {
    
    // MARK: Client
    
    static var client: Audiobus?
    
    // MARK: Actions
    
    static func start() {
        guard client == nil, let apiKey = apiKey else {
            return
        }
        
        client = Audiobus(apiKey: apiKey)
    }
    
    private static var apiKey: String? {
        guard let path = Bundle.main.path(forResource: "audiobus", ofType: "txt") else {
            return nil
        }
        
        do {
            return try String(contentsOfFile: path)
        } catch {
            return nil
        }
    }
    
    // MARK: Initialization
    
    var controller: ABAudiobusController
    
    var audioUnit: AudioUnit {
        return AKManager.shared().engine.audioUnit
    }

    init?(apiKey: String) {
        guard let controller = ABAudiobusController(apiKey: apiKey) else {
            print("Warning: Audiobus failed to initialize, aborting setup.")
            return nil
        }
        
        self.controller = controller
        
        self.controller.addSenderPort(
            ABSenderPort(
                name: "Sender",
                title: "HOWL (Sender)",
                audioComponentDescription: AudioComponentDescription(
                    componentType: kAudioUnitType_RemoteGenerator,
                    componentSubType: UInt32(fourCharacterCode: "howg"),
                    componentManufacturer: UInt32(fourCharacterCode: "ptnm"),
                    componentFlags: 0,
                    componentFlagsMask: 0
                ),
                audioUnit: AKManager.shared().engine.audioUnit
            )
        )
        
        self.controller.addFilterPort(
            ABFilterPort(
                name: "Filter",
                title: "HOWL (Filter)",
                audioComponentDescription: AudioComponentDescription(
                    componentType: kAudioUnitType_RemoteEffect,
                    componentSubType: UInt32(fourCharacterCode: "howx"),
                    componentManufacturer: UInt32(fourCharacterCode: "ptnm"),
                    componentFlags: 0,
                    componentFlagsMask: 0
                ),
                audioUnit: AKManager.shared().engine.audioUnit
            )
        )
        
        startObservingInterAppAudioConnections()
        startObservingAudiobusConnections()
    }
    
    deinit {
        stopObservingInterAppAudioConnections()
        stopObservingAudiobusConnections()
    }
    
    // MARK: Properties
    
    var isConnected: Bool {
        return controller.isConnectedToAudiobus || audioUnit.isConnectedToInterAppAudio
    }
    
    var isConnectedToInput: Bool {
        return controller.isConnectedToAudiobus(portOfType: ABPortTypeSender) || audioUnit.isConnectedToInterAppAudio(nodeOfType: kAudioUnitType_RemoteEffect)
    }
    
    // MARK: Connections
    
    private var audioUnitPropertyListener: AudioUnitPropertyListener!
    
    private func startObservingInterAppAudioConnections() {
        audioUnitPropertyListener = AudioUnitPropertyListener { (audioUnit, property) in
            self.updateConnections()
        }
        
        audioUnit.add(listener: audioUnitPropertyListener, to: kAudioUnitProperty_IsInterAppConnected)
    }
    
    private func stopObservingInterAppAudioConnections() {
        AKManager.shared().engine.audioUnit.remove(listener: self.audioUnitPropertyListener, from: kAudioUnitProperty_IsInterAppConnected)
    }
    
    private func startObservingAudiobusConnections() {
        NotificationCenter.default.addObserver(forName: .ABConnectionsChanged, object: nil, queue: nil, using: { notification in
            self.updateConnections()
        })
    }
    
    private func stopObservingAudiobusConnections() {
        NotificationCenter.default.removeObserver(self, name: .ABConnectionsChanged, object: nil)
    }
    
    private func updateConnections() {
        if (UIApplication.shared.applicationState == .background) {
            if (isConnected) {
                Audio.start()
            } else {
                Audio.stop()
            }
        }
        
        Audio.client?.vocoder.inputEnabled = isConnectedToInput
    }

}

private extension ABAudiobusController {
    
    var isConnectedToAudiobus: Bool {
        return connected == true || memberOfActiveAudiobusSession == true
    }
    
    func isConnectedToAudiobus(portOfType type: ABPortType) -> Bool {
        guard connectedPorts != nil else {
            return false
        }
        
        return connectedPorts.compactMap { $0 as? ABPort }.filter { $0.type == type }.isEmpty == false
    }
    
}

private extension AudioUnit {
    
    var isConnectedToInterAppAudio: Bool {
        let value: UInt32 = getValue(for: kAudioUnitProperty_IsInterAppConnected)
        return value != 0
    }
    
    func isConnectedToInterAppAudio(nodeOfType type: OSType) -> Bool {
        let value: AudioComponentDescription = getValue(for: kAudioOutputUnitProperty_NodeComponentDescription)
        return value.componentType == type
    }
    
}
