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

protocol ChatDelegate {
    func refreshMessages()
}

protocol PollDelegate {
    func refreshPolls(pollMessages: [DytePoll])
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
    var chatDelegate : ChatDelegate?
    var pollDelegate : PollDelegate?
    var participantsDelegate : ParticipantsDelegate?
    var participants = [DyteMeetingParticipant]()
    var screenshares = [DyteMeetingParticipant]()
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
    
    private func refreshPolls(pollMessages: [DytePoll]) {
        pollDelegate?.refreshPolls(pollMessages: pollMessages)
    }
    
    private func refreshMessages() {
        chatDelegate?.refreshMessages()
    }
}

extension MeetingViewModel: DyteChatEventsListener {
    func onMessageRateLimitReset() {
    }
    
    func onChatUpdates(messages: [DyteChatMessage]) {
        chatDelegate?.refreshMessages()
    }
    
    func onNewChatMessage(message: DyteChatMessage) {
        //use to show notifications
    }
}

extension MeetingViewModel: DyteParticipantsEventListener {
    func onActiveParticipantsChanged(active: [DyteRemoteParticipant]) {
        
    }
    
    func onActiveSpeakerChanged(participant: DyteRemoteParticipant?) {
        
    }
    
    func onAllParticipantsUpdated(allParticipants: [DyteParticipant]) {
        for participant in allParticipants {
            participantDict[participant.userId] = UIView()
        }
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }
    
    func onAudioUpdate(participant: DyteRemoteParticipant, isEnabled: Bool) {
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }
    
    func onNewBroadcastMessage(type: String, payload: [String : Any]) {
        
    }
    
    func onParticipantJoin(participant: DyteRemoteParticipant) {
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
    
    func onParticipantLeave(participant: DyteRemoteParticipant) {
        //remove participant.videoTrack to renderer
        if let index = participants.firstIndex(of: participant) {
            participants.remove(at: index)
            participantDict.removeValue(forKey: participant.id)
        }
        refreshData()
    }
    
    func onParticipantPinned(participant: DyteRemoteParticipant) {
        
    }
    
    func onParticipantUnpinned(participant: DyteRemoteParticipant) {
        
    }
    
    func onScreenShareUpdate(participant: DyteRemoteParticipant, isEnabled: Bool) {
        screenshares.removeAll()
        if let screenShares = dyteMobileClient?.participants.screenShares {
            for ssParticipant in screenShares {
                screenshares.append(ssParticipant)
            }
            refreshData()
        }
    }
    
    func onUpdate(participants: DyteParticipants) {
        for participant in participants.joined {
            participantDict[participant.id] = UIView()
        }
        
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
        
        screenshares.removeAll()
        for ssParticipant in participants.screenShares {
            screenshares.append(ssParticipant)
        }
        refreshData()
    }
    
    func onVideoUpdate(participant: DyteRemoteParticipant, isEnabled: Bool) {
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }
}

extension MeetingViewModel: DyteSelfEventsListener {
    func onAudioDevicesUpdated() {
        
    }
    
    func onAudioUpdate(isEnabled: Bool) {
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }
    
    func onMeetingRoomJoinedWithoutCameraPermission() {
        
    }
    
    func onMeetingRoomJoinedWithoutMicPermission() {
        
    }
    
    func onPermissionsUpdated(permission: SelfPermissions) {
        
    }
    
    func onPinned() {
        
    }
    
    func onRemovedFromMeeting() {
        
    }
    
    func onScreenShareStartFailed(reason: String) {
        
    }
    
    func onScreenShareUpdate(isEnabled: Bool) {
        screenshares.removeAll()
        if let screenShares = dyteMobileClient?.participants.screenShares {
            for ssParticipant in screenShares {
                screenshares.append(ssParticipant)
            }
            refreshData()
        }
    }
    
    func onUnpinned() {
        
    }
    
    func onUpdate(participant: DyteSelfParticipant) {
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }
    
    func onVideoDeviceChanged(videoDevice: DyteVideoDevice) {
        
    }
    
    func onVideoUpdate(isEnabled: Bool) {
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }
    
    func onWaitListStatusUpdate(waitListStatus: DyteiOSCore.WaitListStatus) {
        
    }
}

extension MeetingViewModel: DyteMeetingRoomEventsListener {
    func onActiveTabUpdate(meeting: DyteMobileClient, activeTab: ActiveTab) {
        
    }
    
    func onMeetingEnded() {
        meetingDelegate?.onMeetingRoomLeft()
    }
    
    func onMeetingInitCompleted(meeting: DyteMobileClient) {
        print("self.dyteMobile is \(self.dyteMobileClient?.localUser.videoEnabled ?? false)")
        self.dyteMobileClient?.joinRoom()
    }
    
    func onMeetingInitFailed(error: MeetingError) {
        print("Error: onMeetingInitFailed: \(error.message)")
        meetingDelegate?.onMeetingInitFailed()
    }
    
    func onMeetingInitStarted() {
        
    }
    
    func onMeetingRoomJoinCompleted(meeting: DyteMobileClient) {
        meetingDelegate?.onMeetingRoomJoined()
    }
    
    func onMeetingRoomJoinFailed(error: MeetingError) {
        print("Error: onMeetingRoomJoinFailed: \(error.message)")
    }
    
    func onMeetingRoomJoinStarted() {
        
    }
    
    func onMeetingRoomLeaveCompleted() {
        meetingDelegate?.onMeetingRoomLeft()
    }
    
    func onMeetingRoomLeaveStarted() {
        
    }
    
    func onMediaConnectionUpdate(update: MediaConnectionUpdate) {
        
    }
    
    func onSocketConnectionUpdate(newState: SocketConnectionState) {
        
    }
}

extension MeetingViewModel: DyteParticipantUpdateListener {
    func onAudioUpdate(participant: DyteMeetingParticipant, isEnabled: Bool) {
        
    }
    
    func onScreenShareUpdate(participant: DyteMeetingParticipant, isEnabled: Bool) {
        screenshares.removeAll()
        if let screenShares = dyteMobileClient?.participants.screenShares {
            for ssParticipant in screenShares {
                screenshares.append(ssParticipant)
            }
            refreshData()
        }
    }
    
    func onVideoUpdate(participant: DyteMeetingParticipant, isEnabled: Bool) {
        
    }
    
    func onUpdate(participant: DyteMeetingParticipant) {
        
    }
    
    func onPinned(participant: DyteMeetingParticipant) {
        
    }
    
    func onUnpinned(participant: DyteMeetingParticipant) {
        
    }
}

extension MeetingViewModel: DytePollsEventListener {
    func onNewPoll(poll: DytePoll) {
        
    }
    
    func onPollUpdate(poll: DytePoll) {
        
    }
    
    func onPollUpdates(pollItems: [DytePoll]) {
        refreshPolls(pollMessages: pollItems)
    }
}
