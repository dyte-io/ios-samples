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
    func refreshPolls(pollMessages: [DytePollMessage])
}

protocol ParticipantsDelegate {
    func refreshList()
}

final class MeetingViewModel {
    private var dyteMobileClient: DyteMobileClient?

    init(dyteClient: DyteMobileClient) {
        dyteMobileClient = dyteClient
    }

    var meetingDelegate: MeetingDelegate?
    var chatDelegate: ChatDelegate?
    var pollDelegate: PollDelegate?
    var participantsDelegate: ParticipantsDelegate?
    var participants = [DyteJoinedMeetingParticipant]()
    var screenshares = [DyteScreenShareMeetingParticipant]()
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
    func onAllParticipantsUpdated(allParticipants _: [DyteParticipant]) {}

    func onScreenShareEnded(participant _: DyteJoinedMeetingParticipant) {}

    func onScreenShareStarted(participant _: DyteJoinedMeetingParticipant) {}

    func onScreenShareEnded(participant_ _: DyteScreenShareMeetingParticipant) {}

    func onScreenShareStarted(participant_ _: DyteScreenShareMeetingParticipant) {}

    func onParticipantPinned(participant _: DyteJoinedMeetingParticipant) {}

    func onParticipantUnpinned(participant _: DyteJoinedMeetingParticipant) {}

    func onActiveSpeakerChanged(participant _: DyteJoinedMeetingParticipant) {}

    func onActiveParticipantsChanged(active _: [DyteJoinedMeetingParticipant]) {}

    func onParticipantJoin(participant _: DyteMeetingParticipant) {}

    func onParticipantLeave(participant _: DyteMeetingParticipant) {}

    func onVideoUpdate(videoEnabled _: Bool, participant _: DyteMeetingParticipant) {
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }

    func onAudioUpdate(audioEnabled _: Bool, participant _: DyteMeetingParticipant) {
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }

    func onGridUpdated(gridInfo _: GridInfo) {}

    func onActiveParticipantsChanged(active _: [DyteMeetingParticipant]) {}

    func onWaitListParticipantAccepted(participant _: DyteMeetingParticipant) {}

    func onWaitListParticipantClosed(participant _: DyteMeetingParticipant) {}

    func onWaitListParticipantJoined(participant _: DyteMeetingParticipant) {}

    func onWaitListParticipantRejected(participant _: DyteMeetingParticipant) {}

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

    func onParticipantsUpdated(participants: DyteRoomParticipants, isNextPagePossible _: Bool, isPreviousPagePossible _: Bool) {
        for participant in participants.joined {
            participantDict[participant.id] = UIView()
        }
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }

    func onParticipantPinned(participant _: DyteMeetingParticipant) {}

    func onParticipantUnpinned(participant _: DyteMeetingParticipant) {}

    func onScreenSharesUpdated() {
        screenshares.removeAll()
        if let screenShares = dyteMobileClient?.participants.screenshares {
            for ssParticipant in screenShares {
                screenshares.append(ssParticipant)
            }
            refreshData()
        }
    }

    func onActiveSpeakerChanged(participant _: DyteMeetingParticipant) {}

    func onNoActiveSpeaker() {}

//    func videoUpdate(videoEnabled: Bool, participant: DyteMeetingParticipant) {
//        meetingDelegate?.refreshList()
//        participantsDelegate?.refreshList()
//    }
}

extension MeetingViewModel: DyteSelfEventsListener {
    func onPermissionsUpdated(permission _: SelfPermissions) {}

    func onScreenShareStartFailed(reason _: String) {}

    func onScreenShareStopped() {}

    func onRoomMessage(type _: String, payload _: [String: Any]) {}

    func onVideoDeviceChanged(videoDevice _: DyteVideoDevice) {}

    func onStageStatusUpdated(stageStatus _: StageStatus) {}

    func onUpdate(participant_ _: DyteSelfParticipant) {
        // only for flutter
    }

    func onRemovedFromMeeting() {}

    func onMeetingRoomLeaveStarted() {}

    func onStoppedPresenting() {}

    func onWebinarPresentRequestReceived() {}

    func onMeetingRoomJoinedWithoutCameraPermission() {}

    func onMeetingRoomJoinedWithoutMicPermission() {}

    func onWaitListStatusUpdate(waitListStatus _: WaitListStatus) {}

    func onRoomJoined() {
        meetingDelegate?.onMeetingRoomJoined()
    }

    func onUpdate(participant _: DyteMeetingParticipant) {}

    func onAudioDevicesUpdated() {}

    func onProximityChanged(isNear _: Bool) {}

    func onAudioUpdate(audioEnabled _: Bool) {
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }

    func onVideoUpdate(videoEnabled _: Bool) {
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }
}

extension MeetingViewModel: DyteChatEventsListener {
    func onChatUpdates(messages _: [DyteChatMessage]) {
        chatDelegate?.refreshMessages()
    }

    func onNewChatMessage(message _: DyteChatMessage) {
        // use to show noptifications
    }
}

extension MeetingViewModel: DyteMeetingRoomEventsListener {
    func onActiveTabUpdate(activeTab _: ActiveTab) {}

    func onMeetingEnded() {
        meetingDelegate?.onMeetingRoomLeft()
    }

    func onActiveTabUpdate(id _: String, tabType _: ActiveTabType) {}

    func onConnectedToMeetingRoom() {}

    func onConnectingToMeetingRoom() {}

    func onDisconnectedFromMeetingRoom() {}

    func onMeetingRoomConnectionFailed() {}

    func onDisconnectedFromMeetingRoom(reason _: String) {}

    func onMeetingRoomConnectionError(errorMessage _: String) {}

    func onMeetingRoomReconnectionFailed() {}

    func onReconnectedToMeetingRoom() {}

    func onReconnectingToMeetingRoom() {}

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
        print("self.dyteMobile is \(dyteMobileClient?.localUser.videoEnabled ?? false)")
        dyteMobileClient?.joinRoom()
    }

    func onMeetingInitFailed(exception: KotlinException) {
        print("Error: onMeetingInitFailed: \(exception.message ?? "")")
        meetingDelegate?.onMeetingInitFailed()
    }

    func onMeetingInitStarted() {
        // 1
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
        // 1
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
        // remove participant.videoTrack to renderer
        if let index = participants.firstIndex(of: participant) {
            participants.remove(at: index)
            participantDict.removeValue(forKey: participant.id)
        }
        refreshData()
    }

    func onParticipantUpdated(participant _: DyteMeetingParticipant) {
        // 7
        refreshData()
    }

    func onParticipantsUpdated(participants: DyteRoomParticipants, enabledPaginator _: Bool) {
        // 4,8
        self.participants = participants.joined
        self.participants.append(contentsOf: participants.screenshares)
        refreshData()
    }

    func onPermissionDenied() {}

    func onPermissionDeniedAlways() {}

    func onPollUpdates(newPoll _: Bool, pollMessages: [DytePollMessage], updatedPollMessage _: DytePollMessage?) {
        refreshPolls(pollMessages: pollMessages)
    }
}

extension MeetingViewModel: DyteParticipantUpdateListener {
    func onPinned() {}

    func onRemovedAsActiveSpeaker() {}

    func onScreenShareEnded() {}

    func onScreenShareStarted() {}

    func onSetAsActiveSpeaker() {}

    func onUnpinned() {}

    func onAudioUpdate(isEnabled _: Bool) {}

    func onPinned(participant _: DyteMeetingParticipant) {}

    func onScreenShareEnded(participant _: DyteMeetingParticipant) {
        screenshares.removeAll()
        if let screenShares = dyteMobileClient?.participants.screenshares {
            for ssParticipant in screenShares {
                screenshares.append(ssParticipant)
            }
            refreshData()
        }
    }

    func onScreenShareStarted(participant _: DyteMeetingParticipant) {
        screenshares.removeAll()
        if let screenShares = dyteMobileClient?.participants.screenshares {
            for ssParticipant in screenShares {
                screenshares.append(ssParticipant)
            }
            refreshData()
        }
    }

    func onUnpinned(participant _: DyteMeetingParticipant) {}

    func onVideoUpdate(isEnabled _: Bool) {
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }
}
