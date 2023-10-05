//
//  MeetingViewModel.swift
//  iosApp
//
//  Created by Shaunak Jagtap on 18/08/22.
//  Copyright © 2022 orgName. All rights reserved.
//
import DyteiOSCore
import UIKit

protocol MeetingDelegate {
    func refreshList()
    func onMeetingRoomLeft()
    func onMeetingRoomJoined()
    func onMeetingInitFailed()
}

protocol PluginDelegate {
    func refreshPluginView(plugin: DytePlugin)
}

protocol ChatDelegate {
    func refreshMessages()
}

protocol PollDelegate {
    func refreshPolls(pollMessages: [DytePollMessage])
}


protocol ParticipantsDelegate {
    func refreshList()
}

final class MeetingViewModel {
    private var dyteMobileClient: DyteMobileClient?

    init(dyteClient: DyteMobileClient) {
        self.dyteMobileClient = dyteClient
    }
    
    var meetingDelegate : MeetingDelegate?
    var pluginDelegate : PluginDelegate?
    var chatDelegate : ChatDelegate?
    var pollDelegate : PollDelegate?
    var participantsDelegate : ParticipantsDelegate?
    var participants = [DyteJoinedMeetingParticipant]()
    var screenshares = [DyteJoinedMeetingParticipant]()
    var participantDict = [String: UIView]()
    var isFrontCam = true
    
    private func refreshData() {
        participants.removeAll()
        if let array = dyteMobileClient?.participants.joined {
            participants = array
            participants = participants.sorted(by: { $0.id > $1.id })
        }
        
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }
    
    private func refreshPolls(pollMessages: [DytePollMessage]) {
        pollDelegate?.refreshPolls(pollMessages: pollMessages)
    }
    
    private func refreshMessages() {
        chatDelegate?.refreshMessages()
    }

}

extension MeetingViewModel: DyteParticipantEventsListener {
    func onScreenShareEnded(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    func onScreenShareStarted(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    func onScreenShareEnded(participant_ participant: DyteScreenShareMeetingParticipant) {
        
    }
    
    func onScreenShareStarted(participant_ participant: DyteScreenShareMeetingParticipant) {
        
    }
    

    func onActiveParticipantsChanged(active: [DyteJoinedMeetingParticipant]) {
        print("onActiveParticipantsChanged \(active.count)")
        
    }
    func onParticipantUnpinned(participant: DyteJoinedMeetingParticipant) {

    }
    
    func onActiveSpeakerChanged(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    
    func onVideoUpdate(videoEnabled: Bool, participant: DyteMeetingParticipant) {
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }
    
    func onAudioUpdate(audioEnabled: Bool, participant: DyteMeetingParticipant) {
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }
    
    func onGridUpdated(gridInfo: GridInfo) {
        
    }

   
    
    func onWaitListParticipantAccepted(participant: DyteWaitlistedParticipant) {
        
    }
    
    func onWaitListParticipantClosed(participant: DyteWaitlistedParticipant) {
        
    }
    
    func onWaitListParticipantJoined(participant: DyteWaitlistedParticipant) {
        
    }
    
    func onWaitListParticipantRejected(participant: DyteWaitlistedParticipant) {
        
    }
    
    func onUpdate(participants: DyteRoomParticipants) {
        for participant in participants.joined {
            participantDict[participant.id] = UIView()
        }
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
        
        screenshares.removeAll()
        if let screenShares = dyteMobileClient?.participants.screenshares {
            for ssParticipant in screenShares {
                screenshares.append(ssParticipant)
            }
            refreshData()
        }
    }
    
    func onParticipantsUpdated(participants: DyteRoomParticipants, isNextPagePossible: Bool, isPreviousPagePossible: Bool) {
        for participant in participants.joined {
            participantDict[participant.id] = UIView()
        }
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }
    
    func onParticipantPinned(participant: DyteJoinedMeetingParticipant) {
        
    }
    
    func onScreenSharesUpdated() {
        screenshares.removeAll()
        if let screenShares = dyteMobileClient?.participants.screenshares {
            for ssParticipant in screenShares {
                screenshares.append(ssParticipant)
            }
            refreshData()
        }
    }
    
    func onNoActiveSpeaker() {
        
    }

}

extension MeetingViewModel: DyteSelfEventsListener {
    func onRoomMessage(type: String, payload: [String : Any]) {
        
    }
    
    func onVideoDeviceChanged(videoDevice: DyteVideoDevice) {

    }

    func onStageStatusUpdated(stageStatus: StageStatus) {

    }

    func onRoomMessage(message: String) {
        
    }

    func onUpdate(participant_ participant: DyteSelfParticipant) {
        //only for flutter
    }
    
    func onRemovedFromMeeting() {
        
    }
    
    func onMeetingRoomLeaveStarted() {
        
    }
    
    func onStoppedPresenting() {
        
    }
    
    func onWebinarPresentRequestReceived() {
    
    }
    
    func onMeetingRoomJoinedWithoutCameraPermission() {
        
    }
    
    func onMeetingRoomJoinedWithoutMicPermission() {
        
    }
    
    func onWaitListStatusUpdate(waitListStatus: WaitListStatus) {
        
    }
    
    func onRoomJoined() {
        meetingDelegate?.onMeetingRoomJoined()
    }
    
    func onUpdate(participant: DyteMeetingParticipant) {
        
    }
    
    func onAudioDevicesUpdated() {
        
    }
    
    func onProximityChanged(isNear: Bool) {
        
    }
    
    func onAudioUpdate(audioEnabled: Bool) {
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }
    
    func onVideoUpdate(videoEnabled: Bool) {
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }
}

extension MeetingViewModel: DyteChatEventsListener {
    func onChatUpdates(messages: [DyteChatMessage]) {
        chatDelegate?.refreshMessages()
    }
    
    func onNewChatMessage(message: DyteChatMessage) {
        //use to show noptifications
    }
}


extension MeetingViewModel: DyteMeetingRoomEventsListener {
    func onConnectedToMeetingRoom() {
        
    }
    
    func onConnectingToMeetingRoom() {
        
    }
    
    func onDisconnectedFromMeetingRoom() {
        
    }
    
    func onMeetingRoomConnectionFailed() {
        
    }
    
    func onMeetingRoomReconnectionFailed() {
        
    }
    
    func onReconnectedToMeetingRoom() {
        
    }
    
    func onReconnectingToMeetingRoom() {
        
    }
    
    
    func onMeetingRoomJoinCompleted() {
        meetingDelegate?.onMeetingRoomJoined()
    }
    
    func onMeetingRoomLeaveCompleted() {
        meetingDelegate?.onMeetingRoomLeft()
    }
    
//    func onChatUpdates(messages: [DyteChatMessage]) {
//        chatDelegate?.refreshMessages()
//    }
//
//    func onMeetingRecordingStateUpdated(state: DyteRecordingState) {
//        refreshData()
//    }
//
//    func onNewChatMessage(message: DyteChatMessage) {
//
//    }
//
//    func onNewPoll(poll: DytePollMessage) {
//
//    }
//    //
//    func onPollUpdates(pollMessages: [DytePollMessage]) {
//        refreshPolls(pollMessages: pollMessages)
//    }
//
//    func onWaitingRoomEntered() {
//
//    }
//
//    func onWaitingRoomEntryAccepted() {
//
//    }
//
//    func onWaitingRoomEntryRejected() {
//
//    }
    
//    func onHostKicked() {
//        meetingDelegate?.onMeetingRoomLeft()
//    }
//
//    func onMeetingRecordingStopError(e: KotlinException) {
//        Utils.displayAlert(alertTitle: Constants.errorTitle, message: Constants.recordingError)
//    }
    
    func onMeetingRoomDisconnected() {
        participantDict.removeAll()
        participants.removeAll()
    }
    
    
    func onMeetingInitCompleted() {
        self.dyteMobileClient?.localUser.setDisplayName(name: Constants.USER_NAME)
        self.dyteMobileClient?.joinRoom()
    }
    
    func onMeetingInitFailed(exception: KotlinException) {
        print("Error: onMeetingInitFailed: \(exception.message ?? "")")
        meetingDelegate?.onMeetingInitFailed()
    }
    
    func onMeetingInitStarted() {
        //1
    }

    
    func onMeetingRecordingEnded() {
        refreshData()
    }
    
    func onMeetingRecordingStarted() {
        refreshData()
    }
    
    func onMeetingRoomJoinFailed(exception: KotlinException) {
        print("Error: onMeetingRoomJoinFailed: \(exception.message ?? "")")
    }
    
    func onMeetingRoomJoinStarted() {
        //1
    }

    
    
    
    func onParticipantJoin(participant: DyteJoinedMeetingParticipant) {
        var peerExist = false
        let nib = UINib(nibName: "PeerCollectionViewCell", bundle: nil)
        if let videoView = nib.instantiate(withOwner: meetingDelegate, options: nil).first as? PeerCollectionViewCell {
            participantDict[participant.id] = videoView
        }
        
        for lParticipant in participants {
            if lParticipant.id == participant.id {
                peerExist = true
            }
        }
        if !peerExist {
            participant.addParticipantUpdateListener(participantUpdateListener: self)
            participants.append(participant)
            refreshData()
        }
    }
    
    func onParticipantLeave(participant: DyteJoinedMeetingParticipant) {
        //remove participant.videoTrack to renderer
        if let index = participants.firstIndex(of: participant) {
            participants.remove(at: index)
            participantDict.removeValue(forKey: participant.id)
        }
        refreshData()
    }
    
    func onParticipantUpdated(participant: DyteMeetingParticipant) {
        //7
        refreshData()
    }
    
    func onParticipantsUpdated(participants: DyteRoomParticipants, enabledPaginator: Bool) {
        //4,8
        self.participants = participants.joined
        self.participants.append(contentsOf: participants.screenshares)
        refreshData()
    }
    
    func onPermissionDenied() {
        
    }
    
    func onPermissionDeniedAlways() {
        
    }
    
    func onPollUpdates(newPoll: Bool, pollMessages: [DytePollMessage], updatedPollMessage: DytePollMessage?) {
        refreshPolls(pollMessages: pollMessages)
    }
    
}

extension MeetingViewModel: DyteParticipantUpdateListener {
    func onScreenShareEnded() {
        
    }
    
    func onScreenShareStarted() {
        
    }
    
    func onPinned() {
        
    }
    
    func onRemovedAsActiveSpeaker() {
        
    }
    
    func onSetAsActiveSpeaker() {
        
    }
    
    func onUnpinned() {
        
    }
    
    func onAudioUpdate(isEnabled: Bool) {
        
    }
    
    func onPinned(participant: DyteMeetingParticipant) {
        
    }
    
    func onScreenShareEnded(participant: DyteScreenShareMeetingParticipant) {
        screenshares.removeAll()
        if let screenShares = dyteMobileClient?.participants.screenshares {
            for ssParticipant in screenShares {
                screenshares.append(ssParticipant)
            }
            refreshData()
        }
    }
    
    func onScreenShareStarted(participant: DyteScreenShareMeetingParticipant) {
        screenshares.removeAll()
        if let screenShares = dyteMobileClient?.participants.screenshares {
            for ssParticipant in screenShares {
                screenshares.append(ssParticipant)
            }
            refreshData()
        }
    }
    
    func onUnpinned(participant: DyteMeetingParticipant) {
        
    }
    
    func onVideoUpdate(isEnabled: Bool) {
        
    }
    
    
}

extension MeetingViewModel: DytePluginEventsListener {
    
    public func onPluginActivated(plugin: DytePlugin) {
        self.pluginDelegate?.refreshPluginView(plugin: plugin)
    }
    
    public func onPluginDeactivated(plugin: DytePlugin) {
        self.pluginDelegate?.refreshPluginView(plugin: plugin)
    }
    
    public func onPluginFileRequest(plugin: DytePlugin) {
        
    }
    
    public func onPluginMessage(message: [String : Kotlinx_serialization_jsonJsonElement]) {
        
    }
    
}
