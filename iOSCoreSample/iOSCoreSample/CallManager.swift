import AVFoundation
import CallKit
import Foundation
import RealtimeKit

protocol CallManagerDelegate: AnyObject {
    func callManager(_ manager: CallManager, didEncounterError error: Error)
    func callManagerDidUpdateCallState(_ manager: CallManager, state: CallManager.CallState)
}

extension CallManager: CXProviderDelegate {
    func providerDidReset(_: CXProvider) {
        rtkClient?.leaveMeeting()
        callState = .idle
    }

    func provider(_: CXProvider, perform action: CXAnswerCallAction) {
        callState = .connecting
        rtkClient?.joinMeeting { [weak self] success, error in
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

    func provider(_: CXProvider, perform action: CXEndCallAction) {
        rtkClient?.leaveMeeting()
        callState = .disconnected
        action.fulfill()
    }

    func provider(_: CXProvider, perform action: CXStartCallAction) {
        callState = .connecting
        rtkClient?.joinMeeting { [weak self] success, error in
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

    func provider(_: CXProvider, perform action: CXSetHeldCallAction) {
        if action.isOnHold {
            // Put the call on hold
            rtkClient?.holdCall { [weak self] success in
                guard let self = self else { return }
                if success {
                    action.fulfill()
                } else {
                    action.fail()
                    self.delegate?.callManager(self, didEncounterError: NSError(domain: "com.cloudflare.CallManager", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to hold call"]))
                }
            }
        } else {
            // Resume the call
            rtkClient?.resumeCall { [weak self] success in
                guard let self = self else { return }
                if success {
                    action.fulfill()
                } else {
                    action.fail()
                    self.delegate?.callManager(self, didEncounterError: NSError(domain: "com.cloudflare.CallManager", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Failed to resume call"]))
                }
            }
        }
    }

    func provider(_: CXProvider, perform action: CXSetMutedCallAction) {
        if action.isMuted {
            rtkClient?.muteAudio()
        } else {
            rtkClient?.unmuteAudio()
        }
        action.fulfill()
    }
}

class CallManager: NSObject {
    enum CallState {
        case idle, connecting, connected, disconnected
    }

    let callController = CXCallController()
    var provider: CXProvider
    var rtkClient: RtkClient?
    weak var delegate: CallManagerDelegate?
    private(set) var callState: CallState = .idle {
        didSet {
            delegate?.callManagerDidUpdateCallState(self, state: callState)
        }
    }

    override init() {
        let configuration = CXProviderConfiguration(localizedName: "Rtk Meeting")
        configuration.supportsVideo = true
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportedHandleTypes = [.generic]
        configuration.includesCallsInRecents = true
        configuration.supportsVideo = true
        let localizedName = NSLocalizedString("CallKitDemo", comment: "Name of application")

        configuration.supportsVideo = false

        configuration.maximumCallsPerCallGroup = 1

        configuration.ringtoneSound = "Ringtone.caf"
        provider = CXProvider(configuration: configuration)

        super.init()

        provider.setDelegate(self, queue: nil)

        // Set up audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            delegate?.callManager(self, didEncounterError: error)
        }
    }

    func startCall(handle: String, meetingInfo: RtkMeetingInfo) {
        let handle = CXHandle(type: .generic, value: handle)
        let startCallAction = CXStartCallAction(call: UUID(), handle: handle)
        let transaction = CXTransaction(action: startCallAction)

        rtkClient = RtkClient(meetingInfo: meetingInfo)

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
                self.rtkClient?.joinMeeting { _, error in
                    if let error = error {
                        self.delegate?.callManager(self, didEncounterError: error as! Error)
                        self.callState = .disconnected
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
                self.rtkClient?.leaveMeeting()
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
        rtkClient?.muteAudio()
    }

    func unmuteCall() {
        rtkClient?.unmuteAudio()
    }

    func enableVideo() {
        rtkClient?.enableVideo()
    }

    func disableVideo() {
        rtkClient?.disableVideo()
    }

    func checkAudioState() -> Bool {
        return rtkClient?.audioState() ?? false
    }

    func checkVideoState() -> Bool {
        return rtkClient?.videoState() ?? false
    }

    func setAudioOutputSpeaker(_ speaker: Bool) {
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(speaker ? .speaker : .none)
        } catch {
            delegate?.callManager(self, didEncounterError: error)
        }
    }
}

class RtkClient {
    var rtkClient: RealtimeKitClient?
    private var meetingInfo: RtkMeetingInfo?

    init(meetingInfo: RtkMeetingInfo) {
        self.meetingInfo = meetingInfo
        rtkClient = RealtimeKitiOSClientBuilder().build()
    }

    func joinMeeting(completion: @escaping (Bool, MeetingError?) -> Void) {
        guard let rtkClient = rtkClient, let meetingInfo = meetingInfo else { return }

        rtkClient.doInit(meetingInfo: meetingInfo) {
            rtkClient.joinRoom {
                completion(true, nil)
            } onFailure: { _ in
                completion(false, nil)
            }
        } onFailure: { error in
            completion(false, error)
        }
    }

    func audioState() -> Bool {
        return rtkClient?.localUser.audioEnabled ?? false
    }

    func videoState() -> Bool {
        return rtkClient?.localUser.videoEnabled ?? false
    }

    func leaveMeeting() {
        rtkClient?.leaveRoom {} onFailure: { _ in }
    }

    func muteAudio() {
        rtkClient?.localUser.disableAudio { _ in }
    }

    func unmuteAudio() {
        rtkClient?.localUser.enableAudio { _ in }
    }

    func disableVideo() {
        rtkClient?.localUser.disableVideo { _ in }
    }

    func enableVideo() {
        rtkClient?.localUser.enableVideo { _ in }
    }

    func resumeCall(completion: @escaping (Bool) -> Void) {
        guard let rtkClient = rtkClient else {
            completion(false)
            return
        }

        // Re-enable audio and video
        rtkClient.localUser.enableAudio { _ in }
        rtkClient.localUser.enableVideo { _ in }

        // If you paused incoming audio/video, resume it here
        // For example: rtkClient.resumeIncomingStreams()

        completion(true)
    }

    func holdCall(completion: @escaping (Bool) -> Void) {
        guard let rtkClient = rtkClient else {
            completion(false)
            return
        }

        // Disable audio and video
        rtkClient.localUser.disableAudio { _ in }
        rtkClient.localUser.disableVideo { _ in }

        // If you have a way to pause incoming audio/video, implement it here
        // For example: rtkClient.pauseIncomingStreams()

        completion(true)
    }
}
