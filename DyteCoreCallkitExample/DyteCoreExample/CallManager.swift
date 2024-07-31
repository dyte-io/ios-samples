//
//  CallManager.swift
//  DyteCoreExample
//
//  Created by Shaunak Jagtap on 30/07/24.
//
import Foundation
import CallKit
import DyteiOSCore
import AVFoundation

protocol CallManagerDelegate: AnyObject {
    func callManager(_ manager: CallManager, didEncounterError error: Error)
    func callManagerDidUpdateCallState(_ manager: CallManager, state: CallManager.CallState)
}

class CallManager: NSObject {
    enum CallState {
        case idle, connecting, connected, disconnected
    }
    
    let callController = CXCallController()
    var provider: CXProvider
    var dyteClient: DyteClient?
    weak var delegate: CallManagerDelegate?
    private(set) var callState: CallState = .idle {
        didSet {
            delegate?.callManagerDidUpdateCallState(self, state: callState)
        }
    }
    
    override init() {
        let configuration = CXProviderConfiguration(localizedName: "Dyte Meeting")
        configuration.supportsVideo = true
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportedHandleTypes = [.generic]
        configuration.includesCallsInRecents = true
        configuration.supportsVideo = true
        let localizedName = NSLocalizedString("CallKitDemo", comment: "Name of application")

        configuration.supportsVideo = false

        configuration.maximumCallsPerCallGroup = 1

//        configuration.supportedHandleTypes = [.phoneNumber]

//        configuration.iconTemplateImageData = #imageLiteral(resourceName: "IconMask").pngData()

        configuration.ringtoneSound = "Ringtone.caf"
        self.provider = CXProvider(configuration: configuration)
        
        super.init()
        
        self.provider.setDelegate(self, queue: nil)
        
        // Set up audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            delegate?.callManager(self, didEncounterError: error)
        }
    }
    
    func startCall(handle: String, meetingInfo: DyteMeetingInfoV2) {
        let handle = CXHandle(type: .generic, value: handle)
        let startCallAction = CXStartCallAction(call: UUID(), handle: handle)
        let transaction = CXTransaction(action: startCallAction)
        
        dyteClient = DyteClient(meetingInfo: meetingInfo)
        
        callController.request(transaction) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.delegate?.callManager(self, didEncounterError: error)
            } else {
                let callUpdate = CXCallUpdate()
                callUpdate.remoteHandle = handle
                callUpdate.hasVideo = true
                self.provider.reportCall(with: startCallAction.callUUID, updated: callUpdate)
                self.callState = .connecting
                self.dyteClient?.joinMeeting { success, error in
                    if let error = error {
                        self.delegate?.callManager(self, didEncounterError: error as! Error)
                        self.callState = .disconnected
                    } else if success {
                        self.callState = .connected
                    }
                }
            }
        }
    }
    
    func endCall(uuid: UUID) {
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)
        callController.request(transaction) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.delegate?.callManager(self, didEncounterError: error)
            } else {
                self.dyteClient?.leaveMeeting()
                self.callState = .disconnected
            }
        }
    }
    
    func reportIncomingCall(uuid: UUID, handle: String, completion: @escaping (Error?) -> Void) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: handle)
        update.hasVideo = true
        
        provider.reportNewIncomingCall(with: uuid, update: update) { [weak self] error in
            if let error = error {
                self?.delegate?.callManager(self!, didEncounterError: error)
            }
            completion(error)
        }
    }
    
    func muteCall() {
        dyteClient?.muteAudio()
    }
    
    func unmuteCall() {
        dyteClient?.unmuteAudio()
    }
    
    func enableVideo() {
        dyteClient?.enableVideo()
    }
    
    func disableVideo() {
        dyteClient?.disableVideo()
    }
    
    func checkAudioState() -> Bool {
        return dyteClient?.audioState() ?? false
    }
    
    func checkVideoState() -> Bool {
        return dyteClient?.videoState() ?? false
    }
    
    func setAudioOutputSpeaker(_ speaker: Bool) {
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(speaker ? .speaker : .none)
        } catch {
            delegate?.callManager(self, didEncounterError: error)
        }
    }
}

extension CallManager: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        dyteClient?.leaveMeeting()
        callState = .idle
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        callState = .connecting
        dyteClient?.joinMeeting { [weak self] success, error in
            guard let self = self else { return }
            if let error = error {
                self.delegate?.callManager(self, didEncounterError: error as! Error)
                self.callState = .disconnected
            } else if success {
                self.callState = .connected
            }
            action.fulfill()
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        dyteClient?.leaveMeeting()
        callState = .disconnected
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        callState = .connecting
        dyteClient?.joinMeeting { [weak self] success, error in
            guard let self = self else { return }
            if let error = error {
                self.delegate?.callManager(self, didEncounterError: error as! Error)
                self.callState = .disconnected
            } else if success {
                self.callState = .connected
            }
            action.fulfill()
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        if action.isOnHold {
            // Put the call on hold
            dyteClient?.holdCall { [weak self] success in
                guard let self = self else { return }
                if success {
                    action.fulfill()
                } else {
                    action.fail()
                    self.delegate?.callManager(self, didEncounterError: NSError(domain: "com.dyte.CallManager", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to hold call"]))
                }
            }
        } else {
            // Resume the call
            dyteClient?.resumeCall { [weak self] success in
                guard let self = self else { return }
                if success {
                    action.fulfill()
                } else {
                    action.fail()
                    self.delegate?.callManager(self, didEncounterError: NSError(domain: "com.dyte.CallManager", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Failed to resume call"]))
                }
            }
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        if action.isMuted {
            dyteClient?.muteAudio()
        } else {
            dyteClient?.unmuteAudio()
        }
        action.fulfill()
    }
}

class DyteClient {
    var dyteMobileClient: DyteMobileClient?
    private var meetingInfo: DyteMeetingInfoV2?
    
    init(meetingInfo: DyteMeetingInfoV2) {
        self.meetingInfo = meetingInfo
        self.dyteMobileClient = DyteiOSClientBuilder().build()
    }
    
    func joinMeeting(completion: @escaping (Bool, DyteError?) -> Void) {
        guard let dyteMobileClient = dyteMobileClient, let meetingInfo = meetingInfo else {
            completion(false, DyteError(code: 12, message: "Initialization error"))
            return
        }
        
        dyteMobileClient.doInit(dyteMeetingInfo: meetingInfo) {
            dyteMobileClient.joinRoom {
                completion(true, nil)
            } onRoomJoinFailed: {
                completion(false, nil)
            }
        } onInitFailure: { error in
            completion(false, error)
        }
    }
    
    func audioState() -> Bool {
        return dyteMobileClient?.localUser.audioEnabled ?? false
    }
    
    func videoState() -> Bool {
        return dyteMobileClient?.localUser.videoEnabled ?? false
    }
    
    func leaveMeeting() {
        dyteMobileClient?.leaveRoom()
    }
    
    func muteAudio() {
        try? dyteMobileClient?.localUser.disableAudio()
    }
    
    func unmuteAudio() {
        dyteMobileClient?.localUser.enableAudio()
    }
    
    func disableVideo() {
        try? dyteMobileClient?.localUser.disableVideo()
    }
    
    func enableVideo() {
        dyteMobileClient?.localUser.enableVideo()
    }
    
    func resumeCall(completion: @escaping (Bool) -> Void) {
            guard let dyteMobileClient = dyteMobileClient else {
                completion(false)
                return
            }
            
            // Re-enable audio and video
            dyteMobileClient.localUser.enableAudio()
            dyteMobileClient.localUser.enableVideo()
            
            // If you paused incoming audio/video, resume it here
            // For example: dyteMobileClient.resumeIncomingStreams()
            
            completion(true)
        }
    
    func holdCall(completion: @escaping (Bool) -> Void) {
            guard let dyteMobileClient = dyteMobileClient else {
                completion(false)
                return
            }
            
            // Disable audio and video
            do {
                try dyteMobileClient.localUser.disableAudio()
                try dyteMobileClient.localUser.disableVideo()
                
                // If you have a way to pause incoming audio/video, implement it here
                // For example: dyteMobileClient.pauseIncomingStreams()
                
                completion(true)
            } catch {
                print("Error holding call: \(error)")
                completion(false)
            }
        }
}
