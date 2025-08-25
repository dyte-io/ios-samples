//
//  ActiveSpeakerMeetingViewModel.swift
//  active-speaker-ui-sample
//
//  Created by Dyte on 23/01/24.
//

import RealtimeKit
import RealtimeKitUI
import UIKit

protocol ActiveSpeakerMeetingViewModelDelegate: AnyObject {
    func refreshMeetingGrid(forRotation: Bool, animation: Bool, completion: @escaping () -> Void)
    func refreshPluginsView(completion: @escaping () -> Void)
    func activeSpeakerChanged(participant: RtkMeetingParticipant)
    func pinnedChanged(participant: RtkMeetingParticipant)
    func activeSpeakerRemoved()
    func pinnedParticipantRemoved(participant: RtkMeetingParticipant)
    func participantJoined(participant: RtkMeetingParticipant)
    func participantLeft(participant: RtkMeetingParticipant)
    func newPollAdded(createdBy: String)
    func leaveMeeting()
}

extension ActiveSpeakerMeetingViewModelDelegate {
    func refreshMeetingGrid(completion: @escaping () -> Void) {
        refreshMeetingGrid(forRotation: false, animation: true, completion: completion)
    }
}

public final class ActiveSpeakerMeetingViewModel {
    private let meeting: RealtimeKitClient
    let selfListener: RtkEventSelfListener
    let maxParticipantOnpage: UInt
    let waitlistEventListner: RtkWaitListParticipantUpdateEventListener

    weak var delegate: ActiveSpeakerMeetingViewModelDelegate?
    var chatDelegate: ChatDelegate?
    var currentlyShowingItemOnSinglePage: UInt
    var arrGridParticipants = [GridCellViewModel]()
    let screenShareViewModel: ScreenShareViewModel
    var shouldShowShareScreen = false
    let rtkNotification = RtkNotification()
    var notificationDelegate: RtkNotificationDelegate?

    public init(meeting: RealtimeKitClient) {
        self.meeting = meeting
        screenShareViewModel = ScreenShareViewModel(selfActiveTab: meeting.meta.selfActiveTab)
        waitlistEventListner = RtkWaitListParticipantUpdateEventListener(rtkClient: meeting)
        selfListener = RtkEventSelfListener(rtkClient: meeting)
        maxParticipantOnpage = 9
        currentlyShowingItemOnSinglePage = maxParticipantOnpage
        initialise()
    }

    public func clearChatNotification() {
        notificationDelegate?.clearChatNotification()
    }

    func trackOnGoingState() {
        if let participant = meeting.participants.pinned {
            delegate?.pinnedChanged(participant: participant)
        }

        if meeting.plugins.active.count >= 1 {
            screenShareViewModel.refresh(plugins: meeting.plugins.active, selectedPlugin: nil)
            delegate?.refreshPluginsView(completion: {})
        }

        // TODO: Do this onConnectedToMeetingRoom
    }

    func onReconnect() {
        if meeting.participants.screenShares.count > 0 {
            updateScreenShareStatus()
        }
        if meeting.plugins.active.count >= 1 {
            screenShareViewModel.refresh(plugins: meeting.plugins.active, selectedPlugin: nil)
            delegate?.refreshPluginsView { [weak self] in
                guard let self = self else { return }
                self.delegate?.refreshMeetingGrid {}
            }
        } else {
            delegate?.refreshMeetingGrid {}
        }
    }

    func initialise() {
        meeting.addParticipantsEventListener(participantsEventListener: self)
        meeting.addPluginsEventListener(pluginsEventListener: self)
        meeting.addChatEventListener(chatEventListener: self)
        meeting.addMeetingRoomEventListener(meetingRoomEventListener: self)
        meeting.addPollsEventListener(pollsEventListener: self)
    }

    public func clean() {
        selfListener.clean()
        delegate = nil
        meeting.removeMeetingRoomEventListener(meetingRoomEventListener: self)
        meeting.removeParticipantsEventListener(participantsEventListener: self)
        meeting.removePluginsEventListener(pluginsEventListener: self)
        meeting.removeChatEventListener(chatEventListener: self)
        meeting.removePollsEventListener(pollsEventListener: self)
    }
}

extension ActiveSpeakerMeetingViewModel: RtkMeetingRoomEventListener {
    public func onActiveTabUpdate(meeting _: RealtimeKitClient, activeTab _: ActiveTab) {}

    public func onMeetingEnded() {}

    public func onMeetingInitCompleted(meeting _: RealtimeKitClient) {}

    public func onMeetingInitFailed(error _: MeetingError) {}

    public func onMeetingInitStarted() {}

    public func onMeetingRoomJoinCompleted(meeting _: RealtimeKitClient) {}

    public func onMeetingRoomJoinFailed(error _: MeetingError) {}

    public func onMeetingRoomJoinStarted() {}

    public func onMeetingRoomLeaveCompleted() {
        delegate?.leaveMeeting()
    }

    public func onMeetingRoomLeaveStarted() {}

    public func onMediaConnectionUpdate(update _: MediaConnectionUpdate) {}

    public func onSocketConnectionUpdate(newState _: SocketConnectionState) {}
}

extension ActiveSpeakerMeetingViewModel: RtkPollsEventListener {
    public func onPollUpdates(pollItems _: [Poll]) {}

    public func onPollUpdate(poll _: Poll) {}

    public func onNewPoll(poll: Poll) {
        delegate?.newPollAdded(createdBy: poll.createdBy)
        notificationDelegate?.didReceiveNotification(type: .Poll)
    }
}

extension ActiveSpeakerMeetingViewModel {
    public func refreshActiveParticipants(pageItemCount: UInt = 0, completion: @escaping () -> Void) {
        // pageItemCount tell on first page how many tiles needs to be shown to user
        updateActiveGridParticipants(pageItemCount: pageItemCount)
        delegate?.refreshMeetingGrid(completion: completion)
    }

    private func updateActiveGridParticipants(pageItemCount: UInt = 0) {
        currentlyShowingItemOnSinglePage = pageItemCount
        arrGridParticipants = getParticipant(pageItemCount: pageItemCount)
    }

    // Returned a pin particpant at the zero position if exists
    private func getParticipant(pageItemCount: UInt = 0) -> [GridCellViewModel] {
        let activeParticipants = meeting.participants.active

        let rowCount = (pageItemCount == 0 || pageItemCount >= activeParticipants.count) ? UInt(activeParticipants.count) : min(UInt(activeParticipants.count), pageItemCount)

        var itemCount = 0
        var result = [GridCellViewModel]()
        for participant in activeParticipants {
            if itemCount < rowCount {
                if participant.isPinned {
                    result.insert(GridCellViewModel(participant: participant), at: 0)
                } else {
                    result.append(GridCellViewModel(participant: participant))
                }
            } else {
                break
            }
            itemCount += 1
        }
        return result
    }
}

extension ActiveSpeakerMeetingViewModel: RtkParticipantsEventListener {
    public func onAudioUpdate(participant _: RtkRemoteParticipant, isEnabled _: Bool) {}

    public func onNewBroadcastMessage(type _: String, payload _: [String: Any]) {}

    public func onScreenShareUpdate(participant _: RtkRemoteParticipant, isEnabled _: Bool) {}

    public func onVideoUpdate(participant _: RtkRemoteParticipant, isEnabled _: Bool) {}

    public func onScreenSharesUpdated() {}

    public func onUpdate(participants _: RtkParticipants) {}

    public func onAllParticipantsUpdated(allParticipants _: [RtkParticipant]) {}

    public func onScreenShareEnded(participant_ _: RtkRemoteParticipant) {}

    public func onScreenShareStarted(participant_ _: RtkRemoteParticipant) {}

    public func onScreenShareEnded(participant _: RtkRemoteParticipant) {
        updateScreenShareStatus()
    }

    public func onScreenShareStarted(participant _: RtkRemoteParticipant) {
        updateScreenShareStatus()
    }

    public func onParticipantLeave(participant: RtkRemoteParticipant) {
        delegate?.participantLeft(participant: participant)
        notificationDelegate?.didReceiveNotification(type: .Leave)
    }

    public func onActiveParticipantsChanged(active _: [RtkRemoteParticipant]) {
        refreshActiveParticipants(pageItemCount: currentlyShowingItemOnSinglePage) {}
    }

    public func onActiveSpeakerChanged(participant: RtkRemoteParticipant?) {
        guard let pcpt = participant else { return }
        delegate?.activeSpeakerChanged(participant: pcpt)
    }

    public func onNoActiveSpeaker() {
        delegate?.activeSpeakerRemoved()
    }

    public func onAudioUpdate(audioEnabled _: Bool, participant _: RtkRemoteParticipant) {}

    public func onParticipantJoin(participant: RtkRemoteParticipant) {
        delegate?.participantJoined(participant: participant)
        notificationDelegate?.didReceiveNotification(type: .Joined)
    }

    public func onParticipantPinned(participant: RtkRemoteParticipant) {
        refreshActiveParticipants(pageItemCount: currentlyShowingItemOnSinglePage) { [weak self] in
            guard let self = self else { return }
            self.delegate?.pinnedChanged(participant: participant)
        }
    }

    public func onParticipantUnpinned(participant: RtkRemoteParticipant) {
        delegate?.pinnedParticipantRemoved(participant: participant)
    }

    private func updateScreenShareStatus() {
        screenShareViewModel.refresh(participants: meeting.participants.screenShares)
        shouldShowShareScreen = screenShareViewModel.arrScreenShareParticipants.count > 0 ? true : false
        delegate?.refreshPluginsView {}
    }

    public func onVideoUpdate(videoEnabled _: Bool, participant _: RtkRemoteParticipant) {}
}

extension ActiveSpeakerMeetingViewModel: RtkChatEventListener {
    public func onMessageRateLimitReset() {}

    public func onChatUpdates(messages _: [ChatMessage]) {
        chatDelegate?.refreshMessages()
    }

    public func onNewChatMessage(message: ChatMessage) {
        if message.userId != meeting.localUser.userId {
            var chat = ""
            if let textMessage = message as? TextMessage {
                chat = "\(textMessage.displayName): \(textMessage.message)"
            } else {
                if message.type == ChatMessageType.image {
                    chat = "\(message.displayName): Send you an Image"
                } else if message.type == ChatMessageType.file {
                    chat = "\(message.displayName): Send you an File"
                }
            }
            notificationDelegate?.didReceiveNotification(type: .Chat(message: chat))
        }
    }
}

extension ActiveSpeakerMeetingViewModel: RtkPluginsEventListener {
    public func onPluginMessage(plugin _: RtkPlugin, eventName _: String, data _: Any?) {}

    public func onPluginActivated(plugin: RtkPlugin) {
        screenShareViewModel.refresh(plugins: meeting.plugins.active, selectedPlugin: plugin)
        delegate?.refreshPluginsView {}
    }

    public func onPluginDeactivated(plugin: RtkPlugin) {
        screenShareViewModel.removed(plugin: plugin)
        delegate?.refreshPluginsView {}
    }

    public func onPluginFileRequest(plugin _: RtkPlugin) {}
}
